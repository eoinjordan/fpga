IVERILOG ?= iverilog
VVP      ?= vvp
PYTHON   ?= python3
FLAGS     = -g2012 -Wall -Irtl

TBS = tb_popand tb_hamming tb_dot8

all: vectors $(TBS:%=run-%)

vectors: vectors/.stamp

vectors/.stamp: python/gen_vectors.py
	$(PYTHON) python/gen_vectors.py
	touch $@

run-%: %.vvp vectors/.stamp
	$(VVP) $<

tb_popand.vvp: tb/tb_popand.v rtl/popand.v rtl/popcount.v
	$(IVERILOG) $(FLAGS) -o $@ $^

tb_hamming.vvp: tb/tb_hamming.v rtl/hamming.v rtl/popcount.v
	$(IVERILOG) $(FLAGS) -o $@ $^

tb_dot8.vvp: tb/tb_dot8.v rtl/dot8.v
	$(IVERILOG) $(FLAGS) -o $@ $^

waves: run-tb_dot8
	gtkwave tb_dot8.vcd &

clean:
	rm -f *.vvp *.vcd
	rm -rf vectors

# run-% targets are not .PHONY: pattern rules don't apply to phony targets.
.PHONY: all vectors waves clean
