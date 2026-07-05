// Verifies dot8.v against the Python golden model.
// Streams DOT_LEN int8 pairs per test, then compares the accumulator.
`timescale 1ns/1ps
`default_nettype none

module tb_dot8;

    localparam DOT_LEN = 16;
    localparam N_TESTS = 100;

    reg               clk = 0;
    reg               rst = 1;
    reg               clear = 0;
    reg               in_valid = 0;
    reg  signed [7:0] a, b;
    wire signed [31:0] acc;

    dot8 dut (
        .clk(clk), .rst(rst), .clear(clear), .in_valid(in_valid),
        .a(a), .b(b), .acc(acc)
    );

    always #5 clk = ~clk;

    reg [7:0]  vec_a   [0:N_TESTS*DOT_LEN-1];
    reg [7:0]  vec_b   [0:N_TESTS*DOT_LEN-1];
    reg [31:0] expected[0:N_TESTS-1];

    integer t, i, errors = 0;

    initial begin
        $dumpfile("tb_dot8.vcd");
        $dumpvars(0, tb_dot8);

        $readmemh("vectors/dot8_a.hex", vec_a);
        $readmemh("vectors/dot8_b.hex", vec_b);
        $readmemh("vectors/expected_dot8.hex", expected);

        repeat (2) @(negedge clk);
        rst = 0;
        // rst must leave the accumulator at exactly 0, not X
        if (acc !== 32'sd0) begin
            $display("FAIL: acc not zero after reset (acc=%0d)", acc);
            errors = errors + 1;
        end

        for (t = 0; t < N_TESTS; t = t + 1) begin
            @(negedge clk) clear = 1; in_valid = 0;
            @(negedge clk) clear = 0;

            for (i = 0; i < DOT_LEN; i = i + 1) begin
                a = vec_a[t*DOT_LEN + i];
                b = vec_b[t*DOT_LEN + i];
                in_valid = 1;
                @(negedge clk);
            end
            in_valid = 0;
            @(negedge clk);

            if (acc !== $signed(expected[t])) begin
                $display("FAIL test %0d: acc=%0d expected=%0d",
                         t, acc, $signed(expected[t]));
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS: tb_dot8 (%0d tests)", N_TESTS);
        else begin
            $display("FAIL: tb_dot8 (%0d/%0d errors)", errors, N_TESTS);
            $fatal(1);
        end
        $finish;
    end

endmodule
`default_nettype wire
