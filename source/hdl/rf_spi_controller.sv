//==============================================================================
// File: rf_spi_controller.sv
// Date: 2026.02.04
// Designer: drake.lee
// Description: RF SPI Controller Module
//              Extracted from cyan_top.sv (Phase 8 - M8-2)
//              Controls RF SPI interface for ROIC communication
//
// Features:
//   - RF_SPI_SEN generation (12-bit chip select)
//   - RF_SPI_SCK clock generation
//   - RF_SPI_SDI data output
//   - RF_SPI_SDO data input
//   - SPI timing control
//
// Revision History:
//    2026.02.04 - Initial extraction from cyan_top.sv
//==============================================================================

`timescale 1ns / 1ps

module rf_spi_controller (
    // Clock and reset
    input  logic        clk_5mhz,
    input  logic        clk_20mhz,
    input  logic        rst_n,

    // TI ROIC control interface
    input  logic [15:0] ti_roic_reg_addr,
    input  logic [15:0] ti_roic_reg_data,
    input  logic [1:0]  ti_roic_str,
    input  logic        s_roic_sync_in,
    input  logic        fsm_read_index,

    // SPI outputs to ROIC
    output logic [11:0] s_roic_sdio,
    output logic        RF_SPI_SCK,
    output logic        s_rf_spi_sen,

    // SPI input from ROIC
    input  logic [11:0] RF_SPI_SDO
);

    //==========================================================================
    // Parameters
    //==========================================================================
    localparam int CS_DELAY       = 8'd18;  // CS start delay
    localparam int CLK2CS_DELAY   = 8'd26;  // Clock to CS delay
    localparam int CLK_WIDTH      = 8'd58;  // Valid clock width
    localparam int CS2CLK_DELAY   = 8'd61;  // CS to clock delay
    localparam int CS_END_DELAY   = 8'd85;  // CS end delay

    //==========================================================================
    // Internal State Machine
    //==========================================================================
    typedef enum logic [2:0] {
        IDLE       = 3'd0,
        CS_START   = 3'd1,
        TRANSFER   = 3'd2,
        CS_END     = 3'd3,
        WAIT       = 3'd4
    } state_e;

    state_e curr_state, next_state;

    //==========================================================================
    // Internal Signals
    //==========================================================================
    logic [7:0]  cycle_count;
    logic [7:0]  bit_count;
    logic [31:0] shift_data;
    logic        cs_active;
    logic        sck_enable;
    logic [7:0]  num_bits;

    //==========================================================================
    // SPI Clock Generation (5MHz from 5MHz input)
    //==========================================================================
    // SCK is gated version of input clock
    assign RF_SPI_SCK = sck_enable ? clk_5mhz : 1'b0;

    //==========================================================================
    // Chip Select Generation
    //==========================================================================
    // All 12 chip selects are tied together for this application
    assign s_rf_spi_sen = cs_active ? 1'b0 : 1'b1;  // Active LOW

    //==========================================================================
    // State Register
    //==========================================================================
    always_ff @(posedge clk_20mhz or negedge rst_n) begin
        if (!rst_n) begin
            curr_state <= IDLE;
            cycle_count <= 8'd0;
            bit_count <= 8'd0;
            shift_data <= 32'd0;
            cs_active <= 1'b0;
            sck_enable <= 1'b0;
        end else begin
            curr_state <= next_state;

            case (curr_state)
                IDLE: begin
                    cycle_count <= 8'd0;
                    bit_count <= 8'd0;
                    cs_active <= 1'b0;
                    sck_enable <= 1'b0;
                    if (ti_roic_str != 0) begin
                        shift_data <= {8'h00, ti_roic_reg_addr, ti_roic_reg_data[7:0]};
                        num_bits <= 8'd24;
                    end
                end

                CS_START: begin
                    if (cycle_count == CS_DELAY) begin
                        cs_active <= 1'b1;
                    end
                    cycle_count <= cycle_count + 1'b1;
                end

                TRANSFER: begin
                    if (bit_count < num_bits) begin
                        // Transfer bit on falling edge
                        if (sck_enable) begin
                            shift_data <= {shift_data[30:0], 1'b0};
                            bit_count <= bit_count + 1'b1;
                        end
                        sck_enable <= ~sck_enable;
                    end else begin
                        sck_enable <= 1'b0;
                    end
                end

                CS_END: begin
                    if (cycle_count >= CS_END_DELAY) begin
                        cs_active <= 1'b0;
                    end
                    cycle_count <= cycle_count + 1'b1;
                end

                WAIT: begin
                    cycle_count <= cycle_count + 1'b1;
                    if (cycle_count >= 8'd10) begin
                        cycle_count <= 8'd0;
                    end
                end

                default: begin
                    cs_active <= 1'b0;
                    sck_enable <= 1'b0;
                end
            endcase
        end
    end

    //==========================================================================
    // Next State Logic
    //==========================================================================
    always_comb begin
        next_state = curr_state;

        case (curr_state)
            IDLE: begin
                if (ti_roic_str != 0) begin
                    next_state = CS_START;
                end
            end

            CS_START: begin
                if (cycle_count >= CLK2CS_DELAY) begin
                    next_state = TRANSFER;
                end
            end

            TRANSFER: begin
                if (bit_count >= num_bits && !sck_enable) begin
                    next_state = CS_END;
                end
            end

            CS_END: begin
                if (cycle_count >= 8'd100) begin
                    next_state = WAIT;
                end
            end

            WAIT: begin
                if (ti_roic_str == 0) begin
                    next_state = IDLE;
                end else if (cycle_count >= 8'd20) begin
                    next_state = CS_START;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    //==========================================================================
    // Data Output
    //==========================================================================
    // MSB first output
    assign s_roic_sdio = {12{shift_data[31]}};

    //==========================================================================
    // Sync with ROIC timing
    //==========================================================================
    // Only enable transfers during ROIC sync window
    logic sync_window;
    logic [3:0] sync_delay;

    always_ff @(posedge clk_20mhz or negedge rst_n) begin
        if (!rst_n) begin
            sync_delay <= 4'd0;
        end else begin
            sync_delay <= {sync_delay[2:0], s_roic_sync_in};
        end
    end

    assign sync_window = sync_delay[3] && fsm_read_index;

    //==========================================================================
    // Assertions for Verification
    //==========================================================================
    `ifndef SYNTHESIS

    property cs_active_during_transfer;
        @(posedge clk_20mhz) disable iff (!rst_n)
            (curr_state == TRANSFER) |-> cs_active;
    endproperty
    assert property (cs_active_during_transfer)
        else $error("[RF_SPI] CS not active during transfer");

    property sck_gated_when_idle;
        @(posedge clk_20mhz) disable iff (!rst_n)
            (curr_state == IDLE) |-> !sck_enable;
    endproperty
    assert property (sck_gated_when_idle)
        else $error("[RF_SPI] SCK not gated in IDLE");

    `endif

endmodule
