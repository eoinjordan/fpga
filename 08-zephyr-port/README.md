# Stage 08 — Zephyr board port + SemNPU driver (templates ready)

**Prerequisite: stage 06 running on the board with a real UART, timer,
and interrupt controller.** Zephyr is not "bare metal but bigger" — it
schedules threads, so the hardware must provide a system timer and an
interrupt controller before `hello_world` can even boot.

This directory is a complete **out-of-tree Zephyr module skeleton**. The
structure is final; the `TODO(csr)` addresses get filled in from your
generated SoC.

## The route

PicoRV32 (stage 06) is perfect for learning but has no Zephyr-standard
timer/intc story. The proven path is **LiteX + VexRiscv**, which Zephyr
already supports (`litex_vexriscv` board, `litex,uart` / `litex,timer0` /
`litex,vexriscv-intc0` drivers all upstream):

1. `pip install litex` (plus `litex-boards`, which has a
   `sipeed_tang_nano_20k` target) and generate a VexRiscv SoC with
   `--with-uart --timer` for this board.
2. LiteX emits `csr.json` — every peripheral's base address and IRQ.
   Copy those numbers into `tangnano20k_semrv.dts` (they replace each
   `TODO(csr)` marker).
3. Add the SemNPU as a LiteX CSR peripheral or a plain wishbone slave at
   a fixed address — `semnpu_regs.v` drops in with a thin wishbone shim.
4. Build the sample: `west build -b tangnano20k_semrv 08-zephyr-port/app`
   with `ZEPHYR_EXTRA_MODULES` pointing at this directory.
5. Flash the SoC bitstream + firmware, watch `*** Booting Zephyr OS ***`
   arrive on the USB serial console.

## What each file is

```
zephyr/module.yml                       tells west this repo is a Zephyr module
boards/eoin/tangnano20k_semrv/
  board.yml                             board identity
  tangnano20k_semrv.dts                 THE deliverable: hardware described in devicetree
  tangnano20k_semrv_defconfig           default kernel config for this board
  Kconfig.tangnano20k_semrv             board Kconfig glue
dts/bindings/misc/eoin,semnpu.yaml      your own devicetree binding — the NPU's "type"
drivers/semnpu/                         Zephyr driver: DT_INST + device model + API
include/semnpu.h                        the API applications call
app/                                    sample: prints NPU results to the Zephyr shell
```

## Reading order (this is the lesson)

1. `eoin,semnpu.yaml` — a binding is a schema: "anything compatible with
   `eoin,semnpu` has a `reg` property".
2. `tangnano20k_semrv.dts` — the instance: "there is one at 0x80001000".
3. `drivers/semnpu/semnpu.c` — `DT_INST_REG_ADDR(0)` pulls that address
   out of the devicetree at **compile time**; the driver never hardcodes it.
4. `app/src/main.c` — `DEVICE_DT_GET(DT_NODELABEL(semnpu0))` hands the
   application a typed handle. Devicetree → binding → driver → app is
   the entire Zephyr hardware model in four files you now own.

## Success criteria, in order

1. `west build` compiles for the board (devicetree + Kconfig valid)
2. Zephyr boots to `hello_world` on real hardware
3. Shell over UART responds
4. `semnpu` sample prints popand/hamming/dot8 matching stage 02's
   golden values — same numbers, fourth layer of the stack to agree.
