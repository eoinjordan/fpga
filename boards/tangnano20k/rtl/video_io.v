`default_nettype none
// 27 MHz -> 371.25 MHz serial -> 74.25 MHz pixel (720p60).
module video_clock(input wire clk, input wire rst,
                   output wire serial_clk, output wire pix_clk, output wire locked);
    rPLL #(.FCLKIN("27"), .IDIV_SEL(3), .FBDIV_SEL(54), .ODIV_SEL(2),
           .DYN_IDIV_SEL("false"), .DYN_FBDIV_SEL("false"), .DYN_ODIV_SEL("false"),
           .CLKFB_SEL("internal"), .DEVICE("GW2AR-18C")) pll (
        .CLKIN(clk), .CLKOUT(serial_clk), .LOCK(locked), .RESET(rst), .RESET_P(1'b0),
        .CLKFB(1'b0), .FBDSEL(6'd0), .IDSEL(6'd0), .ODSEL(6'd0),
        .PSDA(4'd0), .DUTYDA(4'd0), .FDLY(4'd0));
    CLKDIV #(.DIV_MODE("5"), .GSREN("false")) divider (
        .HCLKIN(serial_clk), .RESETN(locked), .CALIB(1'b0), .CLKOUT(pix_clk));
endmodule

module tmds_lane(input wire pix_clk, input wire serial_clk, input wire rst,
                 input wire [9:0] symbol, output wire p, output wire n);
    wire serial;
    OSER10 serializer(.PCLK(pix_clk), .FCLK(serial_clk), .RESET(rst),
        .D0(symbol[0]), .D1(symbol[1]), .D2(symbol[2]), .D3(symbol[3]),
        .D4(symbol[4]), .D5(symbol[5]), .D6(symbol[6]), .D7(symbol[7]),
        .D8(symbol[8]), .D9(symbol[9]), .Q(serial));
    TLVDS_OBUF output_buffer(.I(serial), .O(p), .OB(n));
endmodule
`default_nettype wire
