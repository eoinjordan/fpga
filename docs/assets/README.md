# Course artwork

Drop the generated course images here with these names, then the
references below light up in the docs:

| File | Used as |
|------|---------|
| `cover.png` | course-book front cover (root README header) |
| `tutorial-01-sim-first.svg` | stage 01/02 opener — sim-first workflow |
| `tutorial-02-graphics-pipeline.svg` | stage 03/04 opener — retro graphics pipeline |
| `tutorial-03-semrv-semnpu.svg` | stage 06/07 opener — SoC + NPU |

## Accuracy notes — read before regenerating

The SVG tutorial openers in this folder use the implemented values
below. Keep these constraints if regenerating PNG artwork from the project
concept, otherwise the art will contradict the RTL:

1. **Video mode**: art says 640×480@60 (25.175 MHz); the repo implements
   **1280×720@60 (74.25 MHz)** — 1650×750 total, not 800×525.
2. **Bus**: art says "AXI4-LITE interconnect"; the repo uses the
   **PicoRV32 native valid/ready interface** (simpler, one handshake).
3. **CPU config**: art says RV32IMC with 16KB I$/D$ and IRQ controller;
   the repo runs **RV32I, no caches, no IRQs yet** (IRQs arrive with
   stage 08 prerequisites).
4. **Memory map**: art shows UART at 0x1000_0000 / SemNPU at
   0x1000_2000 / 64KB BRAM; the repo uses **4KB RAM at 0x0, MMIO at
   0x8000_0000, SemNPU at 0x8000_1000**.
5. **SemNPU ops**: art shows "8×256b" POPAND and a TOP-K unit; the repo
   implements **128-bit** POPAND/HAMMING and DOT8; ARGMAX/top-k is a
   stage 07 growth item, not built.
6. **Tiles/sprites**: art shows 16×16; the stage 04 plan is **8×8 tiles**
   at 320×180 internal resolution.
7. The UART console mock-up ("SemNPU self-test... All tests passed") is
   aspirational — the real equivalent today is `tb_soc`'s output
   (popand=51, hamming=36, dot8=-5063).

Aspirational art is fine on a cover; in tutorial interiors, numbers that
contradict the code cost the reader trust. Prefer regenerating panels
2-5 above with the real values.
