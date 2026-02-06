# IP 코어 가이드 (IP Core Guide)

**Date**: 2026-02-05
**Project**: CYAN-FPGA xdaq_top
**Vivado Version**: 2025.2

---

## 1. IP 코어 개요

| IP 이름 | 타입 | 용도 | 상태 |
|--------|------|------|------|
| `clk_ctrl` | Clocking Wizard | 다중 클럭 생성 | ✅ |
| `indata_ram` | Block RAM | 입력 데이터 저장 | ✅ |
| `roic_data_bmem` | Block ROM | ROIC 데이터 저장 | ✅ |
| `aed_data_bmem` | Block ROM | AED 데이터 저장 | ✅ |
| `seq_lut` | Distributed RAM | 시퀀스 룩업테이블 | ✅ |
| `ila_0`, `ila_0_1` | Integrated Logic Analyzer | 디버그 | ✅ |
| `ila_csi2` | ILA (CSI-2) | MIPI 디버그 | ✅ |
| `ila_rd_tx` | ILA (Read Data) | 데이터 경로 디버그 | ✅ |
| `ila_top` | ILA (Top) | 최상위 디버그 | ✅ |

---

## 2. 클럭 위저드 (Clock Wizard)

### 2.1 개요

**IP 이름**: `clk_ctrl`
**위치**: `source/ip/clk_ctrl/`
**타입**: MMCM (Mixed-Mode Clock Manager)

### 2.2 설정 파라미터

| 파라미터 | 값 | 설명 |
|----------|-----|------|
| 입력 클럭 | 50 MHz (차동) | `clk_in1_p/n` |
| 출력 c0 | 100 MHz | 시스템 클럭 (`CLK_100MHZ`) |
| 출력 c1 | 20 MHz | 데이터 처리 (`CLK_20MHZ`) |
| 출력 dphy_clk | 200 MHz | MIPI CSI-2 TX (`CLK_200MHZ`) |
| 프리미티브 | MMCM | 클럭 관리자 |

### 2.3 포트 정의

```systemverilog
clk_ctrl clk_ctrl_inst (
    .clk_in1_p(clk_50m_p),  // 입력: 50MHz 차동 클럭
    .clk_in1_n(clk_50m_n),
    .reset(reset),           // 입력: Active-HIGH 리셋
    .c0(clk_100mhz),        // 출력: 100MHz
    .c1(clk_20mhz),         // 출력: 20MHz
    .dphy_clk(clk_200mhz),  // 출력: 200MHz
    .locked(locked)         // 출력: 클럭 락 신호
);
```

### 2.4 재생성 절차

1. Vivado에서 IP Catalog 열기
2. `clk_ctrl` 우클릭 → **Reset Output Product**
3. **Customize IP**에서 설정 확인
4. **OK** → **Generate**
5. 재생성 완료 후 `status = ip_generate_complete` 확인

### 2.5 주의사항

- ⚠️ **반드시 명시적 BUFG 사용**: ERR-017 참조
- ⚠️ **리셋 극성**: Active-HIGH (설정 확인 필요)
- ⚠️ **locked 신호**: 클럭 안정화 후 사용 시작

---

## 3. 블록 RAM (Block RAM)

### 3.1 indata_ram

**위치**: `source/ip/indata_ram/`
**용도**: 입력 데이터 버퍼링
**타입**: Block RAM (True Dual Port)

**설정**:
| 파라미터 | 값 |
|----------|-----|
| 깊이 (Depth) | 1024 |
| 폭 (Width) | 32 |
| 쓰기 폭 | 32 |
| 읽기 폭 | 32 |

**인스턴스**:
```systemverilog
indata_ram u_indata_ram (
    .clka(clk_100mhz),
    .rsta(reset),
    .wea(write_enable),
    .addra(write_addr),
    .dina(write_data),
    .douta(read_data)
);
```

### 3.2 roic_data_bmem

**위치**: `source/ip/roic_data_bmem/`
**용도**: ROIC 데이터 저장 (ROM)
**타입**: Block ROM

**설정**:
| 파라미터 | 값 |
|----------|-----|
| 깊이 (Depth) | 4096 |
| 폭 (Width) | 32 |
| 초기화 파일 | COE 파일 필요시 |

### 3.3 aed_data_bmem

**위치**: `source/ip/aed_data_bmem/`
**용도**: AED 데이터 저장 (ROM)

---

## 4. 분산 RAM (Distributed RAM)

### 4.1 seq_lut

**위치**: `source/ip/seq_lut/`
**용도**: 시퀀서 룩업테이블
**타입**: Distributed RAM

**설정**:
| 파라미터 | 값 |
|----------|-----|
| 깊이 (Depth) | 256 |
| 폭 (Width) | 32 |
| 메모리 타입 | Distributed RAM |

---

## 5. ILA (Integrated Logic Analyzer)

### 5.1 ILA 개요

ILA는 실시간 디버깅을 위한 Xilinx IP 코어입니다.

| ILA 이름 | 트리거 신호 | 샘플深度 | 용도 |
|----------|-------------|----------|------|
| `ila_0` | 일반 신호 | 16384 | 일반 디버그 |
| `ila_0_1` | 일반 신호 | 16384 | 일반 디버그 |
| `ila_csi2` | MIPI DPHY | 16384 | MIPI 인터페이스 |
| `ila_rd_tx` | Read Data Path | 16384 | 데이터 경로 |
| `ila_top` | Top Level | 16384 | 시스템 전체 |

### 5.2 ILA 설정

**표준 설정**:
- 샘플 깊이: 16384
- 트리거 타입: Basic
- 트리거 포지션: Pre-trigger = 0
- 데이터 윈도: 16 (최대)

### 5.3 ILA 사용법

1. **프로그래밍**: Vivado Hardware Manager로 `.bit`와 `.ltx` 함께 다운로드
2. **장치 설정**: Device가 `.ltx`와 함께 로드되었는지 확인
3. **트리거 설정**: Vivado에서 ILA 코어 선택 후 트리거 조건 설정
4. **캡처**: **Run Trigger** 버튼 클릭
5. **분석**: Waveform 창에서 신호 분석

### 5.4 ILA 재생성

```tcl
# ILA 코어 재생성
open_project build/xdaq_top.xpr

# ILA 선택 후
reset_ip [get_ips ila_*]
upgrade_ip [get_ips ila_*]
export_ip_user_files [get_ips ila_*]
```

---

## 6. IP 재생성 절차

### 6.1 전체 재생성

```tcl
# 프로젝트 열기
open_project D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/build/xdaq_top.xpr

# 모든 IP 업그레이드
upgrade_ip [get_ips -all]

# 모든 IP 사용자 파일 내보내기
export_ip_user_files [get_ips -all]

# Synthesis 재실행
reset_run synth_1
launch_runs synth_1
wait_on_run synth_1
```

### 6.2 개별 IP 재생성

```tcl
# 특정 IP만 재생성
open_ip_manager [get_ips clk_ctrl]

# 또는 Tcl 콘솔에서
reset_ip clk_ctrl
upgrade_ip clk_ctrl
```

---

## 7. IP 코어 추가 절차

### 7.1 새 IP 코어 생성

1. **IP Catalog 열기**: Flow Navigator → IP Catalog
2. **IP 선택**: 원하는 IP 더블클릭
3. **설정**: 파라미터 입력
4. **생성**: Generate 버튼 클릭
5. **추가**: 자동으로 프로젝트에 추가됨

### 7.2 생성 후 설정

```tcl
# IP 코어를 RTL 모듈에 연결
# instantiation은 IP 생성 시 자동으로 생성된 예제 코드 참조

# 소스 파일 위치: source/ip/<ip_name>/
# .xci 파일: IP 설정 정보
# .veo 파일: 인스턴스 템플릿
```

---

## 8. IP 코어 트러블슈팅

### IP 로킹 실패

**증상**:
```
ERROR: [IP_Flow 19-4298] Cannot lock the IP
```

**해결**:
1. Vivado 재시작
2. `.cache` 디렉토리 삭제 후 재시도

### IP 업그레이드 실패

**증상**: IP 버전 호환성 문제

**해결**:
```tcl
# IP를 새로운 버전으로 재설정
set_property ip_repo_paths {} [current_project]
update_ip_catalog
```

### ILA가 트리거되지 않음

**증상**: 트리거 조건 맞음에도 캡처 안됨

**해결**:
1. `.ltx` 파일이 함께 다운로드되었는지 확인
2. Vivado 버전과 일치하는지 확인
3. ILA 코어가 Clock Domain 내에 있는지 확인

---

## 9. IP 관련 ERR-XXX

| 에러 코드 | 설명 | 해결책 |
|----------|------|--------|
| ERR-017 | Implicit BUFG inference | 명시적 BUFG 인스턴스화 |
| ERR-020 | Module not found | add_files.tcl 실행 |

---

**END OF IP CORE GUIDE**
