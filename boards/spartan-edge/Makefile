# Requires Vivado on PATH (or set VIVADO=C:/Xilinx/Vivado/<ver>/bin/vivado.bat)
VIVADO ?= vivado

blinky.bit: rtl/blinky_top_sea.v ../../01-hdl-basics/rtl/blinky.v spartan_edge.xdc build.tcl
	$(VIVADO) -mode batch -nolog -nojournal -source build.tcl \
		-tclargs blinky_top_sea $@ rtl/blinky_top_sea.v ../../01-hdl-basics/rtl/blinky.v

clean:
	rm -f *.bit *.rpt vivado*.log vivado*.jou

.PHONY: clean
