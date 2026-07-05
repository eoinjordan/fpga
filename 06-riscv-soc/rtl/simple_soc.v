// SemRV SoC: PicoRV32 + 4KB RAM + MMIO + SemNPU.
//
// Memory map:
//   0x0000_0000 - 0x0000_0FFF  RAM (code + data), loaded from firmware.hex
//   0x8000_0000                UART TX (write a char)
//   0x8000_0004/08/0C          REPORT0..2 (testbench-visible result regs)
//   0x8000_0010                DONE
//   0x8000_1000 - 0x8000_10FF  SemNPU register file (07-semnpu/rtl/semnpu_regs.v)
//
// The uart/report/done outputs exist so the testbench (and later a real
// UART) can observe the firmware. On hardware, uart_* feeds a UART TX
// shift register on pin 69.
`default_nettype none
`timescale 1ns/1ps

module simple_soc #(
    parameter FIRMWARE = "firmware/firmware.hex"
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire        trap,
    // observation taps
    output reg         uart_wr,
    output reg  [7:0]  uart_char,
    output reg         report_wr,
    output reg  [1:0]  report_idx,
    output reg  [31:0] report_val,
    output reg         done
);

    // ---- CPU ----------------------------------------------------------
    wire        mem_valid, mem_instr;
    reg         mem_ready;
    wire [31:0] mem_addr, mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;

    picorv32 #(
        .PROGADDR_RESET(32'h0000_0000),
        .ENABLE_COUNTERS(0),
        .ENABLE_COUNTERS64(0),
        .ENABLE_REGS_DUALPORT(1),
        .CATCH_MISALIGN(1),
        .CATCH_ILLINSN(1)
    ) cpu (
        .clk       (clk),
        .resetn    (rst_n),
        .trap      (trap),
        .mem_valid (mem_valid),
        .mem_instr (mem_instr),
        .mem_ready (mem_ready),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_rdata (mem_rdata),
        .pcpi_wr   (1'b0),
        .pcpi_rd   (32'b0),
        .pcpi_wait (1'b0),
        .pcpi_ready(1'b0),
        .irq       (32'b0)
    );

    // ---- address decode (one-cycle-ready bus) --------------------------
    wire access   = mem_valid && !mem_ready;
    // NOTE: the RAM decode is deliberately loose — everything in
    // 0x0xxx_xxxx aliases onto the 4KB RAM via mem_addr[11:2]. Fine for
    // a toy SoC where firmware stays in the first 4KB; tighten this to
    // (mem_addr < RAM_BYTES) before adding more memories to this range.
    wire sel_ram  = access && (mem_addr[31:28] == 4'h0);
    wire sel_mmio = access && (mem_addr[31:12] == 20'h80000);
    wire sel_npu  = access && (mem_addr[31:12] == 20'h80001);

    // ---- RAM ------------------------------------------------------------
    reg [31:0] ram [0:1023];
    initial $readmemh(FIRMWARE, ram);

    reg [31:0] ram_rdata;
    always @(posedge clk) begin
        if (sel_ram) begin
            ram_rdata <= ram[mem_addr[11:2]];
            if (mem_wstrb[0]) ram[mem_addr[11:2]][ 7: 0] <= mem_wdata[ 7: 0];
            if (mem_wstrb[1]) ram[mem_addr[11:2]][15: 8] <= mem_wdata[15: 8];
            if (mem_wstrb[2]) ram[mem_addr[11:2]][23:16] <= mem_wdata[23:16];
            if (mem_wstrb[3]) ram[mem_addr[11:2]][31:24] <= mem_wdata[31:24];
        end
    end

    // ---- SemNPU ---------------------------------------------------------
    wire [31:0] npu_rdata;
    semnpu_regs npu (
        .clk  (clk),
        .rst  (!rst_n),
        .sel  (sel_npu),
        .addr (mem_addr[7:0]),
        .wdata(mem_wdata),
        .wstrb(mem_wstrb),
        .rdata(npu_rdata)
    );

    // ---- MMIO + ready generation ----------------------------------------
    reg npu_rdata_sel;
    always @(posedge clk) begin
        mem_ready     <= 1'b0;
        uart_wr       <= 1'b0;
        report_wr     <= 1'b0;
        npu_rdata_sel <= 1'b0;

        if (!rst_n) begin
            done <= 1'b0;
        end else if (access) begin
            mem_ready     <= 1'b1;
            npu_rdata_sel <= sel_npu;

            if (sel_mmio && mem_wstrb != 4'b0000) begin
                case (mem_addr[7:0])
                    8'h00: begin uart_wr <= 1'b1; uart_char <= mem_wdata[7:0]; end
                    8'h04: begin report_wr <= 1'b1; report_idx <= 2'd0; report_val <= mem_wdata; end
                    8'h08: begin report_wr <= 1'b1; report_idx <= 2'd1; report_val <= mem_wdata; end
                    8'h0C: begin report_wr <= 1'b1; report_idx <= 2'd2; report_val <= mem_wdata; end
                    8'h10: done <= 1'b1;
                    default: ;
                endcase
            end
        end
    end

    assign mem_rdata = npu_rdata_sel ? npu_rdata : ram_rdata;

endmodule

`default_nettype wire
