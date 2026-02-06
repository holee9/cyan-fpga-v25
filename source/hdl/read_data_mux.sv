`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// File: read_data_mux.sv
// Date: 2026.02.04
// Designer: drake.lee
// Description: 12-Channel Data Multiplexer with CDC (Refactored - Phase 8)
//              - Integrates 3 new sub-modules:
//                1. async_fifo_controller (CDC-003 fix)
//                2. data_path_selector (12-channel mux)
//                3. timing_generator (HSYNC/VSYNC/tlast)
// Revision History:
//    2025.05.19 - Initial SystemVerilog conversion
//    2026.02.04 - Refactored to use sub-modules (Phase 8 - M8-4/5/6)
///////////////////////////////////////////////////////////////////////////////

module read_data_mux (
    input  logic        sys_clk,
    input  logic        sys_rst,

    input  logic        eim_clk,
    input  logic        eim_rst,
    input  logic        rst_n_eim,  // Synchronized reset from top level

    input  logic        csi_done,

    input  logic        dummy_get_image,
    output logic        exist_get_image,

    input  logic [15:0]  dsp_image_height,
    input  logic [15:0]  max_v_count,
    input  logic [15:0]  max_h_count,

    input  logic        FSM_aed_read_index,
    input  logic        FSM_read_index,
    input  logic        read_data_start,

    input  wire [23:0]  roic_read_data_a [11:0],
    input  wire [23:0]  roic_read_data_b [11:0],

    input  logic        valid_read_mem,

    input  logic        read_axis_tready,
    output logic        read_axis_tlast,
    output logic        read_data_valid,
    output logic [23:0]  read_data_out_a,
    output logic [23:0]  read_data_out_b,
    output logic        read_frame_start,
    output logic        read_frame_reset,
    output logic [11:0]  data_read_req
);

    //==========================================================================
    // Parameters
    //==========================================================================
    localparam [15:0] VALID_NUM_ROIC_BURST = 16'h0020;
    localparam [7:0]  NUM_ROIC_CHANNEL      = 8'b01111111;  // 127

    //==========================================================================
    // Internal Signals - Counters
    //==========================================================================
    logic [15:0] s_h_count;
    logic [15:0] s_v_count;
    logic [15:0] s_max_h_count;
    logic [15:0] s_max_v_count;

    assign s_max_h_count = max_h_count;
    assign s_max_v_count = max_v_count;

    //==========================================================================
    // Internal Signals - Timing Generator Outputs
    //==========================================================================
    logic        sig_hsync_int;
    logic        sig_vsync_int;
    logic        hi_vsync_int;
    logic        lo_hsync_int;
    logic        lo_vsync_int;
    logic        s_h_sync;
    logic        s_v_sync;
    logic        s_axis_tlast_int;
    logic        s_tuser_0_int;
    logic        read_frame_reset_int;
    logic        read_frame_start_int;
    logic [11:0] hsync_cnt_int;

    //==========================================================================
    // Internal Signals - Reset
    //==========================================================================
    logic        tx_eim_rst_n;
    logic        tx_sys_rst_n;
    logic        internal_reset;
    logic        rst_hsync_cnt_dly;

    assign internal_reset = rst_hsync_cnt_dly || hi_vsync_int || !tx_sys_rst_n;

    //==========================================================================
    // Internal Signals - AXI-Stream
    //==========================================================================
    logic        s_axis_tvalid;
    logic        s_axis_tvalid_1d;
    logic        s_axis_tvalid_2d;
    logic        s_axis_tvalid_3d;
    logic        s_axis_tlast_1d;
    logic        s_axis_tlast_2d;
    logic        s_axis_tlast_3d;
    logic        s_read_axis_tready;

    assign s_read_axis_tready = read_axis_tready;

    //==========================================================================
    // Internal Signals - Memory Control
    //==========================================================================
    logic [11:0] read_mem;
    logic [11:0] read_mem_1d;
    logic [11:0] read_mem_2d;
    logic [11:0] end_read_mem;
    logic [11:0] start_read_mem;
    logic        read_mem_index;

    //==========================================================================
    // Internal Signals - Dummy Mode
    //==========================================================================
    logic        s_dummy_start;
    logic        s_dummy_get_image_1d;
    logic        s_dummy_get_image_2d;
    logic        s_dummy_valid;
    logic        s_dummy_read_index;
    logic [15:0] s_dummy_valid_count;

    //==========================================================================
    // Internal Signals - FSM Synchronization
    //==========================================================================
    logic        FSM_read_index_eim_1d;
    logic        FSM_read_index_eim_2d;
    logic        FSM_read_index_eim_3d;
    logic        FSM_read_index_eim_4d;
    logic        FSM_read_index_eim_5d;
    logic        FSM_read_index_sys_1d;
    logic        FSM_read_index_sys_2d;

    //==========================================================================
    // Internal Signals - Test Pattern
    //==========================================================================
    logic [15:0] test_pattern_col_1 [11:0] = '{
        16'h0001, 16'h0101, 16'h0201, 16'h0301, 16'h0401, 16'h0501,
        16'h0601, 16'h0701, 16'h0801, 16'h0901, 16'h0a01, 16'h0b01
    };

    logic [15:0] test_pattern_col_2 [11:0] = '{
        16'h0002, 16'h0102, 16'h0202, 16'h0302, 16'h0402, 16'h0502,
        16'h0602, 16'h0702, 16'h0802, 16'h0902, 16'h0a02, 16'h0b02
    };

    //==========================================================================
    // Internal Signals - Data Path
    //==========================================================================
    logic [23:0] s_read_data_a_eim;
    logic [23:0] s_read_data_b_eim;
    logic        s_read_data_valid_eim;
    logic [23:0] s_read_data_a_sys;
    logic [23:0] s_read_data_b_sys;
    logic        s_read_data_valid_sys;
    logic        s_fifo_full;
    logic        s_fifo_empty;

    //==========================================================================
    // Horizontal/Vertical Counter
    //==========================================================================
    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!rst_n_eim) begin
            s_h_count <= 16'h0000;
            s_v_count <= 16'h0000;
        end else if (internal_reset) begin
            s_h_count <= 16'h0000;
            s_v_count <= 16'h0000;
            if (s_h_count == (s_max_h_count - 1)) begin
                if (s_v_count == (s_max_v_count - 1)) begin
                    s_h_count <= 16'h0000;
                    s_v_count <= 16'h0000;
                end else begin
                    s_h_count <= 16'h0000;
                    s_v_count <= s_v_count + 1;
                end
            end else begin
                s_h_count <= s_h_count + 1;
            end
        end
    end

    //==========================================================================
    // Dummy Mode Control
    //==========================================================================
    always_ff @(posedge eim_clk or negedge eim_rst) begin
        if (!eim_rst) begin
            s_dummy_get_image_1d <= 1'b0;
            s_dummy_get_image_2d <= 1'b0;
        end else begin
            s_dummy_get_image_1d <= dummy_get_image;
            s_dummy_get_image_2d <= s_dummy_get_image_1d;
        end
    end

    assign s_dummy_start = s_dummy_get_image_1d && !s_dummy_get_image_2d;

    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!rst_n_eim) begin
            s_dummy_valid <= 1'b0;
            s_dummy_valid_count <= '0;
        end else begin
            if (s_dummy_start) begin
                s_dummy_valid <= 1'b1;
            end else if ((s_v_count == (s_max_v_count - 1)) && (s_h_count == (s_max_h_count - 1))) begin
                s_dummy_valid <= 1'b0;
            end
            if (s_dummy_valid) begin
                s_dummy_valid_count <= s_dummy_valid_count + 1'b1;
            end
        end
    end

    assign exist_get_image = s_dummy_valid;
    assign s_dummy_read_index = (s_dummy_valid_count[11] == 0) ||
                               (s_dummy_valid_count[11] && s_h_count > 0 && s_h_count <= (max_h_count - 1)) ?
                               s_dummy_valid : 1'b0;

    //==========================================================================
    // Reset Generation
    //==========================================================================
    assign tx_eim_rst_n = !(FSM_read_index_eim_1d && !FSM_read_index_eim_2d && !FSM_aed_read_index);
    assign tx_sys_rst_n = !(FSM_read_index_sys_1d && !FSM_read_index_sys_2d && !FSM_aed_read_index);

    //==========================================================================
    // FSM Synchronization
    //==========================================================================
    always_ff @(posedge sys_clk or negedge sys_rst) begin
        if (!sys_rst) begin
            FSM_read_index_sys_1d <= 1'b0;
            FSM_read_index_sys_2d <= 1'b0;
        end else begin
            FSM_read_index_sys_1d <= FSM_read_index;
            FSM_read_index_sys_2d <= FSM_read_index_sys_1d;
        end
    end

    always_ff @(posedge eim_clk or negedge eim_rst) begin
        if (!eim_rst) begin
            FSM_read_index_eim_1d <= 1'b0;
            FSM_read_index_eim_2d <= 1'b0;
            FSM_read_index_eim_3d <= 1'b0;
            FSM_read_index_eim_4d <= 1'b0;
            FSM_read_index_eim_5d <= 1'b0;
        end else begin
            FSM_read_index_eim_1d <= FSM_read_index;
            FSM_read_index_eim_2d <= FSM_read_index_eim_1d;
            FSM_read_index_eim_3d <= FSM_read_index_eim_2d;
            FSM_read_index_eim_4d <= FSM_read_index_eim_3d;
            FSM_read_index_eim_5d <= FSM_read_index_eim_4d;
        end
    end

    //==========================================================================
    // AXI-Stream Valid Generation
    //==========================================================================
    logic        s_sync_gen_en;
    logic        s_valid_read_mem;
    logic [11:0] s_axis_read_mem;

    assign s_valid_read_mem = s_axis_tvalid & s_read_axis_tready & valid_read_mem;
    assign s_sync_gen_en = ((read_mem_index || s_dummy_read_index) && s_read_axis_tready) ? 1'b1 : 1'b0;

    assign s_axis_tvalid = (s_sync_gen_en && !s_axis_tlast_int && (s_h_count == 16'h0000)) ? 1'b1 :
                           (s_sync_gen_en && s_h_sync) ? 1'b1 : 1'b0;

    //==========================================================================
    // Memory Read Control
    //==========================================================================
    assign read_mem_index = |read_mem;

    genvar i;
    generate
        for (i = 0; i < 12; i++) begin : gen_end_read_mem
            assign end_read_mem[i] = (read_mem[i] && (s_valid_read_mem && ({1'b0, s_h_count[6:0]} == NUM_ROIC_CHANNEL))) ? 1'b1 : 1'b0;
        end
    endgenerate

    assign start_read_mem[0] = sig_hsync_int;

    logic s_hsync_FSM_read_index;
    logic s_hsync_dly_FSM_read_index;

    assign s_hsync_FSM_read_index = (FSM_read_index || s_hsync_dly_FSM_read_index) ? 1'b1 : 1'b0;

    always_ff @(posedge eim_clk or negedge eim_rst) begin
        if (!eim_rst) begin
            s_hsync_dly_FSM_read_index <= 1'b0;
        end else begin
            if (lo_hsync_int)
                s_hsync_dly_FSM_read_index <= FSM_read_index;
        end
    end

    generate
        for (i = 0; i < 12; i++) begin : gen_start_read_mem_full
            assign s_axis_read_mem[i] = (s_axis_tvalid) ? read_mem[i] : 1'b0;
            assign data_read_req[i] = (csi_done && s_hsync_FSM_read_index) ? s_axis_read_mem[i] : 1'b0;
        end
    endgenerate

    //==========================================================================
    // Memory Read Flag Pipeline
    //==========================================================================
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || tx_eim_rst_n) begin
            read_mem <= '0;
            read_mem_1d <= '0;
            read_mem_2d <= '0;
            s_axis_tvalid_1d <= 1'b0;
            s_axis_tvalid_2d <= 1'b0;
            s_axis_tvalid_3d <= 1'b0;
            s_axis_tlast_1d <= 1'b0;
            s_axis_tlast_2d <= 1'b0;
            s_axis_tlast_3d <= 1'b0;
            read_axis_tlast <= 1'b0;
        end else begin
            for (int k = 0; k < 12; k++) begin
                if (end_read_mem[k])
                    read_mem[k] <= 1'b0;
                else if (start_read_mem[k])
                    read_mem[k] <= 1'b1;
            end
            read_mem_1d <= read_mem;
            read_mem_2d <= read_mem_1d;
            s_axis_tvalid_1d <= s_axis_tvalid;
            s_axis_tvalid_2d <= s_axis_tvalid_1d;
            s_axis_tvalid_3d <= s_axis_tvalid_2d;
            s_axis_tlast_1d <= s_axis_tlast_int;
            s_axis_tlast_2d <= s_axis_tlast_1d;
            s_axis_tlast_3d <= s_axis_tlast_2d;
            read_axis_tlast <= s_axis_tlast_3d;
        end
    end

    //==========================================================================
    // Phase 8: Data Path Selector Integration (M8-5)
    //==========================================================================
    // 12-channel data multiplexer with test pattern support

    data_path_selector data_path_sel_inst (
        // Clock and reset
        .eim_clk                (eim_clk),
        .eim_rst                (eim_rst),
        .tx_eim_rst_n           (tx_eim_rst_n),

        // Channel selection
        .read_mem               (read_mem),
        .read_mem_2d            (read_mem_2d),

        // ROIC data inputs (12 channels)
        .roic_read_data_a       (roic_read_data_a),
        .roic_read_data_b       (roic_read_data_b),

        // Test pattern control
        .en_test_pattern_col    (1'b0),  // Test pattern disabled
        .test_pattern_col_1     (test_pattern_col_1),
        .test_pattern_col_2     (test_pattern_col_2),
        .s_dummy_valid          (s_dummy_valid),

        // Data outputs
        .s_read_data_a_eim      (s_read_data_a_eim),
        .s_read_data_b_eim      (s_read_data_b_eim),
        .s_read_data_valid_eim  (s_read_data_valid_eim)
    );

    //==========================================================================
    // Phase 8: Async FIFO Controller Integration (M8-4)
    //==========================================================================
    // CDC-003 Fix: Clock domain crossing from eim_clk to sys_clk

    async_fifo_controller async_fifo_ctrl_inst (
        // Write clock domain (eim_clk)
        .eim_clk                (eim_clk),
        .rst_n_eim              (rst_n_eim),

        // Read clock domain (sys_clk)
        .sys_clk                (sys_clk),
        .sys_rst                (sys_rst),

        // Data inputs (eim_clk domain)
        .s_read_data_a_eim      (s_read_data_a_eim),
        .s_read_data_b_eim      (s_read_data_b_eim),
        .s_read_data_valid_eim  (s_read_data_valid_eim),

        // Control signals
        .read_axis_tready       (read_axis_tready),

        // Data outputs (sys_clk domain)
        .s_read_data_a_sys      (s_read_data_a_sys),
        .s_read_data_b_sys      (s_read_data_b_sys),
        .s_read_data_valid_sys  (s_read_data_valid_sys),

        // Status flags
        .s_fifo_full            (s_fifo_full),
        .s_fifo_empty           (s_fifo_empty)
    );

    // CDC-003: Output assignments from sys_clk domain
    assign read_data_out_a = s_read_data_a_sys;
    assign read_data_out_b = s_read_data_b_sys;
    assign read_data_valid = s_read_data_valid_sys;

    //==========================================================================
    // Phase 8: Timing Generator Integration (M8-6)
    //==========================================================================
    // HSYNC/VSYNC/tlast generation

    // Additional timing signals needed by timing_generator
    logic        sig_hsync_1d;
    logic        sig_hsync_2d;
    logic [15:0] s_tuser_0_dly;
    logic        s_tuser_0;

    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || tx_eim_rst_n) begin
            sig_hsync_1d <= 1'b0;
            sig_hsync_2d <= 1'b0;
        end else begin
            sig_hsync_1d <= sig_hsync_int;
            sig_hsync_2d <= sig_hsync_1d;
        end
    end

    assign s_tuser_0 = (s_sync_gen_en && s_h_count==16'h0000 && s_v_count==16'h0000) ? 1'b1 : 1'b0;
    assign s_v_sync = (s_v_count > '0 && s_v_count <= s_max_v_count) ? 1'b1 : 1'b0;
    assign s_h_sync = (s_h_count > '0 && s_h_count <= s_max_h_count) ? 1'b1 : 1'b0;

    // TUSER delay line
    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || tx_eim_rst_n) begin
            s_tuser_0_dly <= '0;
        end else begin
            s_tuser_0_dly <= {s_tuser_0_dly[14:0], s_tuser_0};
        end
    end

    timing_generator timing_gen_inst (
        // Clock and reset
        .eim_clk                (eim_clk),
        .eim_rst                (eim_rst),
        .tx_eim_rst_n           (tx_eim_rst_n),
        .rst_n_eim              (rst_n_eim),

        // Configuration
        .max_h_count            (s_max_h_count),
        .max_v_count            (s_max_v_count),
        .dsp_image_height       (dsp_image_height),

        // Control inputs
        .read_data_start        (read_data_start),
        .FSM_read_index_eim     (FSM_read_index),
        .FSM_aed_read_index     (FSM_aed_read_index),
        .read_axis_tready       (read_axis_tready),

        // Counters (external)
        .s_h_count              (s_h_count),
        .s_v_count              (s_v_count),

        // HSYNC outputs
        .sig_hsync              (sig_hsync_int),
        .hsync_keep_hi          (),
        .hsync_keep_hi_cnt      (),
        .hsync_cnt              (hsync_cnt_int),

        // VSYNC outputs
        .sig_vsync              (sig_vsync_int),
        .hi_vsync               (hi_vsync_int),
        .vsync_keep_hi          (),
        .vsync_keep_hi_cnt      (),

        // Frame timing outputs
        .s_axis_tlast           (s_axis_tlast_int),
        .s_tuser_0              (s_tuser_0),
        .read_frame_reset       (read_frame_reset_int),
        .read_frame_start       (read_frame_start_int)
    );

    // Assign outputs from timing_generator
    assign read_frame_reset = read_frame_reset_int;
    assign read_frame_start = s_tuser_0_dly[11];

    // Additional timing signals not in timing_generator
    logic        up_hsync_keep_hi;
    logic        down_hsync_keep_hi;
    logic        hsync_keep_hi;
    logic [3:0]  hsync_keep_hi_cnt;
    logic        vsync_keep_hi;
    logic [3:0]  vsync_keep_hi_cnt;
    logic        up_vsync_keep_hi;
    logic        down_vsync_keep_hi;
    logic        inc_hsync_cnt;
    logic        rst_hsync_cnt;

    assign inc_hsync_cnt = !sig_hsync_1d && sig_hsync_2d;
    assign rst_hsync_cnt = (inc_hsync_cnt && hsync_cnt_int == (dsp_image_height[11:0] - 12'h1)) ? 1'b1 : 1'b0;

    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || tx_eim_rst_n) begin
            rst_hsync_cnt_dly <= 1'b0;
        end else begin
            rst_hsync_cnt_dly <= rst_hsync_cnt;
        end
    end

    assign up_vsync_keep_hi = rst_hsync_cnt_dly;
    assign down_vsync_keep_hi = sig_vsync_int && vsync_keep_hi && (vsync_keep_hi_cnt == 4'b1111);

    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || tx_eim_rst_n) begin
            vsync_keep_hi <= 1'b0;
        end else begin
            if (down_vsync_keep_hi)
                vsync_keep_hi <= 1'b0;
            else if (up_vsync_keep_hi)
                vsync_keep_hi <= 1'b1;
        end
    end

    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || tx_eim_rst_n) begin
            vsync_keep_hi_cnt <= 4'b0000;
        end else begin
            if (!vsync_keep_hi)
                vsync_keep_hi_cnt <= 4'b0000;
            else if (vsync_keep_hi)
                vsync_keep_hi_cnt <= vsync_keep_hi_cnt + 1'b1;
        end
    end

    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || tx_eim_rst_n) begin
            lo_vsync_int <= 1'b0;
        end else begin
            lo_vsync_int <= down_vsync_keep_hi;
        end
    end

    assign up_hsync_keep_hi = end_read_mem[11];
    assign down_hsync_keep_hi = sig_hsync_int && hsync_keep_hi && (hsync_keep_hi_cnt == 4'b0101);

    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || tx_eim_rst_n) begin
            hsync_keep_hi <= 1'b0;
            hsync_keep_hi_cnt <= '0;
        end else begin
            if (up_hsync_keep_hi) begin
                hsync_keep_hi <= 1'b1;
            end else if (down_hsync_keep_hi) begin
                hsync_keep_hi <= 1'b0;
            end
            if (!hsync_keep_hi) begin
                hsync_keep_hi_cnt <= 4'h0;
            end else begin
                hsync_keep_hi_cnt <= hsync_keep_hi_cnt + 1'b1;
            end
        end
    end

    always_ff @(posedge eim_clk or posedge eim_rst) begin
        if (eim_rst || tx_eim_rst_n) begin
            lo_hsync_int <= 1'b0;
        end else begin
            lo_hsync_int <= down_hsync_keep_hi;
        end
    end

endmodule
