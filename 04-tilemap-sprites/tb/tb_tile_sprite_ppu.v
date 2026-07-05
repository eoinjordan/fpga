`timescale 1ns/1ps
`default_nettype none

module tb_tile_sprite_ppu;

    reg clk = 0, rst = 1, de = 0;
    reg [8:0] x = 0, scroll_x = 0;
    reg [7:0] y = 0, scroll_y = 0;
    wire out_de;
    wire [7:0] r, g, b;
    integer errors = 0;

    tile_sprite_ppu dut (
        .clk(clk), .rst(rst), .de(de), .x(x), .y(y),
        .scroll_x(scroll_x), .scroll_y(scroll_y),
        .out_de(out_de), .r(r), .g(g), .b(b)
    );

    always #5 clk = ~clk;

    task sample(input [8:0] sx, input [7:0] sy, input [23:0] expected, input [127:0] label);
        begin
            x = sx; y = sy; de = 1'b1;
            @(posedge clk); #1;
            if ({r, g, b} !== expected) begin
                $display("FAIL %0s: rgb=%h expected=%h", label, {r, g, b}, expected);
                errors = errors + 1;
            end
            if (!out_de) begin
                $display("FAIL %0s: out_de not asserted", label);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        rst = 0;

        // Pixel 0,0 is sprite 0 and should override the background.
        sample(9'd0, 8'd0, 24'hf0a832, "sprite overlay");

        // Tile-local x=1,y=2 with tile_x=2,tile_y=1 gives index 0.
        sample(9'd17, 8'd10, 24'h101820, "background colour");

        // A tile edge uses the grid highlight colour.
        sample(9'd16, 8'd10, 24'hf5f1e8, "tile grid");

        de = 0; @(posedge clk); #1;
        if ({r, g, b} !== 24'h000000 || out_de !== 1'b0) begin
            $display("FAIL blanking: rgb=%h out_de=%b", {r, g, b}, out_de);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_tile_sprite_ppu");
        else begin
            $display("FAIL: tb_tile_sprite_ppu (%0d errors)", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule

`default_nettype wire
