# -------------------------------------------------------------------
# FMC Clock Timing Constraints
# -------------------------------------------------------------------
create_clock -period 6.400  [get_ports GTXCLK1_P]
create_clock -period 6.400  [get_ports FMC_CLK0_M2C_P]
create_clock -period 6.400  [get_ports FMC_CLK1_M2C_P]

# -------------------------------------------------------------------
# FMC MGTs - Bank 112
# -------------------------------------------------------------------
set_property LOC GTXE2_CHANNEL_X0Y0 \
[get_cells FMC_GEN.fmc_inst/fmcgtx_exdes_i/fmcgtx_support_i/fmcgtx_init_i/U0/fmcgtx_i/gt0_fmcgtx_i/gtxe2_i]

# -------------------------------------------------------------------
# Async false reset paths
# -------------------------------------------------------------------
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *_txfsmresetdone_r*/CLR}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *_txfsmresetdone_r*/D}]
set_false_path -to [get_pins -hierarchical -filter {NAME =~ *reset_on_error_in_r*/D}]

# FMC [33:17] are inputs
#set_false_path -from [lrange [get_ports -regexp FMC_LA_P.*] 1 16]
#set_false_path -from [lrange [get_ports -regexp FMC_LA_N.*] 1 16]

