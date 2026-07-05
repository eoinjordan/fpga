`timescale 1ns/1ps
`default_nettype none

module tb_debounce;

    reg clk = 0, rst = 1, noisy = 0;
    wire clean;
    integer errors = 0;

    debounce #(.COUNT_MAX(3)) dut (.clk(clk), .rst(rst), .noisy(noisy), .clean(clean));
    always #5 clk = ~clk;

    initial begin
        repeat (2) @(posedge clk);
        rst = 0;

        noisy = 1; @(posedge clk);
        noisy = 0; @(posedge clk);
        noisy = 1; @(posedge clk); #1;
        if (clean !== 0) begin
            $display("FAIL: bounce changed output early");
            errors = errors + 1;
        end

        repeat (5) @(posedge clk); #1;
        if (clean !== 1) begin
            $display("FAIL: stable high did not debounce");
            errors = errors + 1;
        end

        noisy = 0; repeat (7) @(posedge clk); #1;
        if (clean !== 0) begin
            $display("FAIL: stable low did not debounce");
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_debounce");
        else begin
            $display("FAIL: tb_debounce (%0d errors)", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule

`default_nettype wire
