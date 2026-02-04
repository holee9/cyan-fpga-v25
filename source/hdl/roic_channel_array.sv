`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: roic_channel_array.sv
// Date: 2026.02.03
// Designer: drake.lee
// Description: TI ROIC 12-Channel Array Module
//              - Instantiates 12 ti_roic_top modules for parallel ROIC channel processing
//              - LVDS differential input interfaces for each channel
//              - Bit alignment and data reordering control
//              - Channel detection and valid read enable outputs
//              - Extracted from cyan_top.sv (Week 7 - M7-2)

// Port Summary:
//   Clocks:      fclk_in_p/n[11:0], clk_in_p/n[11:0], data_read_clk
//   Data:        data_in_p/n[11:0]
//   Control:     deser_reset_n, align_to_fclk, align_start, extra_shift[11:0]
//                en_test_pattern_col/row, sync, data_read_req[11:0]
//   Outputs:     shift_out[11:0], align_done[11:0], valid_read_enable[11:0]
//                reordered_data_a/b[11:0][23:0], reordered_valid[11:0]
//                even_odd_toggle_out[11:0], roic_even_odd_out[11:0]
//                detected_data_out[11:0][23:0], channel_detected[11:0]

// Revision History:
//    2026.02.04 - RST-005 fix: Changed deser_reset to deser_reset_n (active-LOW)
//    2026.02.03 - Initial extraction from cyan_top.sv

///////////////////////////////////////////////////////////////////////////////


module roic_channel_array (
    //==========================================================================
    // Clock and Reset Inputs
    //==========================================================================
    input  logic        deser_reset_n,         // Data path reset (active-LOW, RST-005 fix)
    input  logic        data_read_clk,         // 200MHz data read clock

    //==========================================================================
    // LVDS Differential Clock Inputs (12 channels)
    //==========================================================================
    input  logic [11:0] fclk_in_p,             // Frame clock LVDS positive
    input  logic [11:0] fclk_in_n,             // Frame clock LVDS negative
    input  logic [11:0] clk_in_p,              // Data clock LVDS positive
    input  logic [11:0] clk_in_n,              // Data clock LVDS negative

    //==========================================================================
    // LVDS Differential Data Inputs (12 channels)
    //==========================================================================
    input  logic [11:0] data_in_p,             // Data LVDS positive
    input  logic [11:0] data_in_n,             // Data LVDS negative

    //==========================================================================
    // Bit Alignment Control
    //==========================================================================
    input  logic        align_to_fclk,         // Select mode: 0=pattern, 1=manual
    input  logic        align_start,           // Start alignment process
    input  logic [4:0]  extra_shift [11:0],    // Additional bit shift per channel

    //==========================================================================
    // Test Pattern Control
    //==========================================================================
    input  logic        en_test_pattern_col,   // Enable test pattern column
    input  logic        en_test_pattern_row,   // Enable test pattern row

    //==========================================================================
    // Data Reordering Control
    //==========================================================================
    input  logic        sync,                  // Sync signal for data reordering

    //==========================================================================
    // Data Read Control
    //==========================================================================
    input  logic [11:0] data_read_req,         // Data read request per channel

    //==========================================================================
    // Bit Alignment Outputs
    //==========================================================================
    output logic [4:0]  shift_out [11:0],      // Selected shift amount per channel
    output logic [11:0] align_done,            // Alignment completion flag

    //==========================================================================
    // Data Read Enable Outputs
    //==========================================================================
    output logic [11:0] valid_read_enable,     // Enable signal for reading reordered data

    //==========================================================================
    // Reordered Data Outputs (12 channels x 24 bits)
    //==========================================================================
    output logic [23:0] reordered_data_a [11:0],  // Reordered data A output
    output logic [23:0] reordered_data_b [11:0],  // Reordered data B output
    output logic [11:0] reordered_valid,          // Reordered data valid flag

    //==========================================================================
    // Debug Outputs
    //==========================================================================
    output logic [11:0] even_odd_toggle_out,  // Even/odd toggle output
    output logic [11:0] roic_even_odd_out,    // ROIC even/odd output

    //==========================================================================
    // Channel Detection Outputs
    //==========================================================================
    output logic [23:0] detected_data_out [11:0], // Data at first channel detection
    output logic [11:0] channel_detected          // First channel detection flag
);

    //==========================================================================
    // Module Parameters
    //==========================================================================
    localparam int DATA_WIDTH    = 24;          // 24-bit data word width
    localparam string IOSTANDARD = "LVDS_25";   // LVDS I/O standard
    localparam real REFCLK_FREQ  = 200.0;       // 200MHz reference clock
    localparam logic [23:0] PATTERN_1 = 24'hFFF000;  // First alignment pattern
    localparam logic [23:0] PATTERN_2 = 24'hFF0000;  // Second alignment pattern

    //==========================================================================
    // TI ROIC 12-Channel Generate Block
    //==========================================================================
    // Each channel processes LVDS inputs from one ROIC sensor
    // - Deserializes LVDS data and clock inputs
    // - Performs bit alignment using pattern detection or manual shift
    // - Reorders data based on sync signal timing
    // - Outputs validated, aligned data for readout


    genvar i;
    generate
        for (i = 0; i < 12; i++) begin : gen_ti_roic_channel
            ti_roic_top #(
                .DATA_WIDTH    (DATA_WIDTH),      // 24-bit data width
                .IOSTANDARD    (IOSTANDARD),      // LVDS_25 standard
                .REFCLK_FREQ   (REFCLK_FREQ),     // 200MHz reference clock
                .PATTERN_1     (PATTERN_1),       // First alignment pattern
                .PATTERN_2     (PATTERN_2)        // Second alignment pattern
            ) ti_roic_top_inst (
                //==============================================================
                // Control and Reset Inputs
                //==============================================================
                .clk_reset_n        (deser_reset_n),     // RST-007: active-LOW
                .data_reset_n       (deser_reset_n),     // RST-007: active-LOW

                //==============================================================
                // LVDS Differential Clock Inputs
                //==============================================================
                .fclk_in_p          (fclk_in_p[i]),    // Frame clock positive
                .fclk_in_n          (fclk_in_n[i]),    // Frame clock negative
                .clk_in_p           (clk_in_p[i]),     // Data clock positive
                .clk_in_n           (clk_in_n[i]),     // Data clock negative

                //==============================================================
                // LVDS Differential Data Inputs
                //==============================================================
                .data_in_p          (data_in_p[i]),    // Data positive
                .data_in_n          (data_in_n[i]),    // Data negative

                //==============================================================
                // Bit Alignment Control
                //==============================================================
                .align_to_fclk      (align_to_fclk),   // Alignment mode select
                .align_start        (align_start),     // Start alignment
                .extra_shift        (extra_shift[i]),  // Additional shift

                //==============================================================
                // Test Pattern Control
                //==============================================================
                .en_test_pattern_col(en_test_pattern_col), // Column pattern
                .en_test_pattern_row(en_test_pattern_row), // Row pattern

                //==============================================================
                // Data Reordering Control
                //==============================================================
                .sync               (sync),            // Sync for reordering

                //==============================================================
                // Data Read Control
                //==============================================================
                .data_read_req      (data_read_req[i]),// Read request
                .data_read_clk      (data_read_clk),   // 200MHz read clock

                //==============================================================
                // Debug Outputs
                //==============================================================
                .even_odd_toggle_out(even_odd_toggle_out[i]), // Toggle output
                .roic_even_odd_out  (roic_even_odd_out[i]),   // ROIC even/odd

                //==============================================================
                // Bit Alignment Outputs
                //==============================================================
                .shift_out          (shift_out[i]),    // Shift amount
                .align_done         (align_done[i]),   // Alignment complete

                //==============================================================
                // Data Read Enable Outputs
                //==============================================================
                .valid_read_enable  (valid_read_enable[i]), // Read enable

                //==============================================================
                // Reordered Data Outputs
                //==============================================================
                .reordered_data_a   (reordered_data_a[i]),  // Data A
                .reordered_data_b   (reordered_data_b[i]),  // Data B
                .reordered_valid    (reordered_valid[i]),   // Data valid

                //==============================================================
                // Channel Detection Outputs
                //==============================================================
                .detected_data_out  (detected_data_out[i]), // Detected data
                .channel_detected   (channel_detected[i])   // Detection flag
            );
        end
    endgenerate

endmodule
