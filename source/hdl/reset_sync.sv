`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: reset_sync.sv
// Date: 2025-02-03
// Designer: drake.lee
// Description: Reset Synchronizer (Async Assert, Sync Deassert)
// Revision History:
//    2025.02.03 - Initial implementation for RST-001 fix
//
// Purpose:
//   - Convert asynchronous reset to synchronous reset
//   - Async assertion: reset takes effect immediately
//   - Sync deassertion: reset releases cleanly (no glitches)
//   - Prevents metastability on reset release
//
// Usage:
//   - Place in each clock domain
//   - Feed async reset (nRST) to all domains through this module
//   - Output is a clean synchronous reset for that domain
///////////////////////////////////////////////////////////////////////////////

module reset_sync (
    input  logic clk,      // Destination clock
    input  logic nRST,     // Async reset (active LOW)
    output logic rst_n     // Sync reset (active LOW)
);

    /////////////////////////////////////////////////////////////////////
    // Internal Signals
    /////////////////////////////////////////////////////////////////////
    logic [2:0] reset_sync_chain;

    /////////////////////////////////////////////////////////////////////
    // Reset Synchronizer Chain
    /////////////////////////////////////////////////////////////////////
    // Async assertion, synchronous deassertion
    always_ff @(posedge clk or negedge nRST) begin
        if (!nRST) begin
            // Async assertion - immediate reset
            reset_sync_chain <= 3'b000;
        end else begin
            // Sync deassertion - release cleanly
            reset_sync_chain <= {reset_sync_chain[1:0], 1'b1};
        end
    end

    /////////////////////////////////////////////////////////////////////
    // Output Assignment
    /////////////////////////////////////////////////////////////////////
    assign rst_n = reset_sync_chain[2];

endmodule
