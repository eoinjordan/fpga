IVERILOG ?= iverilog
VVP      ?= vvp
PYTHON   ?= python
# no -Wall here: third_party/picorv32.v is upstream code with benign warnings
FLAGS     = -g2012

RTL = rtl/simple_soc.v \
      third_party/picorv32.v \
      ../07-semnpu/rtl/semnpu_regs.v \
      ../02-golden-models/rtl/popand.v \
      ../02-golden-models/rtl/hamming.v \
      ../02-golden-models/rtl/popcount.v \
      ../02-golden-models/rtl/dot8.v

all: run-tb_soc

firmware/firmware.hex firmware/expected.hex: firmware/build_firmware.py
	$(PYTHON) firmware/build_firmware.py

tb_soc.vvp: tb/tb_soc.v $(RTL) firmware/firmware.hex
	$(IVERILOG) $(FLAGS) -o $@ tb/tb_soc.v $(RTL)

run-tb_soc: tb_soc.vvp firmware/expected.hex
	$(VVP) $<

waves: run-tb_soc
	gtkwave tb_soc.vcd &

clean:
	rm -f *.vvp *.vcd firmware/firmware.hex firmware/expected.hex

.PHONY: all waves clean
