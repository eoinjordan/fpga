`default_nettype none
module tangnano20k_top(input wire clk, input wire btn_s1,
                      output wire [5:0] led_n);
    wire rst;
    board_reset reset_control(.clk(clk), .button(btn_s1), .rst(rst));

    reg [31:0] count;
    always @(posedge clk) if (rst) count <= 0; else count <= count + 1'b1;
    wire [127:0] a = {4{count}}, b = {4{32'h55555555}};
    wire [7:0] score, distance;
    wire signed [31:0] acc;
    popand pa(.a(a), .b(b), .score(score));
    hamming hm(.a(a), .b(b), .distance(distance));
    dot8 dot(.clk(clk), .rst(rst), .clear(count[19:0] == 0),
             .in_valid(count[19:0] == 1), .a(count[27:20]), .b(8'sd3), .acc(acc));
    assign led_n = ~{acc[2:0], distance[1:0], score[0]};
endmodule
`default_nettype wire
