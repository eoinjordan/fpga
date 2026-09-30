`timescale 1ns/1ps
module tb_board_uart;
    reg clk = 0, rst = 1, wr = 0;
    reg [7:0] data = 0;
    wire tx, overflow;
    reg [7:0] received;
    integer i, sent, bit_index;
    board_uart dut(.clk(clk), .rst(rst), .wr(wr), .data(data), .tx(tx), .overflow(overflow));
    always #5 clk = ~clk;
    initial begin
        repeat (3) @(negedge clk);
        rst = 0;
        // Burst writes are much faster than a serial character.
        for (sent = 0; sent < 12; sent = sent + 1) begin
            @(negedge clk); wr = 1; data = 8'h40 + sent;
        end
        @(negedge clk); wr = 0;
    end
    initial begin
        wait (!rst);
        for (i = 0; i < 12; i = i + 1) begin : receive_character
            @(negedge tx);
            repeat (351) @(posedge clk);
            #1;
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                received[bit_index] = tx;
                repeat (234) @(posedge clk);
                #1;
            end
            if (received !== (8'h40 + i) || !tx || overflow)
                $fatal(1, "UART byte %0d: received %h", i, received);
        end
        $display("PASS: buffered board UART burst and 8N1 framing");
        $finish;
    end
    initial begin #1000000; $fatal(1, "UART timeout"); end
endmodule
