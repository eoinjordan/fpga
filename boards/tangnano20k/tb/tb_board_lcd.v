`timescale 1ns/1ps
module tb_board_lcd;
    reg clk = 0, btn_s1 = 0;
    wire [5:0] led_n;
    wire dclk, de, hs, vs;
    wire [4:0] r, b;
    wire [5:0] g;
    integer x, y, samples = 0, active = 0, hsync_pixels = 0, vsync_pixels = 0;
    integer frame = 0;
    reg counting = 0;
    reg [18:0] falling_outputs;
    reg [15:0] expected_rgb;
    tangnano20k_top dut(.clk(clk), .btn_s1(btn_s1), .led_n(led_n),
        .lcd_dclk(dclk), .lcd_de(de), .lcd_hsync(hs), .lcd_vsync(vs),
        .lcd_r(r), .lcd_g(g), .lcd_b(b));
    always #18.5185 clk = ~clk;

    always @(posedge dclk) begin
        if (!dut.video_rst) begin
`ifdef PPU
            // PPU RGB and controls are registered together from this raster.
            x = dut.x; y = dut.y;
            if (dut.in_picture) begin
                if (dut.source_x !== (x * 2 / 3) || dut.source_y !== ((y - 1) * 2 / 3))
                    $fatal(1, "PPU source coordinate mismatch at %0d,%0d", x, y);
                if (dut.source_x > 319 || dut.source_y > 179)
                    $fatal(1, "PPU source coordinate out of bounds");
            end
`else
            #1; x = dut.x; y = dut.y;
`endif
            if (counting && {de,hs,vs,r,g,b} !== falling_outputs)
                $fatal(1, "LCD outputs changed at the panel sampling edge");
        end
    end

    always @(negedge dclk) begin
        #1;
        falling_outputs = {de,hs,vs,r,g,b};
        if (!dut.video_rst) begin
            if (!counting && x == 0 && y == 0) counting = 1;
            if (counting) begin
                if (de !== (x < 480 && y < 272) ||
                    hs !== !(x >= 488 && x < 492) ||
                    vs !== !(y >= 280 && y < 284))
                    $fatal(1, "LCD raster/control mismatch at %0d,%0d", x, y);
                if (!de && {r,g,b} !== 16'd0) $fatal(1, "RGB not blanked");
`ifdef PPU
                if (de && (y == 0 || y == 271) && {r,g,b} !== 16'd0)
                    $fatal(1, "PPU letterbox row is not black");
`else
                case (x / 60)
                    0: expected_rgb = 16'hffff;
                    1: expected_rgb = 16'hffe0;
                    2: expected_rgb = 16'h07ff;
                    3: expected_rgb = 16'h07e0;
                    4: expected_rgb = 16'hf81f;
                    5: expected_rgb = 16'hf800;
                    6: expected_rgb = 16'h001f;
                    default: expected_rgb = 16'h0000;
                endcase
                if (de && {r,g,b} !== expected_rgb)
                    $fatal(1, "LCD colour bar mismatch at %0d,%0d", x, y);
`endif
                samples = samples + 1;
                if (de) active = active + 1;
                if (!hs) hsync_pixels = hsync_pixels + 1;
                if (!vs) vsync_pixels = vsync_pixels + 1;
                if (samples == 531*292) begin
                    if (active != 480*272 || hsync_pixels != 4*292 || vsync_pixels != 4*531)
                        $fatal(1, "LCD frame counts failed");
                    frame = frame + 1;
                    samples = 0; active = 0; hsync_pixels = 0; vsync_pixels = 0;
                    if (frame == 2) begin
                        $display("PASS: LCD two frames, 480x272 timing, RGB565 and sampling edges");
                        $finish;
                    end
                end
            end
        end
    end
    initial begin #60000000; $fatal(1, "LCD timeout"); end
endmodule
