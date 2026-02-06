###############################################################################
# File: compile_sources.do
# Date: 2026-02-05
# Designer: drake.lee
# Description: Questa Source Compilation Script
#              Compiles all source files with proper order
#
# Usage:
#   In Questa Console: do compile_sources.do
#
# Tool Paths:
#   Questa 2025.3: D:\questa_base64_2025.3
#   Compiled Libs:  D:\compile_simlib\vivado_2025_questa_2025
#
# Revision History:
#    2026.02.05 - Initial
###############################################################################

# Clear existing library
if {[file exists work]} {
    vdel -lib work -all
}

# Create working library
vlib work

# Map work library
vmap work work

# Set compile options
set COMPILE_OPTS "+acc -sv -suppress 2583 -suppress 13369"

# Set include paths
set INC_DIRS "+incdir+../source/hdl+../source/hdl/ti-roic"

puts "=========================================="
puts "Compiling Source Files for Questa"
puts "=========================================="

# =============================================================================
# Phase 1: Basic/CDC Modules (No dependencies)
# =============================================================================
puts "\n--- Phase 1: Basic/CDC Modules ---"

vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/cdc_sync_3ff.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/reset_sync.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/async_fifo.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/async_fifo_1b.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/fifo_1b.sv

# =============================================================================
# Phase 2: Communication Modules
# =============================================================================
puts "\n--- Phase 2: Communication Modules ---"

vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/spi_slave.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/i2c_master.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/rf_spi_controller.sv

# =============================================================================
# Phase 3: Clock/Timing Modules
# =============================================================================
puts "\n--- Phase 3: Clock/Timing Modules ---"

vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/dcdc_clk.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/clock_gen_top.sv

# =============================================================================
# Phase 4: Parameter/Include Files
# =============================================================================
puts "\n--- Phase 4: Parameter/Include Files ---"

vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/p_define_refacto.sv

# =============================================================================
# Phase 5: Core Modules
# =============================================================================
puts "\n--- Phase 5: Core Modules ---"

vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/init_refacto.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/init.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/sequencer_fsm.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/read_data_mux.sv

# =============================================================================
# Phase 6: Extracted Modules
# =============================================================================
puts "\n--- Phase 6: Extracted Modules ---"

vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/mipi_interface_wrapper.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/async_fifo_controller.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/timing_generator.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/data_path_selector.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/state_led_controller.sv

# =============================================================================
# Phase 7: Integration Modules
# =============================================================================
puts "\n--- Phase 7: Integration Modules ---"

vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/debug_integration.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/reg_map_integration.sv
vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/cyan_top.sv

# =============================================================================
# Phase 8: TI-ROIC Modules
# =============================================================================
puts "\n--- Phase 8: TI-ROIC Modules ---"

vlog $COMPILE_OPTS $INC_DIRS ../source/hdl/ti-roic/indata_reorder.sv

puts "\n=========================================="
puts "Source Compilation Complete!"
puts "=========================================="
