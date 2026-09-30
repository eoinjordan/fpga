`timescale 1ns/1ps
// Functional model for the LCD board tests, not a timing model of the PLL.
module rPLL(input CLKIN, RESET, RESET_P, CLKFB,
            input [5:0] FBDSEL, IDSEL, ODSEL,
            input [3:0] PSDA, DUTYDA, FDLY,
            output reg CLKOUT = 0, output reg LOCK = 0);
    parameter FCLKIN="27", IDIV_SEL=2, FBDIV_SEL=0, ODIV_SEL=64;
    parameter DYN_IDIV_SEL="false", DYN_FBDIV_SEL="false", DYN_ODIV_SEL="false";
    parameter DYN_DA_EN="false", PSDA_SEL="0000", DUTYDA_SEL="1000";
    parameter CLKFB_SEL="internal", DEVICE="GW2AR-18C";
    integer startup = 0;
    initial begin
        if (FCLKIN != "27" || IDIV_SEL != 2 || FBDIV_SEL != 0 || ODIV_SEL != 64)
            $fatal(1, "LCD PLL model expects the 27 MHz to 9 MHz profile");
    end
    always #55.5555 CLKOUT = ~CLKOUT;
    always @(posedge CLKIN) begin
        if (RESET || RESET_P) begin LOCK <= 0; startup <= 0; end
        else if (startup == 32) LOCK <= 1;
        else startup <= startup + 1;
    end
endmodule
