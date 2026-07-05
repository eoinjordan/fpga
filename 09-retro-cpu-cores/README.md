# Stage 09 — Retro CPU cores for the game-engine builder

**Prerequisite: stage 06.** After integrating PicoRV32 you know the
drill: CPU core + bus + RAM + memory-mapped peripherals. A retro CPU is
the same job with a different (and much quirkier) core.

## First, the honest resource math

Full console clones do NOT fit the Tang Nano 20K. Known data points:
NESTang fits a 20K; SNESTang and GBATang both require Tang Mega
60K/138K-class parts. A complete SNES (CPU+PPU+APU+DSP) or GBA
(ARM7TDMI+PPU+sound+DMA) is 3–5× our LUT budget.

**But you don't want a console clone — you want a game-engine builder.**
That changes everything: keep the SemBoy PPU/APU (stages 04/05, sized
for this chip), and swap only the *CPU* so your engine speaks a
familiar instruction set. CPU cores alone fit easily:

| Core | ISA | ~LUTs | Fit? |
|------|-----|-------|------|
| Arlet Ottens 6502 | 6502 (NES) | ~1k | trivially |
| P65C816 (srg320, from SNESTang/MiSTer) | 65C816 (SNES) | ~4–6k | yes |
| ARM7TDMI cores (e.g. GBATang's) | ARMv4T (GBA) | ~8–12k | yes, snug next to a PPU |
| SM83 cores (e.g. from VerilogBoy/MiSTer GB) | Game Boy CPU | ~2k | trivially |

Note: **GB Studio targets the Game Boy**, so if "GB-Studio-like" is
literal, the SM83 track gives you binary-level familiarity — GBDK-2020
(a maintained C toolchain) can compile game logic for your machine.

## The three tracks (pick per project, they share everything else)

### 09a — SNES CPU track (65C816)
1. Vendor srg320's P65C816 core (GPL — fine for this repo).
2. Same integration as stage 06: bus adapter, RAM, your MMIO map.
   The 65C816's 24-bit banked addressing is the interesting/painful part.
3. Toolchain: `ca65`/`cc65` assembles 65C816; WLA-DX also works.
4. Milestone: 65C816 assembly moving a stage 04 sprite.

### 09b — GBA CPU track (ARM7TDMI)
1. Vendor an open ARM7TDMI-compatible core (GBATang's and MiSTer GBA's
   are the proven ones; check licenses when you vendor).
2. The prize: **GCC targets it directly** (`arm-none-eabi-gcc
   -mcpu=arm7tdmi`), so your engine's game logic is plain C with a
   mature compiler — by far the best software story of the three.
3. Thumb (16-bit) instructions halve code size — matters with BSRAM.
4. Milestone: C compiled for ARM7TDMI running the same demo as 09a.

### 09c — SM83 track (literal GB Studio compatibility)
1. Vendor an SM83 core (VerilogBoy, or MiSTer's GB core).
2. GBDK-2020 for C; or run actual GB Studio-exported logic if you
   emulate enough of the GB's MMIO map.

## How this feeds the engine builder

The engine = a stable "virtual console" spec your tools target:

```
engine spec (fixed):          builder side (per game):
  PPU regs   (stage 04)         tile/sprite asset pipeline (png2tiles)
  APU regs   (stage 05)         music tracker export
  SemNPU     (stage 07)         behavior bitsets / classifiers
  CPU        (pluggable!)       C / asm / bytecode game logic
```

Because stages 04/05/07 hang off a generic bus, the CPU is a socket:
RISC-V for the modern story, 65C816/ARM7TDMI/SM83 for the retro one.
Same game assets, same PPU, different brain. That's the unique thing
this project has that neither MiSTer nor GB Studio does.

## Order of attack

1. 6502 warm-up (a weekend: tiny core, huge documentation culture)
2. 09b ARM7TDMI — best compiler support, closest to "GBA CPU"
3. 09a 65C816 — after you've felt banked addressing pain secondhand
4. Engine spec doc: freeze the register map, version it, build the
   asset pipeline against it
