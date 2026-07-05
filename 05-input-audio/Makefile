IVERILOG ?= iverilog
VVP      ?= vvp
FLAGS     = -g2012 -Wall -Irtl

TBS = tb_debounce tb_square_channel tb_i2s_tx

all: $(TBS:%=run-%)

run-%: %.vvp
	$(VVP) $<

tb_debounce.vvp: tb/tb_debounce.v rtl/debounce.v
	$(IVERILOG) $(FLAGS) -o $@ $^

tb_square_channel.vvp: tb/tb_square_channel.v rtl/square_channel.v
	$(IVERILOG) $(FLAGS) -o $@ $^

tb_i2s_tx.vvp: tb/tb_i2s_tx.v rtl/i2s_tx.v
	$(IVERILOG) $(FLAGS) -o $@ $^

clean:
	rm -f *.vvp *.vcd

.PHONY: all clean
