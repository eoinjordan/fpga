`timescale 1ns/1ps
`default_nettype none

module tb_semnpu_regs;

    reg clk = 0, rst = 1, sel = 0;
    reg [7:0] addr = 0;
    reg [31:0] wdata = 0;
    reg [3:0] wstrb = 0;
    wire [31:0] rdata;
    integer errors = 0;

    semnpu_regs dut (
        .clk(clk), .rst(rst), .sel(sel), .addr(addr),
        .wdata(wdata), .wstrb(wstrb), .rdata(rdata)
    );

    always #5 clk = ~clk;

    task write32(input [7:0] a, input [31:0] d);
        begin
            addr = a; wdata = d; wstrb = 4'hf; sel = 1'b1;
            @(posedge clk); #1;
            sel = 1'b0; wstrb = 4'h0;
        end
    endtask

    task read32(input [7:0] a, input [31:0] expected, input [127:0] label);
        begin
            addr = a; wstrb = 4'h0; sel = 1'b1;
            @(posedge clk); #1;
            sel = 1'b0;
            if (rdata !== expected) begin
                $display("FAIL %0s: rdata=%0d expected=%0d", label, $signed(rdata), $signed(expected));
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        rst = 0;

        write32(8'h00, 32'h0F0F0F0F);
        write32(8'h04, 32'h12345678);
        write32(8'h08, 32'hC0FFEE00);
        write32(8'h0C, 32'hDEADBEEF);
        write32(8'h10, 32'h00FF00FF);
        write32(8'h14, 32'h87654321);
        write32(8'h18, 32'hC0FFEE00);
        write32(8'h1C, 32'hFEEDFACE);
        read32(8'h20, 32'd51, "POPAND");
        read32(8'h24, 32'd36, "HAMMING");

        write32(8'h2C, 32'd1);
        write32(8'h28, 32'h0000_ce64); // a=100,  b=-50
        write32(8'h28, 32'h0000_7f80); // a=-128, b=127
        write32(8'h28, 32'h0000_0907); // a=7,    b=9
        write32(8'h28, 32'h0000_ffff); // a=-1,   b=-1
        write32(8'h28, 32'h0000_7f7f); // a=127,  b=127
        write32(8'h28, 32'h0000_3700); // a=0,    b=55
        read32(8'h30, -32'sd5063, "DOT8");

        if (errors == 0) $display("PASS: tb_semnpu_regs");
        else begin
            $display("FAIL: tb_semnpu_regs (%0d errors)", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule

`default_nettype wire
