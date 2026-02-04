# Week 4: Top-Level Decomposition Plan

## Date: 2025-02-03
## Branch: week4-top-decompose
## Issue: TOP-001

---

## Current Status (cyan_top.sv)

| Metric | Value |
|--------|-------|
| Total Lines | 1313 |
| Sub-modules | 10 |
| Complexity | HIGH |

---

## Sub-Module Analysis

| Module | Lines | Purpose |
|--------|-------|---------|
| clk_ctrl | ~50 | Clock control and locking |
| mipi_csi2_tx_top | IP | MIPI CSI-2 TX (Xilinx IP) |
| init | ~100 | Power-on initialization |
| host_if (SPI) | ~50 | SPI slave interface |
| reg_map_refacto | ~300 | Register map and control |
| roic_gate_drv_gemini | ~100 | ROIC gate driver |
| sequencer_fsm | ~490 | FSM (refactored Week 3) |
| ti_roic_spi | ~80 | TI ROIC SPI interface |
| read_data_mux | ~900 | Data readout mux |
| dcdc_clk | ~30 | DCDC clock generation |

---

## Decomposition Strategy

### Phase 1: Clock Generation Module
**Target Module**: 

Extract from cyan_top.sv:
- clk_ctrl instantiation
- dcdc_clk instantiation
- All clock-related logic
- Reset synchronization (reset_sync modules)

**Interface**:
- Input: nRST, MCLK_50M_p/n
- Output: s_clk_100mhz, s_dphy_clk_200M, s_clk_20mhz, s_clk_5mhz, s_clk_1mhz
- Output: rst_n_100mhz, rst_n_200mhz, rst_n_20mhz, etc.

**Expected Reduction**: ~100 lines

---

### Phase 2: TI ROIC Integration Module
**Target Module**: 

Extract from cyan_top.sv:
- ti_roic_spi instantiation
- roic_gate_drv_gemini instantiation
- All ROIC-related glue logic
- Gate driving signal outputs

**Interface**:
- Clock: s_clk_20mhz
- Resets: rst_n_20mhz
- ROIC I/O signals (12 channels)
- Gate outputs: GF_STV_L/R, GF_XAO, GF_LR, GF_CPV, GF_OE

**Expected Reduction**: ~200 lines

---

### Phase 3: Register Map Integration Module
**Target Module**: 

Extract from cyan_top.sv:
- reg_map_refacto instantiation
- host_if (SPI slave) instantiation
- Register access glue logic

**Interface**:
- Clock: s_clk_100mhz
- SPI: SCLK, SSB, MOSI, MISO
- Control signals to/from sequencer

**Expected Reduction**: ~150 lines

---

### Phase 4: MIPI Integration Module
**Target Module**: 

Extract from cyan_top.sv:
- mipi_csi2_tx_top instantiation
- AXI-Stream data packing logic
- MIPI PHY interface

**Interface**:
- Clocks: dphy_clk_200M, eim_clk
- Data: s_axis_tdata_a/b, s_axis_tvalid, etc.
- MIPI PHY outputs

**Expected Reduction**: ~100 lines

---

## Expected Results

| Phase | cyan_top.sv Lines | New Module |
|-------|-------------------|------------|
| Before | 1313 | - |
| After Phase 1 | ~1200 | clock_gen_top.sv (~200) |
| After Phase 2 | ~1000 | ti_roic_integration.sv (~300) |
| After Phase 3 | ~850 | reg_map_integration.sv (~250) |
| After Phase 4 | ~750 | mipi_integration.sv (~150) |

**Final Target**: cyan_top.sv < 500 lines

---

## Execution Order

1. Phase 1: Clock Generation (Foundation)
2. Phase 2: TI ROIC Integration
3. Phase 3: Register Map Integration  
4. Phase 4: MIPI Integration

Each phase will be:
1. Create new module file
2. Extract logic from cyan_top.sv
3. Update instantiation in cyan_top.sv
4. Verify syntax
5. Commit and test

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Signal connection errors | HIGH | Careful signal accounting |
| Timing changes | MEDIUM | Re-run synthesis after each phase |
| Reset domain changes | MEDIUM | Use existing reset_sync pattern |

---

## Success Criteria

- [ ] cyan_top.sv < 500 lines
- [ ] All new modules compile without errors
- [ ] Timing met after synthesis
- [ ] No functional regressions
