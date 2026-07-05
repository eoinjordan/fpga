# SemBoy-20K — an FPGA series for the Tang Nano 20K

A follow-along series that ends with a retro-style FPGA console with a
semantic/inference coprocessor, built on the [Sipeed Tang Nano 20K](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html)
(Gowin GW2AR-LV18QN88C8/I7).

The series is **sim-first**: stages 01 and 02 run entirely on your PC with
the open-source toolchain, so you can make real progress before the board
arrives. Board stages (03+) use verified pin constraints from Sipeed's
official examples in `vendor/`.

## The roadmap

| Stage | Directory | Needs board? | What you build |
|-------|-----------|--------------|----------------|
| 00 | [docs/00-dev-environment.md](docs/00-dev-environment.md) | No | Toolchain: simulator, synthesis, waveform viewer |
| 01 | [01-hdl-basics/](01-hdl-basics/) | No | Counters, blinky, your first testbenches |
| 02 | [02-golden-models/](02-golden-models/) | No | SemNPU building blocks: popcount, Hamming, int8 dot product — each verified against a Python golden model |
| 03 | [03-hdmi/](03-hdmi/) | Yes (sim for timing) | HDMI/DVI output: 720p colour bars, video timing generator |
| 04 | [04-tilemap-sprites/](04-tilemap-sprites/) | Yes | Tile/sprite PPU: tilemap, palette, sprite overlay |
| 05 | [05-input-audio/](05-input-audio/) | Yes | Buttons/controller input, square-wave audio via MAX98357A |
| 06 | [06-riscv-soc/](06-riscv-soc/) | No (sim works today) | **SemRV**: PicoRV32 SoC running hand-assembled RV32I firmware — boots, prints over UART, drives the NPU |
| 07 | [07-semnpu/](07-semnpu/) | No (sim works today) | The SemNPU coprocessor register file: POPAND, HAMMING, DOT8 — already integrated with stage 06's CPU |
| 08 | [08-zephyr-port/](08-zephyr-port/) | Yes | Zephyr board port: devicetree, `eoin,semnpu` binding, driver, sample app (out-of-tree module skeleton ready) |
| 09 | [09-retro-cpu-cores/](09-retro-cpu-cores/) | Yes | Pluggable retro CPUs (65C816 / ARM7TDMI / SM83) for the GB-Studio-like engine builder |

Each stage directory has its own README with goals, theory, exercises, and
a `make` flow. Do them in order — every stage reuses modules from the one
before it. Stages 01, 02, 03 (sim), 06, and 07 are fully runnable today
with no hardware; try `cd 06-riscv-soc && make` to watch a RISC-V CPU
boot and drive the inference coprocessor in simulation.

## Quick start

```powershell
# 1. One-time setup (installs/locates tools) — see docs/00-dev-environment.md
# 2. Every session: put the toolchain on PATH
. .\tools\activate.ps1

# 3. Check everything works
.\tools\check-env.ps1

# 4. Run your first simulation
cd 01-hdl-basics
make          # runs all testbenches
make waves    # opens the waveform viewer
```

## Repository layout

```
docs/       series-wide documentation and hardware notes
tools/      environment activation + sanity checks
01-.../     one directory per stage, each self-contained:
  rtl/        synthesizable Verilog
  tb/         testbenches (simulation only)
  python/     golden models + test-vector generators (stage 02+)
  Makefile    sim / synth / waves targets
vendor/     Sipeed's official TangNano-20K-example repo (reference only,
            not tracked by this repo — reclone with tools/clone-vendor.ps1)
```

## Board reference (Tang Nano 20K)

- FPGA: Gowin GW2AR-LV18QN88 — 20,736 LUT4, 15,552 FF, 828 Kbit BSRAM, 48× 18×18 multipliers
- 64 Mbit 32-bit SDR SDRAM (in-package)
- 27 MHz crystal, HDMI out, TF-card slot, MAX98357A audio amp, 2× user buttons, 6× LEDs
- USB-C with onboard BL616 debugger (JTAG + UART)

See [docs/hardware-notes.md](docs/hardware-notes.md) for the pin crib sheet.
