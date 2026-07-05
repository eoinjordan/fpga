#!/usr/bin/env python3
"""Golden-model test-vector generator for stage 02.

Writes hex files into vectors/ that the Verilog testbenches load with
$readmemh. Python computes the expected outputs; the RTL must match them
bit for bit. Deterministic (fixed seed) so failures are reproducible.
"""
import random
from pathlib import Path

SEED = 20260705
W = 128            # bitset width for popand/hamming
N_BITSET = 200     # bitset test cases (directed + random)
DOT_LEN = 16       # int8 pairs per dot-product test
N_DOT = 100        # dot-product test cases

OUT = Path(__file__).resolve().parent.parent / "vectors"


def bitset_cases(rng):
    """Directed edge cases first, then random."""
    yield 0, 0
    yield (1 << W) - 1, (1 << W) - 1
    yield (1 << W) - 1, 0
    yield 1, 1
    yield 1 << (W - 1), 1 << (W - 1)
    for _ in range(N_BITSET - 5):
        yield rng.getrandbits(W), rng.getrandbits(W)


def main():
    rng = random.Random(SEED)
    OUT.mkdir(exist_ok=True)

    # --- popand / hamming ---------------------------------------------
    a_lines, b_lines, popand_lines, hamming_lines = [], [], [], []
    for a, b in bitset_cases(rng):
        a_lines.append(f"{a:032x}")
        b_lines.append(f"{b:032x}")
        popand_lines.append(f"{bin(a & b).count('1'):02x}")
        hamming_lines.append(f"{bin(a ^ b).count('1'):02x}")

    (OUT / "bitset_a.hex").write_text("\n".join(a_lines) + "\n")
    (OUT / "bitset_b.hex").write_text("\n".join(b_lines) + "\n")
    (OUT / "expected_popand.hex").write_text("\n".join(popand_lines) + "\n")
    (OUT / "expected_hamming.hex").write_text("\n".join(hamming_lines) + "\n")

    # --- dot8 ----------------------------------------------------------
    # Directed: all-max, all-min (worst-case accumulation), then random.
    tests = [
        [(127, 127)] * DOT_LEN,
        [(-128, -128)] * DOT_LEN,
        [(-128, 127)] * DOT_LEN,
        [(0, 0)] * DOT_LEN,
    ]
    for _ in range(N_DOT - len(tests)):
        tests.append([(rng.randint(-128, 127), rng.randint(-128, 127))
                      for _ in range(DOT_LEN)])

    da, db, dexp = [], [], []
    for pairs in tests:
        acc = sum(x * y for x, y in pairs)
        for x, y in pairs:
            da.append(f"{x & 0xff:02x}")
            db.append(f"{y & 0xff:02x}")
        dexp.append(f"{acc & 0xffffffff:08x}")

    (OUT / "dot8_a.hex").write_text("\n".join(da) + "\n")
    (OUT / "dot8_b.hex").write_text("\n".join(db) + "\n")
    (OUT / "expected_dot8.hex").write_text("\n".join(dexp) + "\n")

    print(f"wrote {len(a_lines)} bitset cases and {len(tests)} dot8 cases to {OUT}")


if __name__ == "__main__":
    main()
