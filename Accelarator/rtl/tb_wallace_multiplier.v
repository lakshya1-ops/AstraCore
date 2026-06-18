//=============================================================================
// tb_wallace_multiplier.v
// AstraCore Matrix Accelerator — Wallace Multiplier Exhaustive Testbench
// Author : Lakshya Chowdhury
// Project: AstraCore RISC-V SoC
//
// Tests all 65536 combinations of signed 8-bit inputs (-128 to +127)
// Compares DUT output against Verilog behavioral reference (a*b)
// Reports PASS/FAIL per case and final summary
//=============================================================================

`include "accelerator_pkg.vh"

// NOTE: cla_adder must be stubbed or written before this TB compiles
// We include a behavioral stub here for isolation testing

//=============================================================================
// CLA ADDER STUB — behavioral, for TB isolation only
// Replace with real cla_adder.v once written
//=============================================================================
module cla_adder #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              cin,
    output [WIDTH-1:0] sum,
    output             cout
);
    wire [WIDTH:0] result;
    assign result = {1'b0, a} + {1'b0, b} + cin;
    assign sum    = result[WIDTH-1:0];
    assign cout   = result[WIDTH];
endmodule

//=============================================================================
// TESTBENCH
//=============================================================================
module tb_wallace_multiplier;

    // DUT ports
    reg  signed [7:0]  a;
    reg  signed [7:0]  b;
    wire signed [15:0] product;

    // Reference
    reg signed [15:0] expected;

    // Counters
    integer pass_count;
    integer fail_count;
    integer total;

    // Loop variables
    integer i, j;

    // DUT instantiation
    wallace_multiplier #(
        .WIDTH(`DATA_WIDTH)
    ) dut (
        .a      (a),
        .b      (b),
        .product(product)
    );

    initial begin

        // Waveform dump
        $dumpfile("tb_wallace_multiplier.vcd");
        $dumpvars(0, tb_wallace_multiplier);

        // Initialize counters
        pass_count = 0;
        fail_count = 0;
        total      = 0;

        $display("============================================");
        $display("  Wallace Multiplier Exhaustive Testbench  ");
        $display("  Testing all 65536 signed 8x8 cases       ");
        $display("============================================");

        // Exhaustive test — all 256x256 signed combinations
        for(i = -128; i <= 127; i = i+1) begin
            for(j = -128; j <= 127; j = j+1) begin

                // Apply inputs
                a = i[7:0];
                b = j[7:0];

                // Compute reference
                expected = i * j;

                // Wait for combinational logic to settle
                #10;

                total = total + 1;

                // Compare DUT vs reference
                if(product === expected) begin
                    pass_count = pass_count + 1;

                    // Only print special boundary cases to avoid flooding terminal
                    if((i == -128 && j == -128) ||
                       (i == -128 && j ==  127) ||
                       (i ==  127 && j ==  127) ||
                       (i ==   -1 && j ==   -1) ||
                       (i ==   -1 && j ==    1) ||
                       (i ==    0 && j ==  127) ||
                       (i == -128 && j ==    1)) begin
                        $display("PASS | a=%4d  b=%4d  expected=%6d  got=%6d",
                                  i, j, expected, product);
                    end

                end else begin
                    fail_count = fail_count + 1;

                    // Print ALL failures
                    $display("FAIL | a=%4d  b=%4d  expected=%6d  got=%6d",
                              i, j, expected, product);
                end

            end
        end

        // Final summary
        $display("============================================");
        $display("  TOTAL   : %0d", total);
        $display("  PASSED  : %0d", pass_count);
        $display("  FAILED  : %0d", fail_count);
        $display("============================================");

        if(fail_count == 0)
            $display("  RESULT  : ALL PASS — Multiplier Correct");
        else
            $display("  RESULT  : FAILURES DETECTED — Check above");

        $display("============================================");

        $finish;
    end

endmodule