// Eight vertical colour bars across the active area.
// Pure function from x to colour -- the simplest possible "PPU".
//
// Deliberately no division in the pixel path: H_ACTIVE/8 = 160 is not a
// power of two, so `x / 160` would synthesize into a wide combinational
// divider (or at best a multiply-by-reciprocal). Comparisons against
// constants are just carry chains -- cheap and fast. Later PPU stages
// keep the same rule: pixel-rate math is shifts, compares, and adds.
`default_nettype none
`timescale 1ns/1ps

module colorbars #(
    parameter H_ACTIVE = 1280
) (
    input  wire [11:0] x,
    input  wire        de,
    output reg  [7:0]  r,
    output reg  [7:0]  g,
    output reg  [7:0]  b
);

    localparam BAR = H_ACTIVE / 8;

    reg [2:0] bar;
    always @(*) begin
        if      (x < 1 * BAR) bar = 3'd0;
        else if (x < 2 * BAR) bar = 3'd1;
        else if (x < 3 * BAR) bar = 3'd2;
        else if (x < 4 * BAR) bar = 3'd3;
        else if (x < 5 * BAR) bar = 3'd4;
        else if (x < 6 * BAR) bar = 3'd5;
        else if (x < 7 * BAR) bar = 3'd6;
        else                  bar = 3'd7;
    end

    always @(*) begin
        if (!de) begin
            {r, g, b} = 24'h000000;   // must be black during blanking
        end else begin
            case (bar)
                3'd0: {r, g, b} = 24'hFFFFFF;  // white
                3'd1: {r, g, b} = 24'hFFFF00;  // yellow
                3'd2: {r, g, b} = 24'h00FFFF;  // cyan
                3'd3: {r, g, b} = 24'h00FF00;  // green
                3'd4: {r, g, b} = 24'hFF00FF;  // magenta
                3'd5: {r, g, b} = 24'hFF0000;  // red
                3'd6: {r, g, b} = 24'h0000FF;  // blue
                default: {r, g, b} = 24'h000000;
            endcase
        end
    end

endmodule

`default_nettype wire
