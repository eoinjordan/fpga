# Vivado non-project batch flow.
# Usage: vivado -mode batch -source build.tcl -tclargs <top> <out.bit> <src1> [src2 ...]
set top   [lindex $argv 0]
set out   [lindex $argv 1]
set srcs  [lrange $argv 2 end]

set part xc7s15ftgb196-1

read_verilog {*}$srcs
read_xdc spartan_edge.xdc

synth_design -top $top -part $part
opt_design
place_design
route_design

report_timing_summary -file timing.rpt
report_utilization    -file utilization.rpt

write_bitstream -force $out
puts "OK: wrote $out"
