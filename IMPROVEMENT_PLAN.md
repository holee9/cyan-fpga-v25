# CYAN-FPGA 개선 계획 v2.0

**Project**: xdaq_top (CYAN-FPGA)
**FPGA**: Xilinx Artix-7 XC7A35TFGG484-1
**Tool**: Vivado 2025.2
**Date**: 2026-02-04
**Current Week**: Week 11 (Bitstream 완료)
**Document Version**: 2.0

---

## 목차(Table of Contents)

1. [Executive Summary](#1-executive-summary)
2. [Completed Work (Weeks 1-11)](#2-completed-work-weeks-1-11)
3. [Current Status](#3-current-status)
4. [Remaining Work](#4-remaining-work)
5. [Module Specifications](#5-module-specifications)
6. [Roadmap (Weeks 12+)](#6-roadmap-weeks-12)
7. [Success Criteria](#7-success-criteria)
8. [Risk & Mitigation](#8-risk--mitigation)

---

## 1. Executive Summary

### 1.1 프로젝트 개요(Project Overview)

CYAN-FPGA 프로젝트는 ROIC(Readout Integrated Circuit) 제어 및 MIPI CSI-2 데이터 전송을 위한 Xilinx Artix-7 기반 FPGA 설계입니다. 11주에 걸쳐 체계적인 리팩토링을 수행했으며, 주요 안전 이슈(CDC), Reset 표준화, FSM 리팩토링, 모듈 추출, Bitstream 생성을 달성했습니다.

### 1.2 주요 성과(Key Achievements, Weeks 1-11)

| Category | Metric | Initial | Final | Status |
|----------|--------|---------|-------|--------|
| CDC Violations | 8+ | 0 | ✅ 달성 |
| Reset Consistency | 30% | 100% | ✅ 달성 |
| FSM Standard Compliance | 0% | 100% | ✅ 달성 |
| Syntax Errors | 2 | 0 | ✅ 달성 |
| Bitstream Generation | N/A | PASS | ✅ 달성 |
| Module Count | 21 | 39 | ✅ 완료 |
| IP Files Tracked | 594 | 0 (.gitignore) | ✅ 달성 |

### 1.3 Week 11 주요 성과(Milestone)

**Status**: ✅ **BITSTREAM 완료**

- ✅ ERR-017: Bitstream Clock Routing 수정 (BUFG 명시적 인스턴스화)
- ✅ Build 자동화: TCL 스크립트 (build_bitstream.tcl) 완료
- ✅ File 정리: 594개 IP 생성 파일을 .gitignore로 이동
- ✅ 출력 파일: cyan_top.bit, .bin, .mcs 생성 완료
- ✅ Synthesis: 0 errors, 0 critical warnings
- ✅ Implementation: 0 errors, timing 충족

---

## 2. Completed Work (Weeks 1-11)

### 2.1 Phase 1: Critical Safety (Week 1)

**Focus**: Clock Domain Crossing (CDC) 위반 수정

| Issue ID | Category | Description | Solution |
|----------|----------|-------------|----------|
| CDC-001 | CDC Violation | gen_sync_start signal이 domain을 무단위로 건넘감 | 3-stage synchronizer |
| CDC-002 | Missing Constraints | CDC false path 제약조건 없음 | Clock groups + CDC constraints |

**Deliverables**:
- cdc_sync_3ff.sv: 3-stage CDC synchronizer 모듈 (91 lines)
- Clock groups를 포함한 timing 제약조건 업데이트
- 모든 CDC 위반 해결

### 2.2 Phase 2: Reset Standardization (Week 2)

**Focus**: 통합 Reset 아키텍처

| Issue ID | Category | Description | Solution |
|----------|----------|-------------|----------|
| RST-001 | Reset Inconsistency | active-LOW/HIGH mixed | Active-LOW 표준 |
| RST-002 | Multiple Async Resets | Domain당 여러 async reset | 단일 synchronized reset |

**Deliverables**:
- reset_sync.sv: Reset synchronizer 모듈 (53 lines)
- 모든 reset을 active-LOW 극성으로 통합
- Async assert, sync deassert 패턴

### 2.3 Phase 3: FSM Refactoring (Weeks 3-4)

**Focus**: 3-Block FSM 스타일 준수

| Issue ID | Category | Description | Solution |
|----------|----------|-------------|----------|
| FSM-001 | Non-Standard FSM | sequencer_fsm가 2-block 스타일 사용 | 3-block 리팩토링 |
| CDC-003 | MIPI Data CDC | async_fifo_24b 통합 | async_fifo_24b 모듈 |

**Deliverables**:
- sequencer_fsm.sv: 3-block 스타일로 리팩토링 (603 lines)
- async_fifo_24b.sv: 24-bit async FIFO (138 lines)
- async_fifo.sv: Universal async FIFO (165 lines)
- FSM testbench 생성

### 2.4 Phase 4: Critical Fixes (Week 5)

**Focus**: P0 Syntax 및 통합 이슈

| Issue ID | Category | Description | Solution |
|----------|----------|-------------|----------|
| SYN-001 | Syntax Error | cyan_top.sv:530 중복 세미콜론 | 제거 |
| SYN-002 | Self-Assignment | reg_map_integration.sv:149 | 제거 |
| RST-003 | Reset Polarity | init, ti_roic_integration에 혼합 극성 | active-LOW로 통합 |

**Deliverables**:
- Syntax 오류 해결
- mipi_integration.sv: MIPI CSI-2 TX wrapper (89 lines)
- sequencer_wrapper.sv: FSM + index wrapper (128 lines)
- data_path_integration.sv: Data path wrapper (109 lines)

### 2.5 Phase 5: Top-Level Decomposition (Weeks 6-10)

**Focus**: cyan_top.sv에서 모듈 추출

#### Week 6: Debug 및 Sync 처리

| Module ID | Module | Lines | Purpose |
|-----------|--------|-------|---------|
| M6-1 | debug_integration.sv | 166 | ILA debug 통합 |
| M6-2 | sync_processing.sv | 111 | Sync signal 처리 |

#### Week 7: Gate Driver 및 ROIC 배열

| Module ID | Module | Lines | Purpose |
|-----------|--------|-------|---------|
| M7-1 | gate_driver_output.sv | 135 | ROIC gate driver 출력 |
| M7-2 | roic_channel_array.sv | 212 | ROIC 12-채널 배열 |

#### Week 8: Control Signal 및 Power

| Module ID | Module | Lines | Purpose |
|-----------|--------|-------|---------|
| M8-1 | control_signal_mux.sv | 77 | Control signal mux |
| M8-2 | power_control.sv | 99 | Power sequencing 제어 |

#### Week 9: FSM Refactoring

| Module ID | Module | Lines | Purpose |
|-----------|--------|-------|---------|
| M9-1 | init.sv (refactored) | 344 | 3-block FSM 스타일 |

#### Week 10: 최종 통합

| Task | Description | Status |
|------|-------------|--------|
| M10-1 | 모듈 통합 검증 | ✅ |
| M10-2 | 문서 업데이트 | ✅ |
| M10-3 | 아카이브 완료 | ✅ |

**Phase 5 요약**:
- 9개 모듈 추출 (1,467 lines)
- 모듈 수: 24 → 33
- FSM 표준 준수: 50% → 100%

### 2.6 Phase 6: Bitstream Generation (Week 11)

**Focus**: Build 자동화 및 Timing closure

| Issue ID | Category | Description | Solution |
|----------|----------|-------------|----------|
| ERR-017 | Clock Routing | Place 30-574: BUFG routing error | 명시적 BUFG 인스턴스화 |

**Deliverables**:
- build_bitstream.tcl: 자동화 Build 스크립트
- post_script.tcl: Post-build 처리
- cyan_top.bit: FPGA programming bitstream
- cyan_top.bin: Binary format
- cyan_top.mcs: SPI Flash 이미지
- cyan_top.ltx: Debug probes
- 594개 IP 생성 파일을 .gitignore로

**Build 결과**:
```
Synthesis:   PASS (0 errors, 0 critical warnings)
Implementation: PASS (0 errors, timing met)
Bitstream:   PASS
```

---

## 3. Current Status

### 3.1 품질 지표(Quality Metrics)

| Metric | Week 0 | Week 11 | Target | Status |
|--------|--------|---------|--------|--------|
| CDC Violations | 8+ | 0 | 0 | ✅ |
| Reset Consistency | 30% | 100% | 100% | ✅ |
| FSM Standard Compliance | 0% | 100% | 100% | ✅ |
| Syntax Errors | 2 | 0 | 0 | ✅ |
| Synthesis Errors | N/A | 0 | 0 | ✅ |
| Bitstream Generation | FAIL | PASS | PASS | ✅ |
| Module Count | 21 | 39 | - | ✅ |
| cyan_top.sv Lines | 1261 | 1292 | <500 | 🟡 |
| Test Coverage | 23% | 23% | >70% | ⏳ |

### 3.2 모듈 분해(Module Breakdown, 39 Modules)

**Core Modules (5개)**:
- cyan_top.sv (1292 lines) - Top level
- init.sv (344 lines) - Power initialization FSM
- sequencer_fsm.sv (603 lines) - Acquisition sequencer FSM
- read_data_mux.sv (771 lines) - LVDS data read mux
- reg_map_integration.sv (278 lines) - SPI register map

**Integration Modules (10개)**: Weeks 4-10 추출
**CDC/Reset Modules (5개)**: Synchronization primitives
**Clock/Timing Modules (2개)**: Clock generation
**Communication Modules (3개)**: SPI, I2C, gate driver
**TI-ROIC Subsystem (8개)**: TI ROIC interface
**CSI2 Subsystem (2개)**: MIPI CSI-2 TX
**Legacy/Reference (4개)**: Historical reference

### 3.3 이슈 요약(Issues Summary)

**Open Issues**: 0
**Critical Issues**: 0
**Resolved Issues**: 12

---

## 4. Remaining Work

### 4.1 대형 모듈 분해(Large Module Decomposition)

| Module | Lines | Target | Priority | Action |
|--------|-------|--------|----------|--------|
| cyan_top.sv | 1292 | <500 | P1 | MIPI wrapper, RF SPI control, LED control 추출 |
| read_data_mux.sv | 771 | <500 | P2 | Async FIFO control, data path logic 추출 |

### 4.2 Test Coverage 확장

| Current | Target | Gap | Priority |
|---------|--------|-----|----------|
| 23% | >70% | 47% | P1 |

**필요한 Testbench**:
- [ ] cyan_top_tb.sv - Top-level 통합
- [ ] init_tb.sv - Power initialization FSM
- [ ] sequencer_fsm_tb.sv - Sequencer state machine
- [ ] read_data_mux_tb.sv - Data path with async FIFO
- [ ] Integration modules (10 testbenches)

### 4.3 Simulation 검증

**Pre-Simulation 체크리스트**:
- [ ] Synthesis: ✅ PASS
- [ ] Bitstream: ✅ PASS
- [ ] Testbench 생성: ⏳ 대기 중
- [ ] Behavioral simulation: ⏳ 대기 중
- [ ] Post-synthesis simulation: ⏳ 대기 중

**Post-Simulation 작업**:
1. 결과 분석
2. 이슈 추적
3. Bug 수정
4. 재검증

---

## 5. Module Specifications

### 5.1 Core Modules (핵심 모듈)

#### cyan_top.sv (1292 lines)

**Purpose**: 모든 하위 시스템을 통합하는 Top-level 모듈

**Key Interfaces**:
- Clock inputs: CLK_200MHZ_P/N, CLK_100MHZ, CLK_20MHZ
- Reset input: nRST (active-LOW)
- LVDS I/O: ROIC data channels (12x)
- MIPI CSI-2 TX: mipi_csi2_tx data
- SPI Slave: 레지스터 접근 인터페이스

**Sub-modules**:
- clock_gen_top: Clock generation 및 reset synchronization
- init: Power initialization FSM
- ti_roic_integration: TI ROIC interface
- mipi_integration: MIPI CSI-2 TX wrapper
- sequencer_wrapper: Sequencer FSM
- data_path_integration: Data processing
- debug_integration: ILA debug
- sync_processing: Sync signals
- gate_driver_output: ROIC gate driver
- roic_channel_array: 12-channel array
- control_signal_mux: Control routing
- power_control: Power sequencing
- reg_map_integration: SPI register map

**분해 계획(Decomposition Plan)**:
- MIPI interface wrapper 추출 (~100 lines)
- RF SPI control 추출 (~80 lines)
- State LED control 추출 (~20 lines)

#### init.sv (344 lines)

**Purpose**: Power initialization FSM (3-block 스타일)

**State Machine**:
- Block 1: State register (always_ff)
- Block 2: Next state logic (always_comb)
- Block 3: Output logic (always_comb)

**States**: IDLE → PWR_SEQ → STABILIZE → READY

#### sequencer_fsm.sv (603 lines)

**Purpose**: Acquisition sequencer FSM (3-block 스타일)

**States**: IDLE → PRE_CONFIG → INTEGRATE → READ → TRANSFER → DONE

**Output**: ROIC gate driver, data path, MIPI TX용 제어 신호

#### read_data_mux.sv (771 lines)

**Purpose**: LVDS data read multiplexer with async FIFO

**Key Features**:
- 12-channel LVDS input
- CDC용 async_fifo_24b (200MHz → 100MHz)
- Data reordering 및 alignment
- First channel detection

**분해 계획**:
- Async FIFO control logic 추출 (~150 lines)
- Data path logic 추출 (~100 lines)

### 5.2 Integration Modules (통합 모듈)

#### mipi_integration.sv (89 lines)

**Purpose**: MIPI CSI-2 TX + AXI stream wrapper

**Interfaces**:
- Input: AXI stream from data path
- Output: MIPI CSI-2 TX interface

#### sequencer_wrapper.sv (128 lines)

**Purpose**: FSM + index generation wrapper

**Features**:
- Sequencer FSM instantiation
- Index generation logic
- Control signal aggregation

#### data_path_integration.sv (109 lines)

**Purpose**: read_data_mux + data processing wrapper

**Features**:
- Data mux instantiation
- Processing pipeline
- Output formatting

### 5.3 CDC and Reset Modules

#### cdc_sync_3ff.sv (91 lines)

**Purpose**: 3-stage CDC synchronizer

**Parameters**:
- WIDTH: Data width
- RESET_VALUE: Initial value

**Usage**: 모든 단일 비트 CDC crossing

#### async_fifo_24b.sv (138 lines)

**Purpose**: CDC용 24-bit async FIFO

**Features**:
- Gray code pointer synchronization
- Full/empty detection
- MTBF-optimized design

**Usage**: MIPI data path CDC (200MHz → 100MHz)

#### reset_sync.sv (53 lines)

**Purpose**: Reset synchronizer (async assert, sync deassert)

**Pattern**:
```systemverilog
always_ff @(posedge clk or negedge rst_async) begin
    if (!rst_async) rst_sync <= 2'b00;
    else rst_sync <= {rst_sync[0], 1'b1};
end
assign rst_sync_n = rst_sync[1];
```

---

## 6. Roadmap (Weeks 12+)

### 6.1 Phase 7: Verification (Week 12+)

**Focus**: Simulation 검증 및 Test Coverage

| Task | Duration | Priority | Status |
|------|----------|----------|--------|
| Testbench 생성 | 1 week | P1 | ⏳ 계획됨 |
| Behavioral simulation | 1 week | P1 | ⏳ 계획됨 |
| Post-synthesis simulation | 1 week | P2 | ⏳ 계획됨 |
| Coverage 분석 | 3 days | P2 | ⏳ 계획됨 |
| Bug 수정 | 1 week | P1 | ⏳ 계획됨 |

### 6.2 Phase 8: Further Decomposition (Week 13+)

**Focus**: 대형 모듈 감축

| Module | Target | Duration | Priority |
|--------|--------|----------|----------|
| cyan_top.sv | <500 lines | 1 week | P1 |
| read_data_mux.sv | <500 lines | 3 days | P2 |

### 6.3 Phase 9: Documentation (지속)

**Focus**: 완전한 문서화

| Document | Status | Priority |
|----------|--------|----------|
| TECHNICAL_REFERENCE.md v2.0 | ⏳ 진행 중 | P1 |
| MODULE_SPECIFICATION.md | ⏳ 계획됨 | P2 |
| TEST_PLAN.md | ⏳ 계획됨 | P1 |

---

## 7. Success Criteria

### 7.1 Quality Gates (품질 게이트)

| Criterion | Target | Current | Status |
|-----------|--------|---------|--------|
| CDC Violations | 0 | 0 | ✅ |
| Reset Consistency | 100% | 100% | ✅ |
| FSM Standard Compliance | 100% | 100% | ✅ |
| Synthesis Errors | 0 | 0 | ✅ |
| Bitstream Generation | PASS | PASS | ✅ |
| Test Coverage | >70% | 23% | ⏳ |
| cyan_top.sv Lines | <500 | 1292 | 🟡 |
| read_data_mux.sv Lines | <500 | 771 | 🟡 |

### 7.2 Exit Criteria (Week 11)

| Criterion | Status |
|-----------|--------|
| 모든 주요 이슈 해결 | ✅ |
| Bitstream 성공적 생성 | ✅ |
| Synthesis 0 errors로 통과 | ✅ |
| Implementation timing 충족 | ✅ |
| Build 자동화 완료 | ✅ |
| 문서 업데이트 | ✅ |

---

## 8. Risk & Mitigation

### 8.1 Risk Assessment (위험 평가)

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Simulation 실패 | Medium | High | Debug capacity ready, 점진적 테스트 |
| Module 분해 복잡 | High | Low | 점진적 접근, reference pattern |
| 문서 업데이트 지연 | Low | Medium | P0 항목 우선, template 재사용 |
| Test coverage 목표 미달 | Medium | Medium | Critical path 우선 |

### 8.2 완화 전략(Mitigation Strategies)

1. **Incremental Verification**: 통합 전 각 모듈 독립적으로 테스트
2. **Reference Patterns**: 기존 리팩토링 모듈을 template로 활용
3. **Documentation Templates**: 기존 문서 구조 재사용
4. **Critical Path Coverage**: Data path 및 FSM에 대한 test coverage 우선

---

## 9. Reference Materials

### 9.1 Documentation (문서)

| Document | Location | Purpose |
|----------|----------|---------|
| README.md | ./ | 프로젝트 개요 |
| TECHNICAL_REFERENCE.md | ./doc/ | 기술 사양 |
| LESSONS_LEARNED.md | ./doc/ | 워크플로우 pattern |
| errors-and-solutions.md | ./.alfred-memory/rules/ | 이슈 추적 |

### 9.2 Archive (보관)

| Document | Location | Content |
|----------|----------|---------|
| WEEK1_STATUS.md | ./doc/archive/ | Week 1 요약 |
| WEEK4_DECOMPOSITION_PLAN.md | ./doc/archive/ | 분해 계획 |
| WEEK5_SUMMARY.md | ./doc/archive/ | Week 5 요약 |
| WEEK6-10_SUMMARY.md | ./doc/archive/ | Weeks 6-10 요약 |
| WEEK11_SUMMARY.md | ./doc/archive/ | Week 11 요약 |

---

## 10. Sign-Off

**Week 11 Status**: ✅ **BITSTREAM 완료**

**Completed By**: FPGA Design Team
**Date**: 2026-02-04
**Next Phase**: Week 12+ - Simulation 검증

**Notes**:
- 6개 Phase (Weeks 1-11) 모두 완료
- Bitstream 생성 성공
- Build 자동화 완료
- 검증 단계 준비 완료

---

**Document Version**: 2.0
**Last Updated**: 2026-02-04
**Maintainer**: FPGA Design Team
