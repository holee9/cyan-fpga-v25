# XDAQ FPGA Technical Reference

**Document Version:** 1.0
**Last Updated:** 2026-02-03
**Project:** XDAQ FPGA Top Module

---

## Table of Contents

This document consolidates the following technical documentation:

1. HDL Implementation Comparison: VHDL vs SystemVerilog
2. ROIC Gate Driver Refactoring Report
3. ROIC Gate Driver Module Specification
4. ROIC Gate Driver Refactoring Guidelines

---

## Section 1: HDL Implementation Comparison

### File Information

| Item | VHDL | SystemVerilog |
|------|------|---------------|
| File Name | read_data_tx.vhd | read_data_tx.sv |
| Code Lines | 2,283 | 845 |
| Last Modified | 2024-01-14 15:16:10 | 2024-01-14 15:16:12 |

**Analysis:** The SystemVerilog implementation achieves a 63% reduction in lines of code.
### Key Improvements in SystemVerilog

- Array usage for signal grouping (e.g., `logic [31:0] write_mem_data [1:12]`)
- Unified `logic` type instead of `std_logic`/`std_logic_vector`
- Simplified constant definitions with `localparam`
- Enhanced maintainability through modern language constructs

### Functional Equivalence

Both implementations maintain complete functional equivalence across:
- Image capture control (get_dark/get_bright)
- AXI Stream data transfer protocol
- Test pattern generation
- Burst mode operations

---

## Section 2: ROIC Gate Driver Refactoring Report

This section details the refactoring comparison between the original (roic_gate_drv.sv) and refactored (roic_gate_drv_gemini.sv) implementations.

### Overall Structure

**Inputs:** FSM states (fsm_flush_index, fsm_aed_read_index, fsm_read_index, fsm_back_bias_index), row_cnt, col_cnt, various parameters

**Outputs:** back_bias, gate_stv_1_1, gate_cpv, gate_oe1, gate_oe2, gate_xao_0~5, roic_sync, roic_aclk, valid_aed_read_skip, roic_data_read_index, valid_read_out

### Key Refactoring Improvements

| Area | Original | Refactored | Benefits |
|------|----------|------------|----------|
| Enable Signals | Individual signals | Internal signals with always_ff | Consistency, maintainability |
| XAO Gates | 6 separate blocks | Generate loop with arrays | Extensibility, reduced duplication |
| ACLK | 11 separate assignments | Parameterized generation | Scalability, OR-reduction |
| Signal Naming | Mixed conventions | Consistent _internal suffix | Improved readability |

---

## Section 3: ROIC Gate Driver Module Specification

### Overview

The ROIC Gate Driver module controls timing and sequencing of gate signals for a Read-Out Integrated Circuit (ROIC) in imaging systems.

### Key Functional Modes

- **Back Bias Mode:** Controls back bias voltage application
- **Flush Mode:** Clears the ROIC array
- **AED Mode:** Automatic exposure detection
- **Normal Read Mode:** Standard image readout

### Input Signals

| Signal | Description |
|--------|-------------|
| fsm_clk | 25MHz system clock |
| fsm_drv_rst | Driver reset signal |
| fsm_back_bias_index | Back bias mode flag |
| fsm_flush_index | Flush mode flag |
| fsm_aed_read_index | AED read mode flag |
| fsm_read_index | Normal read mode flag |
| row_cnt | Current row counter |
| col_cnt | Current column counter |

### Gate Signal Generation

**Primary Gate Signals:**
- gate_stv_1_1: Start vertical gate signal
- gate_cpv: Charge transfer gate signal
- gate_oe1, gate_oe2: Output enable gates
- gate_xao_0 to gate_xao_5: AED mode gate signals

**Features:**
- Dynamic gate signal generation based on mode and counters
- Configurable gate timings via register inputs
- Support for multiple gate transitions

### ROIC Synchronization

| Signal | Description |
|--------|-------------|
| roic_sync | ROIC synchronization signal |
| roic_aclk | ROIC asynchronous clock (11 signals aggregated) |
| roic_data_read_index | Enable signal for data reading |
| valid_read_out | Indicates valid read-out periods |

### Performance Characteristics

- **Clock Frequency:** 25MHz
- **Modes:** Multiple ROIC operational modes
- **Timing Control:** Row/column-level granularity

### Compliance

- Supports CSI-2 interface specifications
- Compatible with ROIC data sheet timing requirements

---

## Section 4: ROIC Gate Driver Refactoring Guidelines

### Refactoring Objectives

- Improve code readability
- Optimize performance
- Enhance maintainability
- Improve hardware resource efficiency

### Code Structure Optimization

**Module Structure:**
- [ ] Split large modules into smaller functional modules
- [ ] Modularize common functionalities
- [ ] Clearly define constants and parameters

**Signal and Variable Optimization:**
- [ ] Remove unnecessary signals
- [ ] Consolidate redundant logic
- [ ] Optimize signal width
- [ ] Use enumerations for readability

### Performance Optimization

**Logic Optimization:**
- [ ] Simplify complex conditional statements
- [ ] Flatten nested conditionals
- [ ] Remove unnecessary conditions
- [ ] Minimize combinational logic

**Clock and Timing Optimization:**
- [ ] Minimize clock domain crossing
- [ ] Add pipeline stages where needed
- [ ] Remove unnecessary clock toggles
- [ ] Explore clock gating techniques

**Resource Usage Optimization:**
- [ ] Remove unnecessary registers
- [ ] Integrate shareable logic
- [ ] Apply hardware reuse patterns

### Code Readability

**Coding Style:**
- [ ] Consistent indentation and formatting
- [ ] Clear and descriptive naming
- [ ] Add comments for all signals
- [ ] Follow SystemVerilog best practices

**Structural Considerations:**
- [ ] Follow single responsibility principle
- [ ] Consider hierarchical design
- [ ] Minimize module coupling
- [ ] Ensure interface clarity

### Reliability and Safety

**Error Handling:**
- [ ] Implement boundary condition verification
- [ ] Validate input data
- [ ] Ensure safe initialization during reset
- [ ] Improve robustness for exceptional scenarios

**Testability:**
- [ ] Create simulation-friendly structure
- [ ] Provide internal state observation points
- [ ] Implement logging mechanisms
- [ ] Facilitate test bench creation

### Specific Optimization Points

**AED Logic Optimization:**
- [ ] Remove hardcoding of AED line calculations
- [ ] Implement dynamic line calculation mechanism
- [ ] Simplify XAO gate control logic

**Gate Signal Generation Optimization:**
- [ ] Abstract repetitive gate signal generation patterns
- [ ] Generalize conditional gate signal generation
- [ ] Improve efficiency of gate timing calculations

**Back Bias Logic Optimization:**
- [ ] Simplify back bias state machine
- [ ] Improve counter logic efficiency
- [ ] Remove unnecessary state transitions

### Refactoring Verification Criteria

**Functional Equivalence:**
- [ ] Guarantee identical functionality to original module
- [ ] Ensure operation consistency across all modes
- [ ] Maintain timing characteristics

**Performance Comparison:**
- [ ] Compare clock cycles and latency
- [ ] Analyze hardware resource utilization
- [ ] Evaluate power consumption

### Refactoring Process

1. **Code Analysis** - Thoroughly analyze existing code structure
2. **Initial Refactoring Application** - Apply initial refactoring changes
3. **Simulation Verification** - Verify functionality through simulation
4. **Performance and Resource Analysis** - Analyze performance and resource usage
5. **Iterative Improvement** - Continuously improve based on analysis

---

## Appendix: Reference Files

The following reference files are maintained in the `doc/` directory:

- `fpga_block_diagram.png` - FPGA block diagram visualization
- `ROIC_timing_chart.xlsx` - ROIC timing parameters
- `xdaq_fpga_design.pptx` - Design presentation
- `Xdaq_Register_Map.xlsx` - Register map documentation
- `Xdaq_Register_Map_24.xlsx` - Register map (24-bit version)

---

**End of Technical Reference Document**
