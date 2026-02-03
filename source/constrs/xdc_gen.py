import pandas as pd
import os

# 현재 작업 디렉토리 출력 (파일 저장 위치 확인용)
print("Current working directory:", os.getcwd())

# 엑셀 파일 열기 (header 값은 엑셀 상황에 맞게 수정)
df = pd.read_excel(r"D:\git_workspace\CYAN-FPGA\xdaq_top\source\constrs\xc7a35tfgg484_Pinmap.xlsx", sheet_name="Sheet1", header=1)

# 컬럼명 공백 제거
df.columns = df.columns.str.strip()

print("Columns:", df.columns.tolist())  # 컬럼명 출력 확인

# 필요한 컬럼이 모두 있는지 확인
required_cols = ['Pin2', 'Signal Name', 'Bank', 'I/O Type']
for col in required_cols:
    if col not in df.columns:
        raise ValueError(f"Column '{col}' not found in Excel sheet")

# 필요한 열 추출 (Bank, I/O Type 도 포함해서 가져옴)
df = df[required_cols].dropna(subset=['Pin2', 'Signal Name', 'Bank', 'I/O Type'])

# 'Bank'와 'I/O Type'이 'NA'인 행 제외
df = df[~df['Bank'].astype(str).str.upper().eq('NA')]
df = df[~df['I/O Type'].astype(str).str.upper().eq('NA')]

# 'Signal Name' 필터링: ['-', '', 'GND'] 제외 + 'VCC_'로 시작하는 것도 제외
df = df[~df['Signal Name'].isin(['-', '', 'GND'])]
df = df[~df['Signal Name'].str.startswith('VCC_')]

# 출력 파일 경로 지정 (원하는 경로로 변경 가능)
output_path = r"D:\git_workspace\CYAN-FPGA\xdaq_top\source\constrs\output.xdc"
print(f"Writing output to: {output_path}")

# 출력 파일 작성
with open(output_path, "w") as f:
    for bank, group in df.groupby('Bank'):
        f.write(f"# ==============================\n")
        f.write(f"# Bank {bank}\n")
        f.write(f"# ==============================\n")
        for _, row in group.iterrows():
            signal = row['Signal Name'].strip()
            pin = str(row['Pin2']).strip()  # 숫자가 있을 수도 있어 str 처리
            f.write(f"set_property PACKAGE_PIN {pin} [get_ports {signal}]\n")
            # f.write(f"set_property IOSTANDARD LVCMOS33 [get_ports {signal}]\n")
        f.write("\n")

with open(output_path, "w") as f:
    for bank, group in df.groupby('Bank'):
        f.write(f"# ==============================\n")
        f.write(f"# Bank {bank}\n")
        f.write(f"# ==============================\n")
        for _, row in group.iterrows():
            signal = row['Signal Name'].strip()
            pin = str(row['Pin2']).strip()  # 숫자가 있을 수도 있어 str 처리
            # f.write(f"set_property PACKAGE_PIN {pin} [get_ports {signal}]\n")
            f.write(f"set_property IOSTANDARD LVCMOS33 [get_ports {signal}]\n")
        f.write("\n")

