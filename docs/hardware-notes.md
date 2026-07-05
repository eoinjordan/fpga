# Tang Nano 20K — hardware crib sheet

Part: **GW2AR-LV18QN88C8/I7** (Gowin GW2AR-18, QN88 package)

| Resource | Amount |
|----------|--------|
| LUT4 | 20,736 |
| Flip-flops | 15,552 |
| Block SRAM | 828 Kbit (46 blocks) |
| 18×18 multipliers | 48 |
| PLLs | 2 × rPLL |
| SDRAM | 64 Mbit 32-bit SDR (in-package, bonded to FPGA) |

## Pin map (verified against `vendor/TangNano-20K-example` .cst files)

| Signal | Pin(s) | Notes |
|--------|--------|-------|
| 27 MHz clock | 4 | `IO_TYPE=LVCMOS33 PULL_MODE=UP` |
| LED0..LED5 | 15, 16, 17, 18, 19, 20 | Active-low on this board |
| Button S1 | 88 | `PULL_MODE=DOWN` — reads 1 when pressed |
| Button S2 | 87 | `PULL_MODE=DOWN` |
| UART TX (FPGA→PC) | 69 | BL616 forwards to USB serial |
| UART RX (PC→FPGA) | 70 | |
| HDMI TMDS clk | 33 (p), 34 (n) | `IO_TYPE=LVDS25 DRIVE=3.5` |
| HDMI TMDS d0 | 35 (p), 36 (n) | |
| HDMI TMDS d1 | 37 (p), 38 (n) | |
| HDMI TMDS d2 | 39 (p), 40 (n) | |

In a Gowin `.cst`, a differential pair is one constraint on the `_p` port
with both pins listed: `IO_LOC "tmds_clk_p" 33,34;`

## Clocking for 720p HDMI

- Pixel clock: 74.25 MHz (1280×720@60, total 1650×750)
- Serial clock: 5× pixel = 371.25 MHz, using `OSER10` DDR serializers
  (10 bits per pixel clock, DDR at 5×)
- Both come from one rPLL fed by the 27 MHz crystal.
  27 MHz × 55 / 4 = 371.25 MHz, then `CLKDIV` by 5 → 74.25 MHz.

## Gotchas

- LEDs are **active-low**: write 0 to light one.
- Buttons have pull-**downs**: pressed = 1 (opposite of most dev boards).
- The SDRAM is SDR, not DDR — use the proven controller from NESTang
  (`vendor/TangNano-20K-example/nestang/`) rather than writing one first.
- BSRAM blocks are 18 Kbit each; a 720p framebuffer does NOT fit in BSRAM
  (1280×720×8bpp ≈ 7.4 Mbit). This is why stage 04 builds a tile engine
  that generates pixels on the fly instead of a framebuffer.
