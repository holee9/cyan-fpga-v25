`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: cdc_sync_3ff.sv
// Date: 2025-02-03
// Designer: drake.lee
// Description: 3-Flip-Flop Synchronizer for CDC (Clock Domain Crossing)
// Revision History:
//    2025.02.03 - Initial implementation for CDC-001 fix
//
// Purpose:
//   - 3-stage synchronizer for safe clock domain crossing
//   - Prevents metastability with 3 FF synchronization chain
//   - Suitable for crossing from slow to fast clock domains
//   - Supports active-LOW or active-HIGH reset
//
// Usage:
//   - Use for single-bit signal CDC
//   - Dest clock should be >= 2x source clock frequency
//   - For multi-bit signals, use async_fifo or handshaking
///////////////////////////////////////////////////////////////////////////////

module cdc_sync_3ff #(
    parameter int WIDTH       = 1,      // Signal width
    parameter bit RESET_VAL  = 1'b0,   // Reset value (0 or 1)
    parameter bit ACTIVE_LOW = 1'b0    // Reset polarity (1=active LOW)
) (
    input  logic                src_clk,   // Source clock
    input  logic                dst_clk,   // Destination clock
    input  logic                rst,       // Reset (active HIGH unless ACTIVE_LOW=1)
    input  logic [WIDTH-1:0]    din,       // Async input
    output logic [WIDTH-1:0]    dout       // Synchronized output
);

    /////////////////////////////////////////////////////////////////////
    // Internal Signals
    /////////////////////////////////////////////////////////////////////
    logic [WIDTH-1:0] sync_stage1;
    logic [WIDTH-1:0] sync_stage2;
    logic [WIDTH-1:0] sync_stage3;
    logic rst_n;

    /////////////////////////////////////////////////////////////////////
    // Reset Signal Generation
    /////////////////////////////////////////////////////////////////////
    generate
        if (ACTIVE_LOW) begin
            // Active-LOW reset (external nRST)
            assign rst_n = rst;
        end else begin
            // Active-HIGH reset (internal reset)
            assign rst_n = ~rst;
        end
    endgenerate

    /////////////////////////////////////////////////////////////////////
    // 3-Stage Synchronizer Chain
    /////////////////////////////////////////////////////////////////////
    // Stage 1: First FF in destination domain
    always_ff @(posedge dst_clk or negedge rst_n) begin
        if (~rst_n) begin
            sync_stage1 <= {WIDTH{RESET_VAL}};
        end else begin
            sync_stage1 <= din;
        end
    end

    // Stage 2: Second FF (metastability settling)
    always_ff @(posedge dst_clk or negedge rst_n) begin
        if (~rst_n) begin
            sync_stage2 <= {WIDTH{RESET_VAL}};
        end else begin
            sync_stage2 <= sync_stage1;
        end
    end

    // Stage 3: Third FF (guaranteed stable output)
    always_ff @(posedge dst_clk or negedge rst_n) begin
        if (~rst_n) begin
            sync_stage3 <= {WIDTH{RESET_VAL}};
        end else begin
            sync_stage3 <= sync_stage2;
        end
    end

    /////////////////////////////////////////////////////////////////////
    // Output Assignment
    /////////////////////////////////////////////////////////////////////
    assign dout = sync_stage3;

endmodule
