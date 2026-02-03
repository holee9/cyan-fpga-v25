///////////////////////////////////////////////////////////////////////////////
// File: clock_gen_top.sv
// Date: 2025-02-03
// Designer: drake.lee
// Description: Clock generation and reset synchronization module
//              Extracted from cyan_top.sv (Week 4: TOP-001)
// Revision History:
//    2025.02.03 - Initial (extracted from cyan_top.sv)
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module clock_gen_top (
    // System inputs
    input  logic        nRST,
    input  logic        MCLK_50M_p,
    input  logic        MCLK_50M_n,

    // Clock outputs
    output logic        s_clk_100mhz,
    output logic        s_dphy_clk_200M,
    output logic        s_clk_20mhz,
    output logic        eim_clk,

    // Reset outputs (active-LOW)
    output logic        rst_n_20mhz,
    output logic        rst_n_100mhz,
    output logic        rst_n_200mhz,
    output logic        rst_n_eim,

    // Status outputs
    output logic        s_clk_lock
);

    ///////////////////////////////////////////////////////////////////////////////
    // Week 2: Reset Synchronization (RST-001 Fix)
    ///////////////////////////////////////////////////////////////////////////////
    
    // 20MHz domain reset synchronizer
    reset_sync reset_sync_20mhz (
        .clk    (s_clk_20mhz),
        .nRST   (nRST),
        .rst_n  (rst_n_20mhz)
    );

    // 100MHz domain reset synchronizer
    reset_sync reset_sync_100mhz (
        .clk    (s_clk_100mhz),
        .nRST   (nRST),
        .rst_n  (rst_n_100mhz)
    );

    // 200MHz domain reset synchronizer
    reset_sync reset_sync_200mhz (
        .clk    (s_dphy_clk_200M),
        .nRST   (nRST),
        .rst_n  (rst_n_200mhz)
    );

    // EIM clock domain reset (uses 100MHz)
    assign rst_n_eim = rst_n_100mhz;

    ///////////////////////////////////////////////////////////////////////////////
    // Clock Generation
    ///////////////////////////////////////////////////////////////////////////////

    // clk_ctrl module instantiation
    clk_ctrl clk_inst0 (
        .reset          (1'b0),
        .clk_in1_p      (MCLK_50M_p),
        .clk_in1_n      (MCLK_50M_n),
        .locked         (s_clk_lock),
        .dphy_clk       (s_dphy_clk_200M),  // 200MHz
        .c0             (s_clk_100mhz),     // 100MHz
        .c1             (s_clk_20mhz)       // 25MHz
    );

    // EIM clock assignment (use 100MHz)
    assign eim_clk = s_clk_100mhz;

endmodule
