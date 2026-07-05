// SEM_DOT8: streaming signed int8 multiply-accumulate.
//   rst=1                          -> acc = 0 (deterministic power-up)
//   clear=1 for one clock          -> acc = 0
//   in_valid=1 with a, b           -> acc += a * b   (one pair per clock)
//   read acc when the stream ends
// One 8x8 signed multiply maps to a fraction of a GW2AR 18x18 DSP block.
`default_nettype none
`timescale 1ns/1ps

module dot8 (
    input  wire               clk,
    input  wire               rst,
    input  wire               clear,
    input  wire               in_valid,
    input  wire signed  [7:0] a,
    input  wire signed  [7:0] b,
    output reg  signed [31:0] acc
);

    always @(posedge clk) begin
        if (rst || clear)
            acc <= 32'sd0;
        else if (in_valid)
            acc <= acc + (a * b);
    end

endmodule

`default_nettype wire
