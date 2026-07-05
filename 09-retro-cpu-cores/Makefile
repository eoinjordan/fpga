IVERILOG ?= iverilog
VVP      ?= vvp
FLAGS     = -g2012 -Wall -Irtl

all: run-tb_cpu_bus_socket

run-tb_cpu_bus_socket: tb_cpu_bus_socket.vvp
	$(VVP) $<

tb_cpu_bus_socket.vvp: tb/tb_cpu_bus_socket.v rtl/cpu_bus_socket.v
	$(IVERILOG) $(FLAGS) -o $@ $^

clean:
	rm -f *.vvp *.vcd

.PHONY: all run-tb_cpu_bus_socket clean
