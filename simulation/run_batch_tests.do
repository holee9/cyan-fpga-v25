###############################################################################
# File: run_batch_tests.do
# Date: 2026-02-05
# Designer: drake.lee
# Description: Questa Batch Test Runner
#              Runs all testbenches in sequence
#
# Usage:
#   In Questa Console: do run_batch_tests.do
#   Command line: vsim -c -do run_batch_tests.do
#
# Tool Paths:
#   Questa 2025.3: D:\questa_base64_2025.3
#   Compiled Libs:  D:\compile_simlib\vivado_2025_questa_2025
#
# Revision History:
#    2026.02.05 - Initial
###############################################################################

# Create results directory
file mkdir sim_results

# Counter variables
set total_tests 0
set passed_tests 0
set failed_tests 0

# Include directories
set INC_DIRS "+incdir+../source/hdl+../source/hdl/ti-roic"

# =============================================================================
# Function to run a single test
# =============================================================================
proc run_single_test {test_name tb_file} {
    global total_tests passed_tests failed_tests INC_DIRS

    incr total_tests

    puts "=========================================="
    puts "Test $total_tests: $test_name"
    puts "File: $tb_file"
    puts "=========================================="

    # Compile testbench
    set compile_cmd "vlog +acc -sv $INC_DIRS $tb_file"
    if {[catch {eval $compile_cmd} result]} {
        puts "FAILED: Compilation error for $test_name"
        incr failed_tests
        return 0
    }

    # Extract testbench module name (remove _tb suffix if present)
    set tb_module $test_name

    # Run simulation - use onfinish to detect completion without quitting
    if {[catch {vsim -lib work $tb_module -do "run -all; onfinish exit"} result]} {
        puts "FAILED: Simulation error for $test_name"
        puts $result
        incr failed_tests
        return 0
    }

    puts "PASSED: $test_name"
    incr passed_tests
    return 1
}

# =============================================================================
# Test Definitions
# List of all testbenches with their file paths
# =============================================================================
set TEST_LIST {
    {"reset_sync_tb" "tb_src/reset_sync_tb.sv"}
    {"cdc_gen_sync_tb" "tb_src/cdc/cdc_gen_sync_tb.sv"}
    {"async_fifo_param_tb" "tb_src/async_fifo_param_tb.sv"}
    {"init_tb" "tb_src/init_tb.sv"}
    {"state_led_controller_tb" "tb_src/state_led_controller_tb.sv"}
    {"clock_gen_top_tb" "tb_src/clock_gen_top_tb.sv"}
    {"rf_spi_controller_tb" "tb_src/rf_spi_controller_tb.sv"}
    {"i2c_master_tb" "tb_src/i2c_master_tb.sv"}
    {"data_path_selector_tb" "tb_src/data_path_selector_tb.sv"}
    {"async_fifo_controller_tb" "tb_src/async_fifo_controller_tb.sv"}
    {"timing_generator_tb" "tb_src/timing_generator_tb.sv"}
    {"mipi_interface_wrapper_tb" "tb_src/mipi_interface_wrapper_tb.sv"}
    {"debug_integration_tb" "tb_src/debug_integration_tb.sv"}
    {"read_data_mux_tb" "tb_src/read_data_mux_tb.sv"}
    {"sequencer_fsm_tb" "tb_src/sequencer_fsm_tb.sv"}
    {"tb_reg_map" "tb_src/tb_reg_map.sv"}
    {"tb_roic_gate_drv_compare" "tb_src/tb_roic_gate_drv_compare.sv"}
    {"cyan_top_tb" "tb_src/cyan_top_tb.sv"}
}

# =============================================================================
# Run All Tests
# =============================================================================
puts "\n=========================================="
puts "CYAN-FPGA Batch Test Runner"
puts "Total Tests: [llength $TEST_LIST]"
puts "=========================================="

foreach test_info $TEST_LIST {
    set test_name [lindex $test_info 0]
    set tb_file [lindex $test_info 1]

    # Check if file exists
    if {[file exists $tb_file]} {
        run_single_test $test_name $tb_file
    } else {
        puts "WARNING: Testbench file not found: $tb_file"
        puts "Skipping: $test_name"
    }
}

# =============================================================================
# Print Summary
# =============================================================================
puts "\n=========================================="
puts "Simulation Summary"
puts "=========================================="
puts "Total:   $total_tests"
puts "Passed:  $passed_tests"
puts "Failed:  $failed_tests"
puts "=========================================="

# Write summary to file
set fid [open "sim_results/test_summary.log" w]
puts $fid "CYAN-FPGA Simulation Test Summary"
puts $fid "Date: [clock format [clock seconds]]"
puts $fid "=========================================="
puts $fid "Total:   $total_tests"
puts $fid "Passed:  $passed_tests"
puts $fid "Failed:  $failed_tests"
puts $fid "=========================================="
close $fid

# Exit with appropriate code
if {$failed_tests > 0} {
    puts "\nFAILED: $failed_tests test(s) failed!"
    puts "Check sim_results/ for detailed logs"
    quit -code 1
} else {
    puts "\nSUCCESS: All tests passed!"
    quit -code 0
}
