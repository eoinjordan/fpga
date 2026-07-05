# Stage 05 — Input and audio

**Prerequisite: stage 04 sprites moving on screen.**

## Input

The two onboard buttons (S1 pin 88, S2 pin 87 — pull-down, pressed = 1)
feed [rtl/debounce.v](rtl/debounce.v), a 2-FF synchronizer plus
counter filter. The testbench covers bounce rejection and both stable
transitions.

External controller options can reuse the debounced GPIO edge:
1. 4 tactile buttons on GPIO (a breadboard D-pad)
2. SNES/NES pad protocol — it's just a shift register (latch, clock,
   serial data), a lovely afternoon project
3. UART "controller" from the PC for automated testing

## Audio

The board has a MAX98357A I2S amplifier onboard (see
`vendor/TangNano-20K-example/audio/` for working pin usage).

Implemented blocks:

| File | What it is |
|------|------------|
| [rtl/square_channel.v](rtl/square_channel.v) | phase accumulator, duty select, enable, and 4-bit volume |
| [rtl/noise_channel.v](rtl/noise_channel.v) | 15-bit LFSR noise source |
| [rtl/audio_mixer.v](rtl/audio_mixer.v) | three-voice signed mixer |
| [rtl/i2s_tx.v](rtl/i2s_tx.v) | 16-bit stereo serial transmitter for the MAX98357A path |
| [tb/tb_debounce.v](tb/tb_debounce.v) | debounce regression |
| [tb/tb_square_channel.v](tb/tb_square_channel.v) | square-wave polarity/enable regression |
| [tb/tb_i2s_tx.v](tb/tb_i2s_tx.v) | serial frame/lrclk regression |

Run it:

```powershell
make
```
