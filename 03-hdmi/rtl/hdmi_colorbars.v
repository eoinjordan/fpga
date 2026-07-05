// Simulatable HDMI/DVI colour-bar pipeline up to 10-bit TMDS symbols.
// Hardware serialization is board-specific and lives after this module.
`default_nettype none
`timescale 1ns/1ps

module hdmi_colorbars (
    input  wire        pix_clk,
    input  wire        rst,
    output wire [11:0] x,
    output wire [11:0] y,
    output wire        de,
    output wire        hsync,
    output wire        vsync,
    output wire [9:0]  tmds_r,
    output wire [9:0]  tmds_g,
    output wire [9:0]  tmds_b
);

    wire [7:0] r, g, b;

    video_timing timing (
        .clk(pix_clk), .rst(rst),
        .x(x), .y(y), .de(de), .hsync(hsync), .vsync(vsync)
    );

    colorbars bars (
        .x(x), .de(de), .r(r), .g(g), .b(b)
    );

    tmds_encoder enc_b (
        .clk(pix_clk), .rst(rst), .data(b),
        .c0(hsync), .c1(vsync), .de(de), .symbol(tmds_b)
    );
    tmds_encoder enc_g (
        .clk(pix_clk), .rst(rst), .data(g),
        .c0(1'b0), .c1(1'b0), .de(de), .symbol(tmds_g)
    );
    tmds_encoder enc_r (
        .clk(pix_clk), .rst(rst), .data(r),
        .c0(1'b0), .c1(1'b0), .de(de), .symbol(tmds_r)
    );

endmodule

`default_nettype wire
