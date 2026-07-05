# Seeed Spartan Edge Accelerator — XC7S15FTGB196-1
# Pins cross-checked between vendor/sea-bspartan and vendor/sea-graphics.
# Uncomment only the ports your top module has.

# 100 MHz oscillator
set_property -dict { PACKAGE_PIN H4  IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

# FPGA_LED1 / FPGA_LED2
set_property -dict { PACKAGE_PIN J1  IOSTANDARD LVCMOS33 } [get_ports led0]
#set_property -dict { PACKAGE_PIN A13 IOSTANDARD LVCMOS33 } [get_ports led1]

# user buttons
set_property -dict { PACKAGE_PIN C3  IOSTANDARD LVCMOS33 } [get_ports btn_user1]
#set_property -dict { PACKAGE_PIN M4  IOSTANDARD LVCMOS33 } [get_ports btn_user2]
# K1-K4: M2, L2, L3, K3

# HDMI TX (stage 03 port)
#set_property -dict { PACKAGE_PIN G4 IOSTANDARD TMDS_33 } [get_ports tmds_clk_p]
#set_property -dict { PACKAGE_PIN F4 IOSTANDARD TMDS_33 } [get_ports tmds_clk_n]
#set_property -dict { PACKAGE_PIN G1 IOSTANDARD TMDS_33 } [get_ports {tmds_d_p[0]}]
#set_property -dict { PACKAGE_PIN F1 IOSTANDARD TMDS_33 } [get_ports {tmds_d_n[0]}]
#set_property -dict { PACKAGE_PIN E2 IOSTANDARD TMDS_33 } [get_ports {tmds_d_p[1]}]
#set_property -dict { PACKAGE_PIN D2 IOSTANDARD TMDS_33 } [get_ports {tmds_d_n[1]}]
#set_property -dict { PACKAGE_PIN D1 IOSTANDARD TMDS_33 } [get_ports {tmds_d_p[2]}]
#set_property -dict { PACKAGE_PIN C1 IOSTANDARD TMDS_33 } [get_ports {tmds_d_n[2]}]

# bitstream compression speeds up the SD-card/ESP32 load path
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
