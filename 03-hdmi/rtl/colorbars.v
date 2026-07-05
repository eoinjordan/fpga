// Eight vertical colour bars across the active area.
// Pure function from x to colour -- the simplest possible "PPU".
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

    // which of the 8 bars are we in?
    wire [2:0] bar = x / (H_ACTIVE / 8);

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
