// Self-checking testbench for counter.v
`timescale 1ns/1ps
`default_nettype none

module tb_counter;

    reg        clk = 0;
    reg        rst = 1;
    reg        en  = 0;
    wire [7:0] count;

    counter #(.WIDTH(8)) dut (
        .clk(clk), .rst(rst), .en(en), .count(count)
    );

    always #5 clk = ~clk;   // 100 MHz sim clock

    integer errors = 0;

    task check(input [7:0] expected, input [127:0] label);
        begin
            if (count !== expected) begin
                $display("FAIL: %0s — count=%0d expected=%0d", label, count, expected);
                errors = errors + 1;
            end
        end
    endtask

    integer i;
    initial begin
        $dumpfile("tb_counter.vcd");
        $dumpvars(0, tb_counter);

        // reset behaviour
        repeat (3) @(posedge clk);
        #1 check(8'd0, "after reset");

        // counts when enabled
        rst = 0; en = 1;
        repeat (10) @(posedge clk);
        #1 check(8'd10, "after 10 enabled clocks");

        // holds when disabled
        en = 0;
        repeat (5) @(posedge clk);
        #1 check(8'd10, "hold while en=0");

        // wraps at 255 -> 0
        en = 1;
        for (i = 0; i < 246; i = i + 1) @(posedge clk);
        #1 check(8'd0, "wrap to zero");

        // synchronous reset mid-count
        repeat (7) @(posedge clk);
        rst = 1; @(posedge clk);
        #1 check(8'd0, "sync reset");

        if (errors == 0) $display("PASS: tb_counter");
        else begin
            $display("FAIL: tb_counter (%0d errors)", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule
`default_nettype wire
