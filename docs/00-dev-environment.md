# Stage 00 — Dev environment

Two toolchains matter for the Tang Nano 20K. You need the first one today;
the second can wait until the board arrives.

## 1. OSS CAD Suite (required — simulation + open-source synthesis)

One self-extracting archive containing everything:

| Tool | Job |
|------|-----|
| `iverilog` / `vvp` | Icarus Verilog — compile and run testbenches |
| `gtkwave` | View waveforms (`.vcd` files) |
| `yosys` | Synthesis (Verilog → netlist) |
| `nextpnr-himbaechel` | Place & route for Gowin parts (via Project Apicula) |
| `gowin_pack` | Netlist → bitstream (`.fs`) |
| `openFPGALoader` | Flash the bitstream over USB |

Install (no admin needed):

1. Download the latest `oss-cad-suite-windows-x64-*.exe` from
   <https://github.com/YosysHQ/oss-cad-suite-build/releases>
2. Run it / extract it to `C:\Users\Eoin\oss-cad-suite`
   (short path, no spaces — some tools break on long paths)
3. Every session, from the repo root: `. .\tools\activate.ps1`
4. Verify: `.\tools\check-env.ps1`

The open flow targets our exact chip: `nextpnr-himbaechel --device GW2AR-LV18QN88C8/I7`.

## 2. Gowin EDA (optional — vendor flow)

The official IDE. You want it eventually for:

- The **Gowin Analyzer Oscilloscope** (on-chip logic analyzer)
- Vendor IP generators (rPLL, SDRAM, DVI_TX) used by Sipeed's examples
- A second opinion when the open flow misbehaves

Install:

1. Register at <https://www.gowinsemi.com> and download the
   **Gowin EDA (Education)** edition — no license file needed and it
   supports the GW2AR-18 on the Tang Nano 20K.
2. Install to the default location; the command-line tool is `gw_sh`.

This cannot be automated (registration wall) — do it once, manually.

## 3. Board connection (when it arrives)

- The onboard BL616 provides USB JTAG + UART. On Windows, if
  `openFPGALoader --detect` can't see the board, use
  [Zadig](https://zadig.akeo.ie/) to bind the WinUSB driver to the JTAG
  interface (interface 0). Leave the UART interface (interface 1) alone —
  that's your serial console.
- Flash SRAM (volatile, fast, for iteration): `openFPGALoader -b tangnano20k top.fs`
- Flash to internal flash (survives power cycle): add `-f`.

## Sanity check

```powershell
. .\tools\activate.ps1
.\tools\check-env.ps1
cd 01-hdl-basics
make            # all testbenches should print PASS
```
