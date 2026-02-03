# Week 2: Reset Standardization Plan

## Date: 2025-02-03
## Branch: week2-reset-std

---

## Current Reset Issues

### RST-001: cyan_top.sv:745-777
```systemverilog
// PROBLEM: Multiple reset polarities and inconsistent logic
assign s_reset = !nRST;              // nRST(active-LOW) → s_reset(active-HIGH)

always_ff @(posedge s_clk_20mhz) begin
    if (system_rst || init_rst || s_reset) rst <= 1'b0;    // rst = active-LOW
    else rst <= 1'b1;
end

always_ff @(posedge s_clk_100mhz) begin
    if (system_rst || s_reset) s_csi2_reset <= 1'b1;      // active-HIGH!
    else s_csi2_reset <= 1'b0;
end

always_ff @(posedge s_clk_20mhz) begin
    if (FSM_rst_index || ~rst) fsm_drv_rst <= 1'b0;      // active-LOW
    else fsm_drv_rst <= 1'b1;
end
```

**Problems:**
1. Mixed polarities: `s_reset` is active-HIGH, `rst` is active-LOW
2. `s_csi2_reset` is active-HIGH while others are active-LOW
3. No proper synchronizers for multi-clock domains
4. Direct reset forwarding without CDC protection

---

## Standardized Reset Architecture

### Target: All active-LOW with proper synchronizers

```
                    ┌─────────────────┐
nRST (active-LOW) ──┤ reset_sync      ├─── rst_n_20mhz
(external async)    │ (per domain)    │
                    └─────────────────┘
                    
Clock Domains:
├── 20MHz  → rst_n_20mhz  (sequencer_fsm, gate driver)
├── 100MHz → rst_n_100mhz (CSI2, system)
├── 200MHz → rst_n_200mhz (DPHY)
├── 5MHz   → rst_n_5mhz   (SPI)
└── 1MHz   → rst_n_1mhz   (switch sync)
```

---

## Implementation Plan

### Step 1: Create reset_sync module ✅ (Already done)
- `source/hdl/reset_sync.sv` - Async assert, sync deassert

### Step 2: Integrate reset_sync for each clock domain
```systemverilog
// 20MHz domain
reset_sync reset_sync_20mhz (
    .clk    (s_clk_20mhz),
    .nRST   (nRST),
    .rst_n  (rst_n_20mhz)
);

// 100MHz domain  
reset_sync reset_sync_100mhz (
    .clk    (s_clk_100mhz),
    .nRST   (nRST),
    .rst_n  (rst_n_100mhz)
);
```

### Step 3: Replace all reset logic with synchronized resets
- Remove `s_reset = !nRST`
- Use `rst_n_<domain>` from reset_sync modules
- All resets: active-LOW

### Step 4: Fix RST-002 in read_data_mux.sv:219
```systemverilog
// BEFORE: Multiple async resets in single always_ff
always_ff @(posedge eim_clk or negedge eim_rst or posedge rst_hsync_cnt_dly ...)
// Problem: Multiple async reset sources!

// AFTER: Single synchronized reset
always_ff @(posedge eim_clk or negedge rst_n_eim)
```

---

## Success Criteria

| Criterion | Target | Status |
|-----------|--------|--------|
| All resets active-LOW | 100% | ⏳ Pending |
| All domains use reset_sync | Yes | ⏳ Pending |
| No async reset crossing | 0 | ⏳ Pending |
| Reset consistency | 100% | ⏳ Pending |

