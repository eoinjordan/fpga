// Simulates one full 720p frame (1,237,500 clocks) and checks:
//   - de is high exactly 1280*720 times
//   - hsync pulses exactly 750 times (once per line)
//   - vsync pulses exactly once
//   - frame period is exactly 1650*750 clocks
`timescale 1ns/1ps
`default_nettype none

module tb_video_timing;

    localparam H_TOTAL = 1650;
    localparam V_TOTAL = 750;
    localparam FRAME   = H_TOTAL * V_TOTAL;

    reg         clk = 0;
    reg         rst = 1;
    wire [11:0] x, y;
    wire        de, hsync, vsync;

    video_timing dut (
        .clk(clk), .rst(rst),
        .x(x), .y(y), .de(de), .hsync(hsync), .vsync(vsync)
    );

    always #5 clk = ~clk;

    integer de_count = 0, hsync_rises = 0, vsync_rises = 0;
    reg prev_h = 0, prev_v = 0;
    integer errors = 0;
    integer i;

    initial begin
        repeat (2) @(posedge clk);
        rst = 0;
        @(posedge clk);  // settle at x=1,y=0; start counting next edge

        // run to the start of the next frame, then measure one whole frame
        while (!(x == 0 && y == 0)) @(posedge clk);

        for (i = 0; i < FRAME; i = i + 1) begin
            if (de) de_count = de_count + 1;
            if (hsync && !prev_h) hsync_rises = hsync_rises + 1;
            if (vsync && !prev_v) vsync_rises = vsync_rises + 1;
            prev_h = hsync;
            prev_v = vsync;
            @(posedge clk);
        end

        if (!(x == 0 && y == 0)) begin
            $display("FAIL: frame period wrong — after %0d clocks got x=%0d y=%0d",
                     FRAME, x, y);
            errors = errors + 1;
        end
        if (de_count !== 1280 * 720) begin
            $display("FAIL: de_count=%0d expected %0d", de_count, 1280 * 720);
            errors = errors + 1;
        end
        if (hsync_rises !== V_TOTAL) begin
            $display("FAIL: hsync_rises=%0d expected %0d", hsync_rises, V_TOTAL);
            errors = errors + 1;
        end
        if (vsync_rises !== 1) begin
            $display("FAIL: vsync_rises=%0d expected 1", vsync_rises);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_video_timing (full 720p frame)");
        else begin
            $display("FAIL: tb_video_timing (%0d errors)", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule
`default_nettype wire
