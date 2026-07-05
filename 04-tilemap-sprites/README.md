# Stage 04 — Tile/sprite PPU (planned)

**Prerequisite: stage 03 colour bars on a real monitor.**

The console's picture processor. No framebuffer — a 720p frame doesn't fit
in BSRAM (see docs/hardware-notes.md). Instead, pixels are generated as
the scan passes, exactly like the NES/Game Boy PPUs.

## Internal resolution

Render 320×180 and pixel-quadruple to 1280×720 (each internal pixel is a
4×4 block). This keeps memory tiny and gives the chunky retro look.

## Memory plan (all BSRAM)

| RAM | Size | Contents |
|-----|------|----------|
| Tile ROM | 256 tiles × 8×8 px × 4 bpp = 64 Kbit | pixel patterns |
| Tilemap | 64×32 entries × 8 bit = 16 Kbit | which tile where (wider than screen for scrolling) |
| Palette | 16 entries × 24 bit | 4-bit colour index → RGB |
| Sprite table | 32 sprites × 32 bit | x, y, tile_id, flags (flip/priority) |

Total ≈ 82 Kbit of 828 Kbit — cheap.

## Build order

1. `tilemap_renderer.v` — background only, no scroll. Golden model: a
   Python script that renders the same tilemap to a PNG; testbench dumps
   the DUT's frame to a file and Python diffs them pixel-for-pixel.
   (The stage 02 workflow, applied to images.)
2. Scroll registers (scroll_x, scroll_y).
3. Sprite overlay: per scanline, scan the sprite table during hblank into
   a line buffer, then mux sprite pixels over background during scanout.
4. A Python `png2tiles.py` asset pipeline so you can draw tiles in any
   editor and `$readmemh` them in.

Milestone: a scrolling tile background with a joystick-free bouncing
sprite — the "it's actually a console now" moment.
