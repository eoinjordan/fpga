# Stage 07 — The SemNPU coprocessor (planned)

**Prerequisite: stage 06 CPU running C with memory-mapped peripherals.**

The payoff stage: wrap stage 02's sim-proven blocks (popand, hamming,
dot8) in a register file the CPU can drive.

## Register map (draft)

| Offset | Name | Function |
|--------|------|----------|
| 0x00 | CTRL | bit0 start, bit1 clear; op select in bits 7:4 (POPAND / HAMMING / DOT8 / ARGMAX) |
| 0x04 | STATUS | bit0 done |
| 0x10–0x1C | A[0..3] | operand A, 128 bits as 4 words |
| 0x20–0x2C | B[0..3] | operand B |
| 0x30 | STREAM | write int8 pairs here for DOT8 (a in [7:0], b in [15:8]) |
| 0x34 | RESULT | score / distance / accumulator / argmax index |

Base address 0x8000_0000 on the PicoRV32 bus.

## Software side

```c
semnpu_write_vec(SEM_A, bitset_a, 4);
semnpu_write_vec(SEM_B, bitset_b, 4);
semnpu_start(SEM_OP_POPAND);
uint32_t score = semnpu_result();
```

Golden-model discipline still applies: the same Python models from
stage 02 generate the firmware's test vectors, and the C test suite
checks hardware results against baked-in expected values.

## Demos (pick by mood)

1. **Semantic sprite AI**: each NPC carries a feature bitset; POPAND
   against the player's state picks its behavior. Retro game where the
   "AI" is real hardware similarity search.
2. **Edge Impulse dashboard**: stream int8 feature vectors over UART,
   DOT8 computes class scores against stored weights, PPU renders
   confidence bars at 60 fps.
3. **Bloom gate visualizer**: k hash probes against a bit array in BSRAM,
   screen shows definitely-absent / maybe-present verdicts live.

## Stretch

- Custom PicoRV32 instruction via the PCPI coprocessor interface
  (`popcnt rd, rs1, rs2` instead of memory-mapped registers)
- DMA: let the SemNPU read vectors straight out of SDRAM
- Batch mode: N stored reference vectors, hardware returns top-1 index
  (that's a 1-nearest-neighbour classifier in silicon)
