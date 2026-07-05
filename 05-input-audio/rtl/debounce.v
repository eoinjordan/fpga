// 2-FF synchronizer plus counter-based debounce filter.
`default_nettype none
`timescale 1ns/1ps

module debounce #(
    parameter COUNT_MAX = 16
) (
    input  wire clk,
    input  wire rst,
    input  wire noisy,
    output reg  clean
);

    localparam COUNT_WIDTH = (COUNT_MAX < 2) ? 1 : $clog2(COUNT_MAX + 1);
    localparam [COUNT_WIDTH-1:0] COUNT_LIMIT = COUNT_MAX;

    reg sync0, sync1;
    reg [COUNT_WIDTH-1:0] count;

    always @(posedge clk) begin
        if (rst) begin
            sync0 <= 1'b0;
            sync1 <= 1'b0;
            clean <= 1'b0;
            count <= 0;
        end else begin
            sync0 <= noisy;
            sync1 <= sync0;

            if (sync1 == clean) begin
                count <= 0;
            end else if (count == COUNT_LIMIT) begin
                clean <= sync1;
                count <= 0;
            end else begin
                count <= count + 1'b1;
            end
        end
    end

endmodule

`default_nettype wire
