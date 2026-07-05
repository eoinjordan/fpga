// Self-checking testbench for blinky.v
// Uses a tiny TOGGLE_COUNT so the sim finishes in milliseconds —
// never simulate 13.5 million clocks to test a divider.
`timescale 1ns/1ps
`default_nettype none

module tb_blinky;

    localparam TOGGLE = 10;

    reg  clk = 0;
    reg  rst = 1;
    wire led_n;

    blinky #(.TOGGLE_COUNT(TOGGLE)) dut (
        .clk(clk), .rst(rst), .led_n(led_n)
    );

    always #5 clk = ~clk;

    integer errors = 0;
    integer toggles = 0;
    reg     prev;

    initial begin
        $dumpfile("tb_blinky.vcd");
        $dumpvars(0, tb_blinky);

        repeat (2) @(posedge clk);
        rst = 0;
        #1 if (led_n !== 1'b1) begin
            $display("FAIL: LED should be off (led_n=1) after reset");
            errors = errors + 1;
        end

        // count LED toggles over 5 full periods
        prev = led_n;
        repeat (5 * TOGGLE) begin
            @(posedge clk); #1;
            if (led_n !== prev) begin
                toggles = toggles + 1;
                prev = led_n;
            end
        end

        if (toggles !== 5) begin
            $display("FAIL: expected 5 toggles in %0d clocks, got %0d",
                     5 * TOGGLE, toggles);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_blinky");
        else begin
            $display("FAIL: tb_blinky (%0d errors)", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule
`default_nettype wire
