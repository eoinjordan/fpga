// Video timing generator, default 1280x720@60 (CEA-861 mode 4).
// Runs at the pixel clock. x/y are only meaningful while de=1.
// 720p uses positive-polarity syncs.
`default_nettype none
`timescale 1ns/1ps

module video_timing #(
    parameter H_ACTIVE = 1280,
    parameter H_FRONT  = 110,
    parameter H_SYNC   = 40,
    parameter H_BACK   = 220,
    parameter V_ACTIVE = 720,
    parameter V_FRONT  = 5,
    parameter V_SYNC   = 5,
    parameter V_BACK   = 20
) (
    input  wire        clk,     // pixel clock
    input  wire        rst,
    output reg  [11:0] x,       // horizontal position, 0..H_TOTAL-1
    output reg  [11:0] y,       // vertical position, 0..V_TOTAL-1
    output wire        de,      // active video
    output wire        hsync,
    output wire        vsync
);

    localparam H_TOTAL = H_ACTIVE + H_FRONT + H_SYNC + H_BACK;
    localparam V_TOTAL = V_ACTIVE + V_FRONT + V_SYNC + V_BACK;

    always @(posedge clk) begin
        if (rst) begin
            x <= 0;
            y <= 0;
        end else if (x == H_TOTAL - 1) begin
            x <= 0;
            y <= (y == V_TOTAL - 1) ? 12'd0 : y + 1'b1;
        end else begin
            x <= x + 1'b1;
        end
    end

    assign de    = (x < H_ACTIVE) && (y < V_ACTIVE);
    assign hsync = (x >= H_ACTIVE + H_FRONT) && (x < H_ACTIVE + H_FRONT + H_SYNC);
    assign vsync = (y >= V_ACTIVE + V_FRONT) && (y < V_ACTIVE + V_FRONT + V_SYNC);

endmodule

`default_nettype wire
