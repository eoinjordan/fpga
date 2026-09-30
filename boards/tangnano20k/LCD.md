# 4.3-inch RGB LCD

The screen used in `GBA-FPGA` is marked **HT043IBB-16A3047-H4**.
It is a 480×272 parallel-RGB TFT connected through the Tang Nano 20K's
40-pin FPC connector. These projects use the same pin mapping and timing
profile as `GBA-FPGA/tangnano20k/gba_lcd_480x272`.

Open one of these files in Gowin IDE:

| Project | Picture |
| --- | --- |
| [03 colour bars](../../03-hdmi/gowin-lcd/tangnano20k.gprj) | Eight 60-pixel-wide bars across the 480×272 panel. |
| [04 tilemap/sprites](../../04-tilemap-sprites/gowin-lcd/tangnano20k.gprj) | 320×180 PPU scaled to 480×270, with one black row above and below. |

The `gowin-lcd` projects are self-contained within this repository. They
do not import sources from the `GBA-FPGA` checkout. The stage directories
also retain their `gowin` projects for HDMI output.

## Panel profile

| Setting | Value |
| --- | --- |
| Pixel clock | 9 MHz from the 27 MHz crystal using rPLL |
| Active area | 480×272 |
| Horizontal front / sync / back | 8 / 4 / 39 pixel clocks |
| Vertical front / sync / back | 8 / 4 / 8 lines |
| Frame totals | 531×292 |
| Frame rate | Approximately 58.05 Hz |
| HSYNC / VSYNC | Active low |
| Data | RGB565, MSB-aligned from each 8-bit colour channel |
| Panel sampling | Rising DCLK edge; FPGA launches data on the falling edge |

The panel timing in `GBA-FPGA` is based on an NV3047 module specification
and Sipeed examples. Its documentation identifies the NV3047 driver by
the panel marking; a datasheet for this exact panel part was unavailable.
The projects here match that existing setup, including its 12 ns setup
and hold requirements in the output timing constraints.

## Connector pins

| Signal | FPGA pin |
| --- | --- |
| DCLK | 77 |
| DE | 48 |
| HSYNC | 25 |
| VSYNC | 26 |
| R[0]–R[4] | 42, 41, 40, 39, 38 |
| G[0]–G[5] | 37, 36, 35, 34, 33, 32 |
| B[0]–B[4] | 31, 30, 29, 28, 27 |

The LCD and HDMI connector share pins 33–40. Leave HDMI unplugged while
using the LCD. Power off before connecting or removing the FPC cable;
use the same cable orientation as the working `GBA-FPGA` setup.
The board powers the panel backlight; these designs do not control it.

## Build and check

1. Open `gowin-lcd/tangnano20k.gprj` from stage 03 or 04.
2. Run synthesis and place-and-route. Check that the 9 MHz pixel clock
   and LCD output timing constraints are applied and pass.
3. Load `gowin-lcd/impl/pnr/tangnano20k.fs` through Gowin Programmer.
4. LED0 indicates PLL lock. S1 resets the demo.
5. On stage 03, check eight equal-width colour bars and all four panel
   edges. On stage 04, check the tile grid, sprite overlay and black rows.

The other stages use LEDs, UART or audio and do not drive the LCD pins.
They can keep using their existing projects with the screen attached.

`python3 tools/run-simulations.py --board-only` checks two full frames of
each LCD project: raster dimensions, sync widths, blanking, colour bars,
PPU coordinate mapping and output stability at the sampling edge.
It uses a functional PLL model. Gowin timing closure and the physical
panel still need to be checked on the board.
