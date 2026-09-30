`default_nettype none
module tangnano20k_top(input wire clk, input wire btn_s1,
                      output wire [5:0] led_n, output wire lcd_dclk, lcd_de, lcd_hsync, lcd_vsync,
                      output wire [4:0] lcd_r,
                      output wire [5:0] lcd_g,
                      output wire [4:0] lcd_b);
    wire rst;
    board_reset reset_control(.clk(clk), .button(btn_s1), .rst(rst));

    wire pix_clk, locked;
    lcd_clock clocks(.clk(clk), .rst(rst), .pix_clk(pix_clk), .locked(locked));
    reg [2:0] reset_pipe = 3'b111;
    always @(posedge pix_clk or negedge locked)
        if (!locked) reset_pipe <= 3'b111;
        else reset_pipe <= {reset_pipe[1:0], 1'b0};
    wire video_rst = reset_pipe[2];
    wire [11:0] x, y;
    wire de, hs, vs;
    video_timing #(.H_ACTIVE(480), .H_FRONT(8), .H_SYNC(4), .H_BACK(39),
                   .V_ACTIVE(272), .V_FRONT(8), .V_SYNC(4), .V_BACK(8)) timing (
        .clk(pix_clk), .rst(video_rst), .x(x), .y(y),
        .de(de), .hsync(hs), .vsync(vs));
    wire pixel_de, pixel_hs, pixel_vs;

    // 320x180 -> 480x270 at 3:2 scale, with one black row above and below.
    // Wide intermediates avoid overflow before division by three.
    wire in_picture = de && y >= 1 && y < 271;
    wire [11:0] source_x_wide = (x * 2) / 3;
    wire [11:0] source_y_wide = ((y - 1) * 2) / 3;
    wire [8:0] source_x = in_picture ? source_x_wide[8:0] : 9'd0;
    wire [7:0] source_y = in_picture ? source_y_wide[7:0] : 8'd0;
    wire [7:0] r, g, b;
    wire ppu_de;
    reg de_delay, hs_delay, vs_delay;
    always @(posedge pix_clk) begin
        if (video_rst) begin de_delay <= 0; hs_delay <= 1; vs_delay <= 1; end
        else begin de_delay <= de; hs_delay <= ~hs; vs_delay <= ~vs; end
    end
    tile_sprite_ppu ppu(.clk(pix_clk), .rst(video_rst), .de(in_picture),
        .x(source_x), .y(source_y), .scroll_x(9'd0), .scroll_y(8'd0),
        .out_de(ppu_de), .r(r), .g(g), .b(b));
    // DE covers the full panel, including the black letterbox rows.
    assign pixel_de = de_delay;
    assign pixel_hs = hs_delay;
    assign pixel_vs = vs_delay;

    lcd_output panel(.pix_clk(pix_clk), .rst(video_rst),
        .de(pixel_de), .hsync(pixel_hs), .vsync(pixel_vs), .r(r), .g(g), .b(b),
        .lcd_dclk(lcd_dclk), .lcd_de(lcd_de), .lcd_hsync(lcd_hsync), .lcd_vsync(lcd_vsync),
        .lcd_r(lcd_r), .lcd_g(lcd_g), .lcd_b(lcd_b));
    assign led_n = {5'b11111, ~locked};

endmodule
`default_nettype wire
