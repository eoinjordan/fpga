// Byte-wide retro CPU socket to the SemBoy 32-bit native peripheral bus.
// 6502/65C816/SM83-style cores can drive cpu_*; the socket expands each
// byte access into a word-addressed valid/ready transaction.
`default_nettype none
`timescale 1ns/1ps

module cpu_bus_socket #(
    parameter BASE_ADDR = 32'h8000_0000
) (
    input  wire        clk,
    input  wire        rst,

    input  wire        cpu_valid,
    input  wire        cpu_we,
    input  wire [15:0] cpu_addr,
    input  wire [7:0]  cpu_wdata,
    output reg         cpu_ready,
    output reg  [7:0]  cpu_rdata,

    output reg         mem_valid,
    output reg  [31:0] mem_addr,
    output reg  [31:0] mem_wdata,
    output reg  [3:0]  mem_wstrb,
    input  wire        mem_ready,
    input  wire [31:0] mem_rdata
);

    reg [1:0] byte_lane;

    always @(posedge clk) begin
        if (rst) begin
            cpu_ready <= 1'b0;
            cpu_rdata <= 8'd0;
            mem_valid <= 1'b0;
            mem_addr <= 32'd0;
            mem_wdata <= 32'd0;
            mem_wstrb <= 4'd0;
            byte_lane <= 2'd0;
        end else begin
            cpu_ready <= 1'b0;

            if (!mem_valid && cpu_valid) begin
                byte_lane <= cpu_addr[1:0];
                mem_valid <= 1'b1;
                mem_addr <= BASE_ADDR + {14'd0, cpu_addr[15:2], 2'b00};
                mem_wstrb <= cpu_we ? (4'b0001 << cpu_addr[1:0]) : 4'b0000;
                mem_wdata <= {24'd0, cpu_wdata} << (8 * cpu_addr[1:0]);
            end else if (mem_valid && mem_ready) begin
                mem_valid <= 1'b0;
                cpu_ready <= 1'b1;
                mem_wstrb <= 4'b0000;
                case (byte_lane)
                    2'd0: cpu_rdata <= mem_rdata[7:0];
                    2'd1: cpu_rdata <= mem_rdata[15:8];
                    2'd2: cpu_rdata <= mem_rdata[23:16];
                    default: cpu_rdata <= mem_rdata[31:24];
                endcase
            end
        end
    end

endmodule

`default_nettype wire
