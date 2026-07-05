# Stage 05 — Input and audio

**Prerequisite: stage 04 sprites moving on screen.**

## Input

Start with the two onboard buttons (S1 pin 88, S2 pin 87 — pull-down,
pressed = 1). Debounce them properly: 2-FF synchronizer + counter filter.
That module (`debounce.v`) gets reused everywhere.

Then a real controller. Easiest options, in order:
1. 4 tactile buttons on GPIO (a breadboard D-pad)
2. SNES/NES pad protocol — it's just a shift register (latch, clock,
   serial data), a lovely afternoon project
3. UART "controller" from the PC for automated testing

## Audio

The board has a MAX98357A I2S amplifier onboard (see
`vendor/TangNano-20K-example/audio/` for working pin usage).

1. `i2s_tx.v` — clock out 16-bit stereo samples; sim-verify frame format
   against a Python golden model that decodes the bitstream back.
2. `square_channel.v` — phase accumulator + duty comparator, with a
   4-bit volume and a simple length counter. Two instances.
3. `noise_channel.v` — 15-bit LFSR, the classic retro percussion.
4. A tiny mixer, then memory-mapped frequency/volume registers so the
   stage 06 CPU can play notes.

Milestone: button press plays a beep; a hardcoded pattern plays a melody.
