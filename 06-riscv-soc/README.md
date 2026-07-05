# Stage 06 — PicoRV32 soft SoC (planned)

**Prerequisite: stage 03 flashing bitstreams comfortably.**
(Can be done in parallel with 04/05 — it's an independent track that
merges with them in stage 07.)

## Plan

Use PicoRV32 (size-optimized RV32I core, ~1500 LUTs in small config) —
not a from-scratch CPU yet. The SoC:

```
picorv32 (RV32I)
   |  simple native memory interface
   +-- BRAM       16-32 KB code+data ($readmemh'd from firmware build)
   +-- UART TX/RX pins 69/70 -> USB serial console
   +-- GPIO       LEDs + buttons
   +-- timer      for delays / later Zephyr tick
```

References:
- `vendor/TangNano-20K-example/picorv32/` — Sipeed's working PicoRV32
  project for this exact board (pins already proven).
- https://github.com/YosysHQ/picorv32 — upstream core + `firmware/`
  showing linker script and startup code.

## Firmware toolchain

`riscv-none-elf-gcc` (xPack builds install cleanly on Windows) with
`-march=rv32i -mabi=ilp32`. Memory-mapped I/O is just volatile pointers:

```c
#define UART_TX (*(volatile uint32_t*)0x80000000)
```

## Build order

1. Simulate the whole SoC in iverilog running a hello-world ELF (PicoRV32
   ships a testbench pattern for this) — printf-over-UART in simulation.
2. Same bitstream on the board, `hello` over USB serial.
3. GPIO peripheral: C program blinks LEDs, reads buttons.
4. Point the CPU's registers at stage 04's PPU and stage 05's APU:
   now C code moves sprites and plays notes. **The console is alive.**

Milestone: Pong in C.

## Later (the Zephyr track)

Once the SoC is stable: swap in LiteX/VexRiscv or add the machine timer +
interrupt controller Zephyr needs, then write the board port
(devicetree + Kconfig). Separate write-up when we get there.
