// Verifies hamming.v against the Python golden model.
`timescale 1ns/1ps
`default_nettype none

module tb_hamming;

    localparam W = 128;
    localparam N = 200;

    reg  [W-1:0] a, b;
    wire [7:0]   distance;

    hamming #(.W(W)) dut (.a(a), .b(b), .distance(distance));

    reg [W-1:0] vec_a   [0:N-1];
    reg [W-1:0] vec_b   [0:N-1];
    reg [7:0]   expected[0:N-1];

    integer i, errors = 0;

    initial begin
        $readmemh("vectors/bitset_a.hex", vec_a);
        $readmemh("vectors/bitset_b.hex", vec_b);
        $readmemh("vectors/expected_hamming.hex", expected);

        for (i = 0; i < N; i = i + 1) begin
            a = vec_a[i]; b = vec_b[i];
            #1;
            if (distance !== expected[i]) begin
                $display("FAIL case %0d: hamming=%0d expected=%0d", i, distance, expected[i]);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("PASS: tb_hamming (%0d cases)", N);
        else begin
            $display("FAIL: tb_hamming (%0d/%0d errors)", errors, N);
            $fatal(1);
        end
        $finish;
    end

endmodule
`default_nettype wire
