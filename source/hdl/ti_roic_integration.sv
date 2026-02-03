`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: ti_roic_integration.sv
// Date: 2026-02-03
// Designer: drake.lee
// Description: TI ROIC Integration Module - Extracted from cyan_top.sv
//              Combines TI ROIC SPI interface and Timing Generator
//
// This module encapsulates:
//  1. ROIC SPI register access (ti_roic_spi)
//  2. Timing Generator (ti_roic_tg)
//  3. SPI control logic (s_spidut_en_1d/2d, s_spiReady)
//
// Revision History:
//    2026.02.03 - Initial extraction from cyan_top.sv
//
///////////////////////////////////////////////////////////////////////////////

module ti_roic_integration (
    // Clocks and resets
    input  logic        clk_5mhz,
    input  logic        clk_20mhz,
    input  logic        deser_reset_n,

    // TI ROIC control
    input  logic [15:0] ti_roic_reg_addr,
    input  logic [15:0] ti_roic_reg_data,
    input  logic [1:0]  ti_roic_str,

    // Control inputs
    input  logic        s_roic_sync_in,
    input  logic        s_roic_tp_sel,
    input  logic        aed_detect_skip_oe,
    input  logic        fsm_read_index,
    input  logic        gen_sync_start_3ff,

    // Counters
    input  logic [15:0] tg_row_cnt,
    input  logic [10:0] tg_col_cnt,

    // SPI outputs
    output logic [11:0] s_roic_sdio,
    output logic        RF_SPI_SCK,
    output logic        RF_SPI_SDI,
    output logic        s_rf_spi_sen,

    // Timing outputs
    output logic        s_roic_sync_out,
    output logic        s_roic_a_bz,
    output logic        s_tg_stv,
    output logic        s_tg_cpv,
    output logic        s_tg_oe,

    // Gate control outputs
    output logic        s_IRST,
    output logic        s_SHR,
    output logic        s_SHS,
    output logic        s_LPF1,
    output logic        s_LPF2,
    output logic        s_TDEF,
    output logic        s_GATE_ON,
    output logic        s_DF_SM0,
    output logic        s_DF_SM1,
    output logic        s_DF_SM2,
    output logic        s_DF_SM3,
    output logic        s_DF_SM4,
    output logic        s_DF_SM5
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    logic [191:0] sdoutWord;
    logic        s_spiReady;
    logic        s_spidut_en_1d;
    logic        s_spidut_en_2d;

    //==========================================================================
    // TI ROIC SPI Interface
    //==========================================================================
    /**
     * @brief TI ROIC SPI for register set
     */
    roic_spi ti_roic_spi_inst (
        .reset              (deser_reset_n),
        .clk                (clk_5mhz),
        .address            (ti_roic_reg_addr[7:0]),
        .data               (ti_roic_reg_data),
        .DUT_EN             (ti_roic_reg_addr[15]),
        .spiReady           (s_spiReady),
        .DUT_SDOUT          (s_roic_sdio),
        .DUT_SCLK           (RF_SPI_SCK),
        .DUT_SDATA          (RF_SPI_SDI),
        .DUT_SEN            (s_rf_spi_sen),
        .sdoutWord          (sdoutWord)
    );

    //==========================================================================
    // SPI Control Logic
    //==========================================================================
    // Generate spiReady pulse on rising edge of DUT_EN
    always_ff @(posedge clk_5mhz or negedge deser_reset_n) begin
        if (~deser_reset_n) begin
            s_spidut_en_1d <= 1'b0;
            s_spidut_en_2d <= 1'b0;
        end else begin
            s_spidut_en_1d <= ti_roic_reg_addr[15];
            s_spidut_en_2d <= s_spidut_en_1d;
        end
    end

    assign s_spiReady = s_spidut_en_1d & ~s_spidut_en_2d;

    //==========================================================================
    // TI ROIC Timing Generator
    //==========================================================================
    ti_roic_tg roic_tg_gen_int (
        .clk                (clk_20mhz),
        .rst                (deser_reset_n),
        .str                (ti_roic_str),
        .sync_in            (s_roic_sync_in),
        .tp_sel             (s_roic_tp_sel),
        .aed_detect_skip_oe (aed_detect_skip_oe),
        .fsm_read_index     (fsm_read_index),
        .reg_en             (ti_roic_reg_addr[15]),
        .reg_addr           (ti_roic_reg_addr[7:0]),
        .reg_data           (ti_roic_reg_data),
        .sync_start         (gen_sync_start_3ff),
        .readout_width      (),
        .tg_row_cnt         (tg_row_cnt),
        .tg_col_cnt         (tg_col_cnt),
        .roic_sync_out      (s_roic_sync_out),
        .roic_a_bz          (s_roic_a_bz),
        .tg_stv             (s_tg_stv),
        .tg_cpv             (s_tg_cpv),
        .tg_oe              (s_tg_oe),
        .v_sync             (),
        .IRST               (s_IRST),
        .SHR                (s_SHR),
        .SHS                (s_SHS),
        .LPF1               (s_LPF1),
        .LPF2               (s_LPF2),
        .TDEF               (s_TDEF),
        .GATE_ON            (s_GATE_ON),
        .DF_SM0             (s_DF_SM0),
        .DF_SM1             (s_DF_SM1),
        .DF_SM2             (s_DF_SM2),
        .DF_SM3             (s_DF_SM3),
        .DF_SM4             (s_DF_SM4),
        .DF_SM5             (s_DF_SM5)
    );

endmodule
