`default_nettype none
module board_reset(input wire clk, input wire button, output wire rst);
    reg [15:0] startup = 0;
    reg [1:0] sync = 0;
    always @(posedge clk) begin
        sync <= {sync[0], button};
        if (!(&startup)) startup <= startup + 1'b1;
    end
    assign rst = !(&startup) | sync[1];
endmodule
`default_nettype wire
