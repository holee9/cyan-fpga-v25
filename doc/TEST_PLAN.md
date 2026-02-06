# CYAN-FPGA Test Plan

**Document ID:** DOC-005
**Version:** 1.0
**Last Updated:** 2026-02-04
**Project:** CYAN-FPGA xdaq_top
**FPGA:** Xilinx Artix-7 XC7A35TFGG484-1
**Tool:** Vivado 2025.2

---

## Table of Contents

1. [Test Strategy](#section-1-test-strategy)
2. [Test Levels](#section-2-test-levels)
3. [Unit Test Cases](#section-3-unit-test-cases)
4. [Integration Test Cases](#section-4-integration-test-cases)
5. [System Test Cases](#section-5-system-test-cases)
6. [Coverage Requirements](#section-6-coverage-requirements)
7. [Success Criteria](#section-7-success-criteria)
8. [Test Execution](#section-8-test-execution)

---

## Section 1: Test Strategy

### 1.1 Testing Philosophy

The CYAN-FPGA testing strategy follows a **V-Model approach**:

```
Requirements → Design → Implementation
     ↓           ↓           ↓
  System Test  Integration  Unit Test
```

### 1.2 Test Categories

| Category | Purpose | Automation |
|----------|---------|------------|
| Unit Tests | Verify individual modules | 100% |
| Integration Tests | Verify module interactions | 100% |
| System Tests | Verify end-to-end functionality | 90% |
| Regression Tests | Verify stability after changes | 100% |

### 1.3 Test Tools

| Tool | Purpose | Version |
|------|---------|---------|
| Vivado Simulator | Behavioral simulation | 2025.2 |
| XSim | Compiled simulation | 2025.2 |
| ModelSim | Alternative simulator | 10.0+ |
| Tcl Scripts | Test automation | - |

---

## Section 2: Test Levels

### 2.1 Unit Tests

**Scope**: Individual module verification

**Modules Tested**:
1. Clock generation and reset
2. CDC synchronizers
3. Async FIFOs
4. FSMs (init, sequencer)
5. Register map
6. Data path modules

**Pass Criteria**:
- All code paths executed
- All assertions pass
- No X/Z propagation
- 100% state coverage for FSMs

### 2.2 Integration Tests

**Scope**: Module interaction verification

**Interfaces Tested**:
1. Clock domain crossings
2. SPI register access
3. MIPI CSI-2 data path
4. ROIC data capture
5. Gate driver timing

**Pass Criteria**:
- No timing violations
- No data corruption across CDC
- Correct protocol behavior

### 2.3 System Tests

**Scope**: End-to-end functionality

**Scenarios**:
1. Complete image acquisition
2. Multi-frame capture
3. Configuration changes
4. Error conditions

**Pass Criteria**:
- Successful image capture
- Correct register responses
- Proper error handling

---

## Section 3: Unit Test Cases

### 3.1 init_refacto (init_tb.sv)

| Test ID | Description | Expected Result |
|---------|-------------|-----------------|
| TB01-01 | FSM reset state | INIT_IDLE active |
| TB01-02 | Power-on sequence | STEP_1 → STEP_6 progression |
| TB01-03 | Power-off sequence | STEP_6 → STEP_1 progression |
| TB01-04 | Power-down FSM | DWN_IDLE → DWN_STEP_5 |
| TB01-05 | ROIC reset pulse | Single pulse detected |
| TB01-06 | init_rst generation | Active LOW at reset |
| TB01-07 | Delay function | Correct cycle counts |
| TB01-08 | Step exclusivity | One-hot maintained |

**Coverage Target**:
- Line: 100%
- FSM State: 100%
- FSM Transition: 100%

### 3.2 read_data_mux (read_data_mux_tb.sv)

| Test ID | Description | Expected Result |
|---------|-------------|-----------------|
| TB02-01 | FIFO CDC | Data integrity maintained |
| TB02-02 | FIFO flags | Full/empty correct |
| TB02-03 | AXI-Stream protocol | Valid/ready handshake |
| TB02-04 | HSYNC generation | Pulses at line end |
| TB02-05 | VSYNC generation | Pulse at frame end |
| TB02-06 | Data mux selection | All 12 channels work |
| TB02-07 | Frame start (tuser) | Asserted at (0,0) |
| TB02-08 | Counter rollover | No overflow |
| TB02-09 | exist_get_image | Asserted when active |
| TB02-10 | Dummy image mode | Test pattern output |

**Coverage Target**:
- Line: 95%
- Branch: 90%
- Toggle: 85%

### 3.3 cyan_top (cyan_top_tb.sv)

| Test ID | Description | Expected Result |
|---------|-------------|-----------------|
| TB03-01 | Power-on reset | Clean reset |
| TB03-02 | Clock lock detection | All clocks stable |
| TB03-03 | SPI write/read | Data matches |
| TB03-04 | MIPI CSI-2 frame | PHY outputs driven |
| TB03-05 | ROIC data capture | Data accepted |
| TB03-06 | FSM transitions | States progress |
| TB03-07 | Multi-clock CDC | No metastability |
| TB03-08 | Power init FSM | Bias outputs active |

**Coverage Target**:
- Line: 80%
- Branch: 75%

### 3.4 CDC Modules

| Test ID | Description | Expected Result |
|---------|-------------|-----------------|
| CDC-001 | 3-stage sync delay | 3-cycle delay |
| CDC-002 | Pulse synchronizer | Pulse captured |
| CDC-003 | Async FIFO | No data loss |
| CDC-004 | Reset sync | Clean deassert |
| CDC-005 | Multi-bit CDC | Gray code used |

### 3.5 FSM Modules

#### 3.5.1 Sequencer FSM

| Test ID | Description | Expected Result |
|---------|-------------|-----------------|
| FSM-001 | State transitions | All states reachable |
| FSM-002 | LUT access | Correct address sequence |
| FSM-003 | Mode switching | AED/Normal modes work |
| FSM-004 | Exit signal | Completes sequence |
| FSM-005 | Repeat count | Iterations match config |

#### 3.5.2 SPI Slave

| Test ID | Description | Expected Result |
|---------|-------------|-----------------|
| SPI-001 | Byte transfer | Correct data |
| SPI-002 | Register write | Value stored |
| SPI-003 | Register read | Value returned |
| SPI-004 | Invalid address | Error response |

---

## Section 4: Integration Test Cases

### 4.1 Clock Domain Integration

| Test ID | Domain A | Domain B | Method | Success |
|---------|----------|----------|--------|---------|
| IT-001 | 200MHz | 100MHz | Async FIFO | No data loss |
| IT-002 | 100MHz | 20MHz | CDC sync | Stable output |
| IT-003 | eim_clk | sys_clk | Async FIFO | CDC-003 compliant |
| IT-004 | Async | 100MHz | Reset sync | Clean reset |

### 4.2 SPI Register Integration

| Test ID | Register | Write | Read | Expected |
|---------|----------|-------|------|----------|
| IT-SPI-01 | SYS_CMD_REG | 0x0001 | 0x0001 | Matches |
| IT-SPI-02 | OP_MODE_REG | 0x0002 | 0x0002 | Matches |
| IT-SPI-03 | EXPOSE_SIZE | 0x03E8 | 0x03E8 | Matches |
| IT-SPI-04 | IMAGE_HEIGHT | 0x0C00 | 0x0C00 | Matches |

### 4.3 MIPI CSI-2 Integration

| Test ID | Description | Check | Success |
|---------|-------------|-------|---------|
| IT-MIPI-01 | PHY initialization | Lock status | Locked |
| IT-MIPI-02 | Data transfer | Word count | Matches |
| IT-MIPI-03 | Frame transfer | SOF/EOF | Detected |
| IT-MIPI-04 | Lane config | Lane count | Correct |

### 4.4 ROIC Data Integration

| Test ID | Description | Check | Success |
|---------|-------------|-------|---------|
| IT-ROIC-01 | Deserializer | Bit alignment | Aligned |
| IT-ROIC-02 | Data reordering | Channel order | Correct |
| IT-ROIC-03 | First channel | Detection | Found |
| IT-ROIC-04 | Full frame | Data count | Matches |
| IT-ROIC-05 | 12 channels | All active | All work |

---

## Section 5: System Test Cases

### 5.1 Acquisition Sequence

| Test ID | Mode | Frames | Success Criteria |
|---------|------|--------|------------------|
| ST-001 | Normal | 1 | Complete frame |
| ST-002 | Normal | 10 | Consistent output |
| ST-003 | AED | 1 | Detection works |
| ST-004 | Flush | 1 | Array cleared |
| ST-005 | Multi-expose | 3 | Correct sum |

### 5.2 Configuration Tests

| Test ID | Parameter | Values | Success |
|---------|-----------|--------|---------|
| ST-CFG-01 | Image height | 64, 128, 256 | All work |
| ST-CFG-02 | Expose size | Min, Max, Typical | All work |
| ST-CFG-03 | Repeat count | 1, 10, 100 | All work |
| ST-CFG-04 | Gate timing | Fast, Slow | All work |

### 5.3 Error Condition Tests

| Test ID | Error | Injection | Response |
|---------|-------|-----------|----------|
| ST-ERR-01 | FIFO overflow | Force write | Handled |
| ST-ERR-02 | Timeout | Stop sequence | Timeout detected |
| ST-ERR-03 | Invalid register | Write | Ignored |
| ST-ERR-04 | Clock loss | Stop clock | Reset triggered |

---

## Section 6: Coverage Requirements

### 6.1 Code Coverage

| Module Type | Line | Branch | FSM | Toggle |
|-------------|------|--------|-----|--------|
| Simple (combinational) | 100% | 100% | N/A | 90% |
| FSM | 100% | 95% | 100% | 85% |
| CDC | 100% | 100% | N/A | 95% |
| Data path | 95% | 90% | N/A | 80% |
| Top-level | 80% | 75% | N/A | 70% |

### 6.2 Functional Coverage

| Feature | Points | Target |
|---------|--------|--------|
| FSM states | All states | 100% |
| FSM transitions | Valid transitions | 100% |
| Register access | All registers | 100% |
| CDC paths | All paths | 100% |
| MIPI modes | All configs | 100% |
| ROIC channels | All 12 | 100% |

### 6.3 Coverage Tools

**Vivado Simulator**:
```tcl
# Enable coverage
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
set_property -name {xsim.compile.enable_line_debug} -value {true} -objects [get_filesets sim_1]

# Generate report
report_coverage -file coverage.rpt
```

---

## Section 7: Success Criteria

### 7.1 Test Completion

A test is considered complete when:

1. **All test cases executed** (no skips without justification)
2. **All assertions pass** (no assertion failures)
3. **Coverage meets target** (metrics above thresholds)
4. **No timeouts** (all waits complete)
5. **No X/Z propagation** (all signals resolved)

### 7.2 Pass/Fail Criteria

| Criterion | Pass | Fail |
|-----------|------|------|
| Test execution | All run | Any skipped |
| Assertions | 0 errors | Any error |
| Coverage | ≥ target | < target |
| Waveforms | Match spec | Deviation |
| Log | No errors | Errors present |

### 7.3 Sign-off Requirements

**Unit Tests**:
- [ ] All 30 unit modules tested
- [ ] Coverage ≥ 95%
- [ ] All assertions pass

**Integration Tests**:
- [ ] All CDC paths verified
- [ ] All interfaces tested
- [ ] No timing violations

**System Tests**:
- [ ] Complete acquisition verified
- [ ] All modes tested
- [ ] Error handling verified

---

## Section 8: Test Execution

### 8.1 Running Tests

#### GUI Mode
```bash
vivado -mode gui -source run_sim.tcl
```

#### Batch Mode
```bash
vivado -mode batch -source run_sim.tcl -log sim.log
```

### 8.2 Test Scripts

**Unit Test Runner** (`run_unit_tests.tcl`):
```tcl
# Run all unit tests
set unit_tests {init_tb read_data_mux_tb cdc_gen_sync_tb}
foreach test $unit_tests {
    set_property top $test [get_filesets sim_1]
    launch_simulation
    run all
    close_sim
}
```

**Regression Runner** (`run_regression.tcl`):
```tcl
# Complete regression suite
source run_unit_tests.tcl
source run_integration_tests.tcl
source run_system_tests.tcl
generate_report
```

### 8.3 Continuous Integration

**CI Pipeline**:
1. Syntax check (xvlog)
2. Elaboration (xelab)
3. Simulation (xsim)
4. Coverage report
5. Pass/Fail determination

### 8.4 Test Schedule

| Phase | Duration | Tests |
|-------|----------|-------|
| Unit | Week 12 | 30 tests |
| Integration | Week 12 | 15 tests |
| System | Week 13 | 10 tests |
| Regression | Week 13 | Full suite |

---

## Appendix: Test Case Template

```systemverilog
// Test Case Template
module <module>_tb;

    // 1. Clock and Reset
    logic clk;
    logic rst_n;

    // 2. DUT Signals
    // ...

    // 3. DUT Instantiation
    <module>_name dut (
        //...
    );

    // 4. Test Control
    int test_passed = 0;
    int test_failed = 0;

    // 5. Test Sequence
    initial begin
        // Apply reset
        // Run tests
        // Report results
    end

    // 6. Waveform Dump
    initial begin
        $dumpfile("<module>_tb.vcd");
        $dumpvars(0, <module>_tb);
    end

endmodule
```

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-04 | drake.lee | Initial |

---

**End of Document: DOC-005**
