`timescale 1ns/1ps
module tb_board_audio;
    reg clk = 0;
    wire [5:0] led_n;
    wire bclk, ws, sd, enabled;
    reg [15:0] word;
    integer frame, bit_index;
    tangnano20k_top dut(.clk(clk), .btn_s1(1'b0), .btn_s2(1'b1),
        .led_n(led_n), .audio_bclk(bclk), .audio_ws(ws), .audio_sd(sd), .audio_en(enabled));
    always #5 clk = ~clk;
    initial begin
        force dut.mixed_l = 16'h96a5;
        force dut.mixed_r = 16'h3cc3;
        wait (enabled);
        #1;
        if (led_n[0] !== 0) $fatal(1, "Audio enable LED");
        for (frame = 0; frame < 3; frame = frame + 1) begin
            @(negedge ws); @(posedge bclk);
            for (bit_index = 15; bit_index >= 0; bit_index = bit_index - 1) begin
                @(posedge bclk); word[bit_index] = sd;
                if (ws !== 0) $fatal(1, "Wrong left WS polarity");
            end
            if (word !== 16'h96a5) $fatal(1, "Left I2S word %h", word);
            @(posedge ws); @(posedge bclk);
            for (bit_index = 15; bit_index >= 0; bit_index = bit_index - 1) begin
                @(posedge bclk); word[bit_index] = sd;
                if (ws !== 1) $fatal(1, "Wrong right WS polarity");
            end
            if (word !== 16'h3cc3) $fatal(1, "Right I2S word %h", word);
        end
        $display("PASS: board I2S stereo MSB order, WS delay and debounced enable");
        $finish;
    end
    initial begin #5000000; $fatal(1, "Audio timeout"); end
endmodule
