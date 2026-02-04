`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: control_signal_mux.sv
// Date: 2026-02-03
// Designer: drake.lee
// Description: Control Signal Multiplexer Module - Extracted from cyan_top.sv
//              (Week 8 - M8-1)
//
// This module encapsulates:
//  1. Control signal multiplexing between register and FSM sources
//  2. Reset-based signal synchronization (active-LOW reset)
//  3. TI ROIC control signal routing
//
// The mux selects between:
//  - Register-controlled signals (from reg_map_integration)
//  - FSM-controlled signals (from sequencer via sync_processing)
//  - TI ROIC integration outputs
//
// Revision History:
//    2026.02.03 - Initial extraction from cyan_top.sv (Week 8 - M8-1)
//    2026.02.03 - Converted reset from active-HIGH to active-LOW (rst_n_20mhz)
//
///////////////////////////////////////////////////////////////////////////////

module control_signal_mux (
    // Clock and Reset
    input  logic        clk_20mhz,
    input  logic        rst_n_20mhz,          // Active-LOW reset

    // TI ROIC Integration Outputs (pass-through/registered)
    input  logic        ti_roic_sync_out,     // From ti_roic_integration

    // Register-based Control Inputs (from reg_map_integration)
    input  logic        reg_tp_sel,           // Register-controlled TP select
    input  logic        reg_roic_sync,        // Register-controlled ROIC sync

    // FSM-based Control Inputs (from sequencer via sync_processing)
    input  logic        fsm_wait_tp_sel,      // FSM-controlled TP select
    input  logic        fsm_wait_roic_sync,   // FSM-controlled ROIC sync

    // Final Control Outputs (to TI ROIC Integration)
    output logic        roic_sync_in,         // Sync input to ti_roic_integration
    output logic        roic_tp_sel,          // TP select to ti_roic_integration

    // Final Control Outputs (to Top-Level ROIC Interface)
    output logic        ti_roic_sync,         // Top-level ROIC_SYNC output
    output logic        ti_roic_tp_sel        // Top-level ROIC_TP_SEL output
);

    //==========================================================================
    // Control Signal Multiplexing
    //==========================================================================
    // Mux between register-controlled and FSM-controlled signals
    // Priority: OR combination allows either source to enable the signal

    always_ff @(posedge clk_20mhz or negedge rst_n_20mhz) begin
        if (!rst_n_20mhz) begin
            // Reset state: all control signals inactive
            ti_roic_sync   <= 1'b0;
            ti_roic_tp_sel <= 1'b0;
            roic_tp_sel    <= 1'b0;
            roic_sync_in   <= 1'b0;
        end else begin
            // Normal operation: mux between sources
            // - TI ROIC sync passes through from integration module
            // - TP select: register OR FSM wait condition
            // - ROIC sync: register OR FSM wait condition

            ti_roic_sync   <= ti_roic_sync_out;
            ti_roic_tp_sel <= reg_tp_sel | fsm_wait_tp_sel;
            roic_tp_sel    <= reg_tp_sel | fsm_wait_tp_sel;
            roic_sync_in   <= reg_roic_sync | fsm_wait_roic_sync;
        end
    end

endmodule
