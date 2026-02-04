`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: debug_integration.sv
// Date: 2026.02.03
// Designer: drake.lee
// Description: Debug and LED integration module - Extracted from cyan_top.sv
// Revision History:
//    2026.02.03 - Initial extraction from cyan_top.sv (Week 6 - M6-1)
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

    always_comb begin
        case (state_led_ctr)
            8'h00: STATE_LED1 = test_cnt[23];
            8'h01: STATE_LED1 = FSM_idle_index;
            8'h02: STATE_LED1 = FSM_read_index;
            8'h03: STATE_LED1 = FSM_exp_index;
            8'h04: STATE_LED1 = FSM_aed_read_index;
            8'h05: STATE_LED1 = FSM_flush_index;
            8'h06: STATE_LED1 = FSM_back_bias_index;
            8'h07: STATE_LED1 = FSM_wait_index;
            8'h08: STATE_LED1 = FSM_rst_index;
            8'h09: STATE_LED1 = valid_roic_data;
            8'h0A: STATE_LED1 = valid_read_mem;
            8'h0B: STATE_LED1 = valid_readout;
            8'h20: STATE_LED1 = channel_detected[0];
            8'h21: STATE_LED1 = channel_detected[1];
            8'h22: STATE_LED1 = channel_detected[2];
            8'h23: STATE_LED1 = channel_detected[3];
            8'h24: STATE_LED1 = channel_detected[4];
            8'h25: STATE_LED1 = channel_detected[5];
            8'h26: STATE_LED1 = channel_detected[6];
            8'h27: STATE_LED1 = channel_detected[7];
            8'h28: STATE_LED1 = channel_detected[8];
            8'h29: STATE_LED1 = channel_detected[9];
            8'h2A: STATE_LED1 = channel_detected[10];
            8'h2B: STATE_LED1 = channel_detected[11];
            8'h30: STATE_LED1 = read_frame_start;
            8'h31: STATE_LED1 = read_frame_reset;
            8'h32: STATE_LED1 = read_axis_tvalid;
            8'h33: STATE_LED1 = read_axis_tlast;
            8'h34: STATE_LED1 = read_axis_tready;
            8'h40: STATE_LED1 = sig_irst;
            8'h41: STATE_LED1 = sig_shr;
            8'h42: STATE_LED1 = sig_shs;
            8'h43: STATE_LED1 = sig_lpf1;
            8'h44: STATE_LED1 = sig_lpf2;
            8'h45: STATE_LED1 = sig_tdef;
            8'h46: STATE_LED1 = sig_gate_on;
            8'h47: STATE_LED1 = sig_df_sm0;
            8'h48: STATE_LED1 = sig_df_sm1;
            8'h49: STATE_LED1 = sig_df_sm2;
            8'h4A: STATE_LED1 = sig_df_sm3;
            8'h4B: STATE_LED1 = sig_df_sm4;
            8'h4C: STATE_LED1 = sig_df_sm5;
            8'h4D: STATE_LED1 = roic_sdio_bit0;
            8'h4E: STATE_LED1 = sum_channel_detected;
            8'h4F: STATE_LED1 = gen_sync_start;
            8'h50: STATE_LED1 = aed_trig;
            8'h51: STATE_LED1 = exit_signal;
            8'h52: STATE_LED1 = panel_stable;
            8'h53: STATE_LED1 = exp_read_exist;
            8'h54: STATE_LED1 = get_dark_hi;
            8'h55: STATE_LED1 = exit_signal_dark;
            8'h56: STATE_LED1 = get_bright_hi;
            8'h57: STATE_LED1 = exit_signal_bright;
            8'h58: STATE_LED1 = get_aed_trig_hi;
            8'h59: STATE_LED1 = exit_signal_aed;
            8'h5A: STATE_LED1 = sequence_done;
            8'h5B: STATE_LED1 = sequence_done_hi;
            8'h60: STATE_LED1 = tg_stv;
            8'h61: STATE_LED1 = mask_stv;
            8'h62: STATE_LED1 = back_bias;
            8'h63: STATE_LED1 = roic_sync_in;
            8'h64: STATE_LED1 = ti_roic_sync;
            8'h65: STATE_LED1 = readout_wait;
            8'h66: STATE_LED1 = valid_readout;
            8'h67: STATE_LED1 = stv_mask;
            8'h68: STATE_LED1 = csi_mask;
            8'h69: STATE_LED1 = clk_5mhz;
            8'h6A: STATE_LED1 = clk_1mhz;
            8'h6B: STATE_LED1 = aed_mode_exist;
            8'h6C: STATE_LED1 = aed_trig_i;
            8'h6D: STATE_LED1 = get_bright;
            8'h6E: STATE_LED1 = aed_ready_done;
            8'h6F: STATE_LED1 = state_exit_flag;
            default: STATE_LED1 = 1'b0;
        endcase
    end

    logic dbg_even_odd_toggle_out;
    assign dbg_even_odd_toggle_out = sig_irst;
    assign DEBUG_SIG = {dbg_even_odd_toggle_out, dbg_roic_even_odd, channel_detected[0], dbg_roic_1st_channel};

endmodule
