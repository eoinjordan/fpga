// 15-bit LFSR noise voice for percussion/noise effects.
`default_nettype none
`timescale 1ns/1ps

module noise_channel (
    input  wire       clk,
    input  wire       rst,
    input  wire       sample_tick,
    input  wire       enable,
    input  wire [3:0] volume,
    output reg signed [15:0] sample
);

    reg [14:0] lfsr;
    wire feedback = lfsr[0] ^ lfsr[1];
    wire signed [15:0] amp = {1'b0, volume, 11'b0};

    always @(posedge clk) begin
        if (rst) begin
            lfsr <= 15'h4000;
            sample <= 0;
        end else if (sample_tick) begin
            lfsr <= {feedback, lfsr[14:1]};
            sample <= enable ? (lfsr[0] ? amp : -amp) : 16'sd0;
        end
    end

endmodule

`default_nettype wire
