IVERILOG ?= iverilog
VVP      ?= vvp
FLAGS     = -g2012 -Wall -Irtl -I../02-golden-models/rtl

all: run-tb_semnpu_regs

run-tb_semnpu_regs: tb_semnpu_regs.vvp
	$(VVP) $<

tb_semnpu_regs.vvp: tb/tb_semnpu_regs.v rtl/semnpu_regs.v ../02-golden-models/rtl/popand.v ../02-golden-models/rtl/hamming.v ../02-golden-models/rtl/popcount.v ../02-golden-models/rtl/dot8.v
	$(IVERILOG) $(FLAGS) -o $@ $^

clean:
	rm -f *.vvp *.vcd

.PHONY: all run-tb_semnpu_regs clean
