// Small tile/sprite PPU for the SemBoy internal 320x180 render target.
// The HDMI stage scales each internal pixel to a 4x4 block for 1280x720.
`default_nettype none
`timescale 1ns/1ps

module tile_sprite_ppu (
    input  wire        clk,
    input  wire        rst,
    input  wire        de,
    input  wire [8:0]  x,
    input  wire [7:0]  y,
    input  wire [8:0]  scroll_x,
    input  wire [7:0]  scroll_y,
    output reg         out_de,
    output reg  [7:0]  r,
    output reg  [7:0]  g,
    output reg  [7:0]  b
);

    function [23:0] palette(input [3:0] idx);
        begin
            case (idx)
                4'h0: palette = 24'h101820;
                4'h1: palette = 24'h2d4f7c;
                4'h2: palette = 24'h3fb9c8;
                4'h3: palette = 24'hf2d16b;
                4'h4: palette = 24'hf06c64;
                4'h5: palette = 24'h7de8a0;
                4'h6: palette = 24'hb476ff;
                4'h7: palette = 24'hf5f1e8;
                4'h8: palette = 24'h1f2f4a;
                4'h9: palette = 24'h356d5c;
                4'ha: palette = 24'h4dd8e6;
                4'hb: palette = 24'hf0a832;
                4'hc: palette = 24'hd94f70;
                4'hd: palette = 24'h8fa3c7;
                4'he: palette = 24'hc9d6ee;
                default: palette = 24'hffffff;
            endcase
        end
    endfunction

    wire [8:0] sx = x + scroll_x;
    wire [7:0] sy = y + scroll_y;
    wire [5:0] tile_x = sx[8:3];
    wire [4:0] tile_y = sy[7:3];
    wire [2:0] tex_x = sx[2:0];
    wire [2:0] tex_y = sy[2:0];

    reg [3:0] bg_idx;
    reg [3:0] sprite_idx;
    reg [8:0] spr_x;
    reg [7:0] spr_y;
    reg [3:0] pixel_idx;
    reg [23:0] rgb;
    integer i;

    always @(*) begin
        if (tex_x == 0 || tex_y == 0)
            bg_idx = 4'h7;                    // tile grid highlight
        else
            bg_idx = tile_x[3:0] ^ {tile_y[2:0], 1'b0};

        sprite_idx = 4'h0;
        for (i = 0; i < 32; i = i + 1) begin
            spr_x = (i * 10) & 9'h1ff;
            spr_y = (i * 5) & 8'hff;
            if ((x >= spr_x) && (x < spr_x + 9'd8) &&
                (y >= spr_y) && (y < spr_y + 8'd8) &&
                ((x[2:0] == y[2:0]) || (x[2:0] == ~y[2:0])))
                sprite_idx = 4'hb;
        end

        pixel_idx = (sprite_idx != 0) ? sprite_idx : bg_idx;
        rgb = de ? palette(pixel_idx) : 24'h000000;
    end

    always @(posedge clk) begin
        if (rst) begin
            out_de <= 1'b0;
            {r, g, b} <= 24'h000000;
        end else begin
            out_de <= de;
            {r, g, b} <= rgb;
        end
    end

endmodule

`default_nettype wire
