// 16-bit stereo I2S-style serializer. One frame is shifted MSB first:
// left channel while lrclk=0, then right channel while lrclk=1.
`default_nettype none
`timescale 1ns/1ps

module i2s_tx (
    input  wire        clk,
    input  wire        rst,
    input  wire        sample_valid,
    input  wire [15:0] sample_l,
    input  wire [15:0] sample_r,
    output reg         ready,
    output reg         bclk,
    output reg         lrclk,
    output reg         sd
);

    reg [31:0] shifter;
    reg [5:0]  bit_pos;
    reg        busy;

    always @(posedge clk) begin
        if (rst) begin
            ready <= 1'b1;
            bclk <= 1'b0;
            lrclk <= 1'b0;
            sd <= 1'b0;
            shifter <= 32'd0;
            bit_pos <= 0;
            busy <= 1'b0;
        end else if (!busy && sample_valid) begin
            shifter <= {sample_l, sample_r};
            bit_pos <= 6'd31;
            busy <= 1'b1;
            ready <= 1'b0;
            bclk <= 1'b0;
            lrclk <= 1'b0;
            sd <= sample_l[15];
        end else if (busy) begin
            bclk <= ~bclk;
            sd <= shifter[bit_pos];
            lrclk <= bit_pos < 16;
            if (bit_pos == 0) begin
                busy <= 1'b0;
                ready <= 1'b1;
            end else begin
                bit_pos <= bit_pos - 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
