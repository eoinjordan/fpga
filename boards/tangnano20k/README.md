# Tang Nano 20K — Gowin IDE projects

Open a stage's `gowin/tangnano20k.gprj` using **File → Open** in Gowin
FPGA Designer. Keep the repository directory structure intact: source paths
are relative and reuse the existing stage RTL. No vendor checkout is needed.

All projects select **GW2AR-18C / GW2AR-LV18QN88C8/I7**, with
`tangnano20k_top` as the top module, SystemVerilog 2017 enabled, the board's
27 MHz input clock constrained, and all external ports assigned to board pins.
The device selection and pin map follow
[Sipeed's examples](https://github.com/sipeed/TangNano-20K-example) and
[IDE instructions](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/example/led.html).

| Stage / project | Hardware demonstration |
| --- | --- |
| [01 HDL basics](../../01-hdl-basics/gowin/tangnano20k.gprj) | LED0 blinks; LED1–5 show counter bits. |
| [02 golden models](../../02-golden-models/gowin/tangnano20k.gprj) | LEDs show selected bits of live POPAND, Hamming and DOT8 results. |
| [03 HDMI](../../03-hdmi/gowin/tangnano20k.gprj) | 1280×720 at 60 Hz DVI colour bars through HDMI; LED0 shows PLL lock. |
| [04 tilemap/sprites](../../04-tilemap-sprites/gowin/tangnano20k.gprj) | 320×180 PPU scaled 4× onto 720p DVI; LED0 shows PLL lock. |
| [05 input/audio](../../05-input-audio/gowin/tangnano20k.gprj) | Hold S2 to enable a quiet square/noise mix through the onboard audio DAC. LED0 shows debounced S2. |
| [06 RISC-V SoC](../../06-riscv-soc/gowin/tangnano20k.gprj) | Included bare-metal firmware prints a greeting over UART and checks SemNPU results. |
| [07 SemNPU](../../07-semnpu/gowin/tangnano20k.gprj) | Same SoC harness exercises the SemNPU register interface with firmware. |
| [09 retro CPU socket](../../09-retro-cpu-cores/gowin/tangnano20k.gprj) | Internal read transaction checks byte-lane expansion; LED0 passes, LED1 completes. No retro CPU is included in this stage. |

S1 resets every demo. LEDs are active-low. On stages 06/07, LED0–2 indicate
passing POPAND/Hamming/DOT8 results, LED3 is firmware completion, LED4 is
CPU trap, LED5 is UART FIFO overflow. UART is **115200 baud, 8N1** on the
BL616 USB serial interface. Its FIFO preserves the firmware's short greeting
without changing the teaching SoC's MMIO interface.

Video uses native Gowin `rPLL`, `CLKDIV`, `OSER10` and `TLVDS_OBUF`
primitives, with 371.25 MHz serialization and 74.25 MHz pixels. It needs
no encrypted DVI IP. Stage 05 uses a continuous standard I2S board adapter
with 32-bit slots (16 audio bits), approximately 46.875 kHz; the original
`i2s_tx` teaching module remains available for its existing simulation lesson.

## Build and program

1. Open the `.gprj`. The source, physical constraints and timing constraints
   appear in the project tree. Configuration is supplied in the project's
   `impl/project_process_config.json`.
2. Run **Synthesize**, then **Place & Route**. Check the reports for errors
   and timing violations, especially the video serializer clock.
3. The result is `gowin/impl/pnr/tangnano20k.fs`. Use Gowin Programmer with
   the Tang Nano 20K BL616 connection to load SRAM for a temporary test.
   Close the serial terminal while programming, then reopen for stages 06/07.

For command-line Gowin builds, each project also has `build.tcl`:

```powershell
& 'C:\path\to\Gowin\IDE\bin\gw_sh.exe' .\03-hdmi\gowin\build.tcl
```

Stages 06/07 include their own committed `firmware.hex` beside the `.gprj`.
The Tcl flow changes into that directory before synthesis, so memory
initialization uses the same path as the IDE. If invoking tools yourself,
use the project's `gowin` directory as the working directory.

## Stage 08: software with a missing SoC prerequisite

`08-zephyr-port` contains C code, devicetree and Zephyr module metadata;
it does not contain a synthesizable LiteX/VexRiscv top or generated SoC RTL.
It needs generated SoC RTL before it can have a standalone FPGA project.
The stage 06/07 PicoRV32 demo cannot boot this Zephyr port: it lacks the
required timer, interrupt controller, RAM capacity and LiteX CSR peripherals.
Follow [stage 08's instructions](../../08-zephyr-port/README.md) to generate
that hardware and reconcile its memory/CSR map before building Zephyr.

## macOS and Linux

The same project files work on all platforms. Install a Gowin release
for your operating system and open the `.gprj` file. Gowin's
[download cable guide](https://www.gowinsemi.com/upload/database_doc/206/document/68b8a03ea0c3f.pdf)
lists Apple Silicon support for macOS; Intel Macs need a compatible
Windows/Linux machine or VM for the vendor tools.

For simulation and project validation on macOS:

```sh
brew install python icarus-verilog yosys
python3 tools/check-gowin.py
python3 tools/run-simulations.py
```

On Debian/Ubuntu Linux:

```sh
sudo apt-get install python3 iverilog yosys make
python3 tools/check-gowin.py
python3 tools/run-simulations.py
```

To build with Gowin from either system:

```sh
/path/to/Gowin/IDE/bin/gw_sh 03-hdmi/gowin/build.tcl
```

If the primitive declarations are installed elsewhere, set
`GOWIN_SIM_CELLS` to the full path of `yosys/gowin/cells_sim.v`.
CI runs the project checks and simulations on Linux and macOS.

## Regeneration

```powershell
python tools/prepare-gowin.py       # regenerate all eight projects and firmware
python tools/check-gowin.py        # check project manifests, ports and elaboration
python tools/run-simulations.py    # core regression and board integration tests
```

The generated files are committed; these commands are not needed to open a
project. Regeneration overwrites the generated board tops and project
settings, so make persistent changes in `tools/prepare-gowin.py`.

Project paths and HDL can be checked with Icarus/Yosys without Gowin.
These checks do not prove Gowin place-and-route timing or physical board
operation; run the vendor build and hardware tests above before treating
the designs as verified bitstreams.
