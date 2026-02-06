# CYAN-FPGA 프로젝트 문서

## 빠른 시작: 어디서부터 시작할까요?

### 프로젝트가 처음이신가요? 여기서 시작하세요:

1. **5분** - 이 개요(Overview) 섹션 읽기
2. **15분** - 아래 현재 상태(Current Status) 검토
3. **30분** - 아키텍처 상세사항은 TECHNICAL_REFERENCE.md 참조
4. **1시간** - 품질 로드맵은 IMPROVEMENT_PLAN.md 학습
5. **지속** - 아래 문서 가이드 참조

### 시작 워크플로우

여기서 시작(README.md) → 시스템 아키텍처 이해 → 현재 상태 검토 → 작업 계획(IMPROVEMENT_PLAN.md) → 기술 상세사항 접근(TECHNICAL_REFERENCE.md) → 참조 자료

---

## 개요(Overview)

CYAN-FPGA 프로젝트는 ROIC(Readout Integrated Circuit) 제어 및 MIPI CSI-2 데이터 전송을 위한 Xilinx Artix-7 기반 FPGA 설계입니다.

**Target Hardware**: Xilinx Artix-7 XC7A35TFGG484-1

**주요 기능(Primary Features)**:
- Multi-clock domain 시스템 (200MHz, 100MHz, 20MHz, 5MHz, 1MHz)
- 비디오 스트리밍용 MIPI CSI-2 TX 출력
- TI ROIC 데이터 캡처용 LVDS 인터페이스 (12채널)
- 레지스터 제어용 SPI Slave 인터페이스
- 획득 제어용 Configurable Sequencer FSM
- 다중 획득 모드 지원
- 디버깅용 Integrated ILA

---

## 현재 상태 및 알려진 문제(Current Status and Known Issues)

**Status**: ✅ **Bitstream 완료** - Week 11

**최근 성과(Recent Achievements)**:
- ✅ Week 1: 모든 CDC 위반 수정 완료 (CDC-001, CDC-002)
- ✅ Week 2: Reset 표준화 완료 (RST-001, RST-002)
- ✅ Week 3: FSM 리팩토링 및 Testbench 완료 (FSM-001)
- ✅ Week 4: CDC-003 async_fifo_24b 통합, Reset 통합 (RST-003)
- ✅ Week 5: P0 주요 수정 완료 (SYN-001, SYN-002, CDC-003, RST-003)
- ✅ Week 6: Debug 통합 (M6-1), Sync 처리 (M6-2) 추출
- ✅ Week 7: Gate Driver 출력 (M7-1), ROIC 채널 배열 (M7-2) 추출
- ✅ Week 8: Control Signal Mux (M8-1), Power Control (M8-2) 추출
- ✅ Week 9: init.sv FSM 3-block 스타일 리팩토링 완료 (M9-1)
- ✅ Week 10: 최종 모듈 추출 완료, 총 33개 모듈
- ✅ Week 11: **Bitstream 생성 완료, ERR-017 해결**
- ✅ Week 12: **코드 리뷰 및 정리 완료** (미사용 신호 13개 제거)

**Week 11 주요 성과(Milestones)**:
- ✅ ERR-017: Bitstream Clock Routing 수정 (BUFG 명시적 인스턴스화)
- ✅ Build 자동화: TCL 스크립트 (build_bitstream.tcl) 완료
- ✅ File 정리: 594개 IP 생성 파일을 .gitignore로 이동
- ✅ 출력 파일: cyan_top.bit, .bin, .mcs 생성 완료
- ✅ Synthesis: 0 errors, 0 critical warnings
- ✅ Implementation: 0 errors, timing 충족

**향후 작업(Remaining Work)**:
- Week 12+: Simulation 검증, Test Coverage 확장

Open Issues: 0
Critical Issues: 0 ✅

### 완료된 이슈(Completed Issues) ✅

| Issue ID | Category | Status | PR | Solution |
|----------|----------|--------|-----|----------|
| CDC-001 | CDC Violation | ✅ Fixed | #1 | gen_sync_start용 3-stage synchronizer |
| CDC-002 | Missing Constraints | ✅ Fixed | #1 | Clock groups + CDC false paths |
| CDC-003 | MIPI Data CDC | ✅ Fixed | #1 | read_data_mux.sv에 async_fifo_24b 모듈 통합 |
| RST-001 | Reset Inconsistency | ✅ Fixed | #1 | reset_sync 모듈, active-LOW 표준 |
| RST-002 | Multiple Async Resets | ✅ Fixed | #1 | Domain당 단일 synchronized reset |
| RST-003 | Reset Polarity Mixed | ✅ Fixed | #5 | 모든 reset을 active-LOW로 통합 |
| SYN-001 | Syntax Error (dup ;) | ✅ Fixed | #5 | cyan_top.sv:530 중복 세미콜론 제거 |
| SYN-002 | Self-Assignment | ✅ Fixed | #5 | reg_map_integration.sv:149 자기 할당 제거 |
| FSM-001 | Non-Standard FSM | ✅ Fixed | #2 | 3-block FSM 리팩토링, 577→490 lines (sequencer_fsm) |
| FSM-002 | init.sv FSM Style | ✅ Fixed | - | init.sv를 3-block FSM로 리팩토링 (Week 9) |
| TOP-001 | cyan_top Decomposition | ✅ Fixed | - | 9개 모듈 추출 (Weeks 5-10) |
| ERR-017 | Clock Routing Error | ✅ Fixed | - | BUFG 명시적 인스턴스화, XDC 제약조건 업데이트 |
| CLR-001 | Unused Signals | ✅ Fixed | - | 13개 미사용 게이트 신호 제거 (Week 12) |

### Open Issues

| Issue ID | Category | Severity | Impact | Notes |
|----------|----------|----------|--------|-------|
| *None* | - | - | - | 모든 주요 및 높은 우선순위 이슈 해결됨 ✅ |


### 품질 지표(Quality Metrics)

| Metric | Week 0 | Week 5 | Week 10 | Week 11 | Target (Final) | Status |
|--------|--------|--------|---------|---------|----------------|--------|
| CDC Violations | 8+ | 0 | 0 | 0 | 0 | ✅ 달성 |
| Reset Consistency | 30% | 100% | 100% | 100% | 100% | ✅ 달성 |
| FSM Standard Compliance | 0% | 50% | 100% | 100% | 100% | ✅ 달성 |
| Syntax Errors | 2 | 0 | 0 | 0 | 0 | ✅ 달성 |
| Synthesis Errors | - | - | - | 0 | 0 | ✅ PASS |
| Bitstream Generation | - | - | - | ✅ | ✅ | ✅ PASS |
| Module Count | 21 | 24 | 33 | 39 | - | ✅ 완료 |
| cyan_top.sv Lines | 1261 | 1261 | 1316 | 1282 | <500 | 진행중 |
| Test Coverage | 23% | 23% | 23% | 23% | >70% | 계획됨 (Week 12) |
| IP Files Tracked | 594 | 594 | 594 | 0 (.gitignore) | 0 | ✅ 달성 |

**수행할 작업은?** 전체 로드맵은 IMPROVEMENT_PLAN.md 참조.

---

## 문서 가이드(Documentation Guide)

### 핵심 문서(Core Documentation)

| Document | Purpose | When to Use |
|----------|---------|-------------|
| README.md (이 파일) | 프로젝트 개요 및 탐색 허브 | 시작점, 리소스 찾기 |
| TECHNICAL_REFERENCE.md | 기술 사양, 모듈 상세, 리팩토링 가이드라인 | 구현 이해 |
| LESSONS_LEARNED.md | 워크플로우 개선 및 모범 사례 | 프로세스 개선 |
| **BUILD_PROCEDURE.md** | 빌드 절차 가이드 (빌드 스크립트 사용법) | 빌드/배포 시 |
| **IP_CORE_GUIDE.md** | IP 코어 설정 및 재생성 가이드 | IP 수정/재생성 시 |
| **RESOURCE_ANALYSIS.md** | 리소스/타이밍/전력 분석 보고서 | 성능 분석 시 |
| **API_REGISTER_GUIDE.md** | SPI 인터페이스 및 레지스터 API | 펌웨어 제어 시 |

### 보관 문서(Archived Documentation)

| Location | Contents | When to Use |
|----------|----------|-------------|
| doc/archive/ | 완료된 주간 보고서, 과거 계획 | 프로젝트 역사 이해 |

### 참조 자료(Reference Materials)

| File | Purpose |
|------|---------|
| fpga_block_diagram.png | 시스템 아키텍처 시각화 |
| ROIC_timing_chart.xlsx | ROIC 타이밍 사양 |
| Xdaq_Register_Map.xlsx | 레지스터 맵 문서 |
| Xdaq_Register_Map_24.xlsx | 레지스터 맵 (24-bit 버전) |
| xdaq_fpga_design.pptx | 설계 프레젠테이션 |

### 각 문서 사용법

**프로젝트 이해를 위해**:
1. README.md (이 파일)로 프로젝트 컨텍스트 시작
2. 시각적 아키텍처는 fpga_block_diagram.png 검토
3. ROIC Gate Driver는 TECHNICAL_REFERENCE.md 섹션 3 참조

**개발 작업을 위해**:
1. 현재 단계 우선순위는 IMPROVEMENT_PLAN.md 확인
2. 리팩토링 가이드라인은 TECHNICAL_REFERENCE.md 섹션 4 참조
3. 타이밍 요구사항은 ROIC_timing_chart.xlsx 참조
4. 레지스터 정의는 Xdaq_Register_Map.xlsx 참조

**이슈 해결을 위해**:
1. errors-and-solutions.md (.alfred-memory/rules/)에서 이슈 ID 조회
2. 권장 수정 사항 및 코드 예제 따르기
3. 성공 기준으로 검증

---

## 시스템 아키텍처(System Architecture)

### Clock Domain Architecture

| Clock Domain | Frequency | Description | Primary Usage |
|--------------|-----------|-------------|---------------|
| CLK_200MHZ | 200 MHz | DPHY high-speed clock | MIPI CSI-2 TX data path |
| CLK_100MHZ | 100 MHz | Main system clock | Register map, control logic |
| CLK_20MHZ | 20 MHz | Processing clock | Data reordering, sequencer |
| CLK_5MHZ | 5 MHz | Slow clock | Timing generation |
| CLK_1MHZ | 1 MHz | Very slow clock | Low-speed timers |

**기술 사양은 어디에?** 상세 아키텍처는 TECHNICAL_REFERENCE.md 참조.

---

## 개발 로드맵(Development Roadmap)

### 7-Phase 개선 계획(12+ Weeks)

| Phase | Focus | Duration | Status |
|-------|-------|----------|--------|
| Phase 1 | Critical Safety (CDC) | Week 1 | ✅ 완료 |
| Phase 2 | Reset Standardization | Week 2 | ✅ 완료 |
| Phase 3 | FSM Refactoring | Weeks 3-4 | ✅ 완료 |
| Phase 4 | Critical Fixes | Week 5 | ✅ 완료 |
| Phase 5 | Top-Level Decomposition | Weeks 6-10 | ✅ 완료 |
| Phase 6 | Bitstream Generation | Week 11 | ✅ 완료 |
| Phase 7 | Verification | Week 12+ | 계획됨 |

### 현재 단계: Phase 6 완료 - Bitstream Generation (Week 11)

**Weeks 1-11 모두 완료**:
- ✅ Week 1: CDC 위반 수정 (CDC-001, CDC-002)
- ✅ Week 2: Reset 표준화 (RST-001, RST-002)
- ✅ Week 3: FSM 리팩토링 (FSM-001) - sequencer_fsm.sv
- ✅ Week 4: CDC 수정, Reset 통합, 모듈 추출
- ✅ Week 5: P0 주요 수정 (SYN-001, SYN-002, CDC-003, RST-003)
- ✅ Week 6: Debug 통합 (M6-1), Sync 처리 (M6-2)
- ✅ Week 7: Gate Driver 출력 (M7-1), ROIC 채널 배열 (M7-2)
- ✅ Week 8: Control Signal Mux (M8-1), Power Control (M8-2)
- ✅ Week 9: init.sv FSM 3-block 스타일 리팩토링 (M9-1)
- ✅ Week 10: 최종 모듈 추출 완료, 문서 업데이트
- ✅ Week 11: **Bitstream 생성, ERR-017 수정, Build 자동화**

**Week 11 Deliverables**:
- ✅ ERR-017: Clock routing error 수정 (BUFG 명시적 인스턴스화)
- ✅ build_bitstream.tcl: 자동화 Build 스크립트
- ✅ post_script.tcl: Post-build 처리
- ✅ 출력 파일: cyan_top.bit, cyan_top.bin, cyan_top.mcs
- ✅ File 정리: 594개 IP 생성 파일을 .gitignore로
- ✅ Synthesis: PASS (0 errors)
- ✅ Implementation: PASS (0 errors, timing 충족)

**상세 로드맵**: 전체 작업 분류는 IMPROVEMENT_PLAN.md 참조.

---

## 모듈 목록(Module List - 39 Files)

### Core Modules (핵심 모듈)
| Module | Lines | Description | Status |
|--------|-------|-------------|--------|
| cyan_top.sv | 1292 | Top-level module | 🟡 Large |
| init.sv | 344 | Power initialization FSM (3-block) | 🟢 OK |
| sequencer_fsm.sv | 603 | Acquisition sequencer FSM (3-block) | 🟢 OK |
| read_data_mux.sv | 771 | LVDS data read multiplexer with async FIFO | 🟡 Medium |
| reg_map_integration.sv | 278 | SPI register map integration | 🟢 OK |

### Integration Modules (통합 모듈, Weeks 5-10 추출)
| Module | Lines | Week | Description | Status |
|--------|-------|------|-------------|--------|
| mipi_integration.sv | 89 | Week 5 | MIPI CSI-2 TX + AXI stream wrapper | 🟢 OK |
| sequencer_wrapper.sv | 128 | Week 5 | FSM + index generation wrapper | 🟢 OK |
| data_path_integration.sv | 109 | Week 5 | read_data_mux + data processing wrapper | 🟢 OK |
| debug_integration.sv | 166 | Week 6 (M6-1) | ILA debug integration | 🟢 OK |
| sync_processing.sv | 111 | Week 6 (M6-2) | Sync signal processing | 🟢 OK |
| gate_driver_output.sv | 135 | Week 7 (M7-1) | ROIC gate driver output logic | 🟢 OK |
| roic_channel_array.sv | 212 | Week 7 (M7-2) | ROIC 12-channel array processing | 🟢 OK |
| control_signal_mux.sv | 77 | Week 8 (M8-1) | Control signal multiplexing | 🟢 OK |
| power_control.sv | 99 | Week 8 (M8-2) | Power sequencing control | 🟢 OK |
| ti_roic_integration.sv | 154 | Week 4 | TI ROIC interface integration | 🟢 OK |

### CDC and Reset Modules (CDC 및 Reset 모듈)
| Module | Lines | Description | Status |
|--------|-------|-------------|--------|
| cdc_sync_3ff.sv | 91 | 3-stage CDC synchronizer | 🟢 OK |
| async_fifo_1b.sv | 117 | 1-bit async FIFO | 🟢 OK |
| async_fifo_24b.sv | 138 | 24-bit async FIFO (CDC-003 fix) | 🟢 OK |
| async_fifo.sv | 165 | Universal async FIFO | 🟢 OK |
| reset_sync.sv | 53 | Reset synchronizer | 🟢 OK |

### Clock and Timing (클럭 및 타이밍)
| Module | Lines | Description | Status |
|--------|-------|-------------|--------|
| clock_gen_top.sv | 82 | Clock generation top module | 🟢 OK |
| dcdc_clk.sv | 37 | DC-DC clock module | 🟢 OK |

### Communication Modules (통신 모듈)
| Module | Lines | Description | Status |
|--------|-------|-------------|--------|
| spi_slave.sv | 245 | SPI slave interface | 🟢 OK |
| i2c_master.sv | 186 | I2C master interface | 🟢 OK |
| roic_gate_drv_gemini.sv | 122 | Gemini ROIC gate driver | 🟢 OK |

### FIFO and Data Storage (FIFO 및 데이터 저장)
| Module | Lines | Description | Status |
|--------|-------|-------------|--------|
| fifo_1b.sv | 87 | 1-bit synchronous FIFO | 🟢 OK |

### TI-ROIC Subsystem (source/hdl/ti-roic/)
| Module | Lines | Description | Status |
|--------|-------|-------------|--------|
| ti_roic_top.sv | 236 | TI ROIC top module | 🟢 OK |
| ti_roic_tg.sv | 754 | Test pattern generator | 🟢 OK |
| deser_single.sv | 218 | Deserializer | 🟢 OK |
| indata_reorder.sv | 339 | Data reordering | 🟢 OK |
| first_ch_detector.sv | 322 | First channel detector | 🟢 OK |
| bit_align.sv | 225 | Bit alignment | 🟢 OK |
| bit_clock_module.sv | 103 | Bit clock module | 🟢 OK |
| roic_spi.sv | 129 | ROIC SPI interface | 🟢 OK |

### CSI2 Subsystem (source/hdl/csi2/)
| Module | Lines | Description | Status |
|--------|-------|-------------|--------|
| mipi_csi2_tx_top.sv | 255 | MIPI CSI-2 TX top | 🟢 OK |
| mipi_csi2_tx_bd.sv | 304 | MIPI CSI-2 TX block diagram | 🟢 OK |

### Legacy/Reference Modules (레거시/참조 모듈)
| Module | Lines | Description | Status |
|--------|-------|-------------|--------|
| cyan_top_new.sv | 1262 | Reference implementation | 🔵 Reference |
| init_refacto.sv | 479 | Legacy init reference | 🔵 Reference |
| p_define_refacto.sv | 509 | Parameter definitions | 🔵 Reference |
| reg_map_refacto.sv | 997 | Legacy register map reference | 🔵 Reference |

---

## 빠른 참조(Quick Reference)

### 프로젝트 상태(Project Status)
- 현재 품질 지표: 위의 표 참조
- 이슈 추적: .alfred-memory/rules/errors-and-solutions.md
- 성공 기준: IMPROVEMENT_PLAN.md

### 기술 정보(Technical Information)
- 시스템 아키텍처: TECHNICAL_REFERENCE.md - 완전한 기술 사양
- HDL 코딩 표준: TECHNICAL_REFERENCE.md - 섹션 1
- ROIC Gate Driver: TECHNICAL_REFERENCE.md - 섹션 3
- 리팩토링 가이드라인: TECHNICAL_REFERENCE.md - 섹션 4

### 참조 데이터(Reference Data)
- 레지스터 맵: Xdaq_Register_Map.xlsx, Xdaq_Register_Map_24.xlsx
- 타이밍 사양: ROIC_timing_chart.xlsx
- 아키텍처 다이어그램: fpga_block_diagram.png
- 설계 프레젠테이션: xdaq_fpga_design.pptx

### Build 결과물(Build Artifacts, Week 11)
| File | Location | Description |
|------|----------|-------------|
| cyan_top.bit | output/ | FPGA programming bitstream |
| cyan_top.bin | output/ | Binary format |
| cyan_top.mcs | output/ | SPI Flash image |
| cyan_top.ltx | output/ | Debug probes |
| *.rpt | reports/ | Timing/utilization reports |

---

## 일반적인 질문(Common Questions)

**어디서 시작해야 하나요?**
1. 이 README.md 읽기 (5분)
2. 위의 현재 상태 검토
3. 로드맵은 IMPROVEMENT_PLAN.md 학습 (30분)
4. 아키텍처는 TECHNICAL_REFERENCE.md 검토 (45분)

**현재 상태는 어떤가요?**
- 단계: Week 11 (Bitstream 완료) - 검증 준비 완료
- CDC 위반: 0 ✅ (Week 1 완료)
- Reset 일관성: 100% ✅ (Week 2 완료)
- FSM 표준 준수: 100% ✅ (Weeks 3, 9 완료)
- 모듈 수: 39 ✅ (Week 11 완료)
- Bitstream: ✅ PASS (Week 11 완료)
- 다음 단계: Simulation 검증, Test Coverage 확장 (Week 12+)

**수행할 작업은?**
- 즉시: Simulation 검증 (Week 12)
- 다음: Test Coverage를 23%에서 >70%로 확장
- 상세 작업 목록: IMPROVEMENT_PLAN.md

**기술 사양은 어디에 있나요?**
- 아키텍처: TECHNICAL_REFERENCE.md
- 타이밍: ROIC_timing_chart.xlsx
- 레지스터: Xdaq_Register_Map.xlsx
- 블록 다이어그램: fpga_block_diagram.png

**Bitstream을 어떻게 빌드하나요?**
```bash
# 프로젝트 루트에서
"D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat" -mode batch -source "build_bitstream.tcl" -log "build_bitstream.log" -nojournal
```

**레지스터 정보는 어떻게 찾나요?**
- 주요: Xdaq_Register_Map.xlsx (현재 버전)
- 대안: Xdaq_Register_Map_24.xlsx (24-bit 버전)
- 구현: TECHNICAL_REFERENCE.md 섹션 3

---

## 문서 유지보수(Document Maintenance)

| Document | Last Updated | Maintainer | Review Cycle |
|----------|--------------|------------|--------------|
| README.md | 2026-02-04 | FPGA Design Team | 주간(Weekly) |
| IMPROVEMENT_PLAN.md | 2026-02-04 | FPGA Design Team | 각 단계 종료 시 |
| TECHNICAL_REFERENCE.md | 2026-02-04 | FPGA Design Team | 필요시 |

---

**Project**: CYAN FPGA - Xilinx Artix-7 ROIC Controller
**Document Version**: 5.0 (Week 11 Update)
**Last Updated**: 2026-02-04 (Week 11 완료 - Bitstream 생성됨)

---

## 탐색 요약(Navigation Summary)

이 README는 다음을 위한 중심 허브입니다:
- 프로젝트 이해 (개요 섹션)
- 현재 상태 확인 (Current Status)
- 작업 찾기 (개발 로드맵 또는 IMPROVEMENT_PLAN.md)
- 기술 상세 정보 얻기 (TECHNICAL_REFERENCE.md)
- 레지스터 정보 조회 (Xdaq_Register_Map.xlsx)
- 타이밍 사양 검토 (ROIC_timing_chart.xlsx)
- 아키텍처 보기 (fpga_block_diagram.png)
- Bitstream 빌드 (build_bitstream.tcl)
