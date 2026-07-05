// Blink an LED by dividing the 27 MHz board clock with a counter.
// TOGGLE_COUNT = clocks per LED toggle. 13_500_000 @ 27 MHz = 1 Hz blink.
// The LED output is active-low to match the Tang Nano 20K.
`default_nettype none
`timescale 1ns/1ps

module blinky #(
    parameter TOGGLE_COUNT = 13_500_000
) (
    input  wire clk,
    input  wire rst,
    output wire led_n
);

    // $clog2 gives the minimum register width that can hold TOGGLE_COUNT-1
    localparam CW = $clog2(TOGGLE_COUNT);

    reg [CW-1:0] div;
    reg          led_state;

    always @(posedge clk) begin
        if (rst) begin
            div       <= 0;
            led_state <= 1'b0;
        end else if (div == TOGGLE_COUNT - 1) begin
            div       <= 0;
            led_state <= ~led_state;
        end else begin
            div <= div + 1'b1;
        end
    end

    assign led_n = ~led_state;   // board LEDs light on 0

endmodule

`default_nettype wire
