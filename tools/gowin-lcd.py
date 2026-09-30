"""LCD variants for the 480x272 screen also used by GBA-FPGA.

Consumed by prepare-gowin.py; no dependency on the GBA-FPGA checkout.
"""


def projects(top):
    result = []
    for stage in ['03-hdmi', '04-tilemap-sprites']:
        sources = ['boards/tangnano20k/rtl/lcd_io.v', '03-hdmi/rtl/video_timing.v']
        body = '''
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
'''
        if stage == '03-hdmi':
            body += '''
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
'''
        else:
            sources += ['04-tilemap-sprites/rtl/tile_sprite_ppu.v']
            body += '''
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
'''
        body += '''
    lcd_output panel(.pix_clk(pix_clk), .rst(video_rst),
        .de(pixel_de), .hsync(pixel_hs), .vsync(pixel_vs), .r(r), .g(g), .b(b),
        .lcd_dclk(lcd_dclk), .lcd_de(lcd_de), .lcd_hsync(lcd_hsync), .lcd_vsync(lcd_vsync),
        .lcd_r(lcd_r), .lcd_g(lcd_g), .lcd_b(lcd_b));
    assign led_n = {5'b11111, ~locked};
'''
        ports = ''', output wire lcd_dclk, lcd_de, lcd_hsync, lcd_vsync,
                      output wire [4:0] lcd_r,
                      output wire [5:0] lcd_g,
                      output wire [4:0] lcd_b'''
        result.append((stage, sources, top(body, ports), {'lcd': True, 'folder': 'gowin-lcd'}))
    return result
