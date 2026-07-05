# Board: Seeed Spartan Edge Accelerator

Xilinx **Spartan-7 XC7S15FTGB196-1** + ESP32. Since this board is in
hand before the Tang Nano 20K arrives, it's the first real hardware the
series touches — and the port is deliberately thin: the same RTL, a
different constraints file and toolchain.

## vs. Tang Nano 20K

| | Tang Nano 20K | Spartan Edge |
|---|---|---|
| Logic | 20,736 LUT4 | 8,000 LUT6 (~comparable capacity) |
| BSRAM | 828 Kbit | 360 Kbit (10× 36Kb) |
| Multipliers | 48× 18×18 | 20× DSP48 |
| FPGA RAM | 64 Mbit SDRAM | none (ESP32 has its own) |
| Clock in | 27 MHz | **100 MHz** (pin H4) |
| Extras | BL616 USB JTAG+UART | ESP32 (WiFi/BT), IMU, ADC/DAC, SD |
| Toolchain | Gowin EDA / Apicula | Vivado / openXC7 |

Everything simulation-side (stages 01/02/06/07) is identical. The PPU
plan (stage 04) fits but with less headroom on tile ROM; the SemNPU
batch-mode stretch goals want the Tang's SDRAM.

## Getting a bitstream onto this board — the big quirk

There is **no onboard USB-JTAG**. The intended flow is:

1. Build `top.bit`
2. Copy it to a microSD card as e.g. `overlay/top.bit`
3. The **ESP32 configures the FPGA from SD at boot** using Seeed's
   `spartan-edge-esp32-boot` Arduino library (their sketch reads the
   filename and bit-bangs the bitstream into the FPGA's slave serial port)

Alternative: a real JTAG probe on the JTAG header + `openFPGALoader`.
For iteration speed the SD/ESP32 route is fine; a cheap FT2232 probe is
worth it later.

## Toolchain

**Vivado (recommended):** install *Vivado ML Standard* (free, no
license, supports XC7S15). Warning: ~40+ GB install. During install,
select only Spartan-7 device support to save most of that.
Then from this directory:

```powershell
make blinky.bit     # runs Vivado in batch mode via build.tcl
```

**openXC7 (open-source, experimental):** yosys + nextpnr-xilinx +
prjxray can target Spartan-7, but the flow is far less turnkey than
Apicula is for the Gowin board. Try it as an experiment after Vivado
works, not before.

## Files

| File | What |
|------|------|
| [spartan_edge.xdc](spartan_edge.xdc) | pin constraints, verified against two community projects in `vendor/` |
| [rtl/blinky_top_sea.v](rtl/blinky_top_sea.v) | stage 01 blinky shimmed to 100 MHz |
| [build.tcl](build.tcl) | Vivado non-project batch flow |
| [Makefile](Makefile) | `make blinky.bit` |

## Pin crib sheet (XC7S15FTGB196)

Sources: `vendor/sea-bspartan/projects/prototyping/src/constraints.xdc`
and `vendor/sea-graphics/.../test_pin.xdc` — they agree on every shared pin.

| Signal | Pin(s) |
|--------|--------|
| 100 MHz clock | H4 |
| FPGA_LED1 / LED2 | J1 / A13 |
| Buttons K1..K4 | M2, L2, L3, K3 |
| Buttons USER1 / USER2 | C3 / M4 |
| HDMI TMDS clk | G4 (p) / F4 (n), `TMDS_33` |
| HDMI TMDS d0 | G1 (p) / F1 (n) |
| HDMI TMDS d1 | E2 (p) / D2 (n) |
| HDMI TMDS d2 | D1 (p) / C1 (n) |
| RGB LED (SK6805, WS2812-style) | N11 |
| DAC7311 (audio-ish DAC) | clk M1, sync_n N1, data L1 |
| ADC1173 8-bit ADC | clk C5, data J3,J2,D12,E12,F12,C11,H11,H12 |

## HDMI on this board (stage 03 port notes)

Same architecture as the Tang, Xilinx names:

| Job | Gowin (Tang) | Xilinx (here) |
|-----|--------------|---------------|
| PLL: 100 MHz → 371.25 + 74.25 MHz | `rPLL` + `CLKDIV` | `MMCME2_BASE` (CLKOUT0 ÷ etc.) |
| 10:1 DDR serializer | `OSER10` | `OSERDESE2` master+slave pair |
| Differential output | `ELVDS_OBUF` | `OBUFDS` |
| TMDS 8b/10b encoder | yours (portable) | same file, unchanged |

The `vendor/sea-graphics` project is a working HDMI-out reference for
this exact board — read its `display_clocks`/serializer wiring when you
get to stage 03 here.
