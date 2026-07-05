`timescale 1ns/1ps
`default_nettype none

module tb_i2s_tx;

    reg clk = 0, rst = 1, valid = 0;
    wire ready, bclk, lrclk, sd;
    integer errors = 0;
    integer i;
    reg [31:0] expected;

    i2s_tx dut (
        .clk(clk), .rst(rst), .sample_valid(valid),
        .sample_l(16'ha5c3), .sample_r(16'h5a3c),
        .ready(ready), .bclk(bclk), .lrclk(lrclk), .sd(sd)
    );

    always #5 clk = ~clk;

    initial begin
        expected = 32'ha5c3_5a3c;
        repeat (2) @(posedge clk);
        rst = 0;
        valid = 1; @(posedge clk); #1; valid = 0;

        for (i = 31; i >= 0; i = i - 1) begin
            @(posedge clk); #1;
            if (sd !== expected[i]) begin
                $display("FAIL bit %0d: sd=%b expected=%b", i, sd, expected[i]);
                errors = errors + 1;
            end
            if (lrclk !== (i < 16)) begin
                $display("FAIL lrclk bit %0d: lrclk=%b", i, lrclk);
                errors = errors + 1;
            end
        end

        @(posedge clk); #1;
        if (!ready) begin
            $display("FAIL: transmitter not ready after frame");
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_i2s_tx");
        else begin
            $display("FAIL: tb_i2s_tx (%0d errors)", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule

`default_nettype wire
