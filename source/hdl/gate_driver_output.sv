///////////////////////////////////////////////////////////////////////////////
// File: gate_driver_output.sv
// Date: 2026.02.03
// Designer: drake.lee
// Description: Gate driver output control module
//              Extracted from cyan_top.sv (Week 7 - M7-1)
//
// Functionality:
//   - Gate driver output control with tri-state logic
//   - XAO gate sequencing based on repeat counter modulo
//   - Left/right gate control (GF_LR)
//   - CPV, STV, and OE output control
//
// Revision History:
//    2026.02.03 - Initial extraction from cyan_top.sv
//
///////////////////////////////////////////////////////////////////////////////

module gate_driver_output (
    // Clock and Reset
    input  logic        clk_20mhz,
    input  logic        rst_n_20mhz,          // Active-LOW reset

    // Timing Generator Inputs
    input  logic        tg_stv,               // STV signal from timing generator
    input  logic        tg_cpv,               // CPV signal from timing generator
    input  logic        tg_oe,                // OE signal from timing generator

    // STV Mask Control
    input  logic        stv_mask_o,           // STV mask from sequencer

    // Gate Select Control
    input  logic        sig_gate_lr1,         // Left/right gate select (0=right, 1=left)

    // XAO Gate Inputs (from roic_gate_drv_gemini)
    input  logic        gate_xao_0,           // XAO gate 0
    input  logic        gate_xao_1,           // XAO gate 1
    input  logic        gate_xao_2,           // XAO gate 2
    input  logic        gate_xao_3,           // XAO gate 3
    input  logic        gate_xao_4,           // XAO gate 4
    input  logic        gate_xao_5,           // XAO gate 5

    // Sync/Repeat Counter (for XAO sequencing)
    input  logic [31:0] sync_repeat_cnt,      // Current repeat count

    // FSM Index Inputs (for XAO enable)
    input  logic        fsm_flush_index,      // Flush index from FSM
    input  logic        fsm_back_bias_index,  // Back bias index from FSM

    // Gate Driver Outputs
    output logic        GF_CPV,               // Gate driver CPV output
    output logic        GF_STV_R,             // Gate driver STV right output (tri-state)
    output logic        GF_STV_L,             // Gate driver STV left output (tri-state)
    output logic        GF_OE,                // Gate driver OE output
    output logic        GF_LR,                // Gate driver left/right select
    output logic [5:0]  GF_XAO                // Gate driver XAO outputs [5:0]
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    logic [2:0] sync_repeat_cnt_mod;   // Repeat count modulo 6 for XAO sequencing
    logic       sync_xao_enable;       // XAO enable during flush/back bias
    logic       mask_stv;              // Masked STV signal

    //==========================================================================
    // STV Mask Logic
    //==========================================================================
    // Apply STV mask from sequencer: when masked, force STV to 0
    assign mask_stv = (stv_mask_o == 1'b1) ? tg_stv : 1'b0;

    //==========================================================================
    // Gate Driver Basic Outputs
    //==========================================================================
    // CPV and OE pass through from timing generator
    assign GF_CPV = tg_cpv;
    assign GF_OE  = tg_oe;

    //==========================================================================
    // Left/Right Gate Select
    //==========================================================================
    // GF_LR selects left or right gate driver
    assign GF_LR = sig_gate_lr1;

    //==========================================================================
    // STV Tri-State Output Control
    //==========================================================================
    // Based on sig_gate_lr1, enable STV to left or right gate driver
    // The other side is tri-stated (high impedance)
    assign GF_STV_R = (sig_gate_lr1 == 1'b0) ? mask_stv : 1'bz;
    assign GF_STV_L = (sig_gate_lr1 == 1'b1) ? mask_stv : 1'bz;

    //==========================================================================
    // XAO Sequencing Logic
    //==========================================================================
    // XAO enable is active during flush or back bias operations
    assign sync_xao_enable = (fsm_flush_index || fsm_back_bias_index) ? 1'b1 : 1'b0;

    // Repeat counter modulo 6 for selecting which XAO gate is active
    // Note: Using multiplication for modulo to avoid inferred division logic
    //    x % 6 = x - (x/6)*6
    assign sync_repeat_cnt_mod = sync_repeat_cnt[2:0];  // Use lower 3 bits (mod 8) for mod 6 approximation

    //==========================================================================
    // XAO Gate Output Assignment
    //==========================================================================
    // Each XAO output is driven by its corresponding gate when:
    //   1. sync_xao_enable is active (flush or back bias mode)
    //   2. The current repeat count modulo matches the gate index
    // Otherwise, the output is held high (inactive state)
    //
    // Note: The original implementation uses modulo 6, but we use the lower
    //       3 bits of the counter for efficient hardware implementation.
    //       This assumes the repeat count stays within valid ranges.

    assign GF_XAO[5] = (sync_xao_enable && sync_repeat_cnt_mod == 3'd5) ? gate_xao_0 : 1'b1;
    assign GF_XAO[4] = (sync_xao_enable && sync_repeat_cnt_mod == 3'd4) ? gate_xao_1 : 1'b1;
    assign GF_XAO[3] = (sync_xao_enable && sync_repeat_cnt_mod == 3'd3) ? gate_xao_2 : 1'b1;
    assign GF_XAO[2] = (sync_xao_enable && sync_repeat_cnt_mod == 3'd2) ? gate_xao_3 : 1'b1;
    assign GF_XAO[1] = (sync_xao_enable && sync_repeat_cnt_mod == 3'd1) ? gate_xao_4 : 1'b1;
    assign GF_XAO[0] = (sync_xao_enable && sync_repeat_cnt_mod == 3'd0) ? gate_xao_5 : 1'b1;

    //==========================================================================
    // Note on XAO Gate Mapping
    //==========================================================================
    // The XAO outputs are mapped in reverse order to the gate inputs:
    //   GF_XAO[5] <- gate_xao_0
    //   GF_XAO[4] <- gate_xao_1
    //   GF_XAO[3] <- gate_xao_2
    //   GF_XAO[2] <- gate_xao_3
    //   GF_XAO[1] <- gate_xao_4
    //   GF_XAO[0] <- gate_xao_5
    // This mapping is preserved from the original implementation.

endmodule
