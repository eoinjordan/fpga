// Combinational population count (number of set bits).
// Synthesizes to an adder tree; fine up to a few hundred bits.
`default_nettype none
`timescale 1ns/1ps

module popcount #(
    parameter W = 128
) (
    input  wire [W-1:0]           bits,
    output reg  [$clog2(W+1)-1:0] count
);

    integer i;
    always @(*) begin
        count = 0;
        for (i = 0; i < W; i = i + 1)
            count = count + bits[i];
    end

endmodule

`default_nettype wire
