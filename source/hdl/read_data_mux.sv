`timescale 1ns / 1ps

// -------------------------------------------------------------------
// Module: read_data_mux
// Description: SystemVerilog conversion of read_data_mux
// -------------------------------------------------------------------

module read_data_mux (
    input  logic        sys_clk,
    input  logic        sys_rst,
    
    input  logic        eim_clk,
    input  logic        eim_rst,
    input  logic        rst_n_eim,  // Week 2: Synchronized reset from top level

//    input  logic        seq_reset,

    input  logic        csi_done,
    
    input  logic        dummy_get_image,
    output logic        exist_get_image,
    
//    input  logic        get_dark,
//    input  logic        get_bright,
    
    input  logic [15:0] dsp_image_height,
    input  logic [15:0] max_v_count,
    input  logic [15:0] max_h_count,
    
//    input  logic        en_test_pattern_col,
//    input  logic        en_test_pattern_row,
    
    input  logic        FSM_aed_read_index,
    input  logic        FSM_read_index,
    input  logic        read_data_start,
    
//    input  logic        valid_roic_data,
    input  wire [23:0] roic_read_data_a [11:0],
    input  wire [23:0] roic_read_data_b [11:0],
    
    input  logic        valid_read_mem,
    
    input  logic        read_axis_tready,
    output logic        read_axis_tlast,
    output logic        read_data_valid,
    output logic [23:0] read_data_out_a,
    output logic [23:0] read_data_out_b,
    output logic        read_frame_start,
    output logic        read_frame_reset,
//    output logic [7:0]  read_addr_cnt,
    output logic [11:0] data_read_req
    
//    output logic        read_vsync,
//    output logic        read_hsync
);

    // Constants
    localparam [15:0] VALID_NUM_ROIC_BURST = 16'h0020;
    localparam [7:0]  NUM_ROIC_CHANNEL = 8'b01111111;    // 127 in binary format
    localparam [9:0]  MEM_HEIGHT = 10'b0011111111;       // 255 in binary format

    // ROIC size constants
    localparam [9:0] UP_XROIC_SIZE[0:5] = '{
        10'b0001111100, 10'b0011111100, 10'b0101111100,
        10'b0111111100, 10'b1001111100, 10'b1011111100
    };
    
    localparam [9:0] DN_XROIC_SIZE[0:5] = '{
        10'b0001111111, 10'b0011111111, 10'b0101111111,
        10'b0111111111, 10'b1001111111, 10'b1011111111
    };
    
    // Internal signals
    logic        tx_eim_rst_n;      
    // Reset signal for tx path
//    logic        valid_read_roic_data;
    logic [15:0] s_h_count;   // Horizontal counter
    logic [15:0] s_v_count;   // Vertical counter
    logic [15:0] s_max_h_count; // Maximum horizontal count (768)
    logic [15:0] s_max_v_count; // Maximum vertical count (1024)
    
    logic s_sync_gen_en;

    // AXI-Stream interface signals
    logic        s_axis_tvalid;          // AXI Stream valid signal
    logic        s_axis_tvalid_1d;
    logic        s_axis_tvalid_2d;
    logic        s_axis_tvalid_3d;
    logic        s_read_axis_tready;     // AXI Stream ready signal
    logic        s_axis_tlast;
    logic        s_axis_tlast_1d;
    logic        s_axis_tlast_2d;
    logic        s_axis_tlast_3d;
    
    
    // Memory interface signals
    // logic [31:0] read_mem_data [11:0];   // Memory read data (1-based indexing)
    logic       s_valid_read_mem;
    logic       s_dummy_read_index;
    logic [11:0] s_axis_read_mem;
    

    // Memory read addressing
    logic        read_mem_index; // Memory read index signal

    // Test pattern signals using arrays for better organization
    logic [15:0] test_pattern_col_1 [11:0] = '{
        16'h0001, 16'h0101, 16'h0201, 16'h0301, 16'h0401, 16'h0501,
        16'h0601, 16'h0701, 16'h0801, 16'h0901, 16'h0a01, 16'h0b01
    };
    
    logic [15:0] test_pattern_col_2 [11:0] = '{
        16'h0002, 16'h0102, 16'h0202, 16'h0302, 16'h0402, 16'h0502,
        16'h0602, 16'h0702, 16'h0802, 16'h0902, 16'h0a02, 16'h0b02
    };

    logic [31:0] test_pattern_row = 32'h00010001;
    logic [15:0] pattern_offset = 16'h0001;
    logic [15:0] line_offset = 16'h0000;

//    // HSYNC delay signals
    
    logic [5:0] hsync;             
    logic [5:0] hi_hsync;             
    logic hi_hsync_all, lo_hsync;
    logic sig_hsync;
    logic sig_hsync_1d, sig_hsync_2d;

    logic up_hsync_keep_hi, down_hsync_keep_hi;
    logic hsync_keep_hi;
    logic [3:0] hsync_keep_hi_cnt;
    
    // HSYNC counter control
    logic rst_hsync_cnt, rst_hsync_cnt_dly;
    logic inc_hsync_cnt;
    logic [11:0] hsync_cnt;

    
    logic s_read_data_start;

    // VSYNC control signals
    logic       FSM_read_index_eim_1d;
    logic       FSM_read_index_eim_2d;
    logic       FSM_read_index_eim_3d;
    logic       FSM_read_index_eim_4d;
    logic       FSM_read_index_eim_5d;
    logic       sig_vsync;
    logic       hi_vsync;
    logic       lo_vsync;
    logic       up_vsync_keep_hi;
    logic       down_vsync_keep_hi;
    logic       vsync_keep_hi;
    logic [3:0] vsync_keep_hi_cnt;

    logic FSM_read_index_sys_1d;
    logic FSM_read_index_sys_2d;
    

    // Signal to indicate if we are in image acquisition
//    logic get_image;
    
    logic s_dummy_start;
    logic s_dummy_get_image_1d;
    logic s_dummy_get_image_2d;
    logic s_dummy_valid;
    logic [15:0] s_dummy_valid_count;
//    logic [3:0] s_tuser_0_cnt;

    logic [11:0] read_mem; // Read memory flags
    logic [11:0] read_mem_1d; // Delayed read memory flags
    logic [11:0] read_mem_2d; // 2-cycle delayed read memory flags
    
    logic [11:0] end_read_mem; // End read memory flags
    logic [11:0] start_read_mem; // Start read memory flags
    
    logic [15:0] s_tuser_0_dly; // Delayed tuser signals
    logic s_v_sync;
    logic s_h_sync;


    ///////////////////////////////////////////////////////////////////////////////
    // CDC-003 Fix: Async FIFO for eim_clk -> sys_clk data path (24-bit)
    ///////////////////////////////////////////////////////////////////////////////
    
    // Internal eim_clk domain signals (before FIFO)
    logic [23:0] s_read_data_a_eim;
    logic [23:0] s_read_data_b_eim;
    logic        s_read_data_valid_eim;
    logic        s_fifo_wr_en;
    logic        s_fifo_full;
    logic        s_fifo_rd_en;
    logic        s_fifo_empty;
    
    // sys_clk domain signals (after FIFO)
    logic [23:0] s_read_data_a_sys;
    logic [23:0] s_read_data_b_sys;
    logic        s_read_data_valid_sys;

    assign s_max_h_count = max_h_count;
    assign s_max_v_count = max_v_count;

//
    ///////////////////////////////////////////////////////////////////////////////
    // Week 2: RST-002 Fix - Single synchronized reset (multi-clock domain safe)
    ///////////////////////////////////////////////////////////////////////////////
    
    // Generate internal reset conditions from control signals
    // RST-003: Internal reset signals (active-LOW for consistency)
    logic        tx_eim_rst_n;
    logic        tx_sys_rst_n;
    logic        internal_reset;
    assign internal_reset = rst_hsync_cnt_dly || hi_vsync || !tx_sys_rst_n;
    
    // h_count/v_count counter (RST-002: Fixed single async reset)
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

    // Dummy and exist_get_image control
    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!rst_n_eim) begin
            s_dummy_valid <= 1'b0;
            s_dummy_valid_count <= '0;
        end else begin
            // Control s_dummy_valid
            if (s_dummy_start) begin
                s_dummy_valid <= 1'b1;
            end else if ((s_v_count == (s_max_v_count - 1)) && (s_h_count == (s_max_h_count - 1))) begin
                s_dummy_valid <= 1'b0;
            end

            // Update dummy valid counter
            if (s_dummy_valid) begin
                s_dummy_valid_count <= s_dummy_valid_count + 1'b1;
            end
        end
    end

    // Dummy and exist_get_image control
    always_ff @(posedge eim_clk or negedge eim_rst) begin
        if (!eim_rst) begin
            s_dummy_get_image_1d <= 1'b0;
            s_dummy_get_image_2d <= 1'b0;
        end else begin
            // Pipeline dummy_get_image signal 
            s_dummy_get_image_1d <= dummy_get_image;
            s_dummy_get_image_2d <= s_dummy_get_image_1d;
        end
    end

   
    // Control signals
    assign s_dummy_start = s_dummy_get_image_1d && !s_dummy_get_image_2d;
    
    // Assign the exist_get_image output
    assign exist_get_image = s_dummy_valid;

    // Dummy read index control based on counter and h_count
    assign s_dummy_read_index = (s_dummy_valid_count[11] == 0) ||
                          (s_dummy_valid_count[11] && s_h_count > 0 && s_h_count <= (max_h_count - 1)) ? 
                          s_dummy_valid : 1'b0;    // Write memory data logic for both test patterns and normal ROIC data
    

    // Internal reset generation (maintains original logic)
    assign tx_eim_rst_n = !(FSM_read_index_eim_1d && !FSM_read_index_eim_2d && !FSM_aed_read_index);
    assign tx_sys_rst_n = !(FSM_read_index_sys_1d && !FSM_read_index_sys_2d && !FSM_aed_read_index);

    assign s_read_data_start = read_data_start;

    
    always_ff @(posedge sys_clk or negedge sys_rst) begin
        if (!sys_rst) begin
            FSM_read_index_sys_1d <= 1'b0;
            FSM_read_index_sys_2d <= 1'b0;
//            get_image_sys_1d <= 1'b0;
        end else begin
            // Valid ROIC data control
            FSM_read_index_sys_1d <= FSM_read_index;
            FSM_read_index_sys_2d <= FSM_read_index_sys_1d;
//            get_image_sys_1d <= get_image;
        end
    end
    
//    assign valid_read_roic_data = (valid_roic_data && FSM_read_index);

//    // Burst counter control
//    assign inc_roic_burst_cnt_sys = !valid_read_roic_data_sys_1d && valid_read_roic_data_sys_2d;
//    assign rst_roic_burst_cnt_sys = (inc_roic_burst_cnt_sys && (roic_burst_cnt_sys == VALID_NUM_ROIC_BURST)) ? 1'b1 : 1'b0;
    
//    // Burst counter
    
    // EIM clock domain reset control
    always_ff @(posedge eim_clk or negedge eim_rst) begin
        if (!eim_rst) begin
            FSM_read_index_eim_1d <= 1'b0;
            FSM_read_index_eim_2d <= 1'b0;
            FSM_read_index_eim_3d <= 1'b0;
            FSM_read_index_eim_4d <= 1'b0;
            FSM_read_index_eim_5d <= 1'b0;
//            get_image_eim_1d <= 1'b0;
        end else begin
            FSM_read_index_eim_1d <= FSM_read_index;
            FSM_read_index_eim_2d <= FSM_read_index_eim_1d;
            FSM_read_index_eim_3d <= FSM_read_index_eim_2d;
            FSM_read_index_eim_4d <= FSM_read_index_eim_3d;
            FSM_read_index_eim_5d <= FSM_read_index_eim_4d;
//            get_image_eim_1d <= get_image;
            
        end
    end


//    assign s_max_read_mem_addr_offset = 10'b0110000000 + NUM_ROIC_CHANNEL;

//    // Memory read address control
//    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
//        if (!eim_rst || tx_eim_rst_n) begin
//            read_mem_addr_offset <= '0;
//            read_mem_addr_offset_1d <= '0;
//            read_mem_addr_offset_2d <= '0;
//        end else begin
//            if (~read_mem_index)
//                read_mem_addr_offset <= '0;
//            else if (read_mem_index && valid_read_mem)
//                read_mem_addr_offset <= (read_mem_addr_offset == s_max_read_mem_addr_offset) ? '0 : read_mem_addr_offset + 1'b1;

//            read_mem_addr_offset_1d <= read_mem_addr_offset[7:0];
//            read_mem_addr_offset_2d <= read_mem_addr_offset_1d;
            
//            // Set max read address offset based on dual readout mode
//        end
//    end

    // Read address counter output
//    assign read_addr_cnt = read_mem_addr_offset_2d;

    // Memory read control signals    
    assign s_valid_read_mem = s_axis_tvalid & s_read_axis_tready & valid_read_mem;

    assign s_read_axis_tready = read_axis_tready;
    
    assign s_sync_gen_en = ((read_mem_index || s_dummy_read_index) && s_read_axis_tready) ? 1'b1 : 1'b0;

    assign s_axis_tvalid = (s_sync_gen_en && !s_axis_tlast && (s_h_count == 16'h0000)) ? 1'b1 :
                            (s_sync_gen_en && s_h_sync) ? 1'b1 : 
                            1'b0;
    
    assign s_tuser_0 = (s_sync_gen_en && s_h_count==16'h0000 && s_v_count==16'h0000) ? 1'b1 : 1'b0;

    assign s_v_sync = (s_v_count > '0 && s_v_count <= s_max_v_count) ? 1'b1 : 1'b0;
    assign s_h_sync = (s_h_count > '0 && s_h_count <= s_max_h_count) ? 1'b1 : 1'b0;

    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!eim_rst || tx_eim_rst_n) begin
            s_axis_tlast <= 1'b0;
        end else begin
            if (s_read_axis_tready) begin
                if (s_h_count == (s_max_h_count - 2)) begin
                    s_axis_tlast <= 1'b1; // Set last signal before the end of the line
                end else if (s_h_count == 16'h0000) begin
                    s_axis_tlast <= 1'b0; // Reset last signal at the start of the line
                end
            end
        end
    end
    

    assign read_mem_index = |read_mem;

    // Memory end control signals
    genvar i;

    generate
        for (i = 0; i < 12; i++) begin : gen_end_read_mem
            assign end_read_mem[i] = (read_mem[i] && (s_valid_read_mem && ({1'b0, s_h_count[6:0]} == NUM_ROIC_CHANNEL))) ? 1'b1 : 1'b0;
        end
    endgenerate    
    
    logic s_hsync_FSM_read_index;
    logic s_hsync_dly_FSM_read_index;

    assign s_hsync_FSM_read_index = (FSM_read_index || s_hsync_dly_FSM_read_index) ? 1'b1 : 1'b0;

    always_ff @(posedge eim_clk or negedge eim_rst) begin
        if (!eim_rst) begin
            s_hsync_dly_FSM_read_index <= 1'b0;
        end else begin
            if (lo_hsync)
                s_hsync_dly_FSM_read_index <= FSM_read_index;
        end
    end

    generate
        for (i = 0; i < 12; i++) begin : gen_start_read_mem
            assign s_axis_read_mem[i] = (s_axis_tvalid) ? read_mem[i] : 1'b0;
            assign data_read_req[i] = (csi_done && s_hsync_FSM_read_index) ? s_axis_read_mem[i] : 1'b0;
            // assign data_read_req[i] = (csi_done && s_hsync_FSM_read_index) ? read_mem[i] : 1'b0;
        end
    endgenerate


    // Memory read control for all channels
    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!eim_rst || tx_eim_rst_n) begin
            read_mem <= '0;
            read_mem_1d <= '0;
            read_mem_2d <= '0;
            
            // AXI-Stream signals reset
            s_axis_tvalid_1d <= 1'b0;
            s_axis_tvalid_2d <= 1'b0;
            s_axis_tvalid_3d <= 1'b0;
            
            s_axis_tlast_1d <= 1'b0;
            s_axis_tlast_2d <= 1'b0;
            s_axis_tlast_3d <= 1'b0;
            read_axis_tlast <= 1'b0;
        end else begin
            // Update read memory flags
            for (int k = 0; k < 12; k++) begin
                if (end_read_mem[k])
                    read_mem[k] <= 1'b0;
                else if (start_read_mem[k])
                    read_mem[k] <= 1'b1;
            end
            
            // Pipeline read memory flags
            read_mem_1d <= read_mem;
            read_mem_2d <= read_mem_1d;
            
            // Pipeline AXI-Stream signals
            s_axis_tvalid_1d <= s_axis_tvalid;
            s_axis_tvalid_2d <= s_axis_tvalid_1d;
            s_axis_tvalid_3d <= s_axis_tvalid_2d;
            
            s_axis_tlast_1d <= s_axis_tlast;
            s_axis_tlast_2d <= s_axis_tlast_1d;
            s_axis_tlast_3d <= s_axis_tlast_2d;
            read_axis_tlast <= s_axis_tlast_3d;
        end
    end

    // Start read operations control
    assign start_read_mem[0]  = hi_hsync_all;
    
//    // Memory read address control for all channels
//    // genvar i;
//    generate

    
    // Memory read data output multiplexing (CDC-003: eim_clk domain internal signals)
    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!eim_rst || tx_eim_rst_n) begin
            s_read_data_a_eim <= '0;
            s_read_data_b_eim <= '0;
            s_read_data_valid_eim <= 1'b0;
        end else begin
            // Use delayed valid signal to match VHDL behavior
            s_read_data_valid_eim <= s_axis_tvalid_3d;
            
            if (|read_mem_2d) begin
                case (1'b1)
                    read_mem_2d[0]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[0]);
                                        s_read_data_b_eim <= (roic_read_data_b[0]);
                                    end
                    read_mem_2d[1]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[1]);
                                        s_read_data_b_eim <= (roic_read_data_b[1]);
                                    end
                    read_mem_2d[2]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[2]);
                                        s_read_data_b_eim <= (roic_read_data_b[2]);
                                    end
                    read_mem_2d[3]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[3]);
                                        s_read_data_b_eim <= (roic_read_data_b[3]);
                                    end
                    read_mem_2d[4]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[4]);
                                        s_read_data_b_eim <= (roic_read_data_b[4]);
                                    end
                    read_mem_2d[5]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[5]);
                                        s_read_data_b_eim <= (roic_read_data_b[5]);
                                    end
                    read_mem_2d[6]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[6]);
                                        s_read_data_b_eim <= (roic_read_data_b[6]);
                                    end
                    read_mem_2d[7]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[7]);
                                        s_read_data_b_eim <= (roic_read_data_b[7]);
                                    end
                    read_mem_2d[8]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[8]);
                                        s_read_data_b_eim <= (roic_read_data_b[8]);
                                    end
                    read_mem_2d[9]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[9]);
                                        s_read_data_b_eim <= (roic_read_data_b[9]);
                                    end
                    read_mem_2d[10]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[10]);
                                        s_read_data_b_eim <= (roic_read_data_b[10]);
                                    end
                    read_mem_2d[11]: begin
                                        s_read_data_a_eim <= (roic_read_data_a[11]);
                                        s_read_data_b_eim <= (roic_read_data_b[11]);
                                    end
                    default:        begin
                                        s_read_data_a_eim <= '0;
                                        s_read_data_b_eim <= '0;
                                    end
                endcase
            end else begin
                s_read_data_a_eim <= '0;
                s_read_data_b_eim <= '0;
            end
        end
    end

    // Frame start/reset control
    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!eim_rst || tx_eim_rst_n) begin
            read_frame_start <= 1'b0;
            read_frame_reset <= 1'b0;
        end else begin
            read_frame_start <= s_tuser_0_dly[11];
            read_frame_reset <= hi_vsync;
        end
    end
    

    // HSYNC control logic
    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (tx_eim_rst_n || !eim_rst) begin
            sig_hsync_1d <= 1'b0;
            sig_hsync_2d <= 1'b0;
            
            hsync_keep_hi <= 1'b0;
            hsync_keep_hi_cnt <= '0;
            
        end else begin
            // HSYNC delay signals
            sig_hsync_1d <= sig_hsync;
            sig_hsync_2d <= sig_hsync_1d;
            
            // HSYNC keep high control
            if (up_hsync_keep_hi) begin
                hsync_keep_hi <= 1'b1;
            end else if (down_hsync_keep_hi) begin
                hsync_keep_hi <= 1'b0;
            end

            // HSYNC counter
            if (!hsync_keep_hi) begin
                    hsync_keep_hi_cnt <= 4'h0;
             end else begin
                    hsync_keep_hi_cnt <= hsync_keep_hi_cnt + 1;
            end
        end
    end

    // HSYNC control signals
    assign hi_hsync_all = |hi_hsync;
    assign sig_hsync = |hsync;
    assign read_hsync = sig_hsync;
    
    // HSYNC keep hi control
    assign up_hsync_keep_hi = end_read_mem[11];
    assign down_hsync_keep_hi = sig_hsync && hsync_keep_hi && (hsync_keep_hi_cnt == 4'b0101);

   // HSYNC counter logic
    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!eim_rst || tx_eim_rst_n) begin
//            hsync_cnt <= 0;
            s_tuser_0_dly <= '0;
//            s_tuser_0_cnt <= '0;
        end else begin
              
            // Update tuser_0 signals from VHDL implementation
            s_tuser_0_dly <= {s_tuser_0_dly[14:0], s_tuser_0};
            
//            if (hi_vsync) begin
//                s_tuser_0_cnt <= 4'h0;
//            end else if (s_tuser_0) begin
//                s_tuser_0_cnt <= s_tuser_0_cnt + 1'b1;
//            end
        end
    end
    
    // HSYNC counter control signals
    assign inc_hsync_cnt = !sig_hsync_1d && sig_hsync_2d;
    assign rst_hsync_cnt = (inc_hsync_cnt && hsync_cnt == (dsp_image_height[11:0] - 12'h1)) ? 1'b1 : 1'b0;

    // HSYNC counter
    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!eim_rst || tx_eim_rst_n) begin
            hsync_cnt <= 12'd0;
            rst_hsync_cnt_dly <= 1'b0;
        end else begin
            if (rst_hsync_cnt_dly) begin
                hsync_cnt <= 12'd0;
            end else if (inc_hsync_cnt & sig_vsync) begin
                hsync_cnt <= hsync_cnt + 1;
            end
            rst_hsync_cnt_dly <= rst_hsync_cnt;
        end
    end


    // assign hi_vsync = (FSM_read_index_eim_4d && !FSM_read_index_eim_5d) && get_image;
    assign hi_vsync = (FSM_read_index_eim_4d && !FSM_read_index_eim_5d);

    assign up_vsync_keep_hi = rst_hsync_cnt_dly;
    assign down_vsync_keep_hi = sig_vsync && vsync_keep_hi && (vsync_keep_hi_cnt == 4'b1111);

    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!eim_rst || tx_eim_rst_n) begin
            vsync_keep_hi <= 1'b0;
        end
        else begin
            if (down_vsync_keep_hi)
                vsync_keep_hi <= 1'b0;
            else if (up_vsync_keep_hi)
                vsync_keep_hi <= 1'b1;
        end
    end

    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!eim_rst || tx_eim_rst_n) begin
            vsync_keep_hi_cnt <= 4'b0000;
        end
        else begin
            if (!vsync_keep_hi)
                vsync_keep_hi_cnt <= 4'b0000;
            else if (vsync_keep_hi)
                vsync_keep_hi_cnt <= vsync_keep_hi_cnt + 1'b1;
        end
    end

    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!eim_rst || tx_eim_rst_n) begin
            lo_vsync <= 1'b0;
        end
        else begin
            lo_vsync <= down_vsync_keep_hi;
        end
    end

    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!eim_rst || tx_eim_rst_n) begin
            sig_vsync <= 1'b0;
        end
        else begin
            if (lo_vsync)
                sig_vsync <= 1'b0;
            else if (hi_vsync)
                sig_vsync <= 1'b1;
        end
    end

//    assign read_vsync = sig_vsync;

    always_ff @(posedge eim_clk or negedge rst_n_eim) begin
        if (!eim_rst || tx_eim_rst_n) begin
            lo_hsync <= 1'b0;
        end else begin
            lo_hsync <= down_hsync_keep_hi;
        end
    end

    // Generate vector signals

    // genvar i;
    generate
        for (i = 0; i < 6; i = i + 1) begin : hi_hsync_gen
            // assign hi_hsync[i] = lo_hsync_delay[i];
            assign hi_hsync[i] = s_read_data_start;
        end
    endgenerate

    generate
//        genvar i;
        for (i = 0; i < 6; i = i + 1) begin : hsync_gen
            always_ff @(posedge eim_clk or negedge rst_n_eim) begin
                if (!eim_rst || tx_eim_rst_n) begin
                    hsync[i] <= 1'b0;
                end else if (lo_hsync) begin
                    hsync[i] <= 1'b0;
                end else if (hi_hsync[i]) begin
                    hsync[i] <= 1'b1;
                end
            end
        end
    endgenerate


    ///////////////////////////////////////////////////////////////////////////////
    // CDC-003 Fix: Async FIFO instantiation for eim_clk -> sys_clk CDC
    ///////////////////////////////////////////////////////////////////////////////
    
    // FIFO write enable (data valid in eim_clk domain)
    assign s_fifo_wr_en = s_read_data_valid_eim;
    
    // FIFO read enable (ready in sys_clk domain)
    assign s_fifo_rd_en = read_axis_tready;
    
    // Async FIFO for data_a channel (24-bit) - DUP-001: using universal async_fifo
    async_fifo #(
        .DATA_WIDTH(24),
        .DEPTH(16)
    ) fifo_data_a_inst (
        // Write clock domain (eim_clk)
        .wr_clk    (eim_clk),
        .wr_rst_n  (rst_n_eim),       // RST-006: active-LOW reset
        .wr_en     (s_fifo_wr_en),
        .din       (s_read_data_a_eim),
        .full      (s_fifo_full),
        
        // Read clock domain (sys_clk = 100MHz)
        .rd_clk    (sys_clk),
        .rd_rst_n  (sys_rst),         // RST-006: active-LOW reset
        .rd_en     (s_fifo_rd_en),
        .dout      (s_read_data_a_sys),
        .empty     (s_fifo_empty)
    );
    
    // Async FIFO for data_b channel (24-bit) - DUP-001: using universal async_fifo
    async_fifo #(
        .DATA_WIDTH(24),
        .DEPTH(16)
    ) fifo_data_b_inst (
        // Write clock domain (eim_clk)
        .wr_clk    (eim_clk),
        .wr_rst_n  (rst_n_eim),       // RST-006: active-LOW reset
        .wr_en     (s_fifo_wr_en),
        .din       (s_read_data_b_eim),
        .full      (),                 // Unused (share with fifo_a)
        
        // Read clock domain (sys_clk = 100MHz)
        .rd_clk    (sys_clk),
        .rd_rst_n  (sys_rst),         // RST-006: active-LOW reset
        .rd_en     (s_fifo_rd_en),
        .dout      (s_read_data_b_sys),
        .empty     ()                  // Unused (share with fifo_a)
    );
    
    // CDC-003: Output assignments from sys_clk domain (FIFO outputs)
    assign read_data_out_a   = s_read_data_a_sys;
    assign read_data_out_b   = s_read_data_b_sys;
    assign read_data_valid   = s_fifo_rd_en && !s_fifo_empty;

endmodule