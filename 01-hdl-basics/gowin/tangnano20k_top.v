`default_nettype none
module tangnano20k_top(input wire clk, input wire btn_s1,
                      output wire [5:0] led_n);
    wire rst;
    board_reset reset_control(.clk(clk), .button(btn_s1), .rst(rst));

    wire blink;
    wire [31:0] count;
    blinky blink_core(.clk(clk), .rst(rst), .led_n(blink));
    counter #(.WIDTH(32)) counter_core(.clk(clk), .rst(rst), .en(1'b1), .count(count));
    assign led_n = {~count[28:24], blink};
endmodule
`default_nettype wire
