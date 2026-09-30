create_clock -name clk27 -period 37.037 [get_ports {clk}]
create_generated_clock -name serial371 -source [get_ports {clk}] -multiply_by 55 -divide_by 4 [get_pins {clocks/pll/CLKOUT}]
create_generated_clock -name pixel74 -source [get_pins {clocks/pll/CLKOUT}] -divide_by 5 [get_pins {clocks/divider/CLKOUT}]
set_false_path -from [get_ports {btn_s1}]
