###############################################################################
# CDC-002 Fix: Clock Group Definitions
# Date: 2025-02-03
# Description: Declare asynchronous clock groups for proper CDC analysis
###############################################################################

# Asynchronous clock groups - these clocks are not related
# Group 1: 200MHz DPHY clock domain
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins -hierarchical -filter {REF_PIN_NAME == dphy_clk}]]
# Group 2: 100MHz system clock domain  
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins -hierarchical -filter {REF_PIN_NAME == c0}]]
# Group 3: 20MHz FSM clock domain
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins -hierarchical -filter {REF_PIN_NAME == c1}]]

# CDC false paths for verified synchronizers
#set_false_path -from [get_pins {}] -to [get_pins {}]
#set_false_path -from [get_pins {}] -to [get_pins {}]

#set_false_path -from [get_pins {}] -to [get_pins {}]
#set_false_path -from [get_pins {}] -to [get_pins {}]

#set_false_path -from [get_pins {roic_tg_gen_int/DF_SM4_fall_reg[6]/C}] -to [get_pins roic_tg_gen_int/DF_SM4_reg/D]
#set_false_path -from [get_pins {roic_tg_gen_int/LPF2_rise_reg[6]/C}] -to [get_pins roic_tg_gen_int/LPF2_reg/D]
#set_false_path -from [get_pins {seq_fsm_inst/current_repeat_count_reg[*]/C}] -to [get_pins {gen_ti_roic_top[*].ti_roic_top_inst/data_reorder/read_req_dly_reg[*]/D}]
#set_false_path -from [get_pins {seq_fsm_inst/active_repeat_count_reg[*]/C}] -to [get_pins {gen_ti_roic_top[*].ti_roic_top_inst/data_reorder/read_req_dly_reg[*]/D}]
#set_false_path -from [get_pins {reg_map_inst/reg_max_h_count_reg[*]/C}] -to [get_pins {gen_ti_roic_top[*].ti_roic_top_inst/data_reorder/read_req_dly_reg[*]/D}]
#set_false_path -from [get_pins {gen_ti_roic_top[*].ti_roic_top_inst/data_reorder/even_odd_toggle_2d_reg/C}] -to [get_pins {read_data_mux_inst/read_data_out_b_reg[*]/D}]
set_false_path -from [get_pins {s_sync_current_repeat_count_o_reg[*]/C}] -to [get_pins {gen_ti_roic_top[*].ti_roic_top_inst/data_reorder/read_req_dly_reg[*]/D}]

set_false_path -from [get_pins {roic_tg_gen_int/counter_reg[*]/C}] -to [get_pins {gen_ti_roic_top[*].ti_roic_top_inst/data_reorder/read_req_dly_reg[*]/CLR}]

# set_false_path -from [get_pins {}] -to [get_pins {}]
#set_false_path -from [get_pins {}] -to [get_pins {}]
#set_false_path -from [get_pins {}] -to [get_pins {}]



###############################################################################
# Additional CDC False Paths (Week 1)
###############################################################################

# 3-stage synchronizer outputs (safe)
set_false_path -through [get_pins -hierarchical -filter {NAME =~ *cdc_sync_3ff*sync_stage*}] -to [get_pins -hierarchical -filter {NAME =~ *cdc_sync_3ff*sync_stage*}]

# Async FIFO Gray code synchronizers (safe - async_fifo_1b pattern)
set_false_path -through [get_pins -hierarchical -filter {NAME =~ *fifo*gray*sync*}] -to [get_pins -hierarchical -filter {NAME =~ *fifo*gray*sync*}]

# Reset synchronization (async assert, sync deassert is safe)
set_false_path -from [get_ports nRST] -to [get_pins -hierarchical -filter {REF_PIN_NAME =~ clk* && IS_SEQUENTIAL}]

# MIPI DPHY interface (controlled by IP core)
set_false_path -from [get_cells -hierarchical -filter {PRIMITIVE_TYPE == dphy}] -to [get_cells -hierarchical -filter {PRIMITIVE_TYPE == dphy}]
