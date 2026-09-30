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

    reg [23:0] rgb;
    always @(*) begin
        case (x / 60)
            0: rgb = 24'hffffff;
            1: rgb = 24'hffff00;
            2: rgb = 24'h00ffff;
            3: rgb = 24'h00ff00;
            4: rgb = 24'hff00ff;
            5: rgb = 24'hff0000;
            6: rgb = 24'h0000ff;
            default: rgb = 24'h000000;
        endcase
    end
    wire [7:0] r = rgb[23:16], g = rgb[15:8], b = rgb[7:0];
    assign pixel_de = de;
    assign pixel_hs = ~hs;
    assign pixel_vs = ~vs;

    lcd_output panel(.pix_clk(pix_clk), .rst(video_rst),
        .de(pixel_de), .hsync(pixel_hs), .vsync(pixel_vs), .r(r), .g(g), .b(b),
        .lcd_dclk(lcd_dclk), .lcd_de(lcd_de), .lcd_hsync(lcd_hsync), .lcd_vsync(lcd_vsync),
        .lcd_r(lcd_r), .lcd_g(lcd_g), .lcd_b(lcd_b));
    assign led_n = {5'b11111, ~locked};

endmodule
`default_nettype wire
