`default_nettype none
module tangnano20k_top(input wire clk, input wire btn_s1,
                      output wire [5:0] led_n);
    wire rst;
    board_reset reset_control(.clk(clk), .button(btn_s1), .rst(rst));

    reg [2:0] state;
    wire ready, valid;
    wire [7:0] data;
    wire [31:0] addr, wdata;
    wire [3:0] wstrb;
    reg passed;
    cpu_bus_socket socket(.clk(clk), .rst(rst), .cpu_valid(state == 0), .cpu_we(1'b0),
        .cpu_addr(16'h1002), .cpu_wdata(8'd0), .cpu_ready(ready), .cpu_rdata(data),
        .mem_valid(valid), .mem_addr(addr), .mem_wdata(wdata), .mem_wstrb(wstrb),
        .mem_ready(valid), .mem_rdata(32'h11223344));
    always @(posedge clk) begin
        if (rst) begin state <= 0; passed <= 0; end
        else case (state)
            0: state <= 1;
            1: if (ready) begin passed <= data == 8'h22 && addr == 32'h80001000; state <= 2; end
            default: state <= state;
        endcase
    end
    assign led_n = {4'b1111, ~(state == 2), ~passed};
endmodule
`default_nettype wire
