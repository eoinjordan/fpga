// SemNPU register file: wraps stage 02's sim-proven blocks (popand,
// hamming, dot8) behind a simple memory-mapped bus so a CPU can use them.
//
// Byte address map (addr is the low 8 bits of the bus address):
//   0x00-0x0C  A[31:0] .. A[127:96]   (write)
//   0x10-0x1C  B[31:0] .. B[127:96]   (write)
//   0x20       POPAND score            (read)
//   0x24       HAMMING distance        (read)
//   0x28       DOT8 stream: a=[7:0], b=[15:8]  (write, one pair per write)
//   0x2C       DOT8 clear              (write anything)
//   0x30       DOT8 accumulator        (read)
//
// sel must pulse exactly one clock per bus transaction.
`default_nettype none
`timescale 1ns/1ps

module semnpu_regs (
    input  wire        clk,
    input  wire        rst,
    input  wire        sel,
    input  wire [7:0]  addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output reg  [31:0] rdata
);

    reg [127:0] vec_a, vec_b;

    wire [7:0] popand_score;
    wire [7:0] hamming_dist;

    popand  #(.W(128)) u_popand  (.a(vec_a), .b(vec_b), .score(popand_score));
    hamming #(.W(128)) u_hamming (.a(vec_a), .b(vec_b), .distance(hamming_dist));

    reg                dot_clear, dot_valid;
    reg  signed [7:0]  dot_a, dot_b;
    wire signed [31:0] dot_acc;

    dot8 u_dot8 (
        .clk(clk), .clear(dot_clear), .in_valid(dot_valid),
        .a(dot_a), .b(dot_b), .acc(dot_acc)
    );

    wire wr = sel && (wstrb != 4'b0000);

    always @(posedge clk) begin
        dot_clear <= 1'b0;
        dot_valid <= 1'b0;

        if (rst) begin
            vec_a <= 128'd0;
            vec_b <= 128'd0;
        end else if (wr) begin
            case (addr)
                8'h00: vec_a[ 31:  0] <= wdata;
                8'h04: vec_a[ 63: 32] <= wdata;
                8'h08: vec_a[ 95: 64] <= wdata;
                8'h0C: vec_a[127: 96] <= wdata;
                8'h10: vec_b[ 31:  0] <= wdata;
                8'h14: vec_b[ 63: 32] <= wdata;
                8'h18: vec_b[ 95: 64] <= wdata;
                8'h1C: vec_b[127: 96] <= wdata;
                8'h28: begin
                    dot_a     <= wdata[7:0];
                    dot_b     <= wdata[15:8];
                    dot_valid <= 1'b1;
                end
                8'h2C: dot_clear <= 1'b1;
                default: ;
            endcase
        end

        if (sel) begin
            case (addr)
                8'h20:   rdata <= {24'd0, popand_score};
                8'h24:   rdata <= {24'd0, hamming_dist};
                8'h30:   rdata <= dot_acc;
                default: rdata <= 32'd0;
            endcase
        end
    end

endmodule

`default_nettype wire
