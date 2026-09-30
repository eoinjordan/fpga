set project_dir [file dirname [file normalize [info script]]]
cd $project_dir
set_device -name GW2AR-18C GW2AR-LV18QN88C8/I7
add_file {../../boards/tangnano20k/rtl/board_reset.v}
add_file {../../06-riscv-soc/rtl/simple_soc.v}
add_file {../../06-riscv-soc/third_party/picorv32.v}
add_file {../rtl/semnpu_regs.v}
add_file {../../boards/tangnano20k/rtl/board_uart.v}
add_file {../../02-golden-models/rtl/popcount.v}
add_file {../../02-golden-models/rtl/popand.v}
add_file {../../02-golden-models/rtl/hamming.v}
add_file {../../02-golden-models/rtl/dot8.v}
add_file {tangnano20k_top.v}
add_file {tangnano20k.cst}
add_file {tangnano20k.sdc}
set_option -top_module tangnano20k_top
set_option -verilog_std sysv2017
set_option -output_base_name tangnano20k
run all
