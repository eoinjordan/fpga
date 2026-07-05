# Verilog cheat sheet (the subset this series uses)

## The two block types — and the golden rule

```verilog
// CLOCKED: becomes flip-flops. Non-blocking (<=) ONLY.
always @(posedge clk) begin
    q <= d;
end

// COMBINATIONAL: becomes LUTs/gates. Blocking (=) ONLY.
always @(*) begin
    y = a & b;
end
```

Why the rule: non-blocking assignments all update "at the same instant"
at the clock edge — like real flip-flops. Blocking assignments happen in
order — like real logic settling. Mix them and simulation stops matching
the synthesized hardware, which is the worst bug class there is.

## What each construct becomes in silicon

| You write | You get |
|-----------|---------|
| `reg` assigned in `always @(posedge clk)` | D flip-flop(s) |
| `reg` assigned in `always @(*)` | LUTs (it is NOT a register!) |
| `wire ... = expr` / `assign` | LUTs |
| `if/else`, `case`, `?:` | multiplexers |
| `+`, `-` | carry-chain adders |
| `*` on 8–18 bit operands | a DSP multiplier block |
| big `reg [..] mem [0:N]` array | BSRAM (if access pattern fits) |
| `#10` delay | **nothing — unsynthesizable, testbench only** |
| `initial` block | **testbench only** (exception: BSRAM init / `$readmemh`) |

`reg` meaning "maybe a register, maybe not" is Verilog's worst naming
mistake. Read it as "assigned inside an always block".

## Sizes and literals

```verilog
8'hFF        // 8-bit hex
12'd1650     // 12-bit decimal
{a, b}       // concatenation
{4{bit}}     // replication: bit,bit,bit,bit
val[11:4]    // bit slice
val[i +: 8]  // 8 bits starting at i (indexed part-select)
$clog2(N)    // bits needed to count to N-1 — use for counter widths
```

Unsized literals (`1650`) are 32 bits — always size constants that feed
comparisons, or widths silently mismatch.

## Module patterns used across this repo

```verilog
`default_nettype none    // typo'd names become errors, not 1-bit wires
`timescale 1ns/1ps

module thing #(
    parameter W = 8              // compile-time knob
) (
    input  wire         clk,
    input  wire         rst,     // we use synchronous, active-high
    input  wire [W-1:0] d,
    output reg  [W-1:0] q
);
    localparam TOTAL = W + 1;    // derived constant, not overridable
    ...
endmodule

`default_nettype wire            // be a good citizen at file end
```

## Testbench essentials

```verilog
always #5 clk = ~clk;            // 100 MHz clock (10ns period)
@(posedge clk);                  // wait one edge
#1;                              // step past the edge before sampling!
repeat (10) @(posedge clk);      // wait ten
$display("x=%0d hex=%08x", x, x);
$readmemh("file.hex", mem);      // load vectors
$dumpfile("tb.vcd"); $dumpvars(0, tb);   // waveforms for gtkwave
if (got !== want) ...            // !== catches X/Z; != treats X as "maybe equal"
$fatal(1);                       // fail with non-zero exit — make notices
```

The `#1` after `@(posedge clk)` matters: sampling *at* the edge races
with the flip-flops updating. Step 1ns past, then look.

## The mental model that unlocks everything

Hardware is not a program. All `always` blocks "run" **simultaneously,
forever**. There is no call stack, no sequence of statements executing —
just registers capturing new values every clock edge, and clouds of
logic computing what those next values should be:

```
            +-----------------------------+
            |     combinational cloud     |
   +------->|  (all your @(*) and assign) |------+
   |        +-----------------------------+      |
   |                                             v
+--+---------+                            +-------------+
|  registers |<---------------------------|   D inputs  |
|  (@posedge)|          clk edge          +-------------+
+------------+
```

Every design in this series — counter, PPU, CPU — is that one picture,
repeated at different sizes.
