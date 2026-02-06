//==============================================================================
// File: async_fifo_controller.sv
// Date: 2026.02.04
// Designer: drake.lee
// Description: Async FIFO Controller Module (CDC-003 Fix)
//              Extracted from read_data_mux.sv (Phase 8 - M8-4)
//              Handles clock domain crossing for eim_clk -> sys_clk data path
//
// Features:
//   - Dual async FIFO for 24-bit A/B data channels
//   - CDC (Clock Domain Crossing) from eim_clk to sys_clk
//   - Full/empty flag management
//   - Data valid synchronization
//
// Revision History:
//    2026.02.04 - Initial extraction from read_data_mux.sv
//==============================================================================

`timescale 1ns / 1ps

module async_fifo_controller (
    // Write clock domain (eim_clk)
    input  logic        eim_clk,
    input  logic        rst_n_eim,

    // Read clock domain (sys_clk)
    input  logic        sys_clk,
    input  logic        sys_rst,

    // Data inputs (eim_clk domain)
    input  logic [23:0] s_read_data_a_eim,
    input  logic [23:0] s_read_data_b_eim,
    input  logic        s_read_data_valid_eim,

    // Control signals
    input  logic        read_axis_tready,

    // Data outputs (sys_clk domain)
    output logic [23:0] s_read_data_a_sys,
    output logic [23:0] s_read_data_b_sys,
    output logic        s_read_data_valid_sys,

    // Status flags
    output logic        s_fifo_full,
    output logic        s_fifo_empty
);

    //==========================================================================
    // Parameters
    //==========================================================================
    localparam int DATA_WIDTH = 24;
    localparam int DEPTH      = 16;

    //==========================================================================
    // Internal Signals
    //==========================================================================
    logic s_fifo_wr_en;
    logic s_fifo_rd_en;

    //==========================================================================
    // FIFO Write Enable Generation
    //==========================================================================
    // Write when data is valid and FIFO is not full
    assign s_fifo_wr_en = s_read_data_valid_eim && !s_fifo_full;

    //==========================================================================
    // FIFO Read Enable Generation
    //==========================================================================
    // Read when downstream is ready and FIFO is not empty
    assign s_fifo_rd_en = read_axis_tready && !s_fifo_empty;

    //==========================================================================
    // Async FIFO for Data Channel A (24-bit)
    //==========================================================================
    // Using universal async_fifo module
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_data_a_inst (
        // Write clock domain (eim_clk)
        .wr_clk    (eim_clk),
        .wr_rst_n  (rst_n_eim),
        .wr_en     (s_fifo_wr_en),
        .din       (s_read_data_a_eim),
        .full      (s_fifo_full),

        // Read clock domain (sys_clk)
        .rd_clk    (sys_clk),
        .rd_rst_n  (sys_rst),
        .rd_en     (s_fifo_rd_en),
        .dout      (s_read_data_a_sys),
        .empty     (s_fifo_empty)
    );

    //==========================================================================
    // Async FIFO for Data Channel B (24-bit)
    //==========================================================================
    // Using universal async_fifo module
    // Shares full/empty with channel A (synchronous operation)
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) fifo_data_b_inst (
        // Write clock domain (eim_clk)
        .wr_clk    (eim_clk),
        .wr_rst_n  (rst_n_eim),
        .wr_en     (s_fifo_wr_en),
        .din       (s_read_data_b_eim),
        .full      (),  // Unused (share with fifo_a)

        // Read clock domain (sys_clk)
        .rd_clk    (sys_clk),
        .rd_rst_n  (sys_rst),
        .rd_en     (s_fifo_rd_en),
        .dout      (s_read_data_b_sys),
        .empty     ()   // Unused (share with fifo_a)
    );

    //==========================================================================
    // Data Valid Synchronization
    //==========================================================================
    // Synchronize data valid flag to read clock domain
    logic [2:0] valid_sync;

    always_ff @(posedge sys_clk or negedge sys_rst) begin
        if (!sys_rst) begin
            valid_sync <= 3'b0;
        end else begin
            // Pipe data valid through FIFO
            valid_sync <= {valid_sync[1:0], !s_fifo_empty && s_fifo_rd_en};
        end
    end

    assign s_read_data_valid_sys = valid_sync[2];

    //==========================================================================
    // CDC Monitoring
    //==========================================================================
    // Count FIFO depth for monitoring
    logic [3:0] fifo_depth;
    logic        fifo_depth_inc;
    logic        fifo_depth_dec;

    assign fifo_depth_inc = s_fifo_wr_en && !s_fifo_rd_en;
    assign fifo_depth_dec = !s_fifo_wr_en && s_fifo_rd_en;

    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!rst_n_eim) begin
            fifo_depth <= 4'b0;
        end else begin
            if (fifo_depth_inc && !fifo_depth_dec) begin
                fifo_depth <= fifo_depth + 1'b1;
            end else if (!fifo_depth_inc && fifo_depth_dec) begin
                fifo_depth <= fifo_depth - 1'b1;
            end
        end
    end

    //==========================================================================
    // Assertions for Verification (CDC-003)
    //==========================================================================
    `ifndef SYNTHESIS

    property fifo_write_when_ready;
        @(posedge eim_clk) disable iff (!rst_n_eim)
            s_fifo_wr_en |-> !s_fifo_full;
    endproperty
    assert property (fifo_write_when_ready)
        else $error("[FIFO_CTRL] Write while FIFO full!");

    property fifo_read_when_data;
        @(posedge sys_clk) disable iff (!sys_rst)
            s_fifo_rd_en |-> !s_fifo_empty;
    endproperty
    assert property (fifo_read_when_data)
        else $error("[FIFO_CTRL] Read while FIFO empty!");

    property no_data_loss;
        @(posedge eim_clk) disable iff (!rst_n_eim)
            not (s_read_data_valid_eim && s_fifo_full);
    endproperty
    assert property (no_data_loss)
        else $error("[FIFO_CTRL] Data loss - FIFO full!");

    // CDC path delay check
    covergroup fifo_cg @(posedge sys_clk);
        cp_depth: coverpoint fifo_depth {
            bins empty = {0};
            bins low = {1, 2, 3};
            bins mid = {4, 5, 6, 7};
            bins high = {8, 9, 10, 11};
            bins full = {12, 13, 14, 15};
        }
    endgroup

    fifo_cg fifo_cov = new();

    `endif

endmodule
