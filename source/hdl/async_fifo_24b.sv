`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: async_fifo_24b.sv
// Date: 2025-02-03
// Designer: drake.lee
// Description: Async FIFO for 24-bit MIPI data (CDC-003 fix)
// Revision History:
//    2025.02.03 - Initial implementation based on async_fifo_1b.sv
//
// Purpose:
//   - Safe CDC for 24-bit MIPI data crossing clock domains
//   - Gray code pointer synchronization for MTBF > 100 years
//   - Based on proven async_fifo_1b.sv pattern (reference implementation)
///////////////////////////////////////////////////////////////////////////////

module async_fifo_24b #(
    parameter int DEPTH = 16   // MUST be a power of two
) (
    // Write clock domain (ROIC data @ 200MHz or variable)
    input  logic             wr_clk,
    input  logic             wr_rst,
    input  logic             wr_en,
    input  logic [23:0]      din,
    output logic             full,

    // Read clock domain (EIM @ 100MHz)
    input  logic             rd_clk,
    input  logic             rd_rst,
    input  logic             rd_en,
    output logic [23:0]      dout,
    output logic             empty
);

    localparam int ADDR_W = $clog2(DEPTH);

    // Memory storage
    logic [23:0] mem [0:DEPTH-1];

    // Write domain pointers (binary + gray)
    logic [ADDR_W:0] wr_bin, wr_bin_next;
    logic [ADDR_W:0] wr_gray, wr_gray_next;
    logic [ADDR_W-1:0] wr_addr;

    // Read domain pointers (binary + gray)
    logic [ADDR_W:0] rd_bin, rd_bin_next;
    logic [ADDR_W:0] rd_gray, rd_gray_next;
    logic [ADDR_W-1:0] rd_addr;

    // Synchronizers for cross-domain pointer transfer
    logic [ADDR_W:0] rd_gray_sync_w1, rd_gray_sync_w2; // rd -> wr
    logic [ADDR_W:0] wr_gray_sync_r1, wr_gray_sync_r2; // wr -> rd

    // Read data register
    logic [23:0] dout_reg;

    // Binary to Gray code converter
    function automatic logic [ADDR_W:0] bin2gray(input logic [ADDR_W:0] b);
        bin2gray = b ^ (b >> 1);
    endfunction

    /////////////////////////////////////////////////////////////////////
    // Write Side
    /////////////////////////////////////////////////////////////////////
    always_comb begin
        wr_bin_next  = wr_bin + ((wr_en && !full) ? 1 : 0);
        wr_gray_next = bin2gray(wr_bin_next);
    end

    assign wr_addr = wr_bin[ADDR_W-1:0];

    // Synchronize read pointer into write domain and update write pointer
    always_ff @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_bin        <= '0;
            wr_gray       <= '0;
            rd_gray_sync_w1 <= '0;
            rd_gray_sync_w2 <= '0;
        end else begin
            // 2-stage synchronizer for rd_gray -> wr domain
            rd_gray_sync_w1 <= rd_gray;
            rd_gray_sync_w2 <= rd_gray_sync_w1;

            // Update write pointers
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end
    end

    // Write to memory on write clock
    always_ff @(posedge wr_clk) begin
        if (!wr_rst) begin
            if (wr_en && !full) mem[wr_addr] <= din;
        end
    end

    // Full detection
    logic [ADDR_W:0] rd_gray_invmsb;
    assign rd_gray_invmsb = {~rd_gray_sync_w2[ADDR_W], ~rd_gray_sync_w2[ADDR_W-1], rd_gray_sync_w2[ADDR_W-2:0]};
    assign full = (wr_gray_next == rd_gray_invmsb);

    /////////////////////////////////////////////////////////////////////
    // Read Side
    /////////////////////////////////////////////////////////////////////
    always_comb begin
        rd_bin_next  = rd_bin + ((rd_en && !empty) ? 1 : 0);
        rd_gray_next = bin2gray(rd_bin_next);
    end

    assign rd_addr = rd_bin[ADDR_W-1:0];

    // Synchronize write pointer into read domain and update read pointer + dout
    always_ff @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_bin         <= '0;
            rd_gray        <= '0;
            wr_gray_sync_r1 <= '0;
            wr_gray_sync_r2 <= '0;
            dout_reg       <= '0;
        end else begin
            // 2-stage synchronizer for wr_gray -> rd domain
            wr_gray_sync_r1 <= wr_gray;
            wr_gray_sync_r2 <= wr_gray_sync_r1;

            // Update read pointers
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;

            // Read data (registered)
            if (rd_en && !empty) dout_reg <= mem[rd_addr];
        end
    end

    // Empty detection (in read domain)
    assign empty = (rd_gray == wr_gray_sync_r2);
    assign dout  = dout_reg;

endmodule
