// Retro square-wave voice: phase accumulator, duty select, 4-bit volume.
`default_nettype none
`timescale 1ns/1ps

module square_channel (
    input  wire        clk,
    input  wire        rst,
    input  wire        sample_tick,
    input  wire        enable,
    input  wire [31:0] freq_step,
    input  wire [1:0]  duty,
    input  wire [3:0]  volume,
    output reg signed [15:0] sample
);

    reg [31:0] phase;
    reg high;
    wire signed [15:0] amp = {1'b0, volume, 11'b0};

    always @(*) begin
        case (duty)
            2'd0: high = phase[31:29] == 3'd0;       // 12.5%
            2'd1: high = phase[31:30] == 2'd0;       // 25%
            2'd2: high = phase[31] == 1'b0;          // 50%
            default: high = phase[31:30] != 2'b11;   // 75%
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            phase <= 0;
            sample <= 0;
        end else if (sample_tick) begin
            phase <= phase + freq_step;
            sample <= enable ? (high ? amp : -amp) : 16'sd0;
        end
    end

endmodule

`default_nettype wire
