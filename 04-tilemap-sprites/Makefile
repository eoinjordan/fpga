IVERILOG ?= iverilog
VVP      ?= vvp
FLAGS     = -g2012 -Wall -Irtl

all: run-tb_tile_sprite_ppu

run-tb_tile_sprite_ppu: tb_tile_sprite_ppu.vvp
	$(VVP) $<

tb_tile_sprite_ppu.vvp: tb/tb_tile_sprite_ppu.v rtl/tile_sprite_ppu.v
	$(IVERILOG) $(FLAGS) -o $@ $^

clean:
	rm -f *.vvp *.vcd

.PHONY: all run-tb_tile_sprite_ppu clean
