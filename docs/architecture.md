# SemBoy-20K — system architecture

The whole series builds one machine. This page is the map; each stage
README zooms into one box.

## The full system

```mermaid
flowchart LR
    subgraph PC["PC / sensors"]
        GCC["riscv-gcc firmware"]
        EI["Edge Impulse features"]
    end

    subgraph FPGA["Tang Nano 20K (GW2AR-18)"]
        subgraph CPU_SOCKET["CPU socket (pluggable)"]
            RV["PicoRV32 / VexRiscv<br/>(stage 06)"]
            RETRO["65C816 / ARM7TDMI / SM83<br/>(stage 09)"]
        end
        BUS(["system bus"])
        RAM["BSRAM<br/>code + data"]
        PPU["tile/sprite PPU<br/>(stage 04)"]
        APU["square + noise APU<br/>(stage 05)"]
        NPU["SemNPU<br/>POPAND / HAMMING / DOT8<br/>(stages 02+07)"]
        UARTIP["UART"]
        SDRAM["64 Mbit SDRAM"]
    end

    HDMI["HDMI 720p<br/>(stage 03)"]
    AMP["MAX98357A speaker"]
    PAD["buttons / pad<br/>(stage 05)"]

    GCC -- "bitstream + firmware" --> FPGA
    EI -- "UART int8 vectors" --> UARTIP
    RV --- BUS
    RETRO -.alternative.- BUS
    BUS --- RAM
    BUS --- PPU
    BUS --- APU
    BUS --- NPU
    BUS --- UARTIP
    BUS --- SDRAM
    PPU --> HDMI
    APU --> AMP
    PAD --> BUS
```

Everything hangs off one bus with one register map. That is the design
decision that makes the CPU a *socket*: RISC-V and the retro cores see
identical peripherals.

## Global memory map

| Range | Device | Stage |
|-------|--------|-------|
| `0x0000_0000` – `0x0000_0FFF` | RAM (grows later) | 06 |
| `0x4000_0000` – ... | SDRAM (when controller lands) | 06+ |
| `0x8000_0000` – `0x8000_0FFF` | System MMIO: UART, reports, DONE | 06 |
| `0x8000_1000` – `0x8000_10FF` | SemNPU register file | 07 |
| `0x8000_2000` – ... | PPU registers (reserved) | 04 |
| `0x8000_3000` – ... | APU registers (reserved) | 05 |
| `0x8000_4000` – ... | pad/input registers (reserved) | 05 |

Reserve addresses *before* you need them — renumbering a live register
map breaks every layer above it at once.

## The verification stack

The same three numbers (popand=51, hamming=36, dot8=−5063) must come out
of every layer. When a layer disagrees, the bug is in that layer.

```mermaid
flowchart TD
    PY["1 - Python golden model<br/>build_firmware.py / gen_vectors.py"]
    RTL["2 - RTL simulation<br/>stage 02 testbenches"]
    SOC["3 - CPU-driven simulation<br/>stage 06 tb_soc: firmware drives NPU"]
    HW["4 - Real board<br/>UART reports from hardware"]
    ZE["5 - Zephyr app<br/>stage 08 sample prints the same numbers"]

    PY -->|"defines truth"| RTL -->|"blocks proven"| SOC -->|"bus + firmware proven"| HW -->|"silicon proven"| ZE
```

## One frame of the console's life

What the finished machine does, 60 times a second:

```mermaid
sequenceDiagram
    participant CPU
    participant NPU as SemNPU
    participant PPU
    participant HDMI as HDMI monitor

    Note over PPU,HDMI: vblank starts (vsync fires)
    PPU->>CPU: vsync interrupt / poll
    CPU->>NPU: stream NPC feature bitsets
    NPU-->>CPU: similarity scores
    CPU->>CPU: game logic picks behaviors
    CPU->>PPU: write sprite table + scroll regs
    Note over PPU,HDMI: active video begins
    loop 720 scanlines
        PPU->>PPU: fetch tiles, overlay sprites
        PPU->>HDMI: pixels, live, no framebuffer
    end
```

The hard real-time constraint lives entirely in the PPU (a pixel every
13.5 ns at 720p). The CPU only has to finish its work within vblank —
exactly the contract 8/16-bit console programmers lived by.
