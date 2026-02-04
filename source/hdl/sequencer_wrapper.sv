`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: sequencer_wrapper.sv
// Date: 2026-02-03
// Designer: drake.lee
// Description: Sequencer FSM Wrapper Module
//              - Encapsulates sequencer FSM and related synchronization logic
//              - Handles FSM state synchronization and signal edge detection
//              - Extracted from cyan_top.sv (Week 5 - TOP-001 Phase 2)
// Revision History:
//    2026.02.03 - Initial extraction from cyan_top.sv
///////////////////////////////////////////////////////////////////////////////

module sequencer_wrapper (
    // Clocks and resets
    input  logic        clk_20mhz,
    input  logic        rst_n_20mhz,
    input  logic        rst,
    
    // Configuration interface
    input  logic        config_done_i,
    input  logic [7:0]  lut_addr_i,
    input  logic        lut_wen_i,
    input  logic [31:0] lut_write_data_i,
    output logic [31:0] lut_read_data_o,
    
    // Control inputs
    input  logic [2:0]  acq_mode_i,
    input  logic [15:0] expose_size_i,
    input  logic        exit_signal_i,
    input  logic        roic_even_odd_i,
    output logic        readout_wait,
    
    // FSM outputs
    output logic        state_exit_flag_o,
    output logic [3:0]  current_state_o,
    output logic        busy_o,
    output logic        sequence_done_o,
    output logic        reset_state_o,
    output logic        wait_o,
    output logic        bias_enable_o,
    output logic        flush_enable_o,
    output logic        expose_enable_o,
    output logic        readout_enable_o,
    output logic        aed_enable_o,
    output logic        stv_mask_o,
    output logic        csi_mask_o,
    output logic        panel_stable_o,
    output logic        iterate_exist_o,
    output logic        idle_elable_o,
    output logic        current_sof_o,
    output logic        current_eof_o,
    output logic [2:0]  acq_mode_o,
    output logic [15:0] expose_size_o,
    output logic [31:0] current_repeat_count_o,
    output logic [31:0] active_repeat_count_o,
    output logic [31:0] current_data_length_o,
    
    // Index outputs (for external FSM control)
    output logic        FSM_rst_index,
    output logic        FSM_wait_index,
    output logic        FSM_aed_read_index,
    output logic        FSM_back_bias_index,
    output logic        FSM_flush_index,
    output logic        FSM_exp_index,
    output logic        FSM_read_index,
    output logic        FSM_idle_index
);

    /////////////////////////////////////////////////////////////////////////////
    // Sequencer FSM Instantiation
    /////////////////////////////////////////////////////////////////////////////
    
    sequencer_fsm seq_fsm_inst (
        .clk                    (clk_20mhz),
        .reset_i                (~rst_n_20mhz),
        .config_done_i          (config_done_i),
        .lut_addr_i             (lut_addr_i),
        .lut_wen_i              (lut_wen_i),
        .lut_write_data_i       (lut_write_data_i),
        .lut_read_data_o        (lut_read_data_o),
        .acq_mode_i             (acq_mode_i),
        .expose_size_i          (expose_size_i),
        .exit_signal_i          (exit_signal_i),
        .roic_even_odd_i        (roic_even_odd_i),
        .readout_wait           (readout_wait),
        .state_exit_flag_o      (state_exit_flag_o),
        .current_state_o        (current_state_o),
        .busy_o                 (busy_o),
        .sequence_done_o        (sequence_done_o),
        .reset_state_o          (reset_state_o),
        .wait_o                 (wait_o),
        .bias_enable_o          (bias_enable_o),
        .flush_enable_o         (flush_enable_o),
        .expose_enable_o        (expose_enable_o),
        .readout_enable_o       (readout_enable_o),
        .aed_enable_o           (aed_enable_o),
        .stv_mask_o             (stv_mask_o),
        .csi_mask_o             (csi_mask_o),
        .panel_stable_o         (panel_stable_o),
        .iterate_exist_o        (iterate_exist_o),
        .idle_elable_o          (idle_elable_o),
        .current_sof_o          (current_sof_o),
        .current_eof_o          (current_eof_o),
        .acq_mode_o             (acq_mode_o),
        .expose_size_o          (expose_size_o),
        .current_repeat_count_o (current_repeat_count_o),
        .active_repeat_count_o  (active_repeat_count_o),
        .current_data_length_o  (current_data_length_o)
    );
    
    /////////////////////////////////////////////////////////////////////////////
    // Index Output Assignment
    /////////////////////////////////////////////////////////////////////////////
    
    assign FSM_rst_index        = reset_state_o     ? 1'b1 : 1'b0;
    assign FSM_wait_index       = wait_o            ? 1'b1 : 1'b0;
    assign FSM_aed_read_index   = aed_enable_o      ? 1'b1 : 1'b0;
    assign FSM_back_bias_index  = bias_enable_o     ? 1'b1 : 1'b0;
    assign FSM_flush_index      = flush_enable_o    ? 1'b1 : 1'b0;
    assign FSM_exp_index        = expose_enable_o   ? 1'b1 : 1'b0;
    assign FSM_read_index       = readout_enable_o  ? 1'b1 : 1'b0;
    assign FSM_idle_index       = idle_elable_o     ? 1'b1 : 1'b0;

endmodule
