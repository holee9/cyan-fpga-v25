# CYAN-FPGA 기술 참조 문서 v2.0

**Document Version:** 2.0
**Last Updated:** 2026-02-04
**Project:** CYAN-FPGA xdaq_top
**FPGA:** Xilinx Artix-7 XC7A35TFGG484-1
**Tool:** Vivado 2025.2

---

## 목차(Table of Contents)

1. [HDL Implementation Comparison](#section-1-hdl-implementation-comparison)
2. [ROIC Gate Driver Module](#section-2-roic-gate-driver-module)
3. [Clock Domain Architecture](#section-3-clock-domain-architecture)
4. [Reset Domain Tree](#section-4-reset-domain-tree)
5. [Module Specifications](#section-5-module-specifications)
6. [Coding Standards](#section-6-coding-standards)
7. [CDC Guidelines](#section-7-cdc-guidelines)
8. [Refactoring Guidelines](#section-8-refactoring-guidelines)

---

## Section 1: HDL Implementation Comparison (HDL 구현 비교)

### File Information (파일 정보)

| Item | VHDL | SystemVerilog | Improvement (개선) |
|------|------|---------------|-------------|
| File Name | read_data_tx.vhd | read_data_tx.sv | - |
| Code Lines | 2,283 | 845 | **63% 감소** |
| Last Modified | 2024-01-14 | 2024-01-14 | - |

### Key Improvements in SystemVerilog (SystemVerilog 주요 개선사항)

| Feature | VHDL | SystemVerilog | Benefit (이점) |
|---------|------|---------------|-------------|
| Array Usage | 별도 신호 | `logic [31:0] arr [1:12]` | Grouped, cleaner |
| Data Type | `std_logic`/`std_logic_vector` | Unified `logic` | Consistent (일관성) |
| Constants | `constant` | `localparam` | Simplified (단순화) |
| Maintainability | Moderate | High | Modern constructs (현대적 구문) |

### Functional Equivalence (기능적 동등성)

두 구현은 다음 기능에서 완전한 기능적 동등성을 유지합니다:
- Image capture control (get_dark/get_bright)
- AXI Stream data transfer protocol
- Test pattern generation
- Burst mode operations

---

## Section 2: ROIC Gate Driver Module (ROIC 게이트 드라이버 모듈)

### 2.1 Overview (개요)

ROIC Gate Driver 모듈은 이미징 시스템에서 Readout Integrated Circuit (ROIC)용 게이트 신호의 타이밍과 시퀀싱을 제어합니다.

### 2.2 Module Specification (모듈 사양)

**Module**: `roic_gate_drv_gemini.sv` (122 lines)

**Purpose**: Gemini ROIC gate driver with timing-critical outputs

#### Key Functional Modes (주요 동작 모드)

| Mode | Description (설명) |
|------|-------------|
| Back Bias Mode | Back bias voltage voltage 제어 |
| Flush Mode | ROIC array clear |
| AED Mode | Automatic exposure detection |
| Normal Read Mode | 표준 이미지 readout |

#### Input Signals (입력 신호)

| Signal | Width | Description (설명) |
|--------|-------|-------------|
| fsm_clk | 1 | 20MHz FSM clock |
| fsm_drv_rst | 1 | Driver reset signal (active-LOW) |
| fsm_back_bias_index | 1 | Back bias mode flag |
| fsm_flush_index | 1 | Flush mode flag |
| fsm_aed_read_index | 1 | AED read mode flag |
| fsm_read_index | 1 | Normal read mode flag |
| row_cnt | Variable | Current row counter |
| col_cnt | Variable | Current column counter |

#### Output Signals (출력 신호)

| Signal | Width | Description (설명) |
|--------|-------|-------------|
| back_bias | 1 | Back bias control |
| gate_stv_1_1 | 1 | Start vertical gate |
| gate_cpv | 1 | Charge transfer gate |
| gate_oe1 | 1 | Output enable 1 |
| gate_oe2 | 1 | Output enable 2 |
| gate_xao_0~5 | 6 | AED mode gates |
| roic_sync | 1 | ROIC synchronization |
| roic_aclk | 11 | ROIC asynchronous clock (aggregated) |
| roic_data_read_index | 1 | Data read enable |
| valid_read_out | 1 | Valid read-out indicator |

### 2.3 Gate Driver Refactoring (게이트 드라이버 리팩토링)

| Area | Original | Refactored | Benefits (이점) |
|------|----------|------------|----------|
| Enable Signals | 개별 신호 | Internal signals with always_ff | Consistency (일관성) |
| XAO Gates | 6개 분리 블록 | Generate loop with arrays | Extensibility (확장성) |
| ACLK | 11개 분리 할당 | Parameterized generation | Scalability (확장성) |
| Signal Naming | 혼합 컨벤션 | Consistent _internal suffix | Readability (가독성) |

### 2.4 Performance Characteristics (성능 특성)

| Parameter (파라미터) | Value (값) |
|-----------|-------|
| Clock Frequency | 20MHz |
| Number of Modes | 4 |
| Timing Granularity | Row/column-level |
| CSI-2 Compliance | Yes |

---

## Section 3: Clock Domain Architecture (클럭 도메인 아키텍처)

### 3.1 Clock Domain Overview (클럭 도메인 개요)

| Clock Domain | Frequency | Source | Description (설명) | Primary Usage |
|--------------|-----------|--------|-------------|---------------|
| CLK_200MHZ | 200 MHz | External differential | DPHY high-speed clock | MIPI CSI-2 TX data path |
| CLK_100MHZ | 100 MHz | CLK_200MHZ divided | Main system clock | Register map, control logic |
| CLK_20MHZ | 20 MHz | CLK_100MHZ divided | Processing clock | Data reordering, sequencer |
| CLK_5MHZ | 5 MHz | CLK_20MHZ divided | Slow clock | Timing generation |
| CLK_1MHZ | 1 MHz | CLK_20MHZ divided | Very slow clock | Low-speed timers |

### 3.2 Clock Generation Module (클럭 생성 모듈)

**Module**: `clock_gen_top.sv` (82 lines)

**Responsibilities (책임)**:
- Clock division from 200MHz input (200MHz 입력에서 분주)
- Reset synchronization for all domains (모든 도메인의 reset 동기화)
- Clock enable generation (클럭 enable 생성)

**Output Resets** (모두 active-LOW):
- `rst_n_200mhz`: 200MHz domain reset
- `rst_n_100mhz`: 100MHz domain reset
- `rst_n_20mhz`: 20MHz domain reset
- `rst_n_5mhz`: 5MHz domain reset (if used)
- `rst_n_1mhz`: 1MHz domain reset (if used)

### 3.3 Clock Domain Crossing Map (CDC 맵)

| Source Domain | Destination Domain | CDC Method (CDC 방법) | Module |
|---------------|---------------------|------------|--------|
| 200MHz | 100MHz | async_fifo_24b | read_data_mux |
| 100MHz | 200MHz | async_fifo_24b | mipi_integration |
| 100MHz | 20MHz | cdc_sync_3ff | sync_processing |
| 20MHz | 100MHz | cdc_sync_3ff | sync_processing |
| Async (external) | 100MHz | cdc_sync_3ff | Multiple |

---

## Section 4: Reset Domain Tree (리셋 도메인 트리)

### 4.1 Reset Architecture (리셋 아키텍처)

```
nRST (external, active-LOW)
    |
    v
[clock_gen_top]
    |
    +-- rst_n_200mhz (synchronized, 동기화됨)
    +-- rst_n_100mhz (synchronized, 동기화됨)
    +-- rst_n_20mhz (synchronized, 동기화됨)
    +-- rst_n_5mhz (synchronized, 동기화됨, if used)
    +-- rst_n_1mhz (synchronized, 동기화됨, if used)
```

### 4.2 Reset Synchronization Pattern (리셋 동기화 패턴)

**Module**: `reset_sync.sv` (53 lines)

**Pattern**: Async assert, sync deassert

```systemverilog
module reset_sync (
    input  wire clk,
    input  wire rst_async_n,
    output wire rst_sync_n
);

    logic [2:0] rst_sync;

    always_ff @(posedge clk or negedge rst_async_n) begin
        if (!rst_async_n) rst_sync <= 3'b000;
        else rst_sync <= {rst_sync[1:0], 1'b1};
    end

    assign rst_sync_n = rst_sync[2];

endmodule
```

### 4.3 Reset Distribution (리셋 분배)

| Domain | Reset Signal | Source | Modules (모듈) |
|--------|--------------|--------|---------|
| 200MHz | rst_n_200mhz | clock_gen_top | mipi_csi2_tx, async_fifo |
| 100MHz | rst_n_100mhz | clock_gen_top | reg_map_integration, spi_slave |
| 20MHz | rst_n_20mhz | clock_gen_top | init, sequencer_fsm, ti_roic_integration |

---

## Section 5: Module Specifications (모듈 사양)

### 5.1 Core Modules (핵심 모듈, 5개)

#### cyan_top.sv (1292 lines)

**Purpose**: 모든 하위 시스템을 통합하는 Top-level 모듈

**Key Interfaces**:
- Clock inputs: CLK_200MHZ_P/N, CLK_100MHZ, CLK_20MHZ
- Reset input: nRST (active-LOW)
- LVDS I/O: ROIC data channels (12x)
- MIPI CSI-2 TX: mipi_csi2_tx data
- SPI Slave: 레지스터 접근 인터페이스

**Sub-modules**: 15개 통합 모듈

**Decomposition Plan (분해 계획, Future)**:
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

#### reg_map_integration.sv (278 lines)

**Purpose**: SPI register map integration

**Features**:
- SPI slave interface
- Register read/write
- Control signal generation

### 5.2 Integration Modules (통합 모듈, 10개)

| Module | Lines | Week | Purpose (목적) |
|--------|-------|------|-------------|
| mipi_integration.sv | 89 | Week 5 | MIPI CSI-2 TX + AXI stream wrapper |
| sequencer_wrapper.sv | 128 | Week 5 | FSM + index generation wrapper |
| data_path_integration.sv | 109 | Week 5 | read_data_mux + data processing wrapper |
| debug_integration.sv | 166 | Week 6 | ILA debug integration |
| sync_processing.sv | 111 | Week 6 | Sync signal processing |
| gate_driver_output.sv | 135 | Week 7 | ROIC gate driver output logic |
| roic_channel_array.sv | 212 | Week 7 | ROIC 12-channel array processing |
| control_signal_mux.sv | 77 | Week 8 | Control signal multiplexing |
| power_control.sv | 99 | Week 8 | Power sequencing control |
| ti_roic_integration.sv | 154 | Week 4 | TI ROIC interface integration |

### 5.3 CDC and Reset Modules (CDC 및 Reset 모듈, 5개)

| Module | Lines | Description (설명) |
|--------|-------|-------------|
| cdc_sync_3ff.sv | 91 | 3-stage CDC synchronizer |
| async_fifo_1b.sv | 117 | 1-bit async FIFO |
| async_fifo_24b.sv | 138 | 24-bit async FIFO (CDC-003 fix) |
| async_fifo.sv | 165 | Universal async FIFO |
| reset_sync.sv | 53 | Reset synchronizer |

### 5.4 TI-ROIC Subsystem (8개 모듈)

**Location**: `source/hdl/ti-roic/`

| Module | Lines | Description (설명) |
|--------|-------|-------------|
| ti_roic_top.sv | 236 | TI ROIC top module |
| ti_roic_tg.sv | 754 | Test pattern generator |
| deser_single.sv | 218 | Deserializer |
| indata_reorder.sv | 339 | Data reordering |
| first_ch_detector.sv | 322 | First channel detector |
| bit_align.sv | 225 | Bit alignment |
| bit_clock_module.sv | 103 | Bit clock module |
| roic_spi.sv | 129 | ROIC SPI interface |

### 5.5 CSI2 Subsystem (2개 모듈)

**Location**: `source/hdl/csi2/`

| Module | Lines | Description (설명) |
|--------|-------|-------------|
| mipi_csi2_tx_top.sv | 255 | MIPI CSI-2 TX top |
| mipi_csi2_tx_bd.sv | 304 | MIPI CSI-2 TX block diagram |

---

## Section 6: Coding Standards (코딩 표준)

### 6.1 SystemVerilog Style Guide (SystemVerilog 스타일 가이드)

#### Naming Conventions (명명 컨벤션)

| Type | Convention (컨벤션) | Example (예시) |
|------|------------------|-------------|
| Module | lowercase with underscores (소문자+밑줄표) | `async_fifo_24b` |
| Port (input) | signal_name or signal_n | `clk`, `rst_n` |
| Port (output) | signal_name or signal_n | `data_valid` |
| Internal signal | signal_name | `data_sync` |
| Reset signals | *_n suffix (active-LOW) | `rst_n`, `reset_n` |
| Clock signals | clk* or *_clk | `clk_100mhz`, `sys_clk` |
| Constants | UPPER_CASE (대문자) | `DATA_WIDTH`, `MAX_COUNT` |
| Parameters | UPPER_CASE or PascalCase | `FIFO_DEPTH`, `DataWidth` |

#### Signal Suffixes (신호 접미사)

| Suffix | Meaning (의미) | Example (예시) |
|--------|---------------|-------------|
| _n | Active-LOW | `rst_n`, `cs_n` |
| _p, _n | Differential pair (차동 쌍) | `clk_p`, `clk_n` |
| _r | Registered signal | `data_r` |
| _next | Next state value | `state_next` |
| _reg | Registered/state | `state_reg` |
| _sync | Synchronized | `signal_sync` |
| _async | Asynchronous | `signal_async` |
| _int | Internal | `signal_int` |

### 6.2 3-Block FSM Style (3블록 FSM 스타일)

모든 FSM은 Xilinx의 권장 3-block 스타일을 사용해야 합니다:

```systemverilog
// Block 1: State Register (always_ff)
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) state_reg <= IDLE;
    else state_reg <= state_next;
end

// Block 2: Next State Logic (always_comb)
always_comb begin
    state_next = state_reg;  // Default assignment
    unique case (state_reg)
        IDLE: begin
            if (start) state_next = RUN;
        end
        RUN: begin
            if (done) state_next = IDLE;
        end
        default: state_next = IDLE;
    endcase
end

// Block 3: Output Logic (always_comb)
always_comb begin
    // Default outputs
    output_valid = 1'b0;
    output_data = 8'd0;

    unique case (state_reg)
        RUN: begin
            output_valid = 1'b1;
            output_data = internal_data;
        end
    endcase
end
```

### 6.3 Reset Guidelines (리셋 가이드라인)

1. **All resets are active-LOW** (모든 reset은 active-LOW, `_n` 접미사 사용)
2. **Use reset synchronizers** for all domains (모든 도메인에 reset synchronizer 사용)
3. **Async assert, sync deassert pattern** (Async assert, sync deassert 패턴)
4. **Reset as few flops as possible** (제어 로직만 reset)

---

## Section 7: CDC Guidelines (CDC 가이드라인)

### 7.1 CDC Requirements (CDC 요구사항)

모든 clock domain crossing은 적절한 CDC 기법을 사용해야 합니다:

| CDC Type | Module (모듈) | Usage (사용처) |
|----------|--------|-----------|
| Single bit | cdc_sync_3ff.sv | Control signals, flags |
| Multi-bit | async_fifo_24b.sv | Data buses |
| Fast to slow | cdc_sync_3ff.sv | Handshake req/ack |
| Slow to fast | cdc_sync_3ff.sv | Pulse synchronizer |

### 7.2 3-Stage Synchronizer (3스테이지 동기화기)

```systemverilog
module cdc_sync_3ff #(
    parameter WIDTH = 1,
    parameter RESET_VALUE = 0
) (
    input  wire                clk_dst,
    input  wire                rst_n,
    input  wire [WIDTH-1:0]     async_in,
    output wire [WIDTH-1:0]     sync_out
);

    logic [2:0][WIDTH-1:0] sync_stages;

    always_ff @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) sync_stages <= RESET_VALUE;
        else sync_stages <= {sync_stages[1:0], async_in};
    end

    assign sync_out = sync_stages[2];

endmodule
```

### 7.3 Async FIFO Usage (Async FIFO 사용)

**Module**: `async_fifo_24b.sv`

**Features**:
- Gray code pointer synchronization
- Full/empty detection
- MTBF-optimized design

**Usage**: MIPI data path CDC (200MHz → 100MHz)

---

## Section 8: Refactoring Guidelines (리팩토링 가이드라인)

### 8.1 Code Structure Optimization (코드 구조 최적화)

**Module Structure**:
- [x] Split large modules into smaller functional modules
- [x] Modularize common functionalities
- [x] Clearly define constants and parameters

**Signal and Variable Optimization**:
- [x] Remove unnecessary signals
- [x] Consolidate redundant logic
- [x] Optimize signal width
- [x] Use enumerations for readability

### 8.2 Performance Optimization (성능 최적화)

**Logic Optimization**:
- [x] Simplify complex conditional statements
- [x] Flatten nested conditionals
- [x] Remove unnecessary conditions
- [x] Minimize combinational logic

**Clock and Timing Optimization**:
- [x] Minimize clock domain crossing
- [x] Add pipeline stages where needed
- [x] Remove unnecessary clock toggles
- [x] Explore clock gating techniques

**Resource Usage Optimization**:
- [x] Remove unnecessary registers
- [x] Integrate shareable logic
- [x] Apply hardware reuse patterns

### 8.3 Code Readability (코드 가독성)

**Coding Style**:
- [x] Consistent indentation and formatting
- [x] Clear and descriptive naming
- [x] Add comments for all signals
- [x] Follow SystemVerilog best practices

**Structural Considerations**:
- [x] Follow single responsibility principle
- [x] Consider hierarchical design
- [x] Minimize module coupling
- [x] Ensure interface clarity

### 8.4 Reliability and Safety (신뢰성 및 안전)

**Error Handling**:
- [x] Implement boundary condition verification
- [x] Validate input data
- [x] Ensure safe initialization during reset
- [x] Improve robustness for exceptional scenarios

**Testability**:
- [x] Create simulation-friendly structure
- [x] Provide internal state observation points
- [ ] Implement logging mechanisms (TODO: Week 12+)
- [x] Facilitate test bench creation

### 8.5 Refactoring Verification Criteria (리팩토링 검증 기준)

**Functional Equivalence**:
- [x] Guarantee identical functionality to original module
- [x] Ensure operation consistency across all modes
- [x] Maintain timing characteristics

**Performance Comparison**:
- [x] Compare clock cycles and latency
- [x] Analyze hardware resource utilization
- [ ] Evaluate power consumption (TODO: Week 12+)

### 8.6 Refactoring Process (리팩토링 프로세스)

1. **Code Analysis** - 기존 코드 구조 철저 분석
2. **Initial Refactoring Application** - 초기 리팩토링 변경 적용
3. **Simulation Verification** - 기능 검증 through simulation
4. **Performance and Resource Analysis** - 성능 및 resource 사용량 분석
5. **Iterative Improvement** - 분석 결과를 바탕으로 지속적 개선

---

## Appendix: Reference Files (부록: 참조 파일)

다음 참조 파일이 `doc/` 디렉토리에 유지됩니다:

- `fpga_block_diagram.png` - FPGA block diagram 시각화
- `ROIC_timing_chart.xlsx` - ROIC 타이밍 파라미터
- `xdaq_fpga_design.pptx` - 설계 프레젠테이션
- `Xdaq_Register_Map.xlsx` - 레지스터 맵 문서
- `Xdaq_Register_Map_24.xlsx` - 레지스터 맵 (24-bit 버전)

---

## Build Artifacts (Build 산출물)

| File | Location | Description (설명) |
|------|----------|-------------|
| cyan_top.bit | output/ | FPGA programming bitstream |
| cyan_top.bin | output/ | Binary format |
| cyan_top.mcs | output/ | SPI Flash 이미지 |
| cyan_top.ltx | output/ | Debug probes |
| *.rpt | reports/ | Timing/utilization reports (타이밍/리소스 보고서) |

---

## Build Commands (빌드 명령어)

### Bitstream Generation (Bitstream 생성)

```bash
# 프로젝트 루트에서
"D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat" -mode batch -source "build_bitstream.tcl" -log "build_bitstream.log" -nojournal
```

### Simulation (시뮬레이션)

```bash
# GUI Mode
vivado -mode gui -source run_sim.tcl

# Batch Mode
vivado -mode batch -source run_sim.tcl
```

---

**End of Technical Reference Document v2.0**
