// Parameterized up-counter with synchronous reset and enable.
`default_nettype none
`timescale 1ns/1ps

module counter #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst,     // synchronous, active high
    input  wire             en,
    output reg  [WIDTH-1:0] count
);

    always @(posedge clk) begin
        if (rst)
            count <= {WIDTH{1'b0}};
        else if (en)
            count <= count + 1'b1;
    end

endmodule

`default_nettype wire
