//******************************************************************************
// Module: init
// Description: Power initialization and reset sequence controller
//
// Week 11 Refactoring (RST-001 fix):
// - Renamed reset parameter to rst_n for consistency
// - Fixed polarity mismatch in instantiation (removed inversion)
//
// Week 9 Refactoring (M9-1):
// - Converted from legacy 2-block FSM style to Xilinx-recommended 3-block style
// - Block 1: State Register (always_ff with async reset)
// - Block 2: Next State Logic (always_comb)
// - Block 3: Output Logic (always_comb)
// - Consolidated power on/off and power down sequences into single FSM
// - Maintains exact functional behavior from original implementation
//
// FSM Style: 3-Block (Recommended for Xilinx FPGAs)
// State Encoding: Binary encoding for efficient resource usage
//******************************************************************************

`include "./p_define_refacto.sv"
`timescale 1ns/1ps

module init(
    // Clock and Reset
    input  logic              fsm_clk,        // System clock
    input  logic              rst_n,          // Active-LOW reset (RST-001 fix: renamed from reset)

    // Control Inputs
    input  logic              en_pwr_off,     // Power off enable
    input  logic              en_pwr_dwn,     // Power down enable

    // Outputs
    output logic              init_rst,       // System reset (active HIGH)
    output logic              pwr_init_step1,  // Power init step 1
    output logic              pwr_init_step2,  // Power init step 2
    output logic              pwr_init_step3,  // Power init step 3
    output logic              pwr_init_step4,  // Power init step 4
    output logic              pwr_init_step5,  // Power init step 5
    output logic              pwr_init_step6,  // Power init step 6
    output logic              roic_reset      // ROIC reset pulse
);

    //==========================================================================
    // State Definitions
    //==========================================================================
    typedef enum logic [3:0] {
        IDLE        = 4'b0000,  // Idle state, waiting for power on/off command
        PWR_ON      = 4'b0001,  // Power on sequence active
        STEP1       = 4'b0010,  // Initialization step 1
        STEP2       = 4'b0011,  // Initialization step 2
        STEP3       = 4'b0100,  // Initialization step 3
        STEP4       = 4'b0101,  // Initialization step 4
        STEP5       = 4'b0110,  // Initialization step 5 (long delay)
        STEP6       = 4'b0111,  // Initialization step 6 (final init state)
        PWR_OFF     = 4'b1000,  // Power off sequence active
        PDWN_STEP5  = 4'b1001,  // Power down step 5
        PDWN_STEP4  = 4'b1010,  // Power down step 4
        PDWN_STEP3  = 4'b1011,  // Power down step 3
        PDWN_STEP2  = 4'b1100,  // Power down step 2
        PDWN_STEP1  = 4'b1101,  // Power down step 1
        STEP5_OFF   = 4'b1110   // Step 5 power off (long delay)
    } state_t;

    //==========================================================================
    // State and Signal Declarations
    //==========================================================================
    state_t                  state_ff;           // Current state register
    state_t                  state_next;         // Next state

    // Edge detection signals for control inputs
    logic                    en_pwr_off_1d;
    logic                    en_pwr_off_2d;
    logic                    start_pwr_off;
    logic                    start_pwr_on;

    logic                    en_pwr_dwn_1d;
    logic                    en_pwr_dwn_2d;
    logic                    start_pwr_dwn_off;
    logic                    start_pwr_dwn_on;

    // Timing counter
    logic           [24:0]   counter_ff;

    // ROIC reset delay chain
    logic                    step_delay_ff;
    logic                    step_delay_1d_ff;
    logic                    step_delay_2d_ff;
    logic                    step_delay_3d_ff;
    logic                    step_delay_4d_ff;

    // System reset control
    logic                    init_step6_1d;
    logic                    init_step6_2d;
    logic                    sig_init_rst_ff;
    logic                    hi_init_rst;

    //==========================================================================
    // Block 1: State Register (Sequential Logic)
    //==========================================================================
    // This block contains only sequential logic for state and data registers.
    // All state transitions and output logic are in separate combinational blocks.
    //==========================================================================

    always_ff @(posedge fsm_clk or negedge rst_n) begin
        if (!rst_n) begin
            state_ff           <= IDLE;
            counter_ff         <= 25'd0;
            sig_init_rst_ff    <= 1'b1;
            init_step6_1d      <= 1'b0;
            init_step6_2d      <= 1'b0;
            en_pwr_off_1d      <= 1'b0;
            en_pwr_off_2d      <= 1'b0;
            en_pwr_dwn_1d      <= 1'b0;
            en_pwr_dwn_2d      <= 1'b0;
            step_delay_ff      <= 1'b0;
            step_delay_1d_ff   <= 1'b0;
            step_delay_2d_ff   <= 1'b0;
            step_delay_3d_ff   <= 1'b0;
            step_delay_4d_ff   <= 1'b0;
        end else begin
            // State register update
            state_ff        <= state_next;

            // Counter register update
            if (state_next == PWR_ON || state_next == PWR_OFF ||
                state_next == PDWN_STEP5 || state_next == STEP5_OFF) begin
                counter_ff   <= 25'd0;
            end else if (state_ff == PWR_ON || state_ff == PWR_OFF ||
                        state_ff == STEP1 || state_ff == STEP2 ||
                        state_ff == STEP3 || state_ff == STEP4 ||
                        state_ff == STEP5 || state_ff == STEP5_OFF ||
                        state_ff == PDWN_STEP5 || state_ff == PDWN_STEP4 ||
                        state_ff == PDWN_STEP3 || state_ff == PDWN_STEP2) begin
                counter_ff   <= counter_ff + 25'd1;
            end

            // System reset control register
            if (hi_init_rst) begin
                sig_init_rst_ff <= 1'b0;
            end

            // Step6 edge detection flops (for reset generation)
            init_step6_1d   <= (state_ff == STEP6);
            init_step6_2d   <= init_step6_1d;

            // Input edge detection flops
            en_pwr_off_1d   <= en_pwr_off;
            en_pwr_off_2d   <= en_pwr_off_1d;
            en_pwr_dwn_1d   <= en_pwr_dwn;
            en_pwr_dwn_2d   <= en_pwr_dwn_1d;

            // ROIC reset delay chain
            step_delay_ff    <= (state_ff == STEP5);
            step_delay_1d_ff <= step_delay_ff;
            step_delay_2d_ff <= step_delay_1d_ff;
            step_delay_3d_ff <= step_delay_2d_ff;
            step_delay_4d_ff <= step_delay_3d_ff;
        end
    end

    //==========================================================================
    // Block 2: Next State Logic (Combinational)
    //==========================================================================
    // This block contains all combinational logic for determining the next state.
    // Pure combinational logic - no sequential elements.
    //==========================================================================

    // Edge detection signals
    assign start_pwr_off     = en_pwr_off_1d & ~en_pwr_off_2d & (state_ff == STEP6);
    assign start_pwr_on      = ~en_pwr_off_1d & en_pwr_off_2d & ~start_pwr_off;
    assign start_pwr_dwn_on  = en_pwr_dwn_1d & ~en_pwr_dwn_2d & (state_ff == PDWN_STEP1);
    assign start_pwr_dwn_off = ~en_pwr_dwn_1d & en_pwr_dwn_2d & ~start_pwr_dwn_on;
    assign hi_init_rst       = init_step6_1d & ~init_step6_2d;

    // Next state logic
    always_comb begin
        // Default: stay in current state
        state_next = state_ff;

        case (state_ff)
            //--------------------------------------------------------------
            // IDLE State
            // Wait for power on command
            //--------------------------------------------------------------
            IDLE: begin
                if (start_pwr_on) begin
                    state_next = PWR_ON;
                end
            end

            //--------------------------------------------------------------
            // Power On Sequence States
            //--------------------------------------------------------------
            PWR_ON: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = STEP1;
                end
            end

            STEP1: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = STEP2;
                end
            end

            STEP2: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = STEP3;
                end
            end

            STEP3: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = STEP4;
                end
            end

            STEP4: begin
                if (counter_ff >= `MORE_DELAY) begin
                    state_next = STEP5;
                end
            end

            STEP5: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = STEP6;
                end
            end

            STEP6: begin
                // Final power on state - wait for power off command
                if (start_pwr_off) begin
                    state_next = PWR_OFF;
                end
            end

            //--------------------------------------------------------------
            // Power Off Sequence States
            //--------------------------------------------------------------
            PWR_OFF: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = STEP5_OFF;
                end
            end

            STEP5_OFF: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = STEP4;
                end
            end

            // Reuse power on states for power down sequence
            // (they are reversed order)
            STEP4: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = STEP3;
                end
            end

            STEP3: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = STEP2;
                end
            end

            STEP2: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = STEP1;
                end
            end

            STEP1: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = IDLE;
                end
            end

            //--------------------------------------------------------------
            // Power Down Sequence States
            // (These states are used when en_pwr_dwn is asserted)
            //--------------------------------------------------------------
            PDWN_STEP1: begin
                if (start_pwr_dwn_on) begin
                    state_next = PDWN_STEP5;
                end
            end

            PDWN_STEP5: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = PDWN_STEP4;
                end
            end

            PDWN_STEP4: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = PDWN_STEP3;
                end
            end

            PDWN_STEP3: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = PDWN_STEP2;
                end
            end

            PDWN_STEP2: begin
                if (counter_ff >= `INIT_DELAY) begin
                    state_next = PDWN_STEP1;
                end
            end

            //--------------------------------------------------------------
            // Default case
            //--------------------------------------------------------------
            default: begin
                state_next = IDLE;
            end
        endcase
    end

    //==========================================================================
    // Block 3: Output Logic (Combinational)
    //==========================================================================
    // This block contains all combinational logic for generating outputs.
    // Outputs are based on current state (Moore machine).
    //==========================================================================

    // Power initialization step outputs
    assign pwr_init_step1 = (state_ff == STEP1);
    assign pwr_init_step2 = (state_ff == STEP2);
    assign pwr_init_step3 = (state_ff == STEP3);
    assign pwr_init_step4 = (state_ff == STEP4);
    assign pwr_init_step5 = (state_ff == STEP5);
    assign pwr_init_step6 = (state_ff == STEP6);

    // System reset output (active HIGH)
    assign init_rst = sig_init_rst_ff;

    // ROIC reset output - generated from delay chain
    // Creates a pulse when step_delay is HIGH and step_delay_4d is LOW
    assign roic_reset = step_delay_ff & ~step_delay_4d_ff;

endmodule
