`default_nettype none
// Buffer the short firmware greeting because the SoC has no UART backpressure.
// 256 bytes; overflow is latched and exposed on an LED.
module board_uart(input wire clk, input wire rst, input wire wr,
                  input wire [7:0] data, output wire tx, output reg overflow);
    reg [7:0] fifo [0:255];
    reg [8:0] wp, rp;
    reg [9:0] shift;
    reg [3:0] bits_left;
    reg [7:0] divider;
    wire full = (wp[8] != rp[8]) && (wp[7:0] == rp[7:0]);
    assign tx = bits_left == 0 ? 1'b1 : shift[0];
    always @(posedge clk) begin
        if (rst) begin
            wp <= 0; rp <= 0; shift <= 10'h3ff;
            bits_left <= 0; divider <= 0; overflow <= 0;
        end else begin
            if (wr) begin
                if (full) overflow <= 1;
                else begin fifo[wp[7:0]] <= data; wp <= wp + 1'b1; end
            end
            if (bits_left == 0) begin
                if (wp != rp) begin
                    shift <= {1'b1, fifo[rp[7:0]], 1'b0};
                    rp <= rp + 1'b1; bits_left <= 10; divider <= 0;
                end
            end else if (divider == 233) begin
                divider <= 0; shift <= {1'b1, shift[9:1]}; bits_left <= bits_left - 1'b1;
            end else divider <= divider + 1'b1;
        end
    end
endmodule
`default_nettype wire
