###############################################################################
# File: run_single_test.do
# Date: 2026-02-05
# Designer: drake.lee
# Description: Questa Single Test Runner
#              Runs a single testbench with waveform output
#
# Usage:
#   vsim -do "run_single_test.do <test_name>"
#
# Example:
#   vsim -do "run_single_test.do reset_sync_tb"
#
# Tool Paths:
#   Questa 2025.3: D:\questa_base64_2025.3
#   Compiled Libs:  D:\compile_simlib\vivado_2025_questa_2025
#
# Revision History:
#    2026.02.05 - Initial
###############################################################################

proc run_test {test_name} {
    # Map test name to file path
    switch -glob -- $test_name {
        "*cdc_gen_sync_tb*" {
            set tb_file "tb_src/cdc/cdc_gen_sync_tb.sv"
        }
        default {
            set tb_file "tb_src/${test_name}.sv"
        }
    }

    # Check if file exists
    if {![file exists $tb_file]} {
        puts "ERROR: Testbench file not found: $tb_file"
        return
    }

    puts "=========================================="
    puts "Running Test: $test_name"
    puts "Testbench File: $tb_file"
    puts "=========================================="

    # Compile testbench
    puts "Compiling testbench..."
    if {[catch {vlog +acc -sv +incdir+../source/hdl+../source/hdl/ti-roic $tb_file} result]} {
        puts "ERROR: Compilation failed"
        puts $result
        return
    }

    # Simulate with GUI
    puts "Starting simulation (GUI mode)..."
    vsim -gui work.$test_name

    # Add common waves
    add wave -position insertpoint  \
        sim:/{$test_name}/* \
        sim:/{$test_name}/DUT/*

    # Run
    run -all

    puts "Simulation complete. Check waveform window."
}

# Run the test if argument provided
if {[llength $::argv] > 0} {
    run_test [lindex $::argv 0]
} else {
    puts "Usage: vsim -do \"run_single_test.do <test_name>\""
    puts ""
    puts "Available testbenches:"
    puts "  Basic/CDC Tests:"
    puts "    - reset_sync_tb"
    puts "    - cdc_gen_sync_tb"
    puts "    - async_fifo_param_tb"
    puts ""
    puts "  Unit Tests - Low Level:"
    puts "    - init_tb"
    puts "    - state_led_controller_tb"
    puts "    - clock_gen_top_tb"
    puts "    - rf_spi_controller_tb"
    puts "    - i2c_master_tb"
    puts "    - data_path_selector_tb"
    puts "    - async_fifo_controller_tb"
    puts ""
    puts "  Unit Tests - High Level:"
    puts "    - timing_generator_tb"
    puts "    - mipi_interface_wrapper_tb"
    puts "    - debug_integration_tb"
    puts "    - read_data_mux_tb"
    puts "    - sequencer_fsm_tb"
    puts ""
    puts "  Integration Tests:"
    puts "    - tb_reg_map"
    puts "    - tb_roic_gate_drv_compare"
    puts "    - cyan_top_tb"
}
