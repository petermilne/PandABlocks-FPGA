#
# Generate Xilinx IP Cores
#

# Source directory
set TARGET_DIR [lindex $argv 0]
set_param board.repoPaths $TARGET_DIR/configs

# Build directory
set BUILD_DIR [lindex $argv 1]/ip_repo

# Create Managed IP Project
create_project managed_ip_project $BUILD_DIR/managed_ip_project -part xc7z030sbg485-1 -ip

set_property target_language VHDL [current_project]
set_property target_simulator ModelSim [current_project]

#
# Create PULSE_QUEUE IP
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name pulse_queue -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {49}    \
    CONFIG.Data_Count {true}        \
    CONFIG.Output_Data_Width {49}   \
    CONFIG.Reset_Type {Synchronous_Reset} \
] [get_ips pulse_queue]

generate_target all [get_files $BUILD_DIR/pulse_queue/pulse_queue.xci]
synth_ip [get_ips pulse_queue]

#
# Create Standard 1Kx32-bit FIFO IP
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name fifo_1K32 -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Input_Data_Width {32}    \
    CONFIG.Data_Count {true}        \
    CONFIG.Output_Data_Width {32}   \
    CONFIG.Reset_Type {Synchronous_Reset} \
] [get_ips fifo_1K32]

generate_target all [get_files $BUILD_DIR/fifo_1K32/fifo_1K32.xci]
synth_ip [get_ips fifo_1K32]

#
# Create PCOMP DMA FIFO IP (asymmetrical)
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name pcomp_dma_fifo -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {32}    \
    CONFIG.Use_Extra_Logic {true}   \
    CONFIG.Write_Data_Count {true}  \
    CONFIG.Output_Data_Width {64}   \
] [get_ips pcomp_dma_fifo]

generate_target all [get_files $BUILD_DIR/pcomp_dma_fifo/pcomp_dma_fifo.xci]
synth_ip [get_ips pcomp_dma_fifo]

#
# Create FMC GTX Aurora IP
#
create_ip -name gtwizard -vendor xilinx.com -library ip -version 3.5 \
-module_name fmcgtx -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.identical_protocol_file {aurora_8b10b_single_lane_2byte} \
    CONFIG.gt0_val {true}                                           \
    CONFIG.gt0_val_tx_refclk {REFCLK1_Q0}                           \
    CONFIG.identical_val_tx_line_rate {3.125}                       \
    CONFIG.identical_val_tx_reference_clock {156.250}               \
    CONFIG.identical_val_rx_line_rate {3.125}                       \
    CONFIG.identical_val_rx_reference_clock {156.250}               \
] [get_ips fmcgtx]

generate_target all [get_files $BUILD_DIR/fmcgtx/fmcgtx.xci]
synth_ip [get_ips fmcgtx]

#
# Create SFP GTX Aurora IP
#
create_ip -name gtwizard -vendor xilinx.com -library ip -version 3.5 \
-module_name sfpgtx -dir $BUILD_DIR/


set_property -dict [list \
    CONFIG.identical_protocol_file {aurora_8b10b_single_lane_2byte} \
    CONFIG.gt0_val_tx_refclk {REFCLK0_Q0}                           \
    CONFIG.gt0_val {true}                                           \
    CONFIG.gt1_val_tx_refclk {REFCLK0_Q0}                           \
    CONFIG.gt1_val {true}                                           \
    CONFIG.gt2_val_tx_refclk {REFCLK0_Q0}                           \
    CONFIG.gt2_val {true}                                           \
    CONFIG.identical_val_tx_line_rate {1}                           \
    CONFIG.identical_val_tx_reference_clock {125.000}               \
    CONFIG.identical_val_rx_line_rate {1}                           \
    CONFIG.identical_val_rx_reference_clock {125.000}               \
] [get_ips sfpgtx]

generate_target all [get_files $BUILD_DIR/sfpgtx/sfpgtx.xci]
synth_ip [get_ips sfpgtx]

#
# Create SlowFPGA Command FIFO
#
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 12.0 \
-module_name slow_cmd_fifo -dir $BUILD_DIR/

set_property -dict [list \
    CONFIG.Performance_Options {First_Word_Fall_Through} \
    CONFIG.Input_Data_Width {42}    \
    CONFIG.Output_Data_Width {42}   \
] [get_ips slow_cmd_fifo]

generate_target all [get_files $BUILD_DIR/slow_cmd_fifo/slow_cmd_fifo.xci]
synth_ip [get_ips slow_cmd_fifo]

# Close project
close_project
exit
