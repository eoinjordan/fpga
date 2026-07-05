# Stage 01 — HDL basics

**Needs board: no.** Everything here runs in Icarus Verilog.

## Goals

- Write synthesizable Verilog: `always @(posedge clk)`, non-blocking
  assignment, reset, parameters.
- Write a **self-checking testbench** — the habit that carries the whole
  series. A testbench that needs a human to stare at waveforms doesn't scale.
- Read a waveform in GTKWave.

## Modules

| File | What it teaches |
|------|-----------------|
| [rtl/counter.v](rtl/counter.v) | Registers, reset, enable, parameterized width |
| [rtl/blinky.v](rtl/blinky.v) | Clock division by counting — 27 MHz down to human speed |

`blinky.v` is also your **first board target** when the Tang Nano arrives
(stage 03's Makefile synthesizes it — see `03-hdmi/README.md`).

## What the counter looks like on a waveform

This is what you'll see in GTKWave after `make waves` — learn to read it
here first. Time flows right; every rising clock edge (↑) is when
registers act:

```
clk    __/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\__
          ↑     ↑     ↑     ↑     ↑     ↑     ↑     ↑
rst    ‾‾‾‾‾‾\_______________________________________
en     ______________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_____________
count  = 0 == 0 == 0 == 0 =X= 1 =X= 2 == 3 == 3 == 3 =
                            ^                 ^
                 first en=1 edge         en=0: holds
```

Three things to internalize from this picture:

1. `count` changes **only at clock edges** — between edges it is rock
   solid. That's what "synchronous" means.
2. `count` changes **one edge after** the inputs that caused it. The
   register samples `en` at the edge, the new value appears after it.
3. `rst` and `en` do nothing between edges. Only their value *at* the
   edge matters (that's also why testbenches sample with `@(posedge clk); #1`).

Keep [docs/verilog-cheatsheet.md](../docs/verilog-cheatsheet.md) open
while you work — the "what each construct becomes" table is the map from
code to silicon.

## Run it

```powershell
make          # compile + run all testbenches, prints PASS/FAIL
make waves    # opens tb_counter.vcd in GTKWave
make clean
```

## Exercises

1. Make `counter` count down instead of up when a new `dir` input is 1.
   Extend the testbench to prove it.
2. Change `blinky`'s `TOGGLE_COUNT` so the LED blinks at 2 Hz. How does the
   testbench parameter override (`defparam`/`-P`) keep the sim fast?
3. Add a second LED to blinky that blinks at half the rate (hint: one more
   register, no second divider).

## Ideas to internalize

- In a testbench, `#10` is fine. In RTL, delays don't exist — hardware is
  clocked. If your RTL has `#`, it won't synthesize.
- Non-blocking (`<=`) in clocked blocks, blocking (`=`) in combinational
  blocks. Mixing them is the classic beginner footgun.
- Every testbench here ends with an explicit PASS or FAIL and a non-zero
  exit code on failure — `make` catches regressions for free.
