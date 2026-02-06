# xdaq_top 빌드 절차 가이드 (Build Procedure Guide)

**Date**: 2026-02-05
**Project**: CYAN-FPGA xdaq_top
**FPGA**: Xilinx Artix-7 XC7A35TFGG484-1
**Vivado Version**: 2025.2

---

## 1. 사전 요구사항 (Prerequisites)

### 1.1 소프트웨어

| 소프트웨어 | 버전 | 용도 |
|----------|------|------|
| Xilinx Vivado | 2025.2 | FPGA 빌드 툴 |
| Python | 3.x | 제약조건 생성 스크립트 |
| Tcl | 8.5+ | Vivado 스크립트 |

### 1.2 환경 변수

```bash
# Vivado 경로 설정 (Windows)
set PATH=%PATH%;D:\AMDDesignTools\2025.2\Vivado\bin

# Linux/macOS
export PATH=$PATH:/tools/Xilinx/Vivado/2025.2/bin
```

### 1.3 필수 파일

| 파일 | 경로 | 설명 |
|------|------|------|
| 프로젝트 파일 | `build/xdaq_top.xpr` | Vivado 프로젝트 |
| 빌드 스크립트 | `build_bitstream.tcl` | 자동 빌드 스크립트 |
| 추가 스크립트 | `add_files.tcl` | 모듈 추가 스크립트 |
| 제약조건 파일 | `source/constrs/cyan_top.xdc` | 핀/타이밍 제약조건 |

---

## 2. 프로젝트 생성 절차

### 2.1 새 프로젝트 생성

```tcl
# Vivado TCL Console 또는 vivado -mode tcl
create_project xdaq_top D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/build -part xc7a35tfgg484-1
set_property target_language Verilog [current_project]
```

### 2.2 소스 파일 추가

```tcl
# RTL 파일 추가
add_files -norecurse {
    ./source/hdl/cyan_top.sv
    ./source/hdl/clock_gen_top.sv
    ./source/hdl/reset_sync.sv
    # ... 기타 모듈 파일들
}

# 제약조건 파일 추가
add_files -fileset constrs_1 -norecurse ./source/constrs/cyan_top.xdc
add_files -fileset constrs_1 -norecurse ./source/constrs/timing.xdc

# IP 코어 추가
add_files -norecurse [
    ./source/ip/clk_ctrl/clk_ctrl.xci
    ./source/ip/indata_ram/indata_ram.xci
    ./source/ip/seq_lut/seq_lut.xci
    # ... 기타 IP 코어들
]
```

### 2.3 IP 업그레이드

```tcl
# IP 코어 업그레이드 및 재생성
upgrade_ip [get_ips -all [current_project]]
export_ip_user_files [get_ips -all [current_project]]
```

---

## 3. 빌드 스크립트 사용법

### 3.1 build_bitstream.tcl - 전체 빌드

**용도**: 합성(Synthesis) → 구현(Implementation) → 비트스트림(Bitstream) 생성까지 자동화

**실행 방법**:
```bash
# Windows
vivado -mode batch -source build_bitstream.tcl -log build_bitstream.log -nojournal

# Linux/macOS
vivado -mode batch -source build_bitstream.tcl -log build_bitstream.log
```

**빌드 단계**:
1. **Synthesis**: RTL → 넷리스트 변환
2. **Implementation**: 넷리스트 → 배치/라우팅
3. **Bitstream**: 프로그래밍 파일 생성

**출력 파일**:
| 파일 | 위치 | 설명 |
|------|------|------|
| `xdaq_top.bit` | `build/xdaq_top.runs/impl_1/` | FPGA 다운로드용 |
| `xdaq_top.bin` | `build/xdaq_top.runs/impl_1/` | 외부 메모리용 |
| `xdaq_top.ltx` | `build/xdaq_top.runs/impl_1/` | ILA 디버깅용 |

### 3.2 add_files.tcl - 모듈 추가

**용도**: 새로운 서브 모듈을 프로젝트에 추가

**실행 방법**:
```bash
vivado -mode batch -source add_files.tcl
```

**추가되는 파일**:
- `async_fifo_controller.sv`
- `data_path_selector.sv`
- `timing_generator.sv`
- `state_led_controller.sv`
- `rf_spi_controller.sv`
- `mipi_interface_wrapper.sv`

**새 모듈 추가 방법**:
1. `add_files.tcl` 파일 편집
2. `add_files` 리스트에 새 파일 경로 추가
3. 스크립트 실행

```tcl
add_files {
    D:/workspace/.../new_module.sv
}
update_compile_order -import_sources
```

### 3.3 xdc_gen.py - 제약조건 생성

**용도**: 엑셀 핀맵에서 XDC 제약조건 파일 자동 생성

**실행 방법**:
```bash
python source/constrs/xdc_gen.py
```

**입력**: `source/constrs/c7a35tfgg484_Pinmap.xlsx`

**출력**: `source/constrs/output.xdc`

---

## 4. 빌드 출력 확인

### 4.1 성공 메시지

```
==========================================
BUILD SUMMARY
==========================================
Synthesis: PASS
Implementation: PASS
Bitstream: PASS
Bitstream file: D:/workspace/.../xdaq_top.bit
==========================================
```

### 4.2 리소스 사용량 확인

```tcl
# Vivado GUI에서
open_report utilization_report
# 또는
report_utilization -file reports/utilization.txt
```

### 4.3 타이밍 보고서

```tcl
# 타이밍 요약
report_timing_summary -file reports/timing_summary.txt

# 상세 타이밍
report_timing -sort_by slack -max_paths 10 -file reports/timing_detailed.txt
```

---

## 5. 문제 해결 (Troubleshooting)

### ERR-017: Clock Routing Error

**증상**:
```
Place 30-574 - IOB driving a BUFG must use a CCIO in the same half side
```

**해결**:
```systemverilog
// WRONG - Implicit BUFG
assign fclk_out = fclk_in_int;

// CORRECT - Explicit BUFG
BUFG fclk_bufg_inst (
    .I(fclk_in_int),
    .O(fclk_out)
);
```

### ERR-020: Module Files Not Added

**증상**:
```
ERROR: [Netlist 29-44] module 'xxx' not found
```

**해결**:
```bash
# add_files.tcl 실행
vivado -mode batch -source add_files.tcl
```

### ERR-021: TCL Path Issues

**증상**: 상대 경로가 작동하지 않음

**해결**: 절대 경로 사용
```tcl
# WRONG
add_files ../../source/hdl/module.sv

# CORRECT
add_files D:/workspace/.../source/hdl/module.sv
```

### Synthesis 실패

**증상**:
```
ERROR: [Synth 8-xxx] Syntax error
```

**해결**:
1. RTL 파일 문법 확인
2. `find . -name "*.sv"`로 모든 SV 파일이 프로젝트에 포함되었는지 확인

### Timing Closure 실패

**증상**: WNS (Worst Negative Slack) < 0

**해결**:
1. `timing.xdc`에서 제약조건 완화
2. 파이프라인 단계 추가
3. 병목 경로 최적화

---

## 6. 빌드 체크리스트

빌드 전 확인:
- [ ] Vivado 버전 확인 (2025.2)
- [ ] 프로젝트 파일 존재 (`build/xdaq_top.xpr`)
- [ ] IP 코어 업데이트 완료
- [ ] 제약조건 파일 추가 완료

빌드 후 확인:
- [ ] Synthesis 성공
- [ ] Implementation 성공
- [ ] Bitstream 생성 완료
- [ ] 타이밍 클로저 (WNS >= 0)
- [ ] 리소스 사용량 확인
- [ ] 출력 파일 존재 (.bit, .bin, .ltx)

---

## 7. 빠른 참조 (Quick Reference)

| 명령 | 용도 |
|------|------|
| `vivado -mode batch -source build_bitstream.tcl` | 전체 빌드 |
| `vivado -mode batch -source add_files.tcl` | 모듈 추가 |
| `python source/constrs/xdc_gen.py` | 제약조건 생성 |
| `open_project build/xdaq_top.xpr` | 프로젝트 열기 |
| `report_utilization` | 리소스 사용량 |
| `report_timing_summary` | 타이밍 요약 |

---

**END OF BUILD PROCEDURE GUIDE**
