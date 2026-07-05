// Boots the SemRV SoC and checks the firmware's whole run:
//   - UART output is exactly "SemRV!\n"
//   - the three reported SemNPU results match firmware/expected.hex
//     (golden values computed by build_firmware.py in Python)
//   - the CPU never traps
`timescale 1ns/1ps
`default_nettype none

module tb_soc;

    reg clk = 0;
    reg rst_n = 0;

    wire        trap;
    wire        uart_wr;
    wire [7:0]  uart_char;
    wire        report_wr;
    wire [1:0]  report_idx;
    wire [31:0] report_val;
    wire        done;

    simple_soc #(.FIRMWARE("firmware/firmware.hex")) dut (
        .clk(clk), .rst_n(rst_n), .trap(trap),
        .uart_wr(uart_wr), .uart_char(uart_char),
        .report_wr(report_wr), .report_idx(report_idx), .report_val(report_val),
        .done(done)
    );

    always #5 clk = ~clk;

    // capture UART stream and reports
    reg [7:0]  captured [0:63];
    integer    n_chars = 0;
    reg [31:0] reports  [0:2];
    reg [31:0] expected [0:2];

    // "SemRV!\n" as one packed constant; char i is WANT[8*(6-i) +: 8]
    localparam [55:0] WANT = {"S", "e", "m", "R", "V", "!", 8'h0A};

    always @(posedge clk) begin
        if (uart_wr) begin
            captured[n_chars] <= uart_char;
            n_chars <= n_chars + 1;
            $write("%c", uart_char);
        end
        if (report_wr)
            reports[report_idx] <= report_val;
    end

    integer i, errors = 0, cycles = 0;

    initial begin
        $dumpfile("tb_soc.vcd");
        $dumpvars(0, tb_soc);
        $readmemh("firmware/expected.hex", expected);

        repeat (5) @(posedge clk);
        rst_n = 1;

        while (!done && !trap && cycles < 100000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        repeat (5) @(posedge clk);   // let the last report land

        if (trap) begin
            $display("FAIL: CPU trapped after %0d cycles", cycles);
            errors = errors + 1;
        end
        if (!done) begin
            $display("FAIL: timeout, no DONE after %0d cycles", cycles);
            errors = errors + 1;
        end
        if (n_chars !== 7) begin
            $display("FAIL: expected 7 UART chars, got %0d", n_chars);
            errors = errors + 1;
        end else begin
            for (i = 0; i < 7; i = i + 1)
                if (captured[i] !== WANT[8*(6-i) +: 8]) begin
                    $display("FAIL: UART char %0d = %02x expected %02x",
                             i, captured[i], WANT[8*(6-i) +: 8]);
                    errors = errors + 1;
                end
        end
        for (i = 0; i < 3; i = i + 1)
            if (reports[i] !== expected[i]) begin
                $display("FAIL: report %0d = %0d (0x%08x) expected %0d (0x%08x)",
                         i, reports[i], reports[i], expected[i], expected[i]);
                errors = errors + 1;
            end

        if (errors == 0)
            $display("PASS: tb_soc — RISC-V firmware drove the SemNPU correctly (popand=%0d hamming=%0d dot8=%0d, %0d cycles)",
                     reports[0], reports[1], $signed(reports[2]), cycles);
        else begin
            $display("FAIL: tb_soc (%0d errors)", errors);
            $fatal(1);
        end
        $finish;
    end

endmodule
`default_nettype wire
