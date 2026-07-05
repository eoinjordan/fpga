`timescale 1ns/1ps
`default_nettype none

module tb_tmds_encoder;

    reg clk = 0, rst = 1, de = 0, c0 = 0, c1 = 0;
    reg [7:0] data = 0;
    wire [9:0] symbol;
    integer errors = 0;

    tmds_encoder dut (
        .clk(clk), .rst(rst), .data(data), .c0(c0), .c1(c1), .de(de),
        .symbol(symbol)
    );

    always #5 clk = ~clk;

    task check(input [9:0] expected, input [127:0] label);
        begin
            @(posedge clk); #1;
            if (symbol !== expected) begin
                $display("FAIL %0s: symbol=%b expected=%b", label, symbol, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        rst = 0;

        de = 0; c1 = 0; c0 = 0; check(10'b1101010100, "ctl 00");
        de = 0; c1 = 0; c0 = 1; check(10'b0010101011, "ctl 01");
        de = 0; c1 = 1; c0 = 0; check(10'b0101010100, "ctl 10");
        de = 0; c1 = 1; c0 = 1; check(10'b1010101011, "ctl 11");

        de = 1; c1 = 0; c0 = 0; data = 8'h00; @(posedge clk); #1;
        if (^symbol === 1'bx) begin
            $display("FAIL data 00: symbol contains X (%b)", symbol);
            errors = errors + 1;
        end
        data = 8'hff; @(posedge clk); #1;
        if (^symbol === 1'bx) begin
            $display("FAIL data ff: symbol contains X");
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_tmds_encoder");
        else begin
            $display("FAIL: tb_tmds_encoder (%0d errors)", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule

`default_nettype wire
