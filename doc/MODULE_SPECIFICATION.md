# CYAN-FPGA Module Specification

**Document ID:** DOC-004
**Version:** 1.0
**Last Updated:** 2026-02-04
**Project:** CYAN-FPGA xdaq_top
**FPGA:** Xilinx Artix-7 XC7A35TFGG484-1
**Tool:** Vivado 2025.2

---

## Table of Contents

1. [Overview](#section-1-overview)
2. [Module Hierarchy](#section-2-module-hierarchy)
3. [Core Modules](#section-3-core-modules)
4. [Integration Modules](#section-4-integration-modules)
5. [CDC and Reset Modules](#section-5-cdc-and-reset-modules)
6. [Interface Definitions](#section-6-interface-definitions)
7. [Functional Descriptions](#section-7-functional-descriptions)
8. [Timing Characteristics](#section-8-timing-characteristics)

---

## Section 1: Overview

### 1.1 Document Purpose

This document provides complete specifications for all modules in the CYAN-FPGA xdaq_top design. It serves as the authoritative reference for:

- Module interfaces and connectivity
- Functional behavior and state machines
- Timing requirements and constraints
- Resource utilization
- Dependencies between modules

### 1.2 Design Architecture

The CYAN-FPGA design implements an imaging system with the following key functions:

- **ROIC Interface**: 12-channel LVDS data capture from Readout Integrated Circuit
- **MIPI CSI-2 TX**: High-speed image data transmission
- **Gate Driver Control**: LCD gate driver timing generation
- **Sequencer FSM**: Acquisition sequence control
- **Register Map**: SPI-based configuration interface

### 1.3 Clock Domains

| Domain | Frequency | Description |
|-------|-----------|-------------|
| CLK_200MHZ | 200 MHz | MIPI DPHY clock, high-speed data path |
| CLK_100MHZ | 100 MHz | Main system clock, register access |
| CLK_20MHZ | 20 MHz | Processing clock, FSM, sequencer |
| CLK_5MHZ | 5 MHz | Slow timing, SPI clock |
| EIM_CLK | ~50 MHz | External image clock domain |

---

## Section 2: Module Hierarchy

### 2.1 Top-Level Block Diagram

```
cyan_top (1292 lines)
├── clock_gen_top
├── mipi_integration (new: mipi_interface_wrapper)
├── init (init_refacto)
├── reg_map_integration
├── roic_gate_drv_gemini
├── sequencer_wrapper
├── data_path_integration (read_data_mux)
│   ├── read_data_mux (771 lines)
│   │   ├── async_fifo_controller (NEW)
│   │   ├── data_path_selector (NEW)
│   │   └── timing_generator (NEW)
│   └── async_fifo
├── ti_roic_integration
│   ├── rf_spi_controller (NEW)
│   └── ti_roic_top (12 channels)
├── roic_channel_array
├── gate_driver_output
├── power_control
├── control_signal_mux
├── sync_processing
└── debug_integration
    └── state_led_controller (NEW)
```

### 2.2 Module Count Summary

| Category | Count |
|----------|-------|
| Core Modules | 5 |
| Integration Modules | 10 |
| CDC/Reset Modules | 5 |
| TI-ROIC Subsystem | 8 |
| CSI2 Subsystem | 2 |
| **Total** | **30** |

---

## Section 3: Core Modules

### 3.1 cyan_top (1292 lines)

**File**: `source/hdl/cyan_top.sv`

**Description**: Top-level module integrating all subsystems

**Key Parameters**: None

**Interfaces**:
- External: 50MHz differential clock, LVDS I/O, MIPI PHY, SPI, triggers
- Internal: 15 sub-module connections

**Resource Estimate**:
| Resource | Utilization |
|----------|-------------|
| LUT | ~8000 |
| FF | ~6000 |
| BRAM | ~32 |
| DSP | ~8 |

### 3.2 init_refacto (496 lines)

**File**: `source/hdl/init_refacto.sv`

**Description**: Power initialization FSM with bidirectional power control

**State Machine**:
```
Power Init FSM: IDLE -> STEP_1 -> STEP_2 -> STEP_3 -> STEP_4 -> STEP_5 -> STEP_6
Power Down FSM: IDLE -> STEP_1 -> STEP_2 -> STEP_3 -> STEP_4 -> STEP_5
```

**Key Outputs**:
- `pwr_init_step1` through `pwr_init_step6`: Power sequencing outputs
- `init_rst`: System reset pulse
- `roic_reset`: ROIC reset pulse

**Timing**:
- State transition delay: `INIT_DELAY` (configurable)
- STEP_5 delay: `MORE_DELAY` (longer delay for stability)

### 3.3 sequencer_fsm (603 lines)

**File**: `source/hdl/sequencer_fsm.sv`

**Description**: Main acquisition sequencer

**States**: RST, PANEL_STABLE, BACK_BIAS, FLUSH, EXPOSE_TIME, READOUT, IDLE

**LUT Interface**:
- Address: 8 bits (256 entries)
- Data: 64 bits per entry
- Control: acq_mode, expose_size

### 3.4 read_data_mux (771 lines)

**File**: `source/hdl/read_data_mux.sv`

**Description**: 12-channel data multiplexer with async FIFO CDC

**Key Features**:
- 12-channel LVDS input multiplexing
- CDC via async FIFO (eim_clk -> sys_clk)
- HSYNC/VSYNC generation
- AXI-Stream output

**Sub-Modules** (Phase 8 extraction):
1. `async_fifo_controller`: FIFO management for CDC
2. `data_path_selector`: 12-channel mux and test pattern
3. `timing_generator`: HSYNC/VSYNC/tlast generation

### 3.5 reg_map_integration (278 lines)

**File**: `source/hdl/reg_map_integration.sv`

**Description**: SPI register map integration

**Register Map**: 512 x 16-bit registers

**Key Features**:
- SPI slave interface
- Control signal generation
- Status register readback

---

## Section 4: Integration Modules

### 4.1 Newly Extracted Modules (Phase 8)

#### 4.1.1 mipi_interface_wrapper

**File**: `source/hdl/mipi_interface_wrapper.sv`
**Lines**: ~120

**Description**: MIPI PHY and AXI-Stream interface wrapper

**Key Functions**:
- MIPI PHY signal buffering
- AXI-Stream data packing (24-bit -> 32-bit)
- CSI-2 word count tracking
- Frame reset CDC

**Parameters**: None

**Interface**:
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| dphy_clk_200M | input | 1 | DPHY 200MHz clock |
| axis_tdata_a | input | 24 | Data A from path |
| axis_tdata_b | input | 24 | Data B from path |
| axis_tvalid | input | 1 | AXI-Stream valid |
| axis_tready | output | 1 | AXI-Stream ready |
| csi2_word_count | output | 16 | Word count |
| mipi_phy_if_* | output | 14 | MIPI PHY outputs |

#### 4.1.2 rf_spi_controller

**File**: `source/hdl/rf_spi_controller.sv`
**Lines**: ~130

**Description**: RF SPI controller for ROIC communication

**Key Functions**:
- SPI transaction generation
- Chip select timing
- Clock gating
- Data shift out/in

**SPI Timing**:
| Phase | Cycles | Description |
|-------|--------|-------------|
| CS Delay | 18 | CS to first clock |
| Clock Width | 58 | Valid clock width |
| CS End | 85 | Clock to CS end |

**Interface**:
| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk_5mhz | input | 1 | SPI base clock |
| ti_roic_reg_addr | input | 16 | Register address |
| ti_roic_reg_data | input | 16 | Register data |
| ti_roic_str | input | 2 | Strobe |
| s_roic_sdio | bidir | 12 | SPI data |
| RF_SPI_SCK | output | 1 | SPI clock |
| s_rf_spi_sen | output | 1 | Chip enable |

#### 4.1.3 state_led_controller

**File**: `source/hdl/state_led_controller.sv`
**Lines**: ~100

**Description**: State LED control for FSM indication

**LED Modes** (state_led_ctr):
- 0x00: FSM state indication (blinking)
- 0x01: Data valid indication
- 0x02: Sync indication
- 0x03: Frame activity
- 0x04: Channel detection
- 0x05: Ready status

#### 4.1.4 async_fifo_controller

**File**: `source/hdl/async_fifo_controller.sv`
**Lines**: ~140

**Description**: Async FIFO controller for CDC (CDC-003 fix)

**Key Features**:
- Dual 24-bit FIFO (A and B channels)
- CDC from eim_clk to sys_clk
- Full/empty flag management
- FIFO depth monitoring

**Parameters**:
- `DATA_WIDTH`: 24
- `DEPTH`: 16

#### 4.1.5 data_path_selector

**File**: `source/hdl/data_path_selector.sv`
**Lines**: ~160

**Description**: 12-channel data multiplexer

**Key Features**:
- One-hot to binary channel decoding
- Test pattern generation
- Dummy mode support
- Data valid generation

#### 4.1.6 timing_generator

**File**: `source/hdl/timing_generator.sv`
**Lines**: ~220

**Description**: HSYNC/VSYNC timing generator

**Key Features**:
- HSYNC pulse generation
- VSYNC generation
- AXI-Stream TLAST generation
- Frame start detection (tuser)

### 4.2 Existing Integration Modules

| Module | Lines | Description |
|--------|-------|-------------|
| mipi_integration | 89 | MIPI CSI-2 TX + AXI stream wrapper |
| sequencer_wrapper | 128 | FSM + index generation wrapper |
| data_path_integration | 109 | read_data_mux + data processing |
| debug_integration | 166 | ILA debug integration |
| sync_processing | 111 | Sync signal processing |
| gate_driver_output | 135 | ROIC gate driver output |
| roic_channel_array | 212 | ROIC 12-channel array |
| control_signal_mux | 77 | Control signal multiplexing |
| power_control | 99 | Power sequencing |
| ti_roic_integration | 154 | TI ROIC interface |

---

## Section 5: CDC and Reset Modules

### 5.1 CDC Modules

| Module | Lines | Width | Description |
|--------|-------|-------|-------------|
| cdc_sync_3ff | 91 | 1 | 3-stage CDC synchronizer |
| async_fifo | 165 | 24 | Universal async FIFO |
| async_fifo_1b | 117 | 1 | 1-bit async FIFO |
| reset_sync | 53 | 1 | Reset synchronizer |

### 5.2 CDC Paths

| Source Domain | Dest Domain | Module | Signal Type |
|---------------|-------------|--------|-------------|
| 200MHz | 100MHz | async_fifo_24b | Data (24-bit) |
| 100MHz | 20MHz | cdc_sync_3ff | Control |
| eim_clk | sys_clk | async_fifo_controller | Data (24-bit) |
| Async | 100MHz | cdc_sync_3ff | Reset |

---

## Section 6: Interface Definitions

### 6.1 MIPI CSI-2 TX Interface

**Physical Layer**: D-PHY compliant

**Lane Configuration**:
- 1 Data Lane (CLK + D0)
- Up to 4 Data Lanes supported

**Data Format**:
- RAW10: 10-bit per pixel
- RAW12: 12-bit per pixel
- Packed in 32-bit words

### 6.2 SPI Slave Interface

**Protocol**: Motorola SPI Mode 0 (CPOL=0, CPHA=0)

**Transfer Format**:
| Byte | Description |
|------|-------------|
| 1 | Command |
| 2 | Address high |
| 3 | Address low |
| 4 | Data high |
| 5 | Data low |

**Timing**:
| Parameter | Min (ns) | Max (ns) |
|-----------|----------|----------|
| t_SU | 10 | - |
| t_H | 50 | - |
| t_RD | 50 | - |

### 6.3 LVDS ROIC Interface

**Channels**: 12 differential pairs

**Data Rate**: Up to 500 Mbps per lane

**Signal Mapping**:
- FCLK: Frame clock
- DCLK: Data clock
- DOUTA_H/L: Data A (differential)

---

## Section 7: Functional Descriptions

### 7.1 Power Initialization FSM

The init_refacto module manages power sequencing for ROIC bias voltages:

1. **Power-On Sequence** (pwr_direction=0):
   - IDLE -> STEP_1 -> STEP_2 -> STEP_3 -> STEP_4 -> STEP_5 -> STEP_6
   - Each step has configurable delay
   - STEP_5 has extended delay for stability

2. **Power-Off Sequence** (pwr_direction=1):
   - STEP_6 -> STEP_5 -> STEP_4 -> STEP_3 -> STEP_2 -> STEP_1 -> IDLE
   - Reverse order for safe shutdown

3. **Power Down FSM**: Separate FSM for power-down control
   - IDLE -> STEP_1 -> STEP_2 -> STEP_3 -> STEP_4 -> STEP_5

### 7.2 Sequencer Operation

The sequencer_fsm implements the acquisition state machine:

```
PANEL_STABLE: Wait for panel ready
BACK_BIAS: Apply back bias voltage
FLUSH: Flush ROIC array
EXPOSE_TIME: Integration period
READOUT: Read out image data
```

**LUT-driven**: Each state reads configuration from LUT

### 7.3 Data Flow

```
ROIC (12ch LVDS)
    -> deser_single (deserialization)
    -> bit_align (bit alignment)
    -> indata_reorder (data reordering)
    -> read_data_mux (channel selection)
    -> async_fifo (CDC)
    -> mipi_integration (AXI-Stream)
    -> MIPI CSI-2 TX (output)
```

---

## Section 8: Timing Characteristics

### 8.1 Clock Summary

| Clock | Frequency | Period | Source |
|-------|-----------|--------|--------|
| MCLK_50M | 50 MHz | 20 ns | External |
| CLK_200M | 200 MHz | 5 ns | MMCM |
| CLK_100M | 100 MHz | 10 ns | MMCM |
| CLK_20M | 20 MHz | 50 ns | Divider |
| CLK_5M | 5 MHz | 200 ns | Divider |
| EIM_CLK | ~50 MHz | 20 ns | External |

### 8.2 Timing Constraints

**Input Delay**:
| Port | Delay (ns) |
|------|------------|
| MCLK_50M_p/n | 0 ± 0.5 |

**Output Delay**:
| Port | Delay (ns) |
|------|------------|
| mipi_phy_if_* | 2.0 ± 0.5 |

**Setup/Hold**:
| Path | Setup | Hold |
|------|-------|------|
| Internal | 2.0 | 0.5 |

### 8.3 Critical Paths

1. **ROIC to FIFO**: eim_clk domain
2. **FIFO to MIPI**: sys_clk to 200MHz CDC
3. **FSM to LUT**: 20MHz synchronous

---

## Appendix: Module Cross-Reference

| Module | File | Phase | Status |
|--------|------|-------|--------|
| init_tb.sv | simulation/tb_src/ | 7 | NEW |
| read_data_mux_tb.sv | simulation/tb_src/ | 7 | NEW |
| cyan_top_tb.sv | simulation/tb_src/ | 7 | NEW |
| mipi_interface_wrapper.sv | source/hdl/ | 8 | NEW |
| rf_spi_controller.sv | source/hdl/ | 8 | NEW |
| state_led_controller.sv | source/hdl/ | 8 | NEW |
| async_fifo_controller.sv | source/hdl/ | 8 | NEW |
| data_path_selector.sv | source/hdl/ | 8 | NEW |
| timing_generator.sv | source/hdl/ | 8 | NEW |

---

**End of Document: DOC-004**
