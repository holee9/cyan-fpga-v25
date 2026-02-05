# =============================================================================
# Vivado Build Script for xdaq_top
# =============================================================================
# Description: Automated bitstream generation for CYAN-FPGA project
#
# Vivado Path: D:\AMDDesignTools\2025.2\Vivado
# Project: D:\workspace\gittea-work\v2025\CYAN-FPGA\xdaq_top\build\xdaq_top.xpr
#
# Build Steps:
#   1. Synthesis  - RTL to netlist
#   2. Implementation - Netlist to placed/routed design
#   3. Bitstream - Generate programming file
# =============================================================================

# Open project
open_project D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/build/xdaq_top.xpr

# =============================================================================
# Step 1: Synthesis
# =============================================================================
puts "\n=========================================="
puts "STEP 1: Running Synthesis..."
puts "=========================================="
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}
puts "Synthesis completed successfully!"

# =============================================================================
# Step 2: Implementation
# =============================================================================
puts "\n=========================================="
puts "STEP 2: Running Implementation..."
puts "=========================================="
reset_run impl_1
launch_runs impl_1 -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
}
puts "Implementation completed successfully!"

# =============================================================================
# Step 3: Bitstream Generation
# =============================================================================
puts "\n=========================================="
puts "STEP 3: Generating Bitstream..."
puts "=========================================="
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {![file exists D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/build/xdaq_top.runs/impl_1/xdaq_top.bit]} {
    puts "ERROR: Bitstream file not found!"
    exit 1
}
puts "Bitstream generated successfully!"

# =============================================================================
# Build Summary
# =============================================================================
puts "\n=========================================="
puts "BUILD SUMMARY"
puts "=========================================="
puts "Synthesis: PASS"
puts "Implementation: PASS"
puts "Bitstream: PASS"
puts "Bitstream file: D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/build/xdaq_top.runs/impl_1/xdaq_top.bit"
puts "=========================================="

close_project
exit 0
