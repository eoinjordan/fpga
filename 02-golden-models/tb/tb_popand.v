// Verifies popand.v against the Python golden model.
`timescale 1ns/1ps
`default_nettype none

module tb_popand;

    localparam W = 128;
    localparam N = 200;

    reg  [W-1:0] a, b;
    wire [7:0]   score;

    popand #(.W(W)) dut (.a(a), .b(b), .score(score));

    reg [W-1:0] vec_a   [0:N-1];
    reg [W-1:0] vec_b   [0:N-1];
    reg [7:0]   expected[0:N-1];

    integer i, errors = 0;

    initial begin
        $readmemh("vectors/bitset_a.hex", vec_a);
        $readmemh("vectors/bitset_b.hex", vec_b);
        $readmemh("vectors/expected_popand.hex", expected);

        for (i = 0; i < N; i = i + 1) begin
            a = vec_a[i]; b = vec_b[i];
            #1;
            if (score !== expected[i]) begin
                $display("FAIL case %0d: popand=%0d expected=%0d", i, score, expected[i]);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS: tb_popand (%0d cases)", N);
        else begin
            $display("FAIL: tb_popand (%0d/%0d errors)", errors, N);
            $fatal(1);
        end
        $finish;
    end

endmodule
`default_nettype wire
