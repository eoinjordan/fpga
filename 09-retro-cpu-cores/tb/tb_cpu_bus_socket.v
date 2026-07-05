`timescale 1ns/1ps
`default_nettype none

module tb_cpu_bus_socket;

    reg clk = 0, rst = 1;
    reg cpu_valid = 0, cpu_we = 0;
    reg [15:0] cpu_addr = 0;
    reg [7:0] cpu_wdata = 0;
    wire cpu_ready;
    wire [7:0] cpu_rdata;
    wire mem_valid;
    wire [31:0] mem_addr, mem_wdata;
    wire [3:0] mem_wstrb;
    reg mem_ready = 0;
    reg [31:0] mem_rdata = 32'h11223344;
    integer errors = 0;

    cpu_bus_socket #(.BASE_ADDR(32'h8000_0000)) dut (
        .clk(clk), .rst(rst),
        .cpu_valid(cpu_valid), .cpu_we(cpu_we), .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata), .cpu_ready(cpu_ready), .cpu_rdata(cpu_rdata),
        .mem_valid(mem_valid), .mem_addr(mem_addr), .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb), .mem_ready(mem_ready), .mem_rdata(mem_rdata)
    );

    always #5 clk = ~clk;

    initial begin
        repeat (2) @(posedge clk);
        rst = 0;

        cpu_addr = 16'h1001; cpu_wdata = 8'ha5; cpu_we = 1'b1; cpu_valid = 1'b1;
        @(posedge clk); #1; cpu_valid = 1'b0;
        if (!mem_valid || mem_addr !== 32'h8000_1000 || mem_wstrb !== 4'b0010 ||
            mem_wdata !== 32'h0000_a500) begin
            $display("FAIL write expansion: valid=%b addr=%h wstrb=%b wdata=%h",
                     mem_valid, mem_addr, mem_wstrb, mem_wdata);
            errors = errors + 1;
        end
        mem_ready = 1'b1; @(posedge clk); #1; mem_ready = 1'b0;
        if (!cpu_ready) begin
            $display("FAIL write did not ack CPU");
            errors = errors + 1;
        end

        cpu_addr = 16'h1002; cpu_we = 1'b0; cpu_valid = 1'b1;
        @(posedge clk); #1; cpu_valid = 1'b0;
        if (!mem_valid || mem_addr !== 32'h8000_1000 || mem_wstrb !== 4'b0000) begin
            $display("FAIL read request: valid=%b addr=%h wstrb=%b",
                     mem_valid, mem_addr, mem_wstrb);
            errors = errors + 1;
        end
        mem_ready = 1'b1; @(posedge clk); #1; mem_ready = 1'b0;
        if (!cpu_ready || cpu_rdata !== 8'h22) begin
            $display("FAIL read response: ready=%b rdata=%h", cpu_ready, cpu_rdata);
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: tb_cpu_bus_socket");
        else begin
            $display("FAIL: tb_cpu_bus_socket (%0d errors)", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule

`default_nettype wire
