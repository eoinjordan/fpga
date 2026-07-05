IVERILOG ?= iverilog
VVP      ?= vvp
FLAGS     = -g2012 -Wall -Irtl

DEVICE = GW2AR-LV18QN88C8/I7
FAMILY = GW2A-18C
BOARD  = tangnano20k

# ---- simulation (no board needed) -----------------------------------
all: run-tb_video_timing run-tb_tmds_encoder

run-tb_video_timing: tb_video_timing.vvp
	$(VVP) $<

tb_video_timing.vvp: tb/tb_video_timing.v rtl/video_timing.v
	$(IVERILOG) $(FLAGS) -o $@ $^

run-tb_tmds_encoder: tb_tmds_encoder.vvp
	$(VVP) $<

tb_tmds_encoder.vvp: tb/tb_tmds_encoder.v rtl/tmds_encoder.v
	$(IVERILOG) $(FLAGS) -o $@ $^

# ---- open-flow bitstream: blinky smoke test (board needed) ----------
blinky.json: rtl/blinky_top.v ../01-hdl-basics/rtl/blinky.v
	yosys -p "read_verilog $^; synth_gowin -top blinky_top -json $@"

blinky_pnr.json: blinky.json constraints/tangnano20k.cst
	nextpnr-himbaechel --json $< --write $@ \
		--device $(DEVICE) \
		--vopt family=$(FAMILY) \
		--vopt cst=constraints/tangnano20k.cst

blinky.fs: blinky_pnr.json
	gowin_pack -d $(FAMILY) -o $@ $<

flash: blinky.fs
	openFPGALoader -b $(BOARD) $<

clean:
	rm -f *.vvp *.vcd *.json *.fs

.PHONY: all run-tb_video_timing run-tb_tmds_encoder flash clean
