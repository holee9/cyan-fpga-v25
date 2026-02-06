# 리소스/성능 분석 보고서 (Resource Analysis Report)

**Date**: 2026-02-05
**Project**: CYAN-FPGA xdaq_top
**FPGA**: Xilinx Artix-7 XC7A35TFGG484-1
**Vivado Version**: 2025.2

---

## 1. 리소스 사용량 요약 (Resource Utilization)

### 1.1 Artix-7 XC7A35TFGG484-1 사양

| 리소스 | 사용 가능량 | 비고 |
|--------|-----------|------|
| Slice LUTs | 20,800 | 룩업 테이블 |
| Slice Registers | 41,600 | 플립플롭 |
| BRAMs | 50 | 36Kb 블록 RAM |
| DSP48E1s | 100 | DSP 슬라이스 |
| I/O Pins | 300 | 입출력 핀 |
| Clocking Tiles | 6 | 클럭 리소스 |

### 1.2 현재 사용량

> **참고**: 실제 리소스 사용량은 Vivado Synthesis 후 `report_utilization`로 확인하세요.

| 리소스 | 사용량 | 사용률 | 상태 |
|--------|--------|--------|------|
| Slice LUTs | TBD | TBD | ⏳ 분석 필요 |
| Slice Registers | TBD | TBD | ⏳ 분석 필요 |
| BRAMs | TBD | TBD | ⏳ 분석 필요 |
| DSP48E1s | TBD | TBD | ⏳ 분석 필요 |

### 1.3 리소스 확인 방법

```tcl
# Vivado Tcl Console 또는 스크립트
open_project build/xdaq_top.xpr

# Synthesis 실행 후
report_utilization -file reports/utilization_report.txt

# 상세 요약
report_utilization -hierarchical -file reports/utilization_detailed.txt
```

---

## 2. 타이밍 분석 (Timing Analysis)

### 2.1 클럭 도메인

| 클럭 도메인 | 주파수 | 용도 | 소스 |
|-------------|--------|------|------|
| `CLK_200MHZ` | 200 MHz | MIPI CSI-2 TX 데이터 경로 | `clk_ctrl` |
| `CLK_100MHZ` | 100 MHz | 메인 시스템 클럭 | `clk_ctrl` |
| `CLK_20MHZ` | 20 MHz | 데이터 처리 | `clk_ctrl` |
| `CLK_50MHZ` | 50 MHz | 기준 클럭 (입력) | 외부 |

### 2.2 타이밍 제약조건

**관련 파일**: `source/constrs/timing.xdc`

```tcl
# 입력 클럭
create_clock -period 20.000 [get_ports clk_50m_p]

# 생성 클럭
create_generated_clock -name clk_100mhz -source [get_pins clk_ctrl_inst/CLKOUT0] \
    [get_pins clk_ctrl_inst/c0]*
create_generated_clock -name clk_20mhz -source [get_pins clk_ctrl_inst/CLKOUT1] \
    [get_pins clk_ctrl_inst/c1]*
create_generated_clock -name clk_200mhz -source [get_pins clk_ctrl_inst/CLKOUT2] \
    [get_pins clk_ctrl_inst/dphy_clk]*
```

### 2.3 타이밍 확인 방법

```tcl
# 타이밍 요약
report_timing_summary -file reports/timing_summary.txt

# 상세 타이밍 (WNS 확인)
report_timing -sort_by slack -max_paths 10 -file reports/timing_detailed.txt

# 제약조건 확인
report_timing_constraints -file reports/constraints.txt
```

### 2.4 Timing Closure 목표

| 지표 | 목표 | 현재 상태 |
|------|------|----------|
| WNS (Worst Negative Slack) | ≥ 0 | ⏳ 확인 필요 |
| WHS (Worst Hold Slack) | ≥ 0.2 | ⏳ 확인 필요 |
| Total Negative Slack (TNS) | 0 | ⏳ 확인 필요 |

---

## 3. 전력 소비 분석 (Power Analysis)

### 3.1 전력 소비 구성

| 구성 요소 | 예상 비율 | 설명 |
|----------|----------|------|
| Dynamic Power | ~70% | 스위칭 전력 |
| Static Power | ~30% | 누설 전력 |

### 3.2 전력 보고서 생성

```tcl
# Synthesis 또는 Implementation 후
report_power -file reports/power_report.txt

# 상세 전력 분석
open_report power_report
```

### 3.3 전력 최적화 방법

1. **Clock Gating**: 사용하지 않는 클럭 게이팅
2. **Block Enable**: BRAM/DSP 사용하지 않을 때 비활성화
3. **Frequency Scaling**: 가능한 낮은 주파수 사용

---

## 4. 클럭 도메인 분석 (Clock Domain Analysis)

### 4.1 클럭 도메인 그래프

```
       ┌─────────────┐
       │  CLK_50MHZ   │ (입력: 외부)
       └──────┬───────┘
              │
       ┌──────▼───────┐
       │  clk_ctrl   │ (MMCM)
       └──────┬───────┘
     ┌─────┼─────┬─────┐
     │     │     │     │
┌────▼─┐ ┌─▼──┐ ┌▼────┐
│CLK_ │ │CLK│ │CLK_ │
│100M │ │ 20│ │ 200M│
└─────┘ └────┘ └─────┘
  시스템  데이터 MIPI
```

### 4.2 CDC (Clock Domain Crossing)

| 소스 도메인 | 대상 도메인 | 동기화 방법 | 상태 |
|-------------|-------------|-------------|------|
| CLK_50MHZ | CLK_100MHZ | 2-FF Synchronizer | ✅ |
| CLK_20MHZ | CLK_100MHZ | FIFO | ✅ |
| CLK_200MHZ | CLK_100MHZ | FIFO (MIPI) | ✅ |

**CDC 검증**:
```tcl
# CDC 리포트 (Vivado HLS 또는 별도 툴 필요)
report_clock_interaction -file reports/cdc_interaction.txt
```

---

## 5. 병목 현상 및 최적화

### 5.1 잠재적 병목 지점

| 영역 | 병목 원인 | 최적화 방안 |
|------|-----------|-----------|
| 데이터 경로 | 조합 논리 복잡도 | 파이프라인 추가 |
| MIPI 인터페이스 | 고속 신호 | Timing 예외 적용 |
| FSM | 상태 전환 지연 | 상태 인코딩 최적화 |

### 5.2 최적화 권장사항

1. **리소스 최적화**
   - 리소스 공유 감안
   - Shift Register 최적화 (SRL16)

2. **타이밍 최적화**
   - Critical Path 파이프라인화
   - Register Balancing
   - Logic Duplication

3. **전력 최적화**
   - Clock Gating 추가
   - 불필요한 신호 제거

---

## 6. 보고서 생성 절차

### 6.1 Vivado GUI

1. **Open Project**: `build/xdaq_top.xpr`
2. **Run Synthesis**: “Run Synthesis” 클릭
3. **Open Reports**:
   - Synthesis → **Reports** → **Utilization Reports**
   - Synthesis → **Reports** → **Timing Reports**
   - Synthesis → **Reports** → **Power Reports**

### 6.2 Tcl 스크립트

```tcl
# generate_reports.tcl
open_project build/xdaq_top.xpr

# Synthesis 실행
launch_runs synth_1
wait_on_run synth_1

# 리포트 생성
report_utilization -file reports/utilization.txt
report_timing_summary -file reports/timing_summary.txt
report_power -file reports/power.txt
report_clock_interaction -file reports/cdc.txt

# 닫기
close_project
```

**실행**:
```bash
vivado -mode batch -source generate_reports.tcl
```

---

## 7. 주요 메트릭 (Key Metrics)

### 7.1 목표 대비

| 메트릭 | 목표 | 현재 | 비고 |
|--------|------|------|------|
| LUT 사용률 | < 80% | TBD | 분석 필요 |
| Register 사용률 | < 80% | TBD | 분석 필요 |
| BRAM 사용률 | < 80% | TBD | 분석 필요 |
| DSP 사용률 | < 80% | TBD | 분석 필요 |
| WNS | ≥ 0 | TBD | 분석 필요 |
| TNS | 0 | TBD | 분석 필요 |

### 7.2 성능 지표

| 지표 | 값 | 설명 |
|------|-----|------|
| Fmax (최대 주파수) | TBD | Timing 분석 후 확인 |
| 총 전력 소비 | TBD | Power Report 확인 |
| 절연 전력 | TBD | Power Report 확인 |
| 동적 전력 | TBD | Power Report 확인 |

---

## 8. 차기 분석 계획

- [ ] Vivado Synthesis 실행
- [ ] `report_utilization` 실행 및 저장
- [ ] `report_timing_summary` 실행 및 저장
- [ ] `report_power` 실행 및 저장
- [ ] CDC 검증 수행
- [ ] 병목 경로 식별
- [ ] 최적화 권장사항 도출

---

**END OF RESOURCE ANALYSIS REPORT**
