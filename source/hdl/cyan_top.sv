`timescale 1ns / 1ps

// File: cyan_top.sv
// Date: 2025.05.19
// Designer: drake.lee
// Description: xdaq fpga top file - Converted from VHDL to SystemVerilog
// Revision History:
//    2025.05.19 - Initial
//    Week 5: Extracted ti_roic_integration, mipi_integration, sequencer_wrapper, data_path_integration
//    Week 6: Extracted debug_integration, sync_processing
//    Week 7: Extracted gate_driver_output, roic_channel_array
//    Week 8: Extracted control_signal_mux, power_control
//    Week 10: Reset standardization (s_seq_reset -> s_seq_reset_n, all modules to active-LOW)
//

module cyan_top (
    // system signal
    input   logic        nRST,
    input   logic        MCLK_50M_p,
    input   logic        MCLK_50M_n,

    // mipi csi2 interface
    output  logic        mipi_phy_if_clk_hs_p,
    output  logic        mipi_phy_if_clk_hs_n,
    output  logic        mipi_phy_if_clk_lp_p,
    output  logic        mipi_phy_if_clk_lp_n,
    output  logic [3:0]  mipi_phy_if_data_hs_p,
    output  logic [3:0]  mipi_phy_if_data_hs_n,
    output  logic [3:0]  mipi_phy_if_data_lp_p,
    output  logic [3:0]  mipi_phy_if_data_lp_n,

    // register map control signal
    input   logic        SCLK,
    input   logic        SSB,
    input   logic        MOSI,
    output  logic        MISO,

    // ROIC Driving Signals
    output  logic        ROIC_TP_SEL,
    output  logic        ROIC_SYNC,
    output  logic        ROIC_MCLK0,
    output  logic        ROIC_MCLK1,

    output  logic [11:0] RF_SPI_SEN,
    output  logic        RF_SPI_SCK,
    output  logic [0:0]  RF_SPI_SDI,
    input   logic [11:0] RF_SPI_SDO,

    output  logic        SWITCH_SYNC,

    input  logic         AED_TRIG,

    input   logic [11:0] R_ROIC_DCLKo_p,
    input   logic [11:0] R_ROIC_DCLKo_n,

    input   logic [11:0] R_ROIC_FCLKo_p,
    input   logic [11:0] R_ROIC_FCLKo_n,

    input   logic [11:0] R_DOUTA_H,
    input   logic [11:0] R_DOUTA_L,

    // Gate Driving Signals
    output  logic        GF_STV_L,
    output  logic        GF_STV_R,

    output  logic [5:0]  GF_XAO,

    output  logic        GF_LR,

    output  logic        GF_CPV,
    output  logic        GF_OE,

    // Bias Signals
    output  logic        ROIC_VBIAS,
    output  logic        ROIC_AVDD1,
    output  logic        ROIC_AVDD2,

    // Trigger Signals
    input   logic        PREP_REQ,
    input   logic        EXP_REQ,

    output  logic        PREP_ACK,
    output  logic        EXP_ACK,

    // debug signals
    output logic [3:0]   DEBUG_SiG,

    // Signals control
    output  logic        STATE_LED1

);

    // (* mark_debug="true" *) 

    // Clock signals
    logic s_clk_100mhz;
    logic s_dphy_clk_200M;
    logic s_clk_20mhz;
    logic s_clk_5mhz;
    logic s_clk_1mhz;

    // Reset signals (from clock_gen_top)
    logic rst_n_20mhz;
    logic rst_n_100mhz;
    logic rst_n_200mhz;
    logic rst_n_eim;
    logic s_clk_lock;

    // Module signals
    logic s_roic_reset;
    logic s_back_bias;

    logic s_roic_tp_sel;
    logic s_roic_sync_in;
    logic s_roic_sync_out;
    logic s_roic_a_bz;

    logic [11:0] s_roic_sdio;

    logic eim_clk;
    logic eim_rst;
    logic sys_rst;
    logic rst;
    logic fsm_drv_rst;

    logic col_end;

    logic FSM_rst_index;
    logic FSM_wait_index;
    logic FSM_back_bias_index;
    logic FSM_flush_index;
    logic FSM_aed_read_index;
    logic FSM_exp_index;
    logic FSM_read_index;
    logic FSM_idle_index;
    logic FSM_index_all;

    logic ready_to_get_image;
    logic aed_ready_done;
    logic aed_ready_done_dark;
    logic panel_stable_o;
    logic s_exp_read_exist;

    logic [15:0] row_cnt;
    logic [15:0] col_cnt;
    logic [15:0] s_sync_col_cnt;

    logic en_pwr_off;
    logic en_pwr_dwn;
    logic system_rst;
    logic reset_FSM;
    logic org_reset_FSM;
    logic dummy_get_image;
    logic burst_get_image;
    logic get_dark;
    logic get_bright;
    logic cmd_get_bright;
    logic s_get_bright;

    logic en_aed;

    logic s_sum_channel_detected;

    logic en_panel_stable;

    logic [15:0] dsp_image_height;
    logic [15:0] max_h_count;
    logic [15:0] max_v_count;
    logic [15:0] csi2_word_count;

    logic [15:0] up_back_bias;
    logic [15:0] down_back_bias;

    logic [15:0] dn_aed_gate_xao [0:5];
    logic [15:0] up_aed_gate_xao [0:5];

    logic en_16bit_adc;
    logic en_test_pattern_col;
    logic en_test_pattern_row;
    logic en_test_roic_col;
    logic en_test_roic_row;
    logic sig_gate_lr1;
    logic sig_gate_lr2;
    logic valid_roic_out;
    logic valid_roic_burst_clk;
    logic valid_roic_reg_out;
    logic valid_roic_header_out;
    logic valid_roic_data;

    // Array signals
    logic valid_aed_test_data;
    logic [15:0] trigger_data_1;
    logic [15:0] trigger_data_2;
    logic [15:0] trigger_data_3;

    logic s_pwr_init_step1;
    logic s_pwr_init_step2;
    logic s_pwr_init_step3;
    logic s_pwr_init_step4;
    logic s_pwr_init_step5;
    logic s_pwr_init_step6;

    logic init_rst;
    logic s_sync_fsm_read_index;
    logic s_sync_fsm_flush_index;
    logic s_sync_fsm_back_bias_index;
    logic s_sync_xao_enable;

    logic gate_xao;
    logic gate_xao_0;
    logic gate_xao_1;
    logic gate_xao_2;
    logic gate_xao_3;
    logic gate_xao_4;

    logic s_tg_stv;
    logic s_tg_cpv;
    logic s_tg_oe;
    logic s_mask_stv;

    logic [15:0] tg_row_cnt;
    logic [10:0] tg_col_cnt;
    // SPI signals - now handled by reg_map_integration module
    logic [15:0] s_reg_data;
    logic s_reg_data_index;
    logic s_read_data_en;

    // Unused gate outputs from reg_map_integration
    logic unused_gate_mode1;
    logic unused_gate_mode2;
    logic unused_gate_cs1;
    logic unused_gate_cs2;
    logic unused_gate_sel;
    logic unused_gate_ud;
    logic unused_gate_stv_mode;
    logic unused_gate_oepsn;
    logic unused_stv_sel_h;
    logic unused_stv_sel_l1;
    logic unused_stv_sel_r1;
    logic unused_stv_sel_l2;
    logic unused_stv_sel_r2;

    logic [23:0] s_read_rx_data_a;
    logic [23:0] s_read_rx_data_b;
    logic s_read_frame_start;
    logic s_read_frame_reset;
    logic s_read_axis_tready;
    logic s_read_axis_tlast;
    logic s_read_axis_tvalid;

    logic [23:0] s_test_cnt;
    logic [7:0] s_state_led_ctr;
    logic s_reg_map_sel;

    // MIPI signals

    logic s_csi2_reset;
    logic s_clk_lock;
    logic s_csi_done;
    logic [0:0] s_axis_video_tuser;
    logic [23:0] s_axis_tdata_a;
    logic [23:0] s_axis_tdata_b;

    logic s_reg_tp_sel;

    logic s_reg_roic_sync;

    logic ti_roic_sync;
    logic ti_roic_tp_sel;
    logic [1:0]  ti_roic_str;
    logic [15:0] ti_roic_reg_addr;
    logic [15:0] ti_roic_reg_data;
    logic gen_sync_start;          // Sync start level signal (in 20MHz domain)
    logic gen_sync_start_3ff;      // Alias for gen_sync_start (same clock domain, no CDC)
    logic s_gen_sync_start_rise;

    // TI ROIC deser signals
    logic ti_roic_deser_reset;
    logic ti_roic_deser_dly_tap_ld;
    logic [4:0] ti_roic_deser_dly_tap_in;
    logic ti_roic_deser_dly_data_ce;
    logic ti_roic_deser_dly_data_inc;
    logic ti_roic_deser_align_mode;
    logic ti_roic_deser_align_start;
    logic [4:0] ti_roic_deser_shift_set[11:0];
    logic [4:0] ti_roic_deser_align_shift[11:0];
    logic [11:0] ti_roic_deser_align_done;

    // Sequence table signals
    logic s_seq_reset_n;  // Active-LOW sequence reset
    logic [7:0] seq_lut_addr;
    logic [63:0] seq_lut_data;
    logic seq_lut_wr_en;
    logic [63:0] seq_lut_read_data;
    logic [15:0] seq_state_read;
    logic seq_lut_config_done;
    logic [15:0] seq_lut_control;
    logic [ 2:0] acq_mode;
    logic [31:0] acq_expose_size;
    logic [ 2:0] acq_mode_o;
    logic [31:0] expose_size_o;

    logic s_config_done_i;
    logic s_sync_config_done;

    logic exit_signal_i;
    logic [3:0] current_state_o;
    logic busy_o;
    logic sequence_done_o;
    logic reset_state_o;
    logic wait_o;
    logic bias_enable_o;
    logic flush_enable_o;
    logic expose_enable_o;
    logic readout_enable_o;
    logic aed_enable_o;
    logic stv_mask_o;
    logic csi_mask_o;
    logic idle_elable_o;
    logic iterate_exist_o;
    logic s_wait_sync;
    logic [2:0] s_wait_sync_dly;
    logic s_wait_tp_sel;
    logic s_wait_roic_sync;

    logic s_sync_stv_mask_o;
    logic s_sync_csi_mask_o;
    logic [31:0] s_sync_current_repeat_count_o;
    logic [31:0] s_sync_repeat_cnt;
    logic [2:0] s_sync_repeat_cnt_mod;

    logic current_sof_o;
    logic current_eof_o;
    logic [31:0] active_repeat_count_o;
    logic [31:0] current_repeat_count_o;
    logic [31:0] valid_repeat_count_o;
    logic [18:0] current_data_length_o;

    logic [1:0] s_get_dark_dly;
    logic [1:0] s_get_bright_dly;
    logic [1:0] s_get_aed_trig_dly;
    logic [1:0] s_sequence_done_dly;
    logic s_get_dark_hi;
    logic s_get_bright_hi;
    logic s_get_aed_trig_hi;
    logic s_sequence_done_hi;
    logic s_exit_signal_dark;
    logic s_exit_signal_bright;
    logic s_exit_signal_aed;
    logic s_aed_mode_exist;

    logic s_aed_trig;
    logic s_aed_trig_i;
    logic s_valid_readout;
    logic s_read_data_start;
    logic s_readout_wait;
    logic s_state_exit_flag;
    logic s_aed_detect_skip_oe_o;

    /////////////////////////////////////////////////////////////////////////////
    // Week 4: Clock Generation Module (TOP-001 Phase 1)
    /////////////////////////////////////////////////////////////////////////////

    // Clock generation and reset synchronization
    clock_gen_top clock_gen_inst (
        .nRST            (nRST),
        .MCLK_50M_p      (MCLK_50M_p),
        .MCLK_50M_n      (MCLK_50M_n),
        .s_clk_100mhz    (s_clk_100mhz),
        .s_dphy_clk_200M (s_dphy_clk_200M),
        .s_clk_20mhz     (s_clk_20mhz),
        .eim_clk         (eim_clk),
        .rst_n_20mhz     (rst_n_20mhz),
        .rst_n_100mhz    (rst_n_100mhz),
        .rst_n_200mhz    (rst_n_200mhz),
        .rst_n_eim       (rst_n_eim),
        .s_clk_lock      (s_clk_lock)
    );

    // clk_ctrl module instantiation

    /////////////////////////////////////////////////////////////////////////////
    // Week 5: MIPI CSI-2 TX Integration Module (TOP-001 Phase 2)
    /////////////////////////////////////////////////////////////////////////////
    
    // MIPI CSI-2 TX integration - encapsulates MIPI CSI-2 TX top and AXI stream processing
    mipi_integration mipi_integration_inst (
        // Clocks and resets
        .dphy_clk_200M          (s_dphy_clk_200M),
        .clk_100M               (s_clk_100mhz),
        .eim_clk                (eim_clk),
        .rst_n_200mhz           (rst_n_200mhz),
        .clk_lock               (s_clk_lock),
        
        // Frame control
        .read_frame_reset       (s_read_frame_reset),
        
        // AXI-Stream interface
        .axis_tdata_a           (s_axis_tdata_a),
        .axis_tdata_b           (s_axis_tdata_b),
        .axis_tlast             (s_read_axis_tlast),
        .axis_tready            (s_read_axis_tready),
        .axis_tvalid            (s_read_axis_tvalid),
        .axis_tstrb             (3'b000),
        .axis_tkeep             (3'b111),
        
        // CSI-2 control/status
        .csi2_word_count        (csi2_word_count),
        .axis_video_tuser       (s_axis_video_tuser),
        .csi_done               (s_csi_done),
        
        // MIPI PHY interface
        .mipi_phy_if_clk_hs_p   (mipi_phy_if_clk_hs_p),
        .mipi_phy_if_clk_hs_n   (mipi_phy_if_clk_hs_n),
        .mipi_phy_if_clk_lp_p   (mipi_phy_if_clk_lp_p),
        .mipi_phy_if_clk_lp_n   (mipi_phy_if_clk_lp_n),
        .mipi_phy_if_data_hs_p  (mipi_phy_if_data_hs_p),
        .mipi_phy_if_data_hs_n  (mipi_phy_if_data_hs_n),
        .mipi_phy_if_data_lp_p  (mipi_phy_if_data_lp_p),
        .mipi_phy_if_data_lp_n  (mipi_phy_if_data_lp_n),
        
        // Status (unused)
        .interrupt              (),
        .status                 (),
        .system_rst_out         ()
    );

    // init module instantiation (RST-001 fix: removed reset inversion)
    init init_inst (
        .fsm_clk            (s_clk_20mhz),
        .rst_n              (rst_n_20mhz),  // Active-LOW reset (direct connection, no inversion)
        .en_pwr_off         (en_pwr_off),
        .en_pwr_dwn         (en_pwr_dwn),
        .init_rst           (init_rst),
        .pwr_init_step1     (s_pwr_init_step1),
        .pwr_init_step2     (s_pwr_init_step2),
        .pwr_init_step3     (s_pwr_init_step3),
        .pwr_init_step4     (s_pwr_init_step4),
        .pwr_init_step5     (s_pwr_init_step5),
        .pwr_init_step6     (s_pwr_init_step6),
        .roic_reset         (s_roic_reset)
    );

    //////////////////////////////////////////////////////////////////////////////
    // Register Map Integration Module
    //////////////////////////////////////////////////////////////////////////////
    // Encapsulates SPI slave interface and register map logic
    
    reg_map_integration reg_map_inst (
        .clk_100mhz                (s_clk_100mhz),
        .clk_20mhz                 (s_clk_20mhz),
        .rst_n_eim                 (rst_n_eim),
        .rst_n_20mhz               (rst_n_20mhz),
        .SCLK                      (SCLK),
        .SSB                       (SSB),
        .MOSI                      (MOSI),
        .MISO                      (MISO),
        .EXP_REQ                   (EXP_REQ),
        .FSM_rst_index             (FSM_rst_index),
        .FSM_wait_index            (FSM_wait_index),
        .FSM_back_bias_index       (FSM_back_bias_index),
        .FSM_flush_index           (FSM_flush_index),
        .FSM_aed_read_index        (FSM_aed_read_index),
        .FSM_exp_index             (FSM_exp_index),
        .FSM_read_index            (FSM_read_index),
        .FSM_idle_index            (FSM_idle_index),
        .ready_to_get_image        (ready_to_get_image),
        .aed_ready_done            (aed_ready_done),
        .panel_stable_exist        (panel_stable_o),
        .exp_read_exist            (s_exp_read_exist),
        .reg_read_out              (),
        .s_reg_data                (s_reg_data),
        .reg_data_index            (s_reg_data_index),
        .s_read_data_en            (s_read_data_en),
        .en_pwr_dwn                (en_pwr_dwn),
        .en_pwr_off                (en_pwr_off),
        .system_rst                (system_rst),
        .reset_fsm                 (reset_FSM),
        .org_reset_fsm             (org_reset_FSM),
        .dummy_get_image           (dummy_get_image),
        .burst_get_image           (burst_get_image),
        .get_dark                  (get_dark),
        .get_bright                (get_bright),
        .cmd_get_bright            (cmd_get_bright),
        .en_panel_stable           (en_panel_stable),
        .dsp_image_height          (dsp_image_height),
        .max_v_count               (max_v_count),
        .max_h_count               (max_h_count),
        .csi2_word_count           (csi2_word_count),
        .sig_gate_lr1              (sig_gate_lr1),
        .sig_gate_lr2              (sig_gate_lr2),
        .up_back_bias              (up_back_bias),
        .down_back_bias            (down_back_bias),
        .en_16bit_adc              (en_16bit_adc),
        .en_test_pattern_col       (en_test_pattern_col),
        .en_test_pattern_row       (en_test_pattern_row),
        .en_test_roic_col          (en_test_roic_col),
        .en_test_roic_row          (en_test_roic_row),
        .exp_ack                   (EXP_ACK),
        .dn_aed_gate_xao           (dn_aed_gate_xao),
        .up_aed_gate_xao           (up_aed_gate_xao),
        .state_led_ctr             (s_state_led_ctr),
        .seq_lut_addr              (seq_lut_addr),
        .seq_lut_data              (seq_lut_data),
        .seq_lut_wr_en             (seq_lut_wr_en),
        .seq_lut_read_data         (seq_lut_read_data),
        .seq_lut_control           (seq_lut_control),
        .seq_lut_config_done       (seq_lut_config_done),
        .acq_mode                  (acq_mode),
        .acq_expose_size           (acq_expose_size),
        .seq_state_read            (seq_state_read),
        .ti_roic_sync              (s_reg_roic_sync),
        .ti_roic_tp_sel            (s_reg_tp_sel),
        .ti_roic_str               (ti_roic_str),
        .ti_roic_reg_addr          (ti_roic_reg_addr),
        .ti_roic_reg_data          (ti_roic_reg_data),
        .ti_roic_deser_reset       (ti_roic_deser_reset),
        .ti_roic_deser_dly_tap_ld  (ti_roic_deser_dly_tap_ld),
        .ti_roic_deser_dly_tap_in  (ti_roic_deser_dly_tap_in),
        .ti_roic_deser_dly_data_ce (ti_roic_deser_dly_data_ce),
        .ti_roic_deser_dly_data_inc(ti_roic_deser_dly_data_inc),
        .ti_roic_deser_align_mode  (ti_roic_deser_align_mode),
        .ti_roic_deser_align_start (ti_roic_deser_align_start),
        .ti_roic_deser_shift_set   (ti_roic_deser_shift_set),
        .ti_roic_deser_align_shift (ti_roic_deser_align_shift),
        .ti_roic_deser_align_done  (ti_roic_deser_align_done),
        .unused_gate_mode1         (unused_gate_mode1),
        .unused_gate_mode2         (unused_gate_mode2),
        .unused_gate_cs1           (unused_gate_cs1),
        .unused_gate_cs2           (unused_gate_cs2),
        .unused_gate_sel           (unused_gate_sel),
        .unused_gate_ud            (unused_gate_ud),
        .unused_gate_stv_mode      (unused_gate_stv_mode),
        .unused_gate_oepsn         (unused_gate_oepsn),
        .unused_stv_sel_h          (unused_stv_sel_h),
        .unused_stv_sel_l1         (unused_stv_sel_l1),
        .unused_stv_sel_r1         (unused_stv_sel_r1),
        .unused_stv_sel_l2         (unused_stv_sel_l2),
        .unused_stv_sel_r2         (unused_stv_sel_r2)
    );

    // assign disable_aed_read_xao = 1'b1; // For Gemini, AED read XAO is always enabled

    roic_gate_drv_gemini roic_gate_drv_inst (
        .fsm_clk                (s_clk_20mhz),
        .fsm_drv_rst            (fsm_drv_rst),
        .row_cnt                (row_cnt),
        .col_cnt                (col_cnt),
        .fsm_back_bias_index    (s_sync_fsm_back_bias_index),
        .fsm_flush_index        (s_sync_fsm_flush_index),
        .col_end                (col_end),
        .up_back_bias           (up_back_bias),
        .dn_back_bias           (down_back_bias),
        .up_aed_gate_xao        (up_aed_gate_xao),
        .dn_aed_gate_xao        (dn_aed_gate_xao),
        .back_bias              (s_back_bias),
        .gate_xao_0             (gate_xao_0),
        .gate_xao_1             (gate_xao_1),
        .gate_xao_2             (gate_xao_2),
        .gate_xao_3             (gate_xao_3),
        .gate_xao_4             (gate_xao_4),
        .gate_xao_5             (gate_xao)
    );

    assign row_cnt = s_sync_repeat_cnt[15:0];
    assign col_cnt = s_sync_col_cnt[15:0];
    assign col_end = (s_sync_col_cnt == 16'd0) ? 1'b1 : 1'b0;

    /////////////////////////////////////////////////////////////////////////////
    // Week 5: Sequencer Wrapper Module (TOP-001 Phase 2)
    /////////////////////////////////////////////////////////////////////////////
    
    // Sequencer wrapper - encapsulates sequencer FSM and index generation
    logic [11:0] s_roic_even_odd_out;
    
    sequencer_wrapper sequencer_wrapper_inst (
        // Clocks and resets
        .clk_20mhz               (s_clk_20mhz),
        .rst_n_20mhz             (rst_n_20mhz),
        .rst                     (rst),
        
        // Configuration interface
        .config_done_i           (s_sync_config_done),
        .lut_addr_i              (seq_lut_addr),
        .lut_wen_i               (seq_lut_wr_en),
        .lut_write_data_i        (seq_lut_data),
        .lut_read_data_o         (seq_lut_read_data),
        
        // Control inputs
        .acq_mode_i              (acq_mode),
        .expose_size_i           (acq_expose_size),
        .exit_signal_i           (exit_signal_i),
        .roic_even_odd_i         (s_roic_even_odd_out[0]),
        .readout_wait            (s_readout_wait),
        
        // FSM outputs
        .state_exit_flag_o       (s_state_exit_flag),
        .current_state_o         (current_state_o),
        .busy_o                  (busy_o),
        .sequence_done_o         (sequence_done_o),
        .reset_state_o           (reset_state_o),
        .wait_o                  (wait_o),
        .bias_enable_o           (bias_enable_o),
        .flush_enable_o          (flush_enable_o),
        .expose_enable_o         (expose_enable_o),
        .readout_enable_o        (readout_enable_o),
        .aed_enable_o            (aed_enable_o),
        .stv_mask_o              (stv_mask_o),
        .csi_mask_o              (csi_mask_o),
        .panel_stable_o          (panel_stable_o),
        .iterate_exist_o         (iterate_exist_o),
        .idle_elable_o           (idle_elable_o),
        .current_sof_o           (current_sof_o),
        .current_eof_o           (current_eof_o),
        .acq_mode_o              (acq_mode_o),
        .expose_size_o           (expose_size_o),
        .current_repeat_count_o  (current_repeat_count_o),
        .active_repeat_count_o   (active_repeat_count_o),
        .current_data_length_o   (current_data_length_o),
        
        // Index outputs (FSM control signals)
        .FSM_rst_index           (FSM_rst_index),
        .FSM_wait_index          (FSM_wait_index),
        .FSM_aed_read_index      (FSM_aed_read_index),
        .FSM_back_bias_index     (FSM_back_bias_index),
        .FSM_flush_index         (FSM_flush_index),
        .FSM_exp_index           (FSM_exp_index),
        .FSM_read_index          (FSM_read_index),
        .FSM_idle_index          (FSM_idle_index)
    );

    assign s_wait_tp_sel = (wait_o && current_eof_o) ? 1'b1 : 1'b0;
    assign s_wait_sync   = (wait_o && current_sof_o) ? 1'b1 : 1'b0;
    assign s_wait_roic_sync = (s_wait_sync_dly == 3'd3) ? 1'b1 : 1'b0;

    assign s_seq_reset_n = rst_n_20mhz;  // Active-LOW reset follows rst_n_20mhz

    assign valid_repeat_count_o = s_sync_current_repeat_count_o - 32'd2;

    assign s_valid_readout = ((~s_sync_csi_mask_o) && s_sync_fsm_read_index && (valid_repeat_count_o > s_sync_repeat_cnt)) ? 1'b1 : 1'b0;

    assign s_read_data_start = (tg_col_cnt == 11'd1024 && s_valid_readout) ? 1'b1 : 1'b0;

    assign seq_state_read = {wait_o , bias_enable_o, flush_enable_o, expose_enable_o, 
                            readout_enable_o, aed_enable_o , current_sof_o , current_eof_o,
                            stv_mask_o     , csi_mask_o  , sequence_done_o, busy_o,
                            current_state_o};

    always_ff @(posedge s_clk_20mhz or negedge s_seq_reset_n) begin
        if (!s_seq_reset_n) begin
            s_get_dark_dly <= 2'b00;
            s_get_bright_dly <= 2'b00;
            s_get_aed_trig_dly <= 2'b00;
            s_sequence_done_dly <= 2'b00;
            s_aed_trig <= 1'b0;
            s_wait_sync_dly <= 3'b000;
        end else begin
            s_get_dark_dly <= {s_get_dark_dly[0], get_dark};
            s_get_bright_dly <= {s_get_bright_dly[0], s_get_bright};
            s_get_aed_trig_dly <= {s_get_aed_trig_dly[0], s_aed_trig_i};
            s_sequence_done_dly <= {s_sequence_done_dly[0], sequence_done_o};
            s_aed_trig <= AED_TRIG;
            s_wait_sync_dly <= {s_wait_sync_dly[1:0], s_wait_sync};
        end
    end

    assign s_get_bright = (s_aed_mode_exist==1'b0 && (cmd_get_bright || get_bright)) ? 1'b1 : 1'b0;

    assign s_aed_mode_exist = (acq_mode_o == 3'd4 || acq_mode_o == 3'd5) ? 1'b1 : 1'b0;
    assign aed_ready_done = aed_enable_o;

    assign s_aed_trig_i = (s_aed_mode_exist) ? s_aed_trig : 1'b0;

    assign s_get_dark_hi = (s_get_dark_dly == 2'b01) ? 1'b1 : 1'b0;
    assign s_get_bright_hi = (s_get_bright_dly == 2'b01) ? 1'b1 : 1'b0;
    assign s_get_aed_trig_hi = (s_get_aed_trig_dly == 2'b01) ? 1'b1 : 1'b0;
    assign s_sequence_done_hi = (s_sequence_done_dly == 2'b01) ? 1'b1 : 1'b0;

    assign exit_signal_i = (s_exit_signal_dark || s_exit_signal_bright || s_exit_signal_aed) ? 1'b1 : 1'b0;
    assign ready_to_get_image = exit_signal_i;

    always_ff @(posedge s_clk_20mhz or negedge s_seq_reset_n) begin
        if (!s_seq_reset_n) begin
            s_exit_signal_dark <= 1'b0;
            s_exit_signal_bright <= 1'b0;
            s_exit_signal_aed <= 1'b0;
            s_exp_read_exist <= 1'b0;
        end else begin
            if (s_get_dark_hi) begin
                s_exit_signal_dark <= 1'b1;
            end else if (s_sequence_done_hi) begin
                s_exit_signal_dark <= 1'b0;
            end

            if (s_get_bright_hi) begin
                s_exit_signal_bright <= 1'b1;
            end else if (s_sequence_done_hi) begin
                s_exit_signal_bright <= 1'b0;
            end

            if (s_get_aed_trig_hi) begin
                s_exit_signal_aed <= 1'b1;
            end else if (s_sequence_done_hi) begin
                s_exit_signal_aed <= 1'b0;
            end

            if (expose_enable_o) begin
                s_exp_read_exist <= 1'b1;
            end else if (current_eof_o) begin
                s_exp_read_exist <= 1'b0;
            end
        end
    end

==================================================
    // Read RX data processing
    always_ff @(posedge eim_clk or negedge eim_rst) begin
        if (!rst_n_eim) begin
            s_axis_tdata_a <= '0;
            s_axis_tdata_b <= '0;
        end else begin
            s_axis_tdata_b <= {s_read_rx_data_b[15:11], 3'b000, s_read_rx_data_b[20:16], 3'b000,
                            s_read_rx_data_b[10:8], s_read_rx_data_b[23:21], 2'b00};
            s_axis_tdata_a <= {s_read_rx_data_a[15:11], 3'b000, s_read_rx_data_a[20:16], 3'b000,
                            s_read_rx_data_a[10:8], s_read_rx_data_a[23:21], 2'b00};
        end
    end

    // STV mask signal (used by debug_integration, kept for compatibility)
    assign s_mask_stv = (s_sync_stv_mask_o == 1'b1) ? s_tg_stv : 1'b0;

    /////////////////////////////////////////////////////////////////////////////
    // Week 7: Gate Driver Output Module (M7-1)
    /////////////////////////////////////////////////////////////////////////////
    // Gate driver output control with tri-state logic and XAO sequencing
    
    gate_driver_output gate_driver_output_inst (
        // Clock and Reset
        .clk_20mhz               (s_clk_20mhz),
        .rst_n_20mhz             (rst_n_20mhz),
        
        // Timing Generator Inputs
        .tg_stv                  (s_tg_stv),
        .tg_cpv                  (s_tg_cpv),
        .tg_oe                   (s_tg_oe),
        
        // STV Mask Control
        .stv_mask_o              (s_sync_stv_mask_o),
        
        // Gate Select Control
        .sig_gate_lr1            (sig_gate_lr1),
        
        // XAO Gate Inputs (from roic_gate_drv_gemini)
        .gate_xao_0              (gate_xao_0),
        .gate_xao_1              (gate_xao_1),
        .gate_xao_2              (gate_xao_2),
        .gate_xao_3              (gate_xao_3),
        .gate_xao_4              (gate_xao_4),
        .gate_xao_5              (gate_xao),
        
        // Sync/Repeat Counter (for XAO sequencing)
        .sync_repeat_cnt         (s_sync_repeat_cnt),
        
        // FSM Index Inputs (for XAO enable)
        .fsm_flush_index         (s_sync_fsm_flush_index),
        .fsm_back_bias_index     (s_sync_fsm_back_bias_index),
        
        // Gate Driver Outputs
        .GF_CPV                  (GF_CPV),
        .GF_STV_R                (GF_STV_R),
        .GF_STV_L                (GF_STV_L),
        .GF_OE                   (GF_OE),
        .GF_LR                   (GF_LR),
        .GF_XAO                  (GF_XAO)
    );
    /////////////////////////////////////////////////////////////////////////////
    // Week 8: Power Control Module (M8-2)
    /////////////////////////////////////////////////////////////////////////////
    // Power control for ROIC bias voltage sequencing
    // - Encapsulates power sequencing control
    // - Bias voltage control (VBIAS, AVDD1, AVDD2)
    // - Power-on initialization coordination

    power_control power_control_inst (
        // Clock and Reset
        .clk_20mhz               (s_clk_20mhz),
        .rst_n_20mhz             (rst_n_20mhz),

        // Power Initialization Control (from init module)
        .pwr_init_step1          (s_pwr_init_step1),
        .pwr_init_step2          (s_pwr_init_step2),
        .pwr_init_step3          (s_pwr_init_step3),
        .pwr_init_step4          (s_pwr_init_step4),
        .pwr_init_step5          (s_pwr_init_step5),
        .pwr_init_step6          (s_pwr_init_step6),

        // Back Bias Control (from roic_gate_drv_gemini)
        .back_bias               (s_back_bias),

        // FSM Reset Control (RST-004 fix: init_rst removed, generated by init module)
        .fsm_rst_index           (FSM_rst_index),

        // ROIC Bias Power Outputs
        .ROIC_VBIAS              (ROIC_VBIAS),
        .ROIC_AVDD1              (ROIC_AVDD1),
        .ROIC_AVDD2              (ROIC_AVDD2)
    );

    // Week 2: Standardized Reset Signals (All Active-LOW)
    
    // Internal control signals (reused)
    
    // FSM driver reset (active-LOW)
    logic fsm_drv_rst;
    assign fsm_drv_rst = rst_n_20mhz & ~FSM_rst_index;

    assign ROIC_TP_SEL  = ti_roic_tp_sel;
    assign ROIC_MCLK0   = s_clk_20mhz;
    assign ROIC_MCLK1   = s_clk_20mhz;
    assign ROIC_SYNC    = ti_roic_sync;

    // TI ROIC module interface
    //--------------------------------------------------------------------------
    // Configuration Parameters
    //--------------------------------------------------------------------------
    localparam int WORD_SIZE     = 24;     // 24-bit data word width

    //--------------------------------------------------------------------------
    // Clock and Reset Signals
    //--------------------------------------------------------------------------
    // RST-005 fix: Standardized on active-LOW reset only
    logic deser_reset_n;             // Deserializer reset (active-LOW)
    assign deser_reset_n = rst_n_20mhz;

    // Bit Alignment Signals
    //--------------------------------------------------------------------------
    logic [4:0] extra_shift [11:0];         // Additional bit alignment shift amount
    logic align_to_fclk;             // Select mode: 0=pattern detection, 1=manual
    logic align_start;               // Start alignment process
    logic [4:0] shift_out [11:0];           // Selected shift amount output
    logic [11:0] align_done;                // Alignment completion flag

    //--------------------------------------------------------------------------
    // Internal Signals
    //--------------------------------------------------------------------------

    logic [11:0] data_read_req;             // Data read request signal

    // Output signals for data validation
    logic [11:0] valid_read_enable;         // Enable signal for reading reordered data

    logic [23:0] reordered_data_a [11:0];     // Reordered data output from ti_roic_top
    logic [23:0] reordered_data_b [11:0];     // Reordered data output from ti_roic_top
    logic [11:0] reordered_valid;           // Reordered data valid flag
    logic [11:0] channel_detected;          // First channel detection signal
    logic [23:0] detected_data_out [11:0];    // Data output at first channel detection
    logic valid_read_mem;
    logic [23:0] roic_read_data;

    logic [11:0] s_even_odd_toggle_out;

    //for debug signal
    logic dbg_even_odd_toggle_out;
    // TI ROIC Integration signals
    logic s_IRST;
    logic s_SHR;
    logic s_SHS;
    logic s_LPF1;
    logic s_LPF2;
    logic s_TDEF;
    logic s_GATE_ON;
    logic s_DF_SM0;
    logic s_DF_SM1;
    logic s_DF_SM2;
    logic s_DF_SM3;
    logic s_DF_SM4;
    logic s_DF_SM5;
    logic s_rf_spi_sen;

    assign RF_SPI_SEN = {12{s_rf_spi_sen}};

    // CDC-005 Fix: gen_sync_start_3ff is now properly named
    // Both signals are in the 20MHz domain - direct connection is correct
    // The _3ff suffix is kept for compatibility but no actual CDC occurs
    assign gen_sync_start_3ff = gen_sync_start;

    // TI ROIC Integration Module
    //   - Encapsulates TI ROIC SPI and Timing Generator
    //   - Extracted from cyan_top.sv (2026-02-03)

    ti_roic_integration ti_roic_integration_inst (
        // Clocks and resets
        .clk_5mhz              (s_clk_5mhz),
        .clk_20mhz             (s_clk_20mhz),
        .deser_reset_n         (deser_reset_n),

        // TI ROIC control
        .ti_roic_reg_addr      (ti_roic_reg_addr),
        .ti_roic_reg_data      (ti_roic_reg_data),
        .ti_roic_str           (ti_roic_str),

        // Control inputs
        .s_roic_sync_in        (s_roic_sync_in),
        .s_roic_tp_sel         (s_roic_tp_sel),
        .aed_detect_skip_oe    (s_aed_detect_skip_oe_o),
        .fsm_read_index        (s_sync_fsm_read_index),
        .gen_sync_start_3ff    (gen_sync_start_3ff),

        // Counters
        .tg_row_cnt            (tg_row_cnt),
        .tg_col_cnt            (tg_col_cnt),

        // SPI outputs
        .s_roic_sdio           (s_roic_sdio),
        .RF_SPI_SCK            (RF_SPI_SCK),
        .RF_SPI_SDI            (RF_SPI_SDI[0]),
        .s_rf_spi_sen          (s_rf_spi_sen),

        // Timing outputs
        .s_roic_sync_out       (s_roic_sync_out),
        .s_roic_a_bz           (s_roic_a_bz),
        .s_tg_stv              (s_tg_stv),
        .s_tg_cpv              (s_tg_cpv),
        .s_tg_oe               (s_tg_oe),

        // Gate control outputs
        .s_IRST                (s_IRST),
        .s_SHR                 (s_SHR),
        .s_SHS                 (s_SHS),
        .s_LPF1                (s_LPF1),
        .s_LPF2                (s_LPF2),
        .s_TDEF                (s_TDEF),
        .s_GATE_ON             (s_GATE_ON),
        .s_DF_SM0              (s_DF_SM0),
        .s_DF_SM1              (s_DF_SM1),
        .s_DF_SM2              (s_DF_SM2),
        .s_DF_SM3              (s_DF_SM3),
        .s_DF_SM4              (s_DF_SM4),
        .s_DF_SM5              (s_DF_SM5)
    );

    // Week 7: ROIC Channel Array Module (M7-2)

    // TI ROIC 12-Channel Array - encapsulates ti_roic_top instances
    // - LVDS differential input interfaces for 12 channels
    // - Bit alignment and data reordering control
    // - Channel detection and valid read enable outputs
    // Extracted from cyan_top.sv (2026-02-03)
    
    roic_channel_array roic_channel_array_inst (
        // Clock and Reset
        .deser_reset_n         (deser_reset_n),       // RST-005 fix: active-LOW reset
        .data_read_clk         (s_dphy_clk_200M),      // 200MHz read clock
        
        // LVDS Differential Clock Inputs
        .fclk_in_p             (R_ROIC_FCLKo_p),       // Frame clock positive
        .fclk_in_n             (R_ROIC_FCLKo_n),       // Frame clock negative
        .clk_in_p              (R_ROIC_DCLKo_p),       // Data clock positive
        .clk_in_n              (R_ROIC_DCLKo_n),       // Data clock negative
        
        // LVDS Differential Data Inputs
        .data_in_p             (R_DOUTA_H),            // Data positive
        .data_in_n             (R_DOUTA_L),            // Data negative
        
        // Bit Alignment Control
        .align_to_fclk         (align_to_fclk),        // Alignment mode select
        .align_start           (align_start),          // Start alignment
        .extra_shift           (extra_shift),          // Additional shift per channel
        
        // Test Pattern Control
        .en_test_pattern_col   (en_test_pattern_col),  // Column pattern enable
        .en_test_pattern_row   (en_test_pattern_row),  // Row pattern enable
        
        // Data Reordering Control
        .sync                  (s_roic_sync_out),      // Sync for reordering
        
        // Data Read Control
        .data_read_req         (data_read_req),        // Read request per channel
        
        // Bit Alignment Outputs
        .shift_out             (shift_out),            // Shift amount per channel
        .align_done            (align_done),           // Alignment complete
        
        // Data Read Enable Outputs
        .valid_read_enable     (valid_read_enable),    // Read enable
        
        // Reordered Data Outputs
        .reordered_data_a      (reordered_data_a),     // Data A
        .reordered_data_b      (reordered_data_b),     // Data B
        .reordered_valid       (reordered_valid),      // Data valid
        
        // Debug Outputs
        .even_odd_toggle_out   (s_even_odd_toggle_out), // Toggle output
        .roic_even_odd_out     (s_roic_even_odd_out),   // ROIC even/odd
        
        // Channel Detection Outputs
        .detected_data_out     (detected_data_out),    // Detected data
        .channel_detected      (channel_detected)      // Detection flag
    );

    assign s_sum_channel_detected = |(channel_detected & align_done);

    // //========================================================================
    // // IDELAYCTRL Instance for Deser_by8_group
    // //========================================================================
    // (* IODELAY_GROUP = "Deser_by8_group" *)
    // IDELAYCTRL idelayctrl_inst (
    //     .RDY        (),
    //     .REFCLK     (s_axi_clk_200M),
    //     .RST        (s_reset)
    // );

    /////////////////////////////////////////////////////////////////////////////
    // Week 5: Data Path Integration Module (TOP-001 Phase 2)
    /////////////////////////////////////////////////////////////////////////////
    
    // Data path integration - encapsulates read_data_mux and data processing
    data_path_integration data_path_inst (
        // Clocks and resets
        .clk_100mhz              (s_clk_100mhz),
        .eim_clk                 (eim_clk),
        .rst_n_100mhz            (rst_n_100mhz),
        .rst_n_eim               (rst_n_eim),
        .dphy_clk_200M           (s_dphy_clk_200M),
        
        // CSI control
        .csi_done                (s_csi_done),
        
        // Image acquisition control
        .dummy_get_image         (dummy_get_image),
        .dsp_image_height        (dsp_image_height),
        .max_v_count             (max_v_count),
        .max_h_count             (max_h_count),
        
        // FSM control
        .FSM_aed_read_index      (FSM_aed_read_index),
        .read_data_start         (s_read_data_start),
        .FSM_read_index          (s_valid_readout),
        
        // ROIC data inputs (from TI ROIC)
        .roic_read_data_a        (reordered_data_a),
        .roic_read_data_b        (reordered_data_b),
        .reordered_valid         (reordered_valid),
        
        // AXI-Stream interface (to MIPI)
        .read_axis_tready        (s_read_axis_tready),
        .read_axis_tready_in     (),
        .read_axis_tlast         (s_read_axis_tlast),
        .read_data_valid         (s_read_axis_tvalid),
        .read_data_out_a         (s_read_rx_data_a),
        .read_data_out_b         (s_read_rx_data_b),
        
        // Frame control
        .read_frame_start        (s_read_frame_start),
        .read_frame_reset        (s_read_frame_reset),
        
        // Data read request (to TI ROIC)
        .data_read_req           (data_read_req),
        
        // Valid data outputs (for status)
        .valid_roic_data         (valid_roic_data),
        .valid_read_mem          (valid_read_mem)
    );

    assign PREP_ACK = PREP_REQ;

    assign s_config_done_i = (seq_lut_config_done || s_reg_roic_sync) ? 1'b1 : 1'b0;

    always_ff @(posedge s_clk_20mhz or negedge rst) begin
        if (~rst) begin
            s_test_cnt <= '0;
        end else begin
            s_test_cnt <= s_test_cnt + 1'b1;
        end
    end

    dcdc_clk dcdc_clk_inst (
        .clk        (s_clk_20mhz),
        .reset_n    (rst_n_20mhz),
        .clk_1M_o   (s_clk_1mhz),
        .clk_5M_o   (s_clk_5mhz)
    );

    assign SWITCH_SYNC = s_clk_1mhz;

    // =====================================
    // Controls signals
    // =====================================

    assign s_roic_sdio = RF_SPI_SDO;

    // Week 8: Control Signal Multiplexer Module (M8-1)

    // Control signal multiplexing between register and FSM sources
    // - Extracted from cyan_top.sv (2026-02-03)
    // - Handles mux between register-controlled and FSM-controlled signals
    // - Deserializer reset-based signal synchronization
    
    control_signal_mux control_signal_mux_inst (
        // Clock and Reset
        .clk_20mhz               (s_clk_20mhz),
        .deser_reset             (deser_reset),
        
        // TI ROIC Integration Outputs (pass-through/registered)
        .ti_roic_sync_out        (s_roic_sync_out),
        
        // Register-based Control Inputs (from reg_map_integration)
        .reg_tp_sel              (s_reg_tp_sel),
        .reg_roic_sync           (s_reg_roic_sync),
        
        // FSM-based Control Inputs (from sequencer via sync_processing)
        .fsm_wait_tp_sel         (s_wait_tp_sel),
        .fsm_wait_roic_sync      (s_wait_roic_sync),
        
        // Final Control Outputs (to TI ROIC Integration)
        .roic_sync_in            (s_roic_sync_in),
        .roic_tp_sel             (s_roic_tp_sel),
        
        // Final Control Outputs (to Top-Level ROIC Interface)
        .ti_roic_sync            (ti_roic_sync),
        .ti_roic_tp_sel          (ti_roic_tp_sel)
    );

    // Week 6: Sync Processing Module (M6-2)

    // Sync signal processing and pipeline synchronization
    // - Edge detection for gen_sync_start
    // - Column counter for image width tracking
    // - FSM signal synchronization/pipeline

    
    sync_processing sync_processing_inst (
        // Clock and Reset
        .clk_20mhz                  (s_clk_20mhz),
        .rst_n_20mhz                (rst_n_20mhz),
        
        // Control Inputs
        .gen_sync_start             (gen_sync_start),
        .config_done_i              (s_config_done_i),
        
        // Sequencer/FSM Inputs (to be captured/synchronized)
        .active_repeat_count_o      (active_repeat_count_o),
        .stv_mask_o                 (stv_mask_o),
        .csi_mask_o                 (csi_mask_o),
        .current_repeat_count_o     (current_repeat_count_o),
        .FSM_read_index             (FSM_read_index),
        .FSM_flush_index            (FSM_flush_index),
        .FSM_back_bias_index        (FSM_back_bias_index),
        
        // Synchronized Outputs
        .gen_sync_start_rise        (s_gen_sync_start_rise),
        .sync_repeat_cnt            (s_sync_repeat_cnt),
        .sync_col_cnt               (s_sync_col_cnt),
        .sync_stv_mask_o            (s_sync_stv_mask_o),
        .sync_csi_mask_o            (s_sync_csi_mask_o),
        .sync_current_repeat_count_o(s_sync_current_repeat_count_o),
        .sync_config_done           (s_sync_config_done),
        .sync_fsm_read_index        (s_sync_fsm_read_index),
        .sync_fsm_flush_index       (s_sync_fsm_flush_index),
        .sync_fsm_back_bias_index   (s_sync_fsm_back_bias_index)
    );

    // Sync Start Latch (CDC-005 Fix)

    // gen_sync_start is a level signal that indicates sync operation is active
    // - Set on rising edge of sync start pulse
    // - Reset on sequence completion
    // All logic is in the 20MHz clock domain - no CDC required

    
    always_ff @(posedge s_clk_20mhz or negedge rst_n_20mhz) begin
        if (!rst_n_20mhz) begin
            gen_sync_start <= 1'b0;
        end else begin
            // Set on sync start pulse, reset on sequence done
            if (s_gen_sync_start_rise) begin
                gen_sync_start <= 1'b1;
            end else if (sequence_done_o) begin
                gen_sync_start <= 1'b0;
            end
        end
    end

    /////////////////////////////////////////////////////////////////////////////
    // Week 6: Debug Integration Module (M6-1)
    /////////////////////////////////////////////////////////////////////////////
    // Debug and LED integration - handles LED state indication and debug signals
    
    debug_integration debug_integration_inst (
        // Clock and reset
        .clk_20mhz              (s_clk_20mhz),
        .rst_n_20mhz            (rst_n_20mhz),
        
        // LED select control
        .state_led_ctr          (s_state_led_ctr),
        
        // FSM state inputs
        .FSM_idle_index         (FSM_idle_index),
        .FSM_read_index         (FSM_read_index),
        .FSM_exp_index          (FSM_exp_index),
        .FSM_aed_read_index     (FSM_aed_read_index),
        .FSM_flush_index        (s_sync_fsm_flush_index),
        .FSM_back_bias_index    (s_sync_fsm_back_bias_index),
        .FSM_wait_index         (FSM_wait_index),
        .FSM_rst_index          (FSM_rst_index),
        
        // Validity signals
        .valid_roic_data        (valid_roic_data),
        .valid_read_mem         (valid_read_mem),
        .valid_readout          (s_valid_readout),
        
        // ROIC channel detection
        .channel_detected       (channel_detected),
        
        // AXI-Stream interface status
        .read_frame_start       (s_read_frame_start),
        .read_frame_reset       (s_read_frame_reset),
        .read_axis_tvalid       (s_read_axis_tvalid),
        .read_axis_tlast        (s_read_axis_tlast),
        .read_axis_tready       (s_read_axis_tready),
        
        // TI ROIC timing signals
        .sig_irst               (s_IRST),
        .sig_shr                (s_SHR),
        .sig_shs                (s_SHS),
        .sig_lpf1               (s_LPF1),
        .sig_lpf2               (s_LPF2),
        .sig_tdef               (s_TDEF),
        .sig_gate_on            (s_GATE_ON),
        .sig_df_sm0             (s_DF_SM0),
        .sig_df_sm1             (s_DF_SM1),
        .sig_df_sm2             (s_DF_SM2),
        .sig_df_sm3             (s_DF_SM3),
        .sig_df_sm4             (s_DF_SM4),
        .sig_df_sm5             (s_DF_SM5),
        
        // ROIC control signals
        .roic_sdio_bit0         (s_roic_sdio[0]),
        .sum_channel_detected   (s_sum_channel_detected),
        .gen_sync_start         (gen_sync_start),
        .roic_sync_in           (s_roic_sync_in),
        .ti_roic_sync           (ti_roic_sync),
        
        // Acquisition and exposure signals
        .aed_trig               (s_aed_trig),
        .aed_trig_i             (s_aed_trig_i),
        .aed_mode_exist         (s_aed_mode_exist),
        .exit_signal            (exit_signal_i),
        .panel_stable           (panel_stable_o),
        .exp_read_exist         (s_exp_read_exist),
        .get_dark_hi            (s_get_dark_hi),
        .exit_signal_dark       (s_exit_signal_dark),
        .get_bright_hi          (s_get_bright_hi),
        .exit_signal_bright     (s_exit_signal_bright),
        .get_aed_trig_hi        (s_get_aed_trig_hi),
        .exit_signal_aed        (s_exit_signal_aed),
        .get_bright             (s_get_bright),
        
        // Sequencer status signals
        .sequence_done          (sequence_done_o),
        .sequence_done_hi       (s_sequence_done_hi),
        .state_exit_flag        (s_state_exit_flag),
        .readout_wait           (s_readout_wait),
        
        // Timing and mask signals
        .tg_stv                 (s_tg_stv),
        .mask_stv               (s_mask_stv),
        .back_bias              (s_back_bias),
        .stv_mask               (stv_mask_o),
        .csi_mask               (csi_mask_o),
        
        // Clock indicators
        .clk_5mhz               (s_clk_5mhz),
        .clk_1mhz               (s_clk_1mhz),
        
        // Ready status
        .aed_ready_done         (aed_ready_done),
        
        // Test counter
        .test_cnt               (s_test_cnt),
        
        // Debug data inputs
        .dbg_roic_1st_channel   (detected_data_out[0][7]),
        .dbg_roic_even_odd      (detected_data_out[0][6]),
        
        // Outputs
        .STATE_LED1             (STATE_LED1),
        .DEBUG_SIG              (DEBUG_SiG)
    );

endmodule
