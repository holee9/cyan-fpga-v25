`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: data_path_integration.sv
// Date: 2026-02-03
// Designer: drake.lee
// Description: Data Path Integration Module
//              - Encapsulates read_data_mux and related data processing
//              - Handles ROIC data flow from TI ROIC to MIPI CSI-2 TX
//              - Extracted from cyan_top.sv (Week 5 - TOP-001 Phase 2)
// Revision History:
//    2026.02.03 - Initial extraction from cyan_top.sv
///////////////////////////////////////////////////////////////////////////////

module data_path_integration (
    // Clocks and resets
    input  logic        clk_100mhz,
    input  logic        eim_clk,
    input  logic        rst_n_100mhz,
    input  logic        rst_n_eim,
    input  logic        dphy_clk_200M,
    
    // CSI control
    input  logic        csi_done,
    
    // Image acquisition control
    input  logic        dummy_get_image,
    input  logic [15:0]  dsp_image_height,
    input  logic [15:0]  max_v_count,
    input  logic [15:0]  max_h_count,
    
    // FSM control
    input  logic        FSM_aed_read_index,
    input  logic        read_data_start,
    input  logic        FSM_read_index,
    
    // ROIC data inputs (from TI ROIC)
    input  logic [23:0]  roic_read_data_a [11:0],
    input  logic [23:0]  roic_read_data_b [11:0],
    input  logic [11:0] reordered_valid,
    
    // AXI-Stream interface (to MIPI)
    output logic        read_axis_tready,
    input  logic        read_axis_tready_in,
    output logic        read_axis_tlast,
    output logic        read_data_valid,
    output logic [23:0]  read_data_out_a,
    output logic [23:0]  read_data_out_b,
    
    // Frame control
    output logic        read_frame_start,
    output logic        read_frame_reset,
    
    // Data read request (to TI ROIC)
    output logic [11:0]  data_read_req,
    
    // Valid data outputs (for status)
    output logic        valid_roic_data,
    output logic        valid_read_mem
);

    ///////////////////////////////////////////////////////////////////////////////
    // Internal Signals
    ///////////////////////////////////////////////////////////////////////////////
    
    logic [11:0] valid_read_enable;

    ///////////////////////////////////////////////////////////////////////////////
    // Valid Signal Assignment
    ///////////////////////////////////////////////////////////////////////////////
    
    assign valid_roic_data = |valid_read_enable;
    assign valid_read_mem  = |reordered_valid;

    ///////////////////////////////////////////////////////////////////////////////
    // Read Data Mux Instantiation
    ///////////////////////////////////////////////////////////////////////////////
    
    read_data_mux read_data_mux_inst (
        .sys_clk                (clk_100mhz),
        .sys_rst                (rst_n_100mhz),
        .eim_clk                (eim_clk),
        .eim_rst                (rst_n_eim),
        .csi_done               (csi_done),
        .dummy_get_image        (dummy_get_image),
        .exist_get_image        (),
        .dsp_image_height       (dsp_image_height),
        .max_v_count            (max_v_count),
        .max_h_count            (max_h_count),
        .FSM_aed_read_index     (FSM_aed_read_index),
        .read_data_start        (read_data_start),
        .FSM_read_index         (FSM_read_index),
        .roic_read_data_a       (roic_read_data_a),
        .roic_read_data_b       (roic_read_data_b),
        .valid_read_mem         (valid_read_mem),
        .read_axis_tready       (read_axis_tready_in),
        .read_axis_tlast        (read_axis_tlast),
        .read_data_valid        (read_data_valid),
        .read_data_out_a        (read_data_out_a),
        .read_data_out_b        (read_data_out_b),
        .read_frame_start       (read_frame_start),
        .read_frame_reset       (read_frame_reset),
        .data_read_req          (data_read_req)
    );
    
    // Assign output ready signal
    assign read_axis_tready = read_axis_tready_in;

endmodule
