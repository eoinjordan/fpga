// SEM_POPAND: score = popcount(a & b)
// Binary semantic similarity -- how many features two bitsets share.
`default_nettype none
`timescale 1ns/1ps

module popand #(
    parameter W = 128
) (
    input  wire [W-1:0]           a,
    input  wire [W-1:0]           b,
    output wire [$clog2(W+1)-1:0] score
);

    popcount #(.W(W)) u_pc (
        .bits (a & b),
        .count(score)
    );

endmodule

`default_nettype wire
