`default_nettype none
module tangnano20k_top(input wire clk, input wire btn_s1,
                      output wire [5:0] led_n, output wire tmds_clk_p, tmds_clk_n,
                      output wire [2:0] tmds_d_p, tmds_d_n);
    wire rst;
    board_reset reset_control(.clk(clk), .button(btn_s1), .rst(rst));

    wire serial_clk, pix_clk, locked;
    video_clock clocks(.clk(clk), .rst(rst), .serial_clk(serial_clk),
                       .pix_clk(pix_clk), .locked(locked));
    reg [2:0] reset_pipe = 3'b111;
    always @(posedge pix_clk or negedge locked)
        if (!locked) reset_pipe <= 3'b111;
        else reset_pipe <= {reset_pipe[1:0], 1'b0};
    wire video_rst = reset_pipe[2];
    wire [11:0] x, y;
    wire de, hs, vs;
    wire [9:0] red, green, blue;

    video_timing timing(.clk(pix_clk), .rst(video_rst), .x(x), .y(y),
                        .de(de), .hsync(hs), .vsync(vs));
    wire [7:0] r, g, b;
    wire ppu_de;
    reg hs_delay, vs_delay;
    always @(posedge pix_clk) begin hs_delay <= hs; vs_delay <= vs; end
    tile_sprite_ppu ppu(.clk(pix_clk), .rst(video_rst), .de(de),
        .x(x[10:2]), .y(y[9:2]), .scroll_x(9'd0), .scroll_y(8'd0),
        .out_de(ppu_de), .r(r), .g(g), .b(b));
    tmds_encoder er(.clk(pix_clk), .rst(video_rst), .data(r),
        .c0(1'b0), .c1(1'b0), .de(ppu_de), .symbol(red));
    tmds_encoder eg(.clk(pix_clk), .rst(video_rst), .data(g),
        .c0(1'b0), .c1(1'b0), .de(ppu_de), .symbol(green));
    tmds_encoder eb(.clk(pix_clk), .rst(video_rst), .data(b),
        .c0(hs_delay), .c1(vs_delay), .de(ppu_de), .symbol(blue));

    tmds_lane lane0(.pix_clk(pix_clk), .serial_clk(serial_clk), .rst(video_rst),
        .symbol(blue), .p(tmds_d_p[0]), .n(tmds_d_n[0]));
    tmds_lane lane1(.pix_clk(pix_clk), .serial_clk(serial_clk), .rst(video_rst),
        .symbol(green), .p(tmds_d_p[1]), .n(tmds_d_n[1]));
    tmds_lane lane2(.pix_clk(pix_clk), .serial_clk(serial_clk), .rst(video_rst),
        .symbol(red), .p(tmds_d_p[2]), .n(tmds_d_n[2]));
    tmds_lane laneclk(.pix_clk(pix_clk), .serial_clk(serial_clk), .rst(video_rst),
        .symbol(10'b1111100000), .p(tmds_clk_p), .n(tmds_clk_n));
    assign led_n = {5'b11111, ~locked};

endmodule
`default_nettype wire
