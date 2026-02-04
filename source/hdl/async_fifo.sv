`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: async_fifo.sv
// Date: 2026-02-04
// Designer: drake.lee
// Description: Universal Asynchronous FIFO with Gray Code CDC
//              (DUP-001: Consolidates async_fifo_1b.sv and async_fifo_24b.sv)
//
// Features:
//   - Parameterized data width (default 24-bit for MIPI)
//   - Parameterized depth (must be power of 2)
//   - Gray code pointer synchronization for safe CDC
//   - MTBF > 100 years with 2-stage synchronizers
//
// Usage:
//   // 24-bit MIPI data FIFO
//   async_fifo #(.DATA_WIDTH(24), .DEPTH(16)) fifo_inst ( ... );
//
//   // 1-bit control signal FIFO
//   async_fifo #(.DATA_WIDTH(1), .DEPTH(4)) fifo_sync_inst ( ... );
//
// Revision History:
//    2026.02.04 - DUP-001: Created universal async FIFO (consolidates async_fifo_1b + async_fifo_24b)
//    2026.02.04 - RST-006: Changed to active-LOW reset for consistency
///////////////////////////////////////////////////////////////////////////////

module async_fifo #(
    parameter int DATA_WIDTH = 24,  // Data width (default 24-bit for MIPI)
    parameter int DEPTH = 16        // FIFO depth (MUST be power of 2)
) (
    // Write clock domain
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,     // Active-LOW write domain reset
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] din,
    output logic                  full,

    // Read clock domain
    input  logic                  rd_clk,
    input  logic                  rd_rst_n,     // Active-LOW read domain reset
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] dout,
    output logic                  empty
);

    localparam int ADDR_W = $clog2(DEPTH);

    //==========================================================================
    // Memory Storage
    //==========================================================================
    (* ram_style = "distributed" *)
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    //==========================================================================
    // Write Domain Pointers (Binary + Gray)
    //==========================================================================
    logic [ADDR_W:0] wr_bin, wr_bin_next;
    logic [ADDR_W:0] wr_gray, wr_gray_next;
    logic [ADDR_W-1:0] wr_addr;

    //==========================================================================
    // Read Domain Pointers (Binary + Gray)
    //==========================================================================
    logic [ADDR_W:0] rd_bin, rd_bin_next;
    logic [ADDR_W:0] rd_gray, rd_gray_next;
    logic [ADDR_W-1:0] rd_addr;

    //==========================================================================
    // Cross-Domain Synchronizers (2-stage for CDC)
    //==========================================================================
    logic [ADDR_W:0] rd_gray_sync_w1, rd_gray_sync_w2;  // rd -> wr domain
    logic [ADDR_W:0] wr_gray_sync_r1, wr_gray_sync_r2;  // wr -> rd domain

    //==========================================================================
    // Read Data Register
    //==========================================================================
    logic [DATA_WIDTH-1:0] dout_reg;

    //==========================================================================
    // Binary to Gray Code Converter
    //==========================================================================
    function automatic logic [ADDR_W:0] bin2gray(input logic [ADDR_W:0] b);
        bin2gray = b ^ (b >> 1);
    endfunction

    //==========================================================================
    // Write Side Logic
    //==========================================================================

    // Next write pointer calculation
    always_comb begin
        wr_bin_next  = wr_bin + ((wr_en && !full) ? 1 : 0);
        wr_gray_next = bin2gray(wr_bin_next);
    end

    assign wr_addr = wr_bin[ADDR_W-1:0];

    // Write pointer update with Gray code synchronization
    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin        <= '0;
            wr_gray       <= '0;
            rd_gray_sync_w1 <= '0;
            rd_gray_sync_w2 <= '0;
        end else begin
            // 2-stage synchronizer for read gray pointer -> write domain
            rd_gray_sync_w1 <= rd_gray;
            rd_gray_sync_w2 <= rd_gray_sync_w1;

            // Update write pointers
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end
    end

    // Write to memory (no reset needed for RAM content)
    always_ff @(posedge wr_clk) begin
        if (wr_en && !full) mem[wr_addr] <= din;
    end

    // Full detection (compare with inverted MSBs of synchronized read pointer)
    logic [ADDR_W:0] rd_gray_invmsb;
    assign rd_gray_invmsb = {~rd_gray_sync_w2[ADDR_W], ~rd_gray_sync_w2[ADDR_W-1], rd_gray_sync_w2[ADDR_W-2:0]};
    assign full = (wr_gray_next == rd_gray_invmsb);

    //==========================================================================
    // Read Side Logic
    //==========================================================================

    // Next read pointer calculation
    always_comb begin
        rd_bin_next  = rd_bin + ((rd_en && !empty) ? 1 : 0);
        rd_gray_next = bin2gray(rd_bin_next);
    end

    assign rd_addr = rd_bin[ADDR_W-1:0];

    // Read pointer update with Gray code synchronization
    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin         <= '0;
            rd_gray        <= '0;
            wr_gray_sync_r1 <= '0;
            wr_gray_sync_r2 <= '0;
            dout_reg       <= '0;
        end else begin
            // 2-stage synchronizer for write gray pointer -> read domain
            wr_gray_sync_r1 <= wr_gray;
            wr_gray_sync_r2 <= wr_gray_sync_r1;

            // Update read pointers
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;

            // Read data (registered output)
            if (rd_en && !empty) dout_reg <= mem[rd_addr];
        end
    end

    // Empty detection (in read domain)
    assign empty = (rd_gray == wr_gray_sync_r2);
    assign dout  = dout_reg;

endmodule
