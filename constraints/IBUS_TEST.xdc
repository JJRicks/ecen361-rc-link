## Pins for IBUS_TEST_TOP on the Cmod A7-35T (from Digilent's Cmod-A7-Master.xdc)

set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVCMOS33 } [get_ports clk_12MHz]
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports clk_12MHz]

set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports IBUS]    ; # Pmod JA pin 2
set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports OUT]     ; # Pmod JA pin 1, same as the PWM project
set_property -dict { PACKAGE_PIN A17 IOSTANDARD LVCMOS33 } [get_ports {led[0]}]
set_property -dict { PACKAGE_PIN C16 IOSTANDARD LVCMOS33 } [get_ports {led[1]}]

## Configuration bank is 3.3V on the Cmod A7 (silences DRC warning CFGBVS-1)
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
