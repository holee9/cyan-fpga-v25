///////////////////////////////////////////////////////////////////////////////
// File: sync_processing.sv
// Date: 2026.02.03
// Designer: drake.lee
// Description: Sync signal processing and pipeline synchronization module
//              Extracted from cyan_top.sv (Week 6 - M6-2)
//
// Functionality:
//   - Edge detection for gen_sync_start signal
//   - Column counter for image width tracking
//   - FSM signal synchronization/pipeline
//   - Reset handling
//
// Revision History:
//    2026.02.03 - Initial extraction from cyan_top.sv
//    2026.02.03 - Convert reset from active-HIGH to active-LOW (negedge rst_n_20mhz)
//
///////////////////////////////////////////////////////////////////////////////

module sync_processing (
    // Clock and Reset
    input  logic        clk_20mhz,
    input  logic        rst_n_20mhz,          // Active-LOW reset

    // Control Inputs
    input  logic        gen_sync_start,       // Sync start trigger
    input  logic        config_done_i,        // Configuration done status

    // Sequencer/FSM Inputs (to be captured/synchronized)
    input  logic [31:0] active_repeat_count_o,// Active repeat count
    input  logic        stv_mask_o,           // STV mask signal
    input  logic        csi_mask_o,           // CSI mask signal
    input  logic [31:0] current_repeat_count_o,// Current repeat count
    input  logic        FSM_read_index,       // FSM read index
    input  logic        FSM_flush_index,      // FSM flush index
    input  logic        FSM_back_bias_index,  // FSM back bias index

    // Synchronized Outputs
    output logic        gen_sync_start_rise,  // Rising edge pulse on gen_sync_start
    output logic [31:0] sync_repeat_cnt,      // Synchronized repeat count (row counter)
    output logic [15:0] sync_col_cnt,         // Column counter for image width
    output logic        sync_stv_mask_o,      // Synchronized STV mask
    output logic        sync_csi_mask_o,      // Synchronized CSI mask
    output logic [31:0] sync_current_repeat_count_o, // Synchronized repeat count
    output logic        sync_config_done,     // Synchronized config done
    output logic        sync_fsm_read_index,  // Synchronized FSM read index
    output logic        sync_fsm_flush_index, // Synchronized FSM flush index
    output logic        sync_fsm_back_bias_index // Synchronized FSM back bias index
);

    //==========================================================================
    // Internal Signals
    //==========================================================================
    logic [1:0] gen_sync_start_dly;   // Delay chain for edge detection

    //==========================================================================
    // Sync Processing Logic
    //==========================================================================
    // This always_ff block handles:
    // 1. Edge detection for gen_sync_start
    // 2. Capturing FSM signals on sync start
    // 3. Column counter for image width tracking
    // 4. Reset handling (active-LOW async reset)
    //==========================================================================
    always_ff @(posedge clk_20mhz or negedge rst_n_20mhz) begin
        if (!rst_n_20mhz) begin
            // Reset all outputs to default values
            gen_sync_start_dly           <= 2'd0;
            gen_sync_start_rise          <= 1'b0;
            sync_repeat_cnt              <= 32'd0;
            sync_col_cnt                 <= 16'd0;
            sync_stv_mask_o              <= 1'b0;
            sync_csi_mask_o              <= 1'b0;
            sync_current_repeat_count_o  <= 32'd0;
            sync_config_done             <= 1'b0;
            sync_fsm_read_index          <= 1'b0;
            sync_fsm_flush_index         <= 1'b0;
            sync_fsm_back_bias_index     <= 1'b0;
        end else begin
            // Capture FSM signals on rising edge of gen_sync_start
            if (gen_sync_start_rise) begin
                sync_repeat_cnt              <= active_repeat_count_o;
                sync_stv_mask_o              <= stv_mask_o;
                sync_csi_mask_o              <= csi_mask_o;
                sync_current_repeat_count_o  <= current_repeat_count_o;
                sync_config_done             <= config_done_i;
                sync_fsm_read_index          <= FSM_read_index;
                sync_fsm_flush_index         <= FSM_flush_index;
                sync_fsm_back_bias_index     <= FSM_back_bias_index;
            end

            // Column counter: reset on sync start, increment otherwise
            if (gen_sync_start_rise) begin
                sync_col_cnt <= 16'd0;
            end else begin
                sync_col_cnt <= sync_col_cnt + 1'b1;
            end

            // Edge detection for gen_sync_start
            gen_sync_start_dly <= {gen_sync_start_dly[0], gen_sync_start};
            gen_sync_start_rise <= ~gen_sync_start_dly[1] & gen_sync_start_dly[0];
        end
    end

    //==========================================================================
    // Signal Aliases (for compatibility with original naming)
    //==========================================================================
    // The outputs use "sync_" prefix to avoid naming conflicts when
    // instantiated in cyan_top.sv

endmodule
