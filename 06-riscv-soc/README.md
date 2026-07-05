# Stage 06 — SemRV: a PicoRV32 SoC (working in simulation)

**Needs board: no** for everything on this page. The whole SoC — CPU,
RAM, MMIO, and the stage 07 SemNPU — boots and runs firmware in Icarus.

```powershell
make        # assembles firmware, boots the CPU, checks UART + NPU results
```

Expected output:

```
SemRV!
PASS: tb_soc — RISC-V firmware drove the SemNPU correctly (popand=51 hamming=36 dot8=-5063, 358 cycles)
```

(The `$readmemh` warning about "not enough words" is benign — the
firmware is smaller than the 4KB RAM.)

## What's here

| File | What it is |
|------|------------|
| [third_party/picorv32.v](third_party/picorv32.v) | upstream PicoRV32 (ISC license) — the CPU |
| [rtl/simple_soc.v](rtl/simple_soc.v) | bus decode, 4KB RAM, MMIO, SemNPU hookup |
| [firmware/build_firmware.py](firmware/build_firmware.py) | RV32I **encoded by hand in Python** — no gcc needed |
| [tb/tb_soc.v](tb/tb_soc.v) | boots the SoC, checks every observable result |

## Memory map

| Address | What |
|---------|------|
| 0x0000_0000–0x0000_0FFF | RAM (code + data) |
| 0x8000_0000 | UART TX |
| 0x8000_0004/08/0C | REPORT0..2 (test result registers) |
| 0x8000_0010 | DONE |
| 0x8000_1000–0x8000_10FF | SemNPU (stage 07) |

## Why the firmware is hand-assembled

`build_firmware.py` encodes LUI/ADDI/LW/SW/JAL bit by bit — read it next
to the RISC-V spec's instruction-format tables and you'll understand
instruction encoding better than any compiler user ever does. It also
computes the golden NPU results in Python, so the testbench proves the
**hardware** and the **software's view of the hardware** agree.

## The upgrade path (in order)

1. **riscv-gcc firmware.** Install the xPack `riscv-none-elf-gcc`
   toolchain, write `start.S` + linker script + C main, and replace
   `firmware.hex`. PicoRV32's upstream `firmware/` directory is the
   template. Now you can write real programs.
2. **Real UART.** Replace the `uart_wr` tap with a 8N1 TX shift register
   at 115200 baud on pin 69 → `hello` over USB serial on the board.
   Sipeed's `vendor/TangNano-20K-example/picorv32/` proves the wiring.
3. **On the board.** Synthesize with the stage 03 flow (add the SoC files
   to a yosys target). PicoRV32 small config ≈ 1500 LUTs of our 20,736.
4. **Interrupts + timer.** Enable `ENABLE_IRQ`, add a machine timer —
   this is exactly what stage 08 (Zephyr) needs from the hardware.
5. **Point it at the PPU/APU** (stages 04/05) — then C code moves sprites
   and plays notes, and the console is programmable.

## Exercises

1. Add a `BEQ`/`BNE` encoder to `build_firmware.py` and write a firmware
   loop that prints "0123456789" using a counter, not unrolled stores.
2. Add a fourth REPORT register and have firmware compute
   `popand XOR hamming` on the CPU (ADD/XOR encoders needed) — CPU math
   vs coprocessor math in one program.
3. Measure: how many cycles does the DOT8 sequence take vs. computing the
   same dot product in pure RV32I (no MUL — shift-and-add)? That ratio is
   your first real "NPU speedup" number.
