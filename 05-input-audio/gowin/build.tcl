set project_dir [file dirname [file normalize [info script]]]
cd $project_dir
set_device -name GW2AR-18C GW2AR-LV18QN88C8/I7
add_file {../../boards/tangnano20k/rtl/board_reset.v}
add_file {../rtl/debounce.v}
add_file {../rtl/square_channel.v}
add_file {../rtl/noise_channel.v}
add_file {../rtl/audio_mixer.v}
add_file {../rtl/i2s_tx.v}
add_file {tangnano20k_top.v}
add_file {tangnano20k.cst}
add_file {tangnano20k.sdc}
set_option -top_module tangnano20k_top
set_option -verilog_std sysv2017
set_option -output_base_name tangnano20k
run all
