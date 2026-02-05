//==============================================================================
// File: data_path_selector.sv
// Date: 2026.02.04
// Designer: drake.lee
// Description: Data Path Selector Module
//              Extracted from read_data_mux.sv (Phase 8 - M8-5)
//              12-channel data multiplexer for ROIC read data
//
// Features:
//   - 12-channel ROIC data selection
//   - Test pattern generation support
//   - Memory read flag processing
//   - Data valid output generation
//
// Revision History:
//    2026.02.04 - Initial extraction from read_data_mux.sv
//==============================================================================

`timescale 1ns / 1ps

module data_path_selector (
    // Clock and reset
    input  logic        eim_clk,
    input  logic        eim_rst,
    input  logic        tx_eim_rst_n,

    // Channel selection
    input  logic [11:0] read_mem,
    input  logic [11:0] read_mem_2d,

    // ROIC data inputs (12 channels)
    input  logic [23:0] roic_read_data_a [11:0],
    input  logic [23:0] roic_read_data_b [11:0],

    // Test pattern control
    input  logic        en_test_pattern_col,
    input  logic [15:0] test_pattern_col_1 [11:0],
    input  logic [15:0] test_pattern_col_2 [11:0],
    input  logic        s_dummy_valid,

    // Data outputs
    output logic [23:0] s_read_data_a_eim,
    output logic [23:0] s_read_data_b_eim,
    output logic        s_read_data_valid_eim
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    logic [23:0] selected_data_a;
    logic [23:0] selected_data_b;
    logic [23:0] test_data_a;
    logic [23:0] test_data_b;
    logic        any_channel_selected;

    //==========================================================================
    // Channel Selection (One-Hot to Binary Decoder)
    //==========================================================================
    // Find which channel is selected based on read_mem_2d
    logic [3:0] channel_sel;
    logic [11:0] channel_onehot;

    always_comb begin
        channel_onehot = read_mem_2d;
        any_channel_selected = |read_mem_2d;

        // Default to channel 0 if no selection
        if (!any_channel_selected) begin
            channel_sel = 4'd0;
        end else begin
            case (1'b1)
                read_mem_2d[0]:  channel_sel = 4'd0;
                read_mem_2d[1]:  channel_sel = 4'd1;
                read_mem_2d[2]:  channel_sel = 4'd2;
                read_mem_2d[3]:  channel_sel = 4'd3;
                read_mem_2d[4]:  channel_sel = 4'd4;
                read_mem_2d[5]:  channel_sel = 4'd5;
                read_mem_2d[6]:  channel_sel = 4'd6;
                read_mem_2d[7]:  channel_sel = 4'd7;
                read_mem_2d[8]:  channel_sel = 4'd8;
                read_mem_2d[9]:  channel_sel = 4'd9;
                read_mem_2d[10]: channel_sel = 4'd10;
                read_mem_2d[11]: channel_sel = 4'd11;
                default:     channel_sel = 4'd0;
            endcase
        end
    end

    //==========================================================================
    // ROIC Data Multiplexer
    //==========================================================================
    always_comb begin
        case (channel_sel)
            4'd0:  begin selected_data_a = roic_read_data_a[0];  selected_data_b = roic_read_data_b[0];  end
            4'd1:  begin selected_data_a = roic_read_data_a[1];  selected_data_b = roic_read_data_b[1];  end
            4'd2:  begin selected_data_a = roic_read_data_a[2];  selected_data_b = roic_read_data_b[2];  end
            4'd3:  begin selected_data_a = roic_read_data_a[3];  selected_data_b = roic_read_data_b[3];  end
            4'd4:  begin selected_data_a = roic_read_data_a[4];  selected_data_b = roic_read_data_b[4];  end
            4'd5:  begin selected_data_a = roic_read_data_a[5];  selected_data_b = roic_read_data_b[5];  end
            4'd6:  begin selected_data_a = roic_read_data_a[6];  selected_data_b = roic_read_data_b[6];  end
            4'd7:  begin selected_data_a = roic_read_data_a[7];  selected_data_b = roic_read_data_b[7];  end
            4'd8:  begin selected_data_a = roic_read_data_a[8];  selected_data_b = roic_read_data_b[8];  end
            4'd9:  begin selected_data_a = roic_read_data_a[9];  selected_data_b = roic_read_data_b[9];  end
            4'd10: begin selected_data_a = roic_read_data_a[10]; selected_data_b = roic_read_data_b[10]; end
            4'd11: begin selected_data_a = roic_read_data_a[11]; selected_data_b = roic_read_data_b[11]; end
            default: begin selected_data_a = 24'h0; selected_data_b = 24'h0; end
        endcase
    end

    //==========================================================================
    // Test Pattern Generation
    //==========================================================================
    // Column-based test patterns for each channel
    always_comb begin
        if (en_test_pattern_col) begin
            case (channel_sel)
                4'd0:  begin test_data_a = {8'h00, test_pattern_col_1[0][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[0][7:0], 8'h00}; end
                4'd1:  begin test_data_a = {8'h00, test_pattern_col_1[1][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[1][7:0], 8'h00}; end
                4'd2:  begin test_data_a = {8'h00, test_pattern_col_1[2][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[2][7:0], 8'h00}; end
                4'd3:  begin test_data_a = {8'h00, test_pattern_col_1[3][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[3][7:0], 8'h00}; end
                4'd4:  begin test_data_a = {8'h00, test_pattern_col_1[4][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[4][7:0], 8'h00}; end
                4'd5:  begin test_data_a = {8'h00, test_pattern_col_1[5][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[5][7:0], 8'h00}; end
                4'd6:  begin test_data_a = {8'h00, test_pattern_col_1[6][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[6][7:0], 8'h00}; end
                4'd7:  begin test_data_a = {8'h00, test_pattern_col_1[7][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[7][7:0], 8'h00}; end
                4'd8:  begin test_data_a = {8'h00, test_pattern_col_1[8][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[8][7:0], 8'h00}; end
                4'd9:  begin test_data_a = {8'h00, test_pattern_col_1[9][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[9][7:0], 8'h00}; end
                4'd10: begin test_data_a = {8'h00, test_pattern_col_1[10][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[10][7:0], 8'h00}; end
                4'd11: begin test_data_a = {8'h00, test_pattern_col_1[11][7:0], 8'h00}; test_data_b = {8'h00, test_pattern_col_2[11][7:0], 8'h00}; end
                default: begin test_data_a = 24'h0; test_data_b = 24'h0; end
            endcase
        end else begin
            test_data_a = 24'h0;
            test_data_b = 24'h0;
        end
    end

    //==========================================================================
    // Output Data Selection
    //==========================================================================
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || !tx_eim_rst_n) begin
            s_read_data_a_eim <= 24'd0;
            s_read_data_b_eim <= 24'd0;
            s_read_data_valid_eim <= 1'b0;
        end else begin
            // Select between ROIC data and test pattern
            if (any_channel_selected) begin
                if (en_test_pattern_col) begin
                    s_read_data_a_eim <= test_data_a;
                    s_read_data_b_eim <= test_data_b;
                end else begin
                    s_read_data_a_eim <= selected_data_a;
                    s_read_data_b_eim <= selected_data_b;
                end
                s_read_data_valid_eim <= 1'b1;
            end else if (s_dummy_valid) begin
                // Dummy mode output
                s_read_data_a_eim <= {8'h00, 16'h0001};
                s_read_data_b_eim <= {8'h00, 16'h0002};
                s_read_data_valid_eim <= 1'b1;
            end else begin
                s_read_data_a_eim <= 24'd0;
                s_read_data_b_eim <= 24'd0;
                s_read_data_valid_eim <= 1'b0;
            end
        end
    end

    //==========================================================================
    // Assertions for Verification
    //==========================================================================
    `ifndef SYNTHESIS

    property onehot_channel_select;
        @(posedge eim_clk) disable iff (!tx_eim_rst_n)
            |read_mem_2d |-> $onehot0(read_mem_2d);
    endproperty
    assert property (onehot_channel_select)
        else $error("[DATA_MUX] Multiple channels selected!");

    property valid_data_when_selected;
        @(posedge eim_clk) disable iff (!tx_eim_rst_n)
            any_channel_selected |-> s_read_data_valid_eim;
    endproperty
    assert property (valid_data_when_selected)
        else $error("[DATA_MUX] Data valid not asserted for selected channel");

    `endif

endmodule
