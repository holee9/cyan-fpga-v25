//==============================================================================
// File: state_led_controller.sv
// Date: 2026.02.04
// Designer: drake.lee
// Description: State LED Controller Module
//              Extracted from cyan_top.sv (Phase 8 - M8-3)
//              Controls STATE_LED1 based on FSM states and status signals
//
// Features:
//   - LED output control for FSM state indication
//   - Configurable LED selection via state_led_ctr
//   - Multiple state mapping options
//   - Blink functionality for active states
//
// Revision History:
//    2026.02.04 - Initial extraction from cyan_top.sv
//==============================================================================

`timescale 1ns / 1ps

module state_led_controller (
    // Clock and reset
    input  logic        clk_20mhz,
    input  logic        rst_n,

    // LED select control
    input  logic [7:0]  state_led_ctr,

    // FSM state inputs
    input  logic        FSM_idle_index,
    input  logic        FSM_read_index,
    input  logic        FSM_exp_index,
    input  logic        FSM_aed_read_index,
    input  logic        FSM_flush_index,
    input  logic        FSM_back_bias_index,
    input  logic        FSM_wait_index,
    input  logic        FSM_rst_index,

    // Validity signals
    input  logic        valid_roic_data,
    input  logic        valid_read_mem,
    input  logic        valid_readout,

    // ROIC channel detection
    input  logic [11:0] channel_detected,

    // AXI-Stream status
    input  logic        read_frame_start,
    input  logic        read_frame_reset,
    input  logic        read_axis_tvalid,
    input  logic        read_axis_tlast,
    input  logic        read_axis_tready,

    // Ready status
    input  logic        aed_ready_done,
    input  logic        panel_stable,
    input  logic        gen_sync_start,

    // LED output
    output logic        STATE_LED1
);

    //==========================================================================
    // LED Control Modes (based on state_led_ctr)
    //==========================================================================
    // 0x00: FSM state indication
    // 0x01: Data valid indication
    // 0x02: Sync indication
    // 0x03: Frame activity
    // 0x04: Channel detection
    // 0x05: Ready status
    // Others: Off

    //==========================================================================
    // Internal Signals
    //==========================================================================
    logic [3:0] led_state;
    logic        led_blink;
    logic [23:0] blink_counter;
    logic        blink_en;

    //==========================================================================
    // LED State Selection
    //==========================================================================
    always_comb begin
        case (state_led_ctr)
            8'h00: begin  // FSM state mode
                led_state = {
                    FSM_rst_index,
                    FSM_flush_index,
                    FSM_back_bias_index,
                    FSM_read_index
                };
                blink_en = 1'b1;
            end

            8'h01: begin  // Data valid mode
                led_state = {
                    valid_readout,
                    valid_read_mem,
                    valid_roic_data,
                    read_axis_tvalid
                };
                blink_en = 1'b0;
            end

            8'h02: begin  // Sync mode
                led_state = {
                    gen_sync_start,
                    panel_stable,
                    aed_ready_done,
                    1'b0
                };
                blink_en = 1'b1;
            end

            8'h03: begin  // Frame activity mode
                led_state = {
                    read_frame_start,
                    read_frame_reset,
                    read_axis_tlast,
                    read_axis_tready
                };
                blink_en = read_axis_tvalid;
            end

            8'h04: begin  // Channel detection mode
                led_state = {4'(channel_detected != 0)};
                blink_en = 1'b0;
            end

            8'h05: begin  // Ready status mode
                led_state = {
                    FSM_idle_index,
                    FSM_wait_index,
                    panel_stable,
                    1'b0
                };
                blink_en = 1'b0;
            end

            default: begin  // Off
                led_state = 4'h0;
                blink_en = 1'b0;
            end
        endcase
    end

    //==========================================================================
    // Blink Counter (for visual indication)
    //==========================================================================
    // Creates a ~2Hz blink rate at 20MHz
    localparam int BLINK_COUNT = 20'd10_000_000;  // 0.5 seconds at 20MHz

    always_ff @(posedge clk_20mhz or negedge rst_n) begin
        if (!rst_n) begin
            blink_counter <= 24'd0;
            led_blink <= 1'b0;
        end else if (blink_en) begin
            if (blink_counter >= BLINK_COUNT) begin
                blink_counter <= 24'd0;
                led_blink <= ~led_blink;
            end else begin
                blink_counter <= blink_counter + 1'b1;
            end
        end else begin
            blink_counter <= 24'd0;
            led_blink <= 1'b0;
        end
    end

    //==========================================================================
    // LED Output Logic
    //==========================================================================
    always_comb begin
        if (blink_en) begin
            // Blinking mode
            STATE_LED1 = |led_state && led_blink;
        end else begin
            // Steady mode
            STATE_LED1 = |led_state;
        end
    end

    //==========================================================================
    // Alternative: Direct LED state mapping (no blink)
    //==========================================================================
    // Uncomment for direct state-to-LED mapping
    /*
    always_comb begin
        case (1'b1)
            FSM_rst_index:       STATE_LED1 = 1'b1;
            FSM_idle_index:      STATE_LED1 = 1'b0;
            FSM_flush_index:     STATE_LED1 = 1'b1;
            FSM_back_bias_index: STATE_LED1 = 1'b1;
            FSM_aed_read_index:  STATE_LED1 = 1'b1;
            FSM_exp_index:       STATE_LED1 = 1'b1;
            FSM_read_index:      STATE_LED1 = 1'b1;
            FSM_wait_index:      STATE_LED1 = 1'b0;
            default:             STATE_LED1 = 1'b0;
        endcase
    end
    */

    //==========================================================================
    // Assertions for Verification
    //==========================================================================
    `ifndef SYNTHESIS

    property led_output_defined;
        @(posedge clk_20mhz) !$isunknown(STATE_LED1);
    endproperty
    assert property (led_output_defined)
        else $error("[STATE_LED] LED output is X or Z");

    property led_mode_coverage;
        @(posedge clk_20mhz) disable iff (!rst_n)
            (state_led_ctr < 8'h06) |-> !$isunknown(STATE_LED1);
    endproperty
    assert property (led_mode_coverage)
        else $error("[STATE_LED] LED output undefined for mode %h", state_led_ctr);

    `endif

endmodule
