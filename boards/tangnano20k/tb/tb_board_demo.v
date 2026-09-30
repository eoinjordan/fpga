`timescale 1ns/1ps
module tb_board_demo;
    reg clk = 0, btn_s1 = 0;
    wire [5:0] led_n;
    wire uart_tx;
    tangnano20k_top dut(.clk(clk), .btn_s1(btn_s1), .led_n(led_n), .uart_tx(uart_tx));
    always #5 clk = ~clk;
    initial begin
        wait (led_n[3] === 1'b0);
        #100;
        if (led_n !== 6'b110000) $fatal(1, "SoC board results: %b", led_n);
        btn_s1 = 1;
        repeat (8) @(negedge clk);
        if (led_n !== 6'b111111) $fatal(1, "S1 did not reset the board demo");
        btn_s1 = 0;
        wait (led_n[3] === 1'b0);
        #100;
        if (led_n !== 6'b110000) $fatal(1, "SoC failed after reset");
        $display("PASS: SoC firmware, SemNPU LED results and button reset");
        $finish;
    end
    initial begin #3000000; $fatal(1, "SoC board timeout"); end
endmodule
