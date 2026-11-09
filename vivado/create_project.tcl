# Builds the IBUS_TEST Vivado project from the files in this repo.
#
# How to run it (pick one):
#   - Vivado start page: Tools > Run Tcl Script... and choose this file.
#   - Vivado Tcl Console:  source {C:/path/to/ecen361-rc-link/vivado/create_project.tcl}
#     (keep the braces; they make paths with spaces work)
#
# The project lands in vivado/ibus_test/, which git ignores.
# Running it again deletes and recreates that project folder.
#
# NOTE: written against Vivado 2025.2 but not yet run. If it errors, use the
# step-by-step GUI instructions in docs/05-vivado-bench-test.md instead.

set repo [file normalize [file join [file dirname [file normalize [info script]]] ..]]

create_project ibus_test [file join $repo vivado ibus_test] -part xc7a35tcpg236-1 -force

# design sources
add_files -norecurse [list \
    [file join $repo hdl IBUS_UART_RX.sv] \
    [file join $repo hdl IBUS_RX.sv] \
    [file join $repo hdl IBUS_TEST_TOP.sv] \
    [file join $repo team-snapshot PWM.sv] ]

# pins
add_files -fileset constrs_1 -norecurse [file join $repo constraints IBUS_TEST.xdc]

# testbenches
add_files -fileset sim_1 -norecurse [list \
    [file join $repo sim IBUS_RX_tb.sv] \
    [file join $repo sim IBUS_TEST_TOP_tb.sv] ]

# PWM.sv also contains the old BUTTONS top, so pick the tops explicitly
set_property top IBUS_TEST_TOP [get_filesets sources_1]
set_property top IBUS_RX_tb [get_filesets sim_1]

# run the testbench until it calls $finish instead of stopping at 1000ns
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

# also write a .bin next to the .bit (needed to program the flash)
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "ibus_test project created. Next: docs/05-vivado-bench-test.md, Part C."
