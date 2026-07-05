// Spartan Edge shim for stage 01's blinky: 100 MHz board clock,
// so TOGGLE_COUNT = 50_000_000 for the same 1 Hz blink.
// LED polarity on this board is unverified — a blink is a blink either way.
`default_nettype none
`timescale 1ns/1ps

module blinky_top_sea (
    input  wire clk,        // 100 MHz, pin H4
    input  wire btn_user1,  // pin C3
    output wire led0        // FPGA_LED1, pin J1
);

    blinky #(.TOGGLE_COUNT(50_000_000)) u_blinky (
        .clk  (clk),
        .rst  (btn_user1),
        .led_n(led0)
    );

endmodule

`default_nettype wire
