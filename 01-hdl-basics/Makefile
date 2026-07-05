IVERILOG ?= iverilog
VVP      ?= vvp
FLAGS     = -g2012 -Wall -Irtl

TBS = tb_counter tb_blinky

all: $(TBS:%=run-%)

run-%: %.vvp
	$(VVP) $<

tb_counter.vvp: tb/tb_counter.v rtl/counter.v
	$(IVERILOG) $(FLAGS) -o $@ $^

tb_blinky.vvp: tb/tb_blinky.v rtl/blinky.v
	$(IVERILOG) $(FLAGS) -o $@ $^

waves: run-tb_counter
	gtkwave tb_counter.vcd &

clean:
	rm -f *.vvp *.vcd

# run-% targets are not .PHONY: pattern rules don't apply to phony targets.
# They never create a file, so they re-run every time anyway.
.PHONY: all waves clean
