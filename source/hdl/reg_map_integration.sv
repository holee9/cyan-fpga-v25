`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: reg_map_integration.sv
// Date: 2025.05.19
// Designer: drake.lee
// Description: Register Map Integration Module - Extracted from cyan_top.sv - Converted from VHDL to SystemVerilog
// Revision History:
//    2025.05.19 - Initial
//
///////////////////////////////////////////////////////////////////////////////


module reg_map_integration (
    // Clocks and resets
    input  logic        clk_100mhz,
    input  logic        clk_20mhz,
    input  logic        rst_n_eim,
    input  logic        rst_n_20mhz,

    // SPI interface
    input  logic        SCLK,
    input  logic        SSB,
    input  logic        MOSI,
    output logic        MISO,

    // Control inputs
    input  logic        EXP_REQ,
    input  logic        FSM_rst_index,
    input  logic        FSM_wait_index,
    input  logic        FSM_back_bias_index,
    input  logic        FSM_flush_index,
    input  logic        FSM_aed_read_index,
    input  logic        FSM_exp_index,
    input  logic        FSM_read_index,
    input  logic        FSM_idle_index,
    input  logic        ready_to_get_image,
    input  logic        aed_ready_done,
    input  logic        panel_stable_exist,
    input  logic        exp_read_exist,

    // Register map outputs
    output logic [15:0] reg_read_out,
    output logic [15:0] s_reg_data,
    output logic        reg_data_index,
    output logic        s_read_data_en,
    output logic        en_pwr_dwn,
    output logic        en_pwr_off,
    output logic        system_rst,
    output logic        reset_fsm,
    output logic        org_reset_fsm,
    output logic        dummy_get_image,
    output logic        burst_get_image,
    output logic        get_dark,
    output logic        get_bright,
    output logic        cmd_get_bright,
    output logic        en_panel_stable,
    output logic [15:0] dsp_image_height,
    output logic [15:0] max_v_count,
    output logic [15:0] max_h_count,
    output logic [15:0] csi2_word_count,
    output logic        sig_gate_lr1,
    output logic        sig_gate_lr2,
    output logic [15:0] up_back_bias,
    output logic [15:0] down_back_bias,
    output logic        en_16bit_adc,
    output logic        en_test_pattern_col,
    output logic        en_test_pattern_row,
    output logic        en_test_roic_col,
    output logic        en_test_roic_row,
    output logic        exp_ack,
    output logic [11:0] dn_aed_gate_xao [0:5],
    output logic [11:0] up_aed_gate_xao [0:5],
    output logic [7:0]  state_led_ctr,

    // Sequence table LUT interface
    output logic  [7:0] seq_lut_addr,
    output logic [63:0] seq_lut_data,
    output logic        seq_lut_wr_en,
    input  logic [63:0] seq_lut_read_data,
    output logic [15:0] seq_lut_control,
    input  logic        seq_lut_config_done,
    output logic  [2:0] acq_mode,
    output logic [31:0] acq_expose_size,
    input  logic [15:0] seq_state_read,

    // TI-ROIC Register signals
    output logic        ti_roic_sync,
    output logic        ti_roic_tp_sel,
    output logic  [1:0] ti_roic_str,
    output logic [15:0] ti_roic_reg_addr,
    output logic [15:0] ti_roic_reg_data,

    // TI-ROIC Deserializer signals
    output logic        ti_roic_deser_reset,
    output logic        ti_roic_deser_dly_tap_ld,
    output logic  [4:0] ti_roic_deser_dly_tap_in,
    output logic        ti_roic_deser_dly_data_ce,
    output logic        ti_roic_deser_dly_data_inc,
    output logic        ti_roic_deser_align_mode,
    output logic        ti_roic_deser_align_start,
    output logic  [4:0] ti_roic_deser_shift_set [11:0],
    input  logic  [4:0] ti_roic_deser_align_shift [11:0],
    output logic [11:0] ti_roic_deser_align_done,

    // Unused gate outputs (for compatibility)
    output logic        gate_mode1,
    output logic        gate_mode2,
    output logic        gate_cs1,
    output logic        gate_cs2,
    output logic        gate_sel,
    output logic        gate_ud,
    output logic        gate_stv_mode,
    output logic        gate_oepsn,
    output logic        stv_sel_h,
    output logic        stv_sel_l1,
    output logic        stv_sel_r1,
    output logic        stv_sel_l2,
    output logic        stv_sel_r2
);

    // SPI Parameters
    localparam int header = 2;
    localparam int payload = 16;
    localparam int addrsz = 14;
    localparam int pktsz = 32; // (header + addrsz + payload) size of SPI packet

    // Internal signals
    logic s_spi_start_flag;
    logic s_addr_dv;
    logic s_rw_out;
    logic s_reg_read_index;
    logic [addrsz-1:0] s_reg_addr;
    logic [payload-1:0] s_reg_data_internal;
    logic s_reg_data_index_internal;
    logic [15:0] s_reg_read_out_new;
    logic [15:0] s_reg_address;
    logic s_miso;

    // Assign s_reg_address with zero extension
    assign s_reg_address = {2'b00, s_reg_addr[addrsz-1:0]};

    // Assign output reg_read_out
    assign reg_read_out = s_reg_read_out_new;

    // Assign internal data to outputs
    assign s_reg_data = s_reg_data_internal;
    assign reg_data_index = s_reg_data_index_internal;

    // SPI slave instantiation
    spi_slave #(
        .header     (header),
        .payload    (payload),
        .addrsz     (addrsz),
        .pktsz      (pktsz)
    )
    host_if_inst (
        .clk               (clk_100mhz),
        .reset             (~rst_n_eim),
        .SCLK              (SCLK),
        .SSB               (SSB),
        .MOSI              (MOSI),
        .MISO              (s_miso),
        .spi_start_flag    (s_spi_start_flag),
        .read_data         (reg_read_out[payload-1:0]),
        .read_en           (s_read_data_en),
        .reg_addr          (s_reg_addr[addrsz-1:0]),
        .addr_valid        (s_addr_dv),
        .wr_data           (s_reg_data_internal[payload-1:0]),
        .wr_data_valid     (s_reg_data_index_internal),
        .rw_out            (s_rw_out)
    );

    // Assign MISO output
    assign MISO = s_miso;

    // Register map read index assignment
    assign s_reg_read_index = (s_rw_out == 1'b1 && s_addr_dv == 1'b1) ? 1'b1 : 1'b0;

    // Register map refacto instantiation
    reg_map_refacto reg_map_refact_inst (
        .eim_clk                    (clk_100mhz),
        .eim_rst                    (rst_n_eim),
        .fsm_clk                    (clk_20mhz),
        .rst                        (rst_n_20mhz),
        .exp_req                    (EXP_REQ),
        .fsm_rst_index              (FSM_rst_index),
        .fsm_init_index             (FSM_wait_index),
        .fsm_back_bias_index        (FSM_back_bias_index),
        .fsm_flush_index            (FSM_flush_index),
        .fsm_aed_read_index         (FSM_aed_read_index),
        .fsm_exp_index              (FSM_exp_index),
        .fsm_read_index             (FSM_read_index),
        .fsm_idle_index             (FSM_idle_index),
        .ready_to_get_image         (ready_to_get_image),
        .aed_ready_done             (aed_ready_done),
        .panel_stable_exist         (panel_stable_exist),
        .exp_read_exist             (exp_read_exist),
        .reg_read_index             (s_reg_read_index),
        .reg_addr                   (s_reg_address),
        .reg_data                   (s_reg_data_internal),
        .reg_data_index             (s_reg_data_index_internal),
        .reg_read_out               (s_reg_read_out_new),
        .read_data_en               (s_read_data_en),
        .en_pwr_dwn                 (en_pwr_dwn),
        .en_pwr_off                 (en_pwr_off),
        .system_rst                 (system_rst),
        .reset_fsm                  (reset_fsm),
        .org_reset_fsm              (org_reset_fsm),
        .dummy_get_image            (dummy_get_image),
        .burst_get_image            (burst_get_image),
        .get_dark                   (get_dark),
        .get_bright                 (get_bright),
        .cmd_get_bright             (cmd_get_bright),
        .en_panel_stable            (en_panel_stable),
        .dsp_image_height           (dsp_image_height),
        .max_v_count                (max_v_count),
        .max_h_count                (max_h_count),
        .csi2_word_count            (csi2_word_count),
        .gate_mode1                 (gate_mode1),
        .gate_mode2                 (gate_mode2),
        .gate_cs1                   (gate_cs1),
        .gate_cs2                   (gate_cs2),
        .gate_sel                   (gate_sel),
        .gate_ud                    (gate_ud),
        .gate_stv_mode              (gate_stv_mode),
        .gate_oepsn                 (gate_oepsn),
        .gate_lr1                   (sig_gate_lr1),
        .gate_lr2                   (sig_gate_lr2),
        .stv_sel_h                  (stv_sel_h),
        .stv_sel_l1                 (stv_sel_l1),
        .stv_sel_r1                 (stv_sel_r1),
        .stv_sel_l2                 (stv_sel_l2),
        .stv_sel_r2                 (stv_sel_r2),
        .up_back_bias               (up_back_bias),
        .dn_back_bias               (down_back_bias),

        .seq_lut_addr               (seq_lut_addr),
        .seq_lut_data               (seq_lut_data),
        .seq_lut_wr_en              (seq_lut_wr_en),
        .seq_lut_read_data          (seq_lut_read_data),
        .seq_lut_control            (seq_lut_control),
        .seq_lut_config_done        (seq_lut_config_done),
        .acq_mode                   (acq_mode),
        .acq_expose_size            (acq_expose_size),
        .seq_state_read             (seq_state_read),

        // TI-ROIC Register signals
        .ti_roic_sync               (ti_roic_sync),
        .ti_roic_tp_sel             (ti_roic_tp_sel),
        .ti_roic_str                (ti_roic_str),
        .ti_roic_reg_addr           (ti_roic_reg_addr),
        .ti_roic_reg_data           (ti_roic_reg_data),

        // TI-ROIC Deserializer signals
        .ti_roic_deser_reset        (ti_roic_deser_reset),
        .ti_roic_deser_dly_tap_ld   (ti_roic_deser_dly_tap_ld),
        .ti_roic_deser_dly_tap_in   (ti_roic_deser_dly_tap_in),
        .ti_roic_deser_dly_data_ce  (ti_roic_deser_dly_data_ce),
        .ti_roic_deser_dly_data_inc (ti_roic_deser_dly_data_inc),
        .ti_roic_deser_align_mode   (ti_roic_deser_align_mode),
        .ti_roic_deser_align_start  (ti_roic_deser_align_start),
        .ti_roic_deser_shift_set    (ti_roic_deser_shift_set),
        .ti_roic_deser_align_shift  (ti_roic_deser_align_shift),
        .ti_roic_deser_align_done   (ti_roic_deser_align_done),

        .en_16bit_adc               (en_16bit_adc),
        .en_test_pattern_col        (en_test_pattern_col),
        .en_test_pattern_row        (en_test_pattern_row),
        .en_test_roic_col           (en_test_roic_col),
        .en_test_roic_row           (en_test_roic_row),
        .exp_ack                    (exp_ack),
        .dn_aed_gate_xao            (dn_aed_gate_xao),
        .up_aed_gate_xao            (up_aed_gate_xao),
        .state_led_ctr              (state_led_ctr)
    );

endmodule
