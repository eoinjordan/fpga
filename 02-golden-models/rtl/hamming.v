// SEM_HAMMING: distance = popcount(a ^ b)
// Bits that differ between two bitset embeddings.
`default_nettype none
`timescale 1ns/1ps

module hamming #(
    parameter W = 128
) (
    input  wire [W-1:0]           a,
    input  wire [W-1:0]           b,
    output wire [$clog2(W+1)-1:0] distance
);

    popcount #(.W(W)) u_pc (
        .bits (a ^ b),
        .count(distance)
    );

endmodule

`default_nettype wire
