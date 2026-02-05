`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: debug_integration.sv
// Date: 2026.02.03
// Designer: drake.lee
// Description: Debug and LED integration module - Extracted from cyan_top.sv
// Revision History:
//    2026.02.03 - Initial extraction from cyan_top.sv (Week 6 - M6-1)
//    2026.02.04 - Integrated state_led_controller (Phase 8)
///////////////////////////////////////////////////////////////////////////////

module debug_integration (
    input logic clk_20mhz,
    input logic rst_n_20mhz,
    input logic [7:0] state_led_ctr,
    input logic FSM_idle_index,
    input logic FSM_read_index,
    input logic FSM_exp_index,
    input logic FSM_aed_read_index,
    input logic FSM_flush_index,
    input logic FSM_back_bias_index,
    input logic FSM_wait_index,
    input logic FSM_rst_index,
    input logic valid_roic_data,
    input logic valid_read_mem,
    input logic valid_readout,
    input logic [11:0] channel_detected,
    input logic read_frame_start,
    input logic read_frame_reset,
    input logic read_axis_tvalid,
    input logic read_axis_tlast,
    input logic read_axis_tready,
    input logic sig_irst,
    input logic sig_shr,
    input logic sig_shs,
    input logic sig_lpf1,
    input logic sig_lpf2,
    input logic sig_tdef,
    input logic sig_gate_on,
    input logic sig_df_sm0,
    input logic sig_df_sm1,
    input logic sig_df_sm2,
    input logic sig_df_sm3,
    input logic sig_df_sm4,
    input logic sig_df_sm5,
    input logic roic_sdio_bit0,
    input logic sum_channel_detected,
    input logic gen_sync_start,
    input logic roic_sync_in,
    input logic ti_roic_sync,
    input logic aed_trig,
    input logic aed_trig_i,
    input logic aed_mode_exist,
    input logic exit_signal,
    input logic panel_stable,
    input logic exp_read_exist,
    input logic get_dark_hi,
    input logic exit_signal_dark,
    input logic get_bright_hi,
    input logic exit_signal_bright,
    input logic get_aed_trig_hi,
    input logic exit_signal_aed,
    input logic get_bright,
    input logic sequence_done,
    input logic sequence_done_hi,
    input logic state_exit_flag,
    input logic readout_wait,
    input logic tg_stv,
    input logic mask_stv,
    input logic back_bias,
    input logic stv_mask,
    input logic csi_mask,
    input logic clk_5mhz,
    input logic clk_1mhz,
    input logic aed_ready_done,
    input logic [23:0] test_cnt,
    input logic dbg_roic_1st_channel,
    input logic dbg_roic_even_odd,
    output logic STATE_LED1,
    output logic [3:0] DEBUG_SIG
);

    //==========================================================================
    // Week 12: state_led_controller Integration (Phase 8 - M8-3)
    //==========================================================================
    // Extract LED control logic to dedicated module

    logic state_led_out;

    state_led_controller state_led_ctrl_inst (
        .clk_20mhz              (clk_20mhz),
        .rst_n                  (rst_n_20mhz),

        // LED select control
        .state_led_ctr          (state_led_ctr),

        // FSM state inputs
        .FSM_idle_index         (FSM_idle_index),
        .FSM_read_index         (FSM_read_index),
        .FSM_exp_index          (FSM_exp_index),
        .FSM_aed_read_index     (FSM_aed_read_index),
        .FSM_flush_index        (FSM_flush_index),
        .FSM_back_bias_index    (FSM_back_bias_index),
        .FSM_wait_index         (FSM_wait_index),
        .FSM_rst_index          (FSM_rst_index),

        // Validity signals
        .valid_roic_data        (valid_roic_data),
        .valid_read_mem         (valid_read_mem),
        .valid_readout          (valid_readout),

        // ROIC channel detection
        .channel_detected       (channel_detected),

        // AXI-Stream status
        .read_frame_start       (read_frame_start),
        .read_frame_reset       (read_frame_reset),
        .read_axis_tvalid       (read_axis_tvalid),
        .read_axis_tlast        (read_axis_tlast),
        .read_axis_tready       (read_axis_tready),

        // Ready status
        .aed_ready_done         (aed_ready_done),
        .panel_stable           (panel_stable),
        .gen_sync_start         (gen_sync_start),

        // LED output
        .STATE_LED1             (state_led_out)
    );

    // Override LED output when state_led_ctr < 0x70 (state_led_controller active)
    // Otherwise use legacy direct mapping
    always_comb begin
        if (state_led_ctr < 8'h70) begin
            STATE_LED1 = state_led_out;
        end else begin
            // Legacy direct mapping for modes 0x70+
            case (state_led_ctr)
                8'h70: STATE_LED1 = sig_irst;
                8'h71: STATE_LED1 = sig_shr;
                8'h72: STATE_LED1 = sig_shs;
                8'h73: STATE_LED1 = sig_lpf1;
                8'h74: STATE_LED1 = sig_lpf2;
                8'h75: STATE_LED1 = sig_tdef;
                8'h76: STATE_LED1 = sig_gate_on;
                8'h77: STATE_LED1 = sig_df_sm0;
                8'h78: STATE_LED1 = sig_df_sm1;
                8'h79: STATE_LED1 = sig_df_sm2;
                8'h7A: STATE_LED1 = sig_df_sm3;
                8'h7B: STATE_LED1 = sig_df_sm4;
                8'h7C: STATE_LED1 = sig_df_sm5;
                8'h7D: STATE_LED1 = roic_sdio_bit0;
                8'h7E: STATE_LED1 = sum_channel_detected;
                8'h7F: STATE_LED1 = gen_sync_start;
                8'h80: STATE_LED1 = aed_trig;
                8'h81: STATE_LED1 = exit_signal;
                8'h82: STATE_LED1 = panel_stable;
                8'h83: STATE_LED1 = exp_read_exist;
                8'h84: STATE_LED1 = get_dark_hi;
                8'h85: STATE_LED1 = exit_signal_dark;
                8'h86: STATE_LED1 = get_bright_hi;
                8'h87: STATE_LED1 = exit_signal_bright;
                8'h88: STATE_LED1 = get_aed_trig_hi;
                8'h89: STATE_LED1 = exit_signal_aed;
                8'h8A: STATE_LED1 = sequence_done;
                8'h8B: STATE_LED1 = sequence_done_hi;
                8'h8C: STATE_LED1 = tg_stv;
                8'h8D: STATE_LED1 = mask_stv;
                8'h8E: STATE_LED1 = back_bias;
                8'h8F: STATE_LED1 = roic_sync_in;
                8'h90: STATE_LED1 = ti_roic_sync;
                8'h91: STATE_LED1 = readout_wait;
                8'h92: STATE_LED1 = valid_readout;
                8'h93: STATE_LED1 = stv_mask;
                8'h94: STATE_LED1 = csi_mask;
                8'h95: STATE_LED1 = clk_5mhz;
                8'h96: STATE_LED1 = clk_1mhz;
                8'h97: STATE_LED1 = aed_mode_exist;
                8'h98: STATE_LED1 = aed_trig_i;
                8'h99: STATE_LED1 = get_bright;
                8'h9A: STATE_LED1 = aed_ready_done;
                8'h9B: STATE_LED1 = state_exit_flag;
                8'h9C: STATE_LED1 = test_cnt[23];  // Test counter mode
                8'h9D: STATE_LED1 = channel_detected[0];
                8'h9E: STATE_LED1 = channel_detected[1];
                8'h9F: STATE_LED1 = channel_detected[2];
                default: STATE_LED1 = 1'b0;
            endcase
        end
    end

    // Debug signal generation
    logic dbg_even_odd_toggle_out;
    assign dbg_even_odd_toggle_out = sig_irst;
    assign DEBUG_SIG = {dbg_even_odd_toggle_out, dbg_roic_even_odd, channel_detected[0], dbg_roic_1st_channel};

endmodule
