// TMDS encoder for DVI/HDMI video periods.
// Produces one 10-bit TMDS symbol per pixel clock. The board top still
// needs Gowin OSER10/ELVDS primitives to serialize these symbols.
`default_nettype none
`timescale 1ns/1ps

module tmds_encoder (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data,
    input  wire       c0,
    input  wire       c1,
    input  wire       de,
    output reg  [9:0] symbol
);

    function [3:0] count_ones8(input [7:0] v);
        integer i;
        begin
            count_ones8 = 0;
            for (i = 0; i < 8; i = i + 1)
                count_ones8 = count_ones8 + v[i];
        end
    endfunction

    function [8:0] make_qm(input [7:0] d);
        reg [3:0] ones_d;
        reg use_xnor;
        integer i;
        begin
            ones_d = count_ones8(d);
            use_xnor = (ones_d > 4) || ((ones_d == 4) && (d[0] == 1'b0));
            make_qm[0] = d[0];
            for (i = 1; i < 8; i = i + 1)
                make_qm[i] = use_xnor ? ~(make_qm[i-1] ^ d[i]) : (make_qm[i-1] ^ d[i]);
            make_qm[8] = use_xnor ? 1'b0 : 1'b1;
        end
    endfunction

    reg signed [4:0] disparity = 0;
    wire [8:0] q_m = make_qm(data);
    wire [3:0] ones_q = count_ones8(q_m[7:0]);
    wire signed [4:0] balance = $signed({1'b0, ones_q}) -
                                $signed(5'd8 - {1'b0, ones_q});

    always @(posedge clk) begin
        if (rst) begin
            symbol <= 10'b1101010100;
            disparity <= 0;
        end else if (!de) begin
            disparity <= 0;
            case ({c1, c0})
                2'b00: symbol <= 10'b1101010100;
                2'b01: symbol <= 10'b0010101011;
                2'b10: symbol <= 10'b0101010100;
                default: symbol <= 10'b1010101011;
            endcase
        end else if ((disparity == 0) || (balance == 0)) begin
            symbol <= {~q_m[8], q_m[8], q_m[8] ? q_m[7:0] : ~q_m[7:0]};
            disparity <= disparity + (q_m[8] ? balance : -balance);
        end else if ((disparity > 0 && balance > 0) ||
                     (disparity < 0 && balance < 0)) begin
            symbol <= {1'b1, q_m[8], ~q_m[7:0]};
            disparity <= disparity + $signed({3'b0, q_m[8], 1'b0}) - balance;
        end else begin
            symbol <= {1'b0, q_m[8], q_m[7:0]};
            disparity <= disparity - $signed({3'b0, ~q_m[8], 1'b0}) + balance;
        end
    end

endmodule

`default_nettype wire
