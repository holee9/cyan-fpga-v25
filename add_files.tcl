# =============================================================================
# Add new sub-module files to Vivado project
# =============================================================================

# Open project
open_project D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/build/xdaq_top.xpr

# Add new sub-module files
puts "Adding new sub-module files to project..."

add_files {
    D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/source/hdl/async_fifo_controller.sv
    D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/source/hdl/data_path_selector.sv
    D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/source/hdl/timing_generator.sv
    D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/source/hdl/state_led_controller.sv
    D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/source/hdl/rf_spi_controller.sv
    D:/workspace/gittea-work/v2025/CYAN-FPGA/xdaq_top/source/hdl/mipi_interface_wrapper.sv
}

# Update design sources
update_compile_order -import_sources

puts "Files added successfully. Close project."
close_project
