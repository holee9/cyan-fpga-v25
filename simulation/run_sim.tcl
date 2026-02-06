#!/usr/bin/tclsh
###############################################################################
# File: run_sim.tcl
# Date: 2026-02-05
# Designer: drake.lee
# Description: Vivado Simulation Runner
#              Runs all testbenches with proper compile order
#
# Usage:
#   vivado -mode batch -source run_sim.tcl
#   Or in Vivado TCL Console: source run_sim.tcl
#
# Revision History:
#    2026.02.05 - Initial
###############################################################################

# Project settings
set PROJECT_DIR ".."
set SOURCE_DIR "${PROJECT_DIR}/source/hdl"
set TB_DIR "tb_src"
set SIM_DIR "sim_results"

# Create simulation results directory
file mkdir ${SIM_DIR}

# Compile order (dependencies first)
set SOURCE_FILES {
    # Basic modules
    "${SOURCE_DIR}/cdc_sync_3ff.sv"
    "${SOURCE_DIR}/reset_sync.sv"
    "${SOURCE_DIR}/async_fifo.sv"
    "${SOURCE_DIR}/async_fifo_1b.sv"
    "${SOURCE_DIR}/fifo_1b.sv"

    # Communication
    "${SOURCE_DIR}/spi_slave.sv"
    "${SOURCE_DIR}/i2c_master.sv"
    "${SOURCE_DIR}/rf_spi_controller.sv"

    # Clock/Timing
    "${SOURCE_DIR}/dcdc_clk.sv"
    "${SOURCE_DIR}/clock_gen_top.sv"

    # Core modules
    "${SOURCE_DIR}/p_define_refacto.sv"
    "${SOURCE_DIR}/init_refacto.sv"
    "${SOURCE_DIR}/init.sv"
    "${SOURCE_DIR}/sequencer_fsm.sv"
    "${SOURCE_DIR}/read_data_mux.sv"

    # Extracted modules (Phase 8)
    "${SOURCE_DIR}/mipi_interface_wrapper.sv"
    "${SOURCE_DIR}/async_fifo_controller.sv"
    "${SOURCE_DIR}/timing_generator.sv"
    "${SOURCE_DIR}/data_path_selector.sv"
    "${SOURCE_DIR}/state_led_controller.sv"

    # Integration modules
    "${SOURCE_DIR}/debug_integration.sv"
    "${SOURCE_DIR}/reg_map_integration.sv"
    "${SOURCE_DIR}/cyan_top.sv"
}

# Testbenches in execution order
set TESTBENCHES {
    "basic/reset_sync_tb.sv"
    "basic/cdc_gen_sync_tb.sv"
    "basic/async_fifo_param_tb.sv"
    "unit/init_tb.sv"
    "unit/state_led_controller_tb.sv"
    "unit/clock_gen_top_tb.sv"
    "unit/rf_spi_controller_tb.sv"
    "unit/i2c_master_tb.sv"
    "unit/data_path_selector_tb.sv"
    "unit/async_fifo_controller_tb.sv"
    "unit/timing_generator_tb.sv"
    "unit/mipi_interface_wrapper_tb.sv"
    "unit/debug_integration_tb.sv"
    "unit/read_data_mux_tb.sv"
    "unit/sequencer_fsm_tb.sv"
    "unit/tb_reg_map.sv"
    "unit/tb_roic_gate_drv_compare.sv"
    "integration/cyan_top_tb.sv"
}

# Function to compile all source files
proc compile_sources {} {
    global SOURCE_FILES SOURCE_DIR

    puts "=========================================="
    puts "Compiling Source Files"
    puts "=========================================="

    foreach file $SOURCE_FILES {
        if {[file exists $file]} {
            puts "Compiling: $file"
            eval exec xvlog -sv $file
        } else {
            puts "WARNING: File not found: $file"
        }
    }
}

# Function to run a single testbench
proc run_testbench {tb_name} {
    global TB_DIR SIM_DIR

    set tb_file "${TB_DIR}/${tb_name}"

    if {![file exists $tb_file]} {
        puts "WARNING: Testbench not found: $tb_file"
        return 0
    }

    puts "=========================================="
    puts "Running: $tb_name"
    puts "=========================================="

    # Get testbench name without extension
    set tb_basename [file rootname [file tail $tb_name]]
    set log_file "${SIM_DIR}/${tb_basename}.log"

    # Compile testbench
    puts "Compiling testbench..."
    if {[catch {exec xelab -debug typical ${tb_dir}/* -s ${tb_basename} -log ${log_file}} result]} {
        puts "ERROR: Elaboration failed for $tb_name"
        puts $result
        return 0
    }

    # Run simulation
    puts "Running simulation..."
    if {[catch {exec xsim ${tb_basename} -runall} result]} {
        puts "ERROR: Simulation failed for $tb_name"
        puts $result
        return 0
    }

    puts "PASSED: $tb_name"
    return 1
}

# Function to run all testbenches
proc run_all_testbenches {} {
    global TESTBENCHES

    set total 0
    set passed 0
    set failed 0

    foreach tb $TESTBENCHES {
        incr total
        if {[run_testbench $tb]} {
            incr passed
        } else {
            incr failed
        }
    }

    puts "\n=========================================="
    puts "Simulation Summary"
    puts "=========================================="
    puts "Total:   $total"
    puts "Passed:  $passed"
    puts "Failed:  $failed"
    puts "=========================================="

    return $failed
}

# Main execution
proc main {} {
    # Compile sources
    compile_sources

    # Run all testbenches
    set fail_count [run_all_testbenches]

    if {$fail_count == 0} {
        puts "\nSUCCESS: All simulations passed!"
        exit 0
    } else {
        puts "\nFAILURE: $fail_count simulations failed!"
        exit 1
    }
}

# Run main
main
