#!/usr/bin/env python3
"""Builds firmware.hex for the SemRV SoC by encoding RV32I instructions
directly -- no riscv-gcc needed. Reading this file next to the RISC-V
spec's instruction-format tables IS the stage 06 encoding lesson.

The program:
  1. prints "SemRV!\\n" to the UART register
  2. loads two 128-bit vectors into the SemNPU, reads POPAND and HAMMING
  3. clears the DOT8 accumulator, streams int8 pairs, reads the result
  4. reports all three scores to MMIO report registers, then signals DONE

Also writes expected.hex (golden values, computed here in Python) which
the testbench compares against what the hardware actually produced.
"""
from pathlib import Path

OUT = Path(__file__).resolve().parent

# ---- memory map (must match simple_soc.v / semnpu_regs.v) -------------
MMIO   = 0x8000_0000        # x1 points here
UART_TX  = 0x00             # write a character
REPORT0  = 0x04             # popand score
REPORT1  = 0x08             # hamming distance
REPORT2  = 0x0C             # dot8 accumulator
DONE     = 0x10             # write 1 to end the test

NPU    = 0x8000_1000        # x3 points here
NPU_A    = 0x00             # A[31:0] .. A[127:96] at 0x00,0x04,0x08,0x0C
NPU_B    = 0x10
NPU_POPAND  = 0x20          # read
NPU_HAMMING = 0x24          # read
NPU_STREAM  = 0x28          # write (a in [7:0], b in [15:8])
NPU_CLEAR   = 0x2C          # write anything
NPU_ACC     = 0x30          # read

# ---- test data ---------------------------------------------------------
VEC_A = 0xDEADBEEF_C0FFEE00_12345678_0F0F0F0F
VEC_B = 0xFEEDFACE_C0FFEE00_87654321_00FF00FF
DOT_PAIRS = [(100, -50), (-128, 127), (7, 9), (-1, -1), (127, 127), (0, 55)]

EXPECTED_POPAND  = bin(VEC_A & VEC_B).count("1")
EXPECTED_HAMMING = bin(VEC_A ^ VEC_B).count("1")
EXPECTED_DOT8    = sum(a * b for a, b in DOT_PAIRS)

# ---- RV32I encoders (see spec ch. 2, "Base Instruction Formats") ------
def lui(rd, imm20):          # U-type
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | 0x37

def addi(rd, rs1, imm12):    # I-type
    return ((imm12 & 0xFFF) << 20) | (rs1 << 15) | (0 << 12) | (rd << 7) | 0x13

def lw(rd, rs1, imm12):      # I-type, funct3=010
    return ((imm12 & 0xFFF) << 20) | (rs1 << 15) | (2 << 12) | (rd << 7) | 0x03

def sw(rs2, rs1, imm12):     # S-type: immediate is split around rs2/rs1
    imm = imm12 & 0xFFF
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (2 << 12) \
         | ((imm & 0x1F) << 7) | 0x23

def jal(rd, offset):         # J-type: the famously scrambled immediate
    o = offset & 0x1FFFFF
    return (((o >> 20) & 1) << 31) | (((o >> 1) & 0x3FF) << 21) \
         | (((o >> 11) & 1) << 20) | (((o >> 12) & 0xFF) << 12) \
         | (rd << 7) | 0x6F

def li(rd, value):
    """Load a full 32-bit constant: lui + addi.
    addi sign-extends its 12-bit immediate, so if bit 11 of the low part
    is set we must bump the upper part by one -- the classic li fixup."""
    value &= 0xFFFFFFFF
    hi = (value + 0x800) >> 12
    lo = value & 0xFFF
    insns = [lui(rd, hi)]
    if lo or not hi:
        insns.append(addi(rd, rd, lo))
    return insns

# ---- the program -------------------------------------------------------
X0, X1, X2, X3 = 0, 1, 2, 3
prog = []

prog += li(X1, MMIO)                       # x1 = MMIO base
prog += li(X3, NPU)                        # x3 = SemNPU base

for ch in "SemRV!\n":                      # 1. hello over UART
    prog.append(addi(X2, X0, ord(ch)))
    prog.append(sw(X2, X1, UART_TX))

for i in range(4):                         # 2. load A and B, 32 bits at a time
    prog += li(X2, (VEC_A >> (32 * i)) & 0xFFFFFFFF)
    prog.append(sw(X2, X3, NPU_A + 4 * i))
for i in range(4):
    prog += li(X2, (VEC_B >> (32 * i)) & 0xFFFFFFFF)
    prog.append(sw(X2, X3, NPU_B + 4 * i))

prog.append(lw(X2, X3, NPU_POPAND))        # read scores, report them
prog.append(sw(X2, X1, REPORT0))
prog.append(lw(X2, X3, NPU_HAMMING))
prog.append(sw(X2, X1, REPORT1))

prog.append(sw(X0, X3, NPU_CLEAR))         # 3. dot product
for a, b in DOT_PAIRS:
    prog += li(X2, (a & 0xFF) | ((b & 0xFF) << 8))
    prog.append(sw(X2, X3, NPU_STREAM))
prog.append(lw(X2, X3, NPU_ACC))
prog.append(sw(X2, X1, REPORT2))

prog.append(addi(X2, X0, 1))               # 4. done
prog.append(sw(X2, X1, DONE))
prog.append(jal(X0, 0))                    # spin forever

# ---- outputs ------------------------------------------------------------
(OUT / "firmware.hex").write_text(
    "\n".join(f"{w:08x}" for w in prog) + "\n")
(OUT / "expected.hex").write_text(
    f"{EXPECTED_POPAND:08x}\n{EXPECTED_HAMMING:08x}\n"
    f"{EXPECTED_DOT8 & 0xFFFFFFFF:08x}\n")

print(f"firmware.hex: {len(prog)} instructions "
      f"(popand={EXPECTED_POPAND} hamming={EXPECTED_HAMMING} dot8={EXPECTED_DOT8})")
