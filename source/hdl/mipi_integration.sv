`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: mipi_integration.sv
// Date: 2026-02-03
// Designer: drake.lee
// Description: MIPI CSI-2 TX Integration Module
//              - Encapsulates MIPI CSI-2 TX top and related AXI stream processing
//              - Extracted from cyan_top.sv (Week 5 - TOP-001 Phase 2)
// Revision History:
//    2026.02.03 - Initial extraction from cyan_top.sv
///////////////////////////////////////////////////////////////////////////////

module mipi_integration (
    // Clocks and resets
    input  logic        dphy_clk_200M,
    input  logic        clk_100M,
    input  logic        eim_clk,
    input  logic        rst_n_200mhz,
    input  logic        clk_lock,
    
    // Frame control
    input  logic        read_frame_reset,
    
    // AXI-Stream input (from read_data_mux)
    input  logic [23:0]  axis_tdata_a,
    input  logic [23:0]  axis_tdata_b,
    input  logic        axis_tlast,
    output logic        axis_tready,
    input  logic        axis_tvalid,
    input  logic [2:0]   axis_tstrb,
    input  logic [2:0]   axis_tkeep,
    
    // CSI-2 control/status
    output logic [15:0]  csi2_word_count,
    output logic        axis_video_tuser,
    output logic        csi_done,
    
    // MIPI PHY interface
    output logic        mipi_phy_if_clk_hs_p,
    output logic        mipi_phy_if_clk_hs_n,
    output logic        mipi_phy_if_clk_lp_p,
    output logic        mipi_phy_if_clk_lp_n,
    output logic [3:0]  mipi_phy_if_data_hs_p,
    output logic [3:0]  mipi_phy_if_data_hs_n,
    output logic [3:0]  mipi_phy_if_data_lp_p,
    output logic [3:0]  mipi_phy_if_data_lp_n,
    
    // Unused/status
    output logic        interrupt,
    output logic [31:0]  status,
    output logic        system_rst_out
);

    ///////////////////////////////////////////////////////////////////////////////
    // MIPI CSI-2 TX Subsystem Instantiation
    ///////////////////////////////////////////////////////////////////////////////
    
    mipi_csi2_tx_top inst_mipi_csi2_tx (
        .reset                  (~rst_n_200mhz),
        .dphy_clk_200M          (dphy_clk_200M),
        .clk_100M               (clk_100M),
        .eim_clk                (eim_clk),
        .locked_i               (clk_lock),
        .read_frame_reset       (read_frame_reset),
        .s_axis_tdata_a         (axis_tdata_a),
        .s_axis_tdata_b         (axis_tdata_b),
        .s_axis_tlast           (axis_tlast),
        .s_axis_tready          (axis_tready),
        .s_axis_tvalid          (axis_tvalid),
        .s_axis_tstrb           (axis_tstrb),
        .s_axis_tkeep           (axis_tkeep),
        .mipi_phy_if_clk_hs_p   (mipi_phy_if_clk_hs_p),
        .mipi_phy_if_clk_hs_n   (mipi_phy_if_clk_hs_n),
        .mipi_phy_if_clk_lp_p   (mipi_phy_if_clk_lp_p),
        .mipi_phy_if_clk_lp_n   (mipi_phy_if_clk_lp_n),
        .mipi_phy_if_data_hs_p  (mipi_phy_if_data_hs_p),
        .mipi_phy_if_data_hs_n  (mipi_phy_if_data_hs_n),
        .mipi_phy_if_data_lp_p  (mipi_phy_if_data_lp_p),
        .mipi_phy_if_data_lp_n  (mipi_phy_if_data_lp_n),
        .csi2_word_count        (csi2_word_count),
        .m_axis_video_tuser     (axis_video_tuser),
        .done                   (csi_done),
        .interrupt              (interrupt),
        .status                 (status),
        .system_rst_out         (system_rst_out)
    );

endmodule
