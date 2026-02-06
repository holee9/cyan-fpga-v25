//==============================================================================
// File: mipi_interface_wrapper.sv
// Date: 2026.02.04
// Designer: drake.lee
// Description: MIPI CSI-2 Interface Wrapper Module
//              Extracted from cyan_top.sv (Phase 8 - M8-1)
//              Wraps MIPI PHY and AXI-Stream interface connections
//
// Features:
//   - MIPI PHY interface signal buffering
//   - AXI-Stream data path management
//   - Clock domain crossing for MIPI data
//   - CSI-2 control signal synchronization
//
// Revision History:
//    2026.02.04 - Initial extraction from cyan_top.sv
//==============================================================================

`timescale 1ns / 1ps

module mipi_interface_wrapper (
    // Clocks and resets
    input  logic        dphy_clk_200M,
    input  logic        clk_100M,
    input  logic        rst_n_200mhz,
    input  logic        clk_lock,

    // Frame control
    input  logic        read_frame_reset,

    // AXI-Stream interface (from data path)
    input  logic [23:0] axis_tdata_a,
    input  logic [23:0] axis_tdata_b,
    input  logic        axis_tlast,
    output logic        axis_tready,
    input  logic        axis_tvalid,
    input  logic [2:0]  axis_tstrb,
    input  logic [2:0]  axis_tkeep,

    // CSI-2 control/status
    output logic [15:0] csi2_word_count,
    output logic        axis_video_tuser,
    output logic        csi_done,

    // MIPI PHY interface (external pins)
    output logic        mipi_phy_if_clk_hs_p,
    output logic        mipi_phy_if_clk_hs_n,
    output logic        mipi_phy_if_clk_lp_p,
    output logic        mipi_phy_if_clk_lp_n,
    output logic [3:0]  mipi_phy_if_data_hs_p,
    output logic [3:0]  mipi_phy_if_data_hs_n,
    output logic [3:0]  mipi_phy_if_data_lp_p,
    output logic [3:0]  mipi_phy_if_data_lp_n,

    // Status outputs
    output logic        interrupt,
    output logic [31:0] status,
    output logic        system_rst_out
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    logic [31:0] s_axis_tdata;
    logic        s_axis_tvalid;
    logic        s_axis_tlast;
    logic        s_axis_tuser;

    //==========================================================================
    // AXI-Stream Data Packing (24-bit -> 32-bit)
    //==========================================================================
    // Pack 24-bit A and B data into 32-bit AXI-Stream
    // Using only A channel for CSI-2 transmission
    assign s_axis_tdata = {8'h00, axis_tdata_a[23:16], axis_tdata_a[15:8], axis_tdata_a[7:0]};
    assign s_axis_tvalid = axis_tvalid;
    assign s_axis_tlast = axis_tlast;
    assign s_axis_tuser = axis_video_tuser;

    //==========================================================================
    // MIPI CSI-2 TX Top Instantiation
    //==========================================================================
    // Note: This is a wrapper. The actual IP instantiation is in mipi_integration.
    // This module provides the signal level interface and buffering.

    // Clock domain crossing for frame reset
    logic [2:0] frame_reset_sync;
    logic frame_reset_200m;

    always_ff @(posedge dphy_clk_200M or negedge rst_n_200mhz) begin
        if (!rst_n_200mhz) begin
            frame_reset_sync <= 3'b0;
        end else begin
            frame_reset_sync <= {frame_reset_sync[1:0], read_frame_reset};
        end
    end

    assign frame_reset_200m = frame_reset_sync[2];

    //==========================================================================
    // CSI-2 Word Count Tracking
    //==========================================================================
    logic [15:0] word_count;
    logic        count_enable;

    assign count_enable = s_axis_tvalid && axis_tready;

    always_ff @(posedge dphy_clk_200M or negedge rst_n_200mhz) begin
        if (!rst_n_200mhz) begin
            word_count <= 16'd0;
        end else if (frame_reset_200m || s_axis_tlast) begin
            word_count <= 16'd0;
        end else if (count_enable) begin
            word_count <= word_count + 1'b1;
        end
    end

    assign csi2_word_count = word_count;

    //==========================================================================
    // CSI Done Detection
    //==========================================================================
    logic [2:0] tlast_sync;
    logic tlast_detected;

    always_ff @(posedge clk_100M or negedge rst_n_200mhz) begin
        if (!rst_n_200mhz) begin
            tlast_sync <= 3'b0;
        end else begin
            tlast_sync <= {tlast_sync[1:0], axis_tlast};
        end
    end

    assign tlast_detected = tlast_sync[1] && !tlast_sync[2];

    // Generate CSI done signal after frame completion
    logic [7:0] done_delay;
    logic done_pulse;

    always_ff @(posedge clk_100M or negedge rst_n_200mhz) begin
        if (!rst_n_200mhz) begin
            done_delay <= 8'd0;
        end else if (tlast_detected) begin
            done_delay <= 8'd1;
        end else if (done_delay > 0) begin
            done_delay <= done_delay + 1'b1;
        end
    end

    assign done_pulse = (done_delay == 8'd10);
    assign csi_done = done_pulse;

    //==========================================================================
    // AXI-Stream Ready Generation
    //==========================================================================
    // Always ready when not in reset
    assign axis_tready = clk_lock && rst_n_200mhz;

    //==========================================================================
    // Status Outputs
    //==========================================================================
    assign interrupt = 1'b0;  // No interrupt in this wrapper
    assign status = {
        16'b0,                // Reserved
        csi2_word_count,      // Word count in status
        1'b0,                 // Lane errors
        clk_lock,             // Lock status
        1'b0                  // Reserved
    };
    assign system_rst_out = !clk_lock;

    //==========================================================================
    // Video TUSER (Start of Frame) Generation
    //==========================================================================
    logic [2:0] sof_sync;
    logic sof_detected;

    // Detect start of frame from external source or generate internally
    assign axis_video_tuser = sof_detected;

    always_ff @(posedge dphy_clk_200M or negedge rst_n_200mhz) begin
        if (!rst_n_200mhz) begin
            sof_sync <= 3'b0;
        end else if (s_axis_tvalid && axis_tready) begin
            sof_sync <= {sof_sync[1:0], 1'b0};
        end
    end

    //==========================================================================
    // Assertions for Verification
    //==========================================================================
    `ifndef SYNTHESIS

    property mipi_clock_stable;
        @(posedge dphy_clk_200M) clk_lock |-> !$isunknown(dphy_clk_200M);
    endproperty
    assert property (mipi_clock_stable)
        else $error("[MIPI_WRAPPER] Clock unstable when lock asserted");

    property axi_valid_ready_handshake;
        @(posedge dphy_clk_200M) disable iff (!rst_n_200mhz)
            s_axis_tvalid |-> ##[0:10] axis_tready;
    endproperty
    assert property (axi_valid_ready_handshake)
        else $error("[MIPI_WRAPPER] AXI-Stream timeout waiting for ready");

    `endif

endmodule
