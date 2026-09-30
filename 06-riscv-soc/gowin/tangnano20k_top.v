`default_nettype none
module tangnano20k_top(input wire clk, input wire btn_s1,
                      output wire [5:0] led_n, output wire uart_tx);
    wire rst;
    board_reset reset_control(.clk(clk), .button(btn_s1), .rst(rst));

    wire trap, uart_wr, report_wr, done, overflow;
    wire [7:0] uart_char;
    wire [1:0] report_idx;
    wire [31:0] report_val;
    reg [2:0] seen;
    reg [2:0] passed;
    simple_soc #(.FIRMWARE("firmware.hex")) soc(.clk(clk), .rst_n(!rst), .trap(trap),
        .uart_wr(uart_wr), .uart_char(uart_char), .report_wr(report_wr),
        .report_idx(report_idx), .report_val(report_val), .done(done));
    board_uart uart(.clk(clk), .rst(rst), .wr(uart_wr), .data(uart_char),
                    .tx(uart_tx), .overflow(overflow));
    always @(posedge clk) begin
        if (rst) begin seen <= 0; passed <= 0; end
        else if (report_wr && report_idx < 3) begin
            seen[report_idx] <= 1;
            case (report_idx)
                0: passed[0] <= report_val == 32'h00000033;
                1: passed[1] <= report_val == 32'h00000024;
                2: passed[2] <= report_val == 32'hffffec39;
            endcase
        end
    end
    assign led_n = ~{overflow, trap, done, seen & passed};
endmodule
`default_nettype wire
