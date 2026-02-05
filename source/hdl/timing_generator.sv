//==============================================================================
// File: timing_generator.sv
// Date: 2026.02.04
// Designer: drake.lee
// Description: Timing Generator Module
//              Extracted from read_data_mux.sv (Phase 8 - M8-6)
//              Generates HSYNC, VSYNC, and timing signals for data path
//
// Features:
//   - HSYNC generation and control
//   - VSYNC generation and control
//   - Horizontal/vertical counters
//   - Frame timing management
//   - AXI-Stream timing signal generation (tlast, tuser)
//
// Revision History:
//    2026.02.04 - Initial extraction from read_data_mux.sv
//==============================================================================

`timescale 1ns / 1ps

module timing_generator (
    // Clock and reset
    input  logic        eim_clk,
    input  logic        eim_rst,
    input  logic        tx_eim_rst_n,
    input  logic        rst_n_eim,

    // Configuration
    input  logic [15:0] max_h_count,
    input  logic [15:0] max_v_count,
    input  logic [15:0] dsp_image_height,

    // Control inputs
    input  logic        read_data_start,
    input  logic        FSM_read_index_eim,
    input  logic        FSM_aed_read_index,
    input  logic        read_axis_tready,

    // Counters (managed in parent module, inputs here)
    input logic [15:0] s_h_count,
    input logic [15:0] s_v_count,

    // HSYNC outputs
    output logic        sig_hsync,
    output logic        hsync_keep_hi,
    output logic [3:0]  hsync_keep_hi_cnt,
    output logic [11:0] hsync_cnt,

    // VSYNC outputs
    output logic        sig_vsync,
    output logic        hi_vsync,
    output logic        vsync_keep_hi,
    output logic [3:0]  vsync_keep_hi_cnt,

    // Frame timing outputs
    output logic        s_axis_tlast,
    output logic        s_tuser_0,
    output logic        read_frame_reset,
    output logic        read_frame_start
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    // HSYNC internal signals
    logic [5:0]  hsync;
    logic [5:0]  hi_hsync;
    logic        lo_hsync;
    logic        up_hsync_keep_hi;
    logic        down_hsync_keep_hi;
    logic        inc_hsync_cnt;
    logic        rst_hsync_cnt;
    logic        rst_hsync_cnt_dly;
    logic        hi_hsync_all;

    // VSYNC internal signals
    logic        FSM_read_index_eim_1d;
    logic        FSM_read_index_eim_2d;
    logic        FSM_read_index_eim_3d;
    logic        FSM_read_index_eim_4d;
    logic        FSM_read_index_eim_5d;
    logic        up_vsync_keep_hi;
    logic        down_vsync_keep_hi;

    // Frame timing
    logic [15:0] s_tuser_0_dly;

    //==========================================================================
    // Counters (managed externally, outputs here)
    //==========================================================================
    // Note: s_h_count and s_v_count are typically managed in the parent module
    // This module provides the timing signals based on those counters

    //==========================================================================
    // VSYNC Control
    //==========================================================================
    // Synchronize FSM read index
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst) begin
            FSM_read_index_eim_1d <= 1'b0;
            FSM_read_index_eim_2d <= 1'b0;
            FSM_read_index_eim_3d <= 1'b0;
            FSM_read_index_eim_4d <= 1'b0;
            FSM_read_index_eim_5d <= 1'b0;
        end else begin
            FSM_read_index_eim_1d <= FSM_read_index_eim;
            FSM_read_index_eim_2d <= FSM_read_index_eim_1d;
            FSM_read_index_eim_3d <= FSM_read_index_eim_2d;
            FSM_read_index_eim_4d <= FSM_read_index_eim_3d;
            FSM_read_index_eim_5d <= FSM_read_index_eim_4d;
        end
    end

    // VSYNC high detection
    assign hi_vsync = (FSM_read_index_eim_4d && !FSM_read_index_eim_5d);

    // VSYNC keep high control
    assign up_vsync_keep_hi = rst_hsync_cnt_dly;
    assign down_vsync_keep_hi = sig_vsync && vsync_keep_hi && (vsync_keep_hi_cnt == 4'b1111);

    // VSYNC keep-high flip-flop
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || !tx_eim_rst_n) begin
            vsync_keep_hi <= 1'b0;
        end else begin
            if (down_vsync_keep_hi)
                vsync_keep_hi <= 1'b0;
            else if (up_vsync_keep_hi)
                vsync_keep_hi <= 1'b1;
        end
    end

    // VSYNC keep-high counter
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || !tx_eim_rst_n) begin
            vsync_keep_hi_cnt <= 4'b0000;
        end else begin
            if (!vsync_keep_hi)
                vsync_keep_hi_cnt <= 4'b0000;
            else if (vsync_keep_hi)
                vsync_keep_hi_cnt <= vsync_keep_hi_cnt + 1'b1;
        end
    end

    // Low VSYNC detection
    logic lo_vsync;
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || !tx_eim_rst_n) begin
            lo_vsync <= 1'b0;
        end else begin
            lo_vsync <= down_vsync_keep_hi;
        end
    end

    // VSYNC output
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || !tx_eim_rst_n) begin
            sig_vsync <= 1'b0;
        end else begin
            if (lo_vsync)
                sig_vsync <= 1'b0;
            else if (hi_vsync)
                sig_vsync <= 1'b1;
        end
    end

    //==========================================================================
    // HSYNC Control
    //==========================================================================
    // Generate HSYNC pulses
    genvar i;
    generate
        for (i = 0; i < 6; i = i + 1) begin : hsync_gen
            always_ff @(posedge eim_clk or posedge eim_rst) begin
                if (eim_rst || !tx_eim_rst_n) begin
                    hsync[i] <= 1'b0;
                end else if (lo_hsync) begin
                    hsync[i] <= 1'b0;
                end else if (hi_hsync[i]) begin
                    hsync[i] <= 1'b1;
                end
            end
        end
    endgenerate

    // HSYNC high generation (6 pulses for read_data_start)
    always_comb begin
        for (int j = 0; j < 6; j++) begin
            hi_hsync[j] = read_data_start;
        end
    end

    assign hi_hsync_all = |hi_hsync;
    assign sig_hsync = |hsync;

    // HSYNC keep-high control
    assign up_hsync_keep_hi = 1'b0;  // Placeholder - would be from end_read_mem[11]
    assign down_hsync_keep_hi = sig_hsync && hsync_keep_hi && (hsync_keep_hi_cnt == 4'b0101);

    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || !tx_eim_rst_n) begin
            hsync_keep_hi <= 1'b0;
            hsync_keep_hi_cnt <= 4'h0;
        end else begin
            if (up_hsync_keep_hi) begin
                hsync_keep_hi <= 1'b1;
            end else if (down_hsync_keep_hi) begin
                hsync_keep_hi <= 1'b0;
            end

            if (!hsync_keep_hi) begin
                hsync_keep_hi_cnt <= 4'h0;
            end else begin
                hsync_keep_hi_cnt <= hsync_keep_hi_cnt + 1'b1;
            end
        end
    end

    // Delayed HSYNC signals
    logic sig_hsync_1d, sig_hsync_2d;
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || !tx_eim_rst_n) begin
            sig_hsync_1d <= 1'b0;
            sig_hsync_2d <= 1'b0;
        end else begin
            sig_hsync_1d <= sig_hsync;
            sig_hsync_2d <= sig_hsync_1d;
        end
    end

    // HSYNC counter control
    assign inc_hsync_cnt = !sig_hsync_1d && sig_hsync_2d;
    assign rst_hsync_cnt = (inc_hsync_cnt && hsync_cnt == (dsp_image_height[11:0] - 12'h1)) ? 1'b1 : 1'b0;

    // HSYNC counter
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || !tx_eim_rst_n) begin
            hsync_cnt <= 12'd0;
            rst_hsync_cnt_dly <= 1'b0;
        end else begin
            if (rst_hsync_cnt_dly) begin
                hsync_cnt <= 12'd0;
            end else if (inc_hsync_cnt & sig_vsync) begin
                hsync_cnt <= hsync_cnt + 1'b1;
            end
            rst_hsync_cnt_dly <= rst_hsync_cnt;
        end
    end

    //==========================================================================
    // Low HSYNC detection
    //==========================================================================
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || !tx_eim_rst_n) begin
            lo_hsync <= 1'b0;
        end else begin
            lo_hsync <= down_hsync_keep_hi;
        end
    end

    //==========================================================================
    // Frame Timing Generation
    //==========================================================================
    // TUSER_0 delay line for frame start detection
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || !tx_eim_rst_n) begin
            s_tuser_0_dly <= '0;
        end else begin
            s_tuser_0_dly <= {s_tuser_0_dly[14:0], s_tuser_0};
        end
    end

    // TUSER generation (start of frame)
    assign s_tuser_0 = (sig_vsync && sig_hsync && s_h_count == 16'h0000 && s_v_count == 16'h0000) ? 1'b1 : 1'b0;

    // Frame reset detection
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || !tx_eim_rst_n) begin
            read_frame_start <= 1'b0;
            read_frame_reset <= 1'b0;
        end else begin
            read_frame_start <= s_tuser_0_dly[11];  // Delayed frame start
            read_frame_reset <= hi_vsync;
        end
    end

    //==========================================================================
    // TLAST Generation (AXI-Stream)
    //==========================================================================
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || tx_eim_rst_n) begin
            s_axis_tlast <= 1'b0;
        end else begin
            if (read_axis_tready) begin
                if (s_h_count == (max_h_count - 2)) begin
                    s_axis_tlast <= 1'b1;  // Set last before end of line
                end else if (s_h_count == 16'h0000) begin
                    s_axis_tlast <= 1'b0;  // Reset at start of line
                end
            end
        end
    end

    //==========================================================================
    // Assertions for Verification
    //==========================================================================
    `ifndef SYNTHESIS

    property vsync_during_frame_end;
        @(posedge eim_clk) disable iff (!rst_n_eim)
            hi_vsync |-> ##[1:100] lo_vsync;
    endproperty
    assert property (vsync_during_frame_end)
        else $error("[TIMING_GEN] VSYNC did not complete properly");

    property hsync_pulses_valid;
        @(posedge eim_clk) disable iff (!rst_n_eim)
            sig_hsync |-> ##[1:50] !sig_hsync;
    endproperty
    assert property (hsync_pulses_valid)
        else $error("[TIMING_GEN] HSYNC pulse too long");

    `endif

endmodule
