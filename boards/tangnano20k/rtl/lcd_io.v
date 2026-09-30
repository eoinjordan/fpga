`default_nettype none
// HT043IBB-16A3047-H4 panel profile used by GBA-FPGA.
// 27 MHz / 3 = 9 MHz; VCO = 9 MHz * 64 = 576 MHz.
module lcd_clock(input wire clk, input wire rst,
                 output wire pix_clk, output wire locked);
    rPLL #(.FCLKIN("27"), .IDIV_SEL(2), .FBDIV_SEL(0), .ODIV_SEL(64),
           .DYN_IDIV_SEL("false"), .DYN_FBDIV_SEL("false"), .DYN_ODIV_SEL("false"),
           .DYN_DA_EN("false"), .PSDA_SEL("0000"), .DUTYDA_SEL("1000"),
           .CLKFB_SEL("internal"), .DEVICE("GW2AR-18C")) pll (
        .CLKIN(clk), .CLKOUT(pix_clk), .LOCK(locked), .RESET(rst), .RESET_P(1'b0),
        .CLKFB(1'b0), .FBDSEL(6'd0), .IDSEL(6'd0), .ODSEL(6'd0),
        .PSDA(4'd0), .DUTYDA(4'd0), .FDLY(4'd0));
endmodule

// The panel samples on rising DCLK edges. Register RGB and controls on
// falling edges to keep them aligned and provide half a cycle of setup.
module lcd_output(input wire pix_clk, input wire rst,
                  input wire de, input wire hsync, input wire vsync,
                  input wire [7:0] r, g, b,
                  output wire lcd_dclk,
                  output reg lcd_de, lcd_hsync, lcd_vsync,
                  output reg [4:0] lcd_r,
                  output reg [5:0] lcd_g,
                  output reg [4:0] lcd_b);
    assign lcd_dclk = pix_clk;
    always @(negedge pix_clk) begin
        if (rst) begin
            lcd_de <= 0;
            lcd_hsync <= 1;
            lcd_vsync <= 1;
            {lcd_r, lcd_g, lcd_b} <= 16'd0;
        end else begin
            lcd_de <= de;
            lcd_hsync <= hsync;
            lcd_vsync <= vsync;
            {lcd_r, lcd_g, lcd_b} <= de ? {r[7:3], g[7:2], b[7:3]} : 16'd0;
        end
    end
endmodule
`default_nettype wire
