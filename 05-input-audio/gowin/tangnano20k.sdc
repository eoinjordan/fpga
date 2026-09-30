create_clock -name clk27 -period 37.037 [get_ports {clk}]
set_false_path -from [get_ports {btn_s1}]
set_false_path -from [get_ports {btn_s2}]
