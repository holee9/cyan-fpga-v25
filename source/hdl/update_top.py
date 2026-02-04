import re

# Read cyan_top.sv
with open('source/hdl/cyan_top.sv', 'r') as f:
    content = f.read()

# Replace the read_data_mux instantiation with the new data_path_integration module
old_read_data_mux = '''    // read_data_mux module instantiation
    assign valid_roic_data = |valid_read_enable;

    assign valid_read_mem = |reordered_valid;

    read_data_mux read_data_mux_inst (
        .sys_clk                (s_clk_100mhz),
        .sys_rst                (rst_n_100mhz),  // Week 2: Standardized active-LOW
        .eim_clk                (eim_clk),
        .eim_rst                (rst_n_eim),      // Week 2: Standardized active-LOW
        .csi_done               (s_csi_done),
        .dummy_get_image        (dummy_get_image),
        .exist_get_image        (),
        .dsp_image_height       (dsp_image_height),
        .max_v_count            (max_v_count),
        .max_h_count            (max_h_count),
        .FSM_aed_read_index     (FSM_aed_read_index),
        .read_data_start        (s_read_data_start),
        .FSM_read_index         (s_valid_readout),
        .roic_read_data_a       (reordered_data_a),
        .roic_read_data_b       (reordered_data_b),
        .valid_read_mem         (valid_read_mem),
        .read_axis_tready       (s_read_axis_tready),
        .read_axis_tlast        (s_read_axis_tlast),
        .read_data_valid        (s_read_axis_tvalid),
        .read_data_out_a        (s_read_rx_data_a),
        .read_data_out_b        (s_read_rx_data_b),
        .read_frame_start       (s_read_frame_start),
        .read_frame_reset       (s_read_frame_reset),
        .data_read_req          (data_read_req)
    );'''

new_data_path = '''    /////////////////////////////////////////////////////////////////////////////
    // Week 5: Data Path Integration Module (TOP-001 Phase 2)
    /////////////////////////////////////////////////////////////////////////////
    
    // Data path integration - encapsulates read_data_mux and data processing
    data_path_integration data_path_inst (
        // Clocks and resets
        .clk_100mhz              (s_clk_100mhz),
        .eim_clk                 (eim_clk),
        .rst_n_100mhz            (rst_n_100mhz),
        .rst_n_eim               (rst_n_eim),
        .dphy_clk_200M           (s_dphy_clk_200M),
        
        // CSI control
        .csi_done                (s_csi_done),
        
        // Image acquisition control
        .dummy_get_image         (dummy_get_image),
        .dsp_image_height        (dsp_image_height),
        .max_v_count             (max_v_count),
        .max_h_count             (max_h_count),
        
        // FSM control
        .FSM_aed_read_index      (FSM_aed_read_index),
        .read_data_start         (s_read_data_start),
        .FSM_read_index          (s_valid_readout),
        
        // ROIC data inputs (from TI ROIC)
        .roic_read_data_a        (reordered_data_a),
        .roic_read_data_b        (reordered_data_b),
        .reordered_valid         (reordered_valid),
        
        // AXI-Stream interface (to MIPI)
        .read_axis_tready        (s_read_axis_tready),
        .read_axis_tready_in     (),
        .read_axis_tlast         (s_read_axis_tlast),
        .read_data_valid         (s_read_axis_tvalid),
        .read_data_out_a         (s_read_rx_data_a),
        .read_data_out_b         (s_read_rx_data_b),
        
        // Frame control
        .read_frame_start        (s_read_frame_start),
        .read_frame_reset        (s_read_frame_reset),
        
        // Data read request (to TI ROIC)
        .data_read_req           (data_read_req),
        
        // Valid data outputs (for status)
        .valid_roic_data         (valid_roic_data),
        .valid_read_mem          (valid_read_mem)
    );'''

content = content.replace(old_read_data_mux, new_data_path)

# Update the file header
content = content.replace(
    '//    2026.02.03 - Extracted MIPI integration to mipi_integration.sv (Week 5)',
    '//    2026.02.03 - Extracted MIPI integration to mipi_integration.sv (Week 5)\n//    2026.02.03 - Extracted Data path integration to data_path_integration.sv (Week 5)'
)

# Write back
with open('source/hdl/cyan_top.sv', 'w') as f:
    f.write(content)

print('Updated cyan_top.sv to use data_path_integration module')
