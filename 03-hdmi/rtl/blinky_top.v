// Board smoke-test top: stage 01's blinky wired to the Tang Nano 20K.
// Button S1 (pressed = 1 on this board) is the reset.
`default_nettype none
`timescale 1ns/1ps

module blinky_top (
    input  wire clk,      // 27 MHz, pin 4
    input  wire btn_s1,   // pin 88, pull-down
    output wire led_n     // pin 15, active-low
);

    blinky #(.TOGGLE_COUNT(13_500_000)) u_blinky (
        .clk  (clk),
        .rst  (btn_s1),
        .led_n(led_n)
    );

endmodule

`default_nettype wire
