// Three-voice signed mixer with a simple divide-by-two headroom shift.
`default_nettype none
`timescale 1ns/1ps

module audio_mixer (
    input  wire signed [15:0] square0,
    input  wire signed [15:0] square1,
    input  wire signed [15:0] noise,
    output wire signed [15:0] mixed_l,
    output wire signed [15:0] mixed_r
);

    wire signed [17:0] sum = {{2{square0[15]}}, square0} +
                             {{2{square1[15]}}, square1} +
                             {{2{noise[15]}}, noise};
    assign mixed_l = sum[16:1];
    assign mixed_r = sum[16:1];

endmodule

`default_nettype wire
