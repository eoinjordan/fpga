`timescale 1ns/1ps
`default_nettype none

module tb_square_channel;

    reg clk = 0, rst = 1, tick = 0, enable = 1;
    wire signed [15:0] sample;
    integer errors = 0;

    square_channel dut (
        .clk(clk), .rst(rst), .sample_tick(tick), .enable(enable),
        .freq_step(32'h8000_0000), .duty(2'd2), .volume(4'd4), .sample(sample)
    );

    always #5 clk = ~clk;

    task pulse_tick;
        begin
            tick = 1; @(posedge clk); #1; tick = 0;
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        rst = 0;
        pulse_tick();
        if (sample !== 16'sd8192) begin
            $display("FAIL: first half sample=%0d", sample);
            errors = errors + 1;
        end
        @(posedge clk); pulse_tick();
        if (sample !== -16'sd8192) begin
            $display("FAIL: second half sample=%0d", sample);
            errors = errors + 1;
        end
        enable = 0; @(posedge clk); pulse_tick();
        if (sample !== 16'sd0) begin
            $display("FAIL: disabled sample=%0d", sample);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_square_channel");
        else begin
            $display("FAIL: tb_square_channel (%0d errors)", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule

`default_nettype wire
