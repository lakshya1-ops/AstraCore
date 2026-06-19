//=============================================================================
// tb_mac_unit.v
// AstraCore Matrix Accelerator — MAC Unit Testbench
// Author : Lakshya Chowdhury
// Project: AstraCore RISC-V SoC
//
// Tests:
//   1. Basic positive accumulation
//   2. Negative number handling
//   3. Clear between dot products
//   4. Enable gating
//   5. Reset behavior
//   6. Dot product verification (4 MACs = one output element of 4x4 matrix)
//=============================================================================

`include "accelerator_pkg.vh"

module tb_mac_unit;

    // DUT ports
    reg                         clk;
    reg                         rst;
    reg                         enable;
    reg                         clear;
    reg  signed [7:0]           a;
    reg  signed [7:0]           b;
    wire signed [31:0]          acc_out;

    // Expected value tracker
    reg  signed [31:0]          expected;

    // Test counters
    integer pass_count;
    integer fail_count;

    // Clock generation — 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // DUT instantiation
    mac_unit #(
        .DATA_WIDTH(`DATA_WIDTH),
        .ACC_WIDTH (`ACC_WIDTH)
    ) dut (
        .clk    (clk),
        .rst    (rst),
        .enable (enable),
        .clear  (clear),
        .a      (a),
        .b      (b),
        .acc_out(acc_out)
    );

    // Task: apply one MAC operation and check result
    task apply_and_check;
        input signed [7:0]  in_a;
        input signed [7:0]  in_b;
        input signed [31:0] exp;
        input [127:0]       test_name;  // string label
        begin
            a        = in_a;
            b        = in_b;
            enable   = 1;
            clear    = 0;
            @(posedge clk);
            #1;                         // small delay after clock edge
            if(acc_out === exp) begin
                $display("PASS | %-20s | a=%4d  b=%4d  acc=%0d",
                          test_name, in_a, in_b, acc_out);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | %-20s | a=%4d  b=%4d  acc=%0d  expected=%0d",
                          test_name, in_a, in_b, acc_out, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Task: clear accumulator and check it resets to 0
    task do_clear;
        begin
            enable = 0;
            clear  = 1;
            @(posedge clk);
            #1;
            if(acc_out === 32'sd0) begin
                $display("PASS | %-20s | acc=%0d", "CLEAR", acc_out);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | %-20s | acc=%0d expected=0", "CLEAR", acc_out);
                fail_count = fail_count + 1;
            end
            clear = 0;
        end
    endtask

    initial begin

        $dumpfile("tb_mac_unit.vcd");
        $dumpvars(0, tb_mac_unit);

        // initialize
        pass_count = 0;
        fail_count = 0;
        rst        = 1;
        enable     = 0;
        clear      = 0;
        a          = 0;
        b          = 0;
        expected   = 0;

        $display("============================================");
        $display("  MAC Unit Testbench                       ");
        $display("============================================");

        // hold reset for 2 cycles
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        //---------------------------------------------------------------------
        // TEST 1 — Basic positive accumulation
        // 2*3 = 6, then +4*5 = 26, then +1*1 = 27
        //---------------------------------------------------------------------
        $display("--- Test 1: Basic Positive Accumulation ---");
        do_clear;
        apply_and_check(8'sd2,   8'sd3,   32'sd6,  "2x3=6");
        apply_and_check(8'sd4,   8'sd5,   32'sd26, "6+4x5=26");
        apply_and_check(8'sd1,   8'sd1,   32'sd27, "26+1x1=27");

        //---------------------------------------------------------------------
        // TEST 2 — Negative number handling
        // (-1)*1 = -1, then +(-1)*1 = -2
        //---------------------------------------------------------------------
        $display("--- Test 2: Negative Numbers ---");
        do_clear;
        apply_and_check(-8'sd1,  8'sd1,  -32'sd1, "-1x1=-1");
        apply_and_check(-8'sd1,  8'sd1,  -32'sd2, "-1+(-1x1)=-2");

        //---------------------------------------------------------------------
        // TEST 3 — Negative × Negative
        // (-3)*(-4) = 12, then +(-2)*(-5) = 22
        //---------------------------------------------------------------------
        $display("--- Test 3: Negative x Negative ---");
        do_clear;
        apply_and_check(-8'sd3, -8'sd4,  32'sd12, "-3x-4=12");
        apply_and_check(-8'sd2, -8'sd5,  32'sd22, "12+(-2x-5)=22");

        //---------------------------------------------------------------------
        // TEST 4 — Clear between dot products
        // accumulate some value, clear, then accumulate again
        //---------------------------------------------------------------------
        $display("--- Test 4: Clear Between Dot Products ---");
        do_clear;
        apply_and_check(8'sd10,  8'sd10, 32'sd100, "10x10=100");
        apply_and_check(8'sd5,   8'sd5,  32'sd125, "100+5x5=125");
        do_clear;                                   // clear — new dot product
        apply_and_check(8'sd3,   8'sd3,  32'sd9,   "after clear 3x3=9");

        //---------------------------------------------------------------------
        // TEST 5 — Enable gating
        // accumulate, then disable enable, value should hold
        //---------------------------------------------------------------------
        $display("--- Test 5: Enable Gating ---");
        do_clear;
        apply_and_check(8'sd7,   8'sd7,  32'sd49, "7x7=49");
        // now disable enable — acc should hold at 49
        enable = 0;
        a      = 8'sd10;
        b      = 8'sd10;
        @(posedge clk);
        #1;
        if(acc_out === 32'sd49) begin
            $display("PASS | %-20s | acc held at %0d", "ENABLE GATE", acc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL | %-20s | acc=%0d expected=49", "ENABLE GATE", acc_out);
            fail_count = fail_count + 1;
        end

        //---------------------------------------------------------------------
        // TEST 6 — Full 4x4 dot product simulation
        // C[0][0] = A[0][0]*B[0][0] + A[0][1]*B[1][0]
        //         + A[0][2]*B[2][0] + A[0][3]*B[3][0]
        // Using A row0 = [1,2,3,4], B col0 = [5,6,7,8]
        // Expected = 1*5 + 2*6 + 3*7 + 4*8 = 5+12+21+32 = 70
        //---------------------------------------------------------------------
        $display("--- Test 6: 4x4 Dot Product Element ---");
        do_clear;
        apply_and_check(8'sd1, 8'sd5, 32'sd5,  "1x5=5");
        apply_and_check(8'sd2, 8'sd6, 32'sd17, "5+2x6=17");
        apply_and_check(8'sd3, 8'sd7, 32'sd38, "17+3x7=38");
        apply_and_check(8'sd4, 8'sd8, 32'sd70, "38+4x8=70");

        //---------------------------------------------------------------------
        // TEST 7 — Boundary values
        // 127 * 127 = 16129
        // -128 * -128 = 16384
        //---------------------------------------------------------------------
        $display("--- Test 7: Boundary Values ---");
        do_clear;
        apply_and_check(8'sd127,  8'sd127,  32'sd16129, "127x127=16129");
        do_clear;
        apply_and_check(-8'sd128, -8'sd128, 32'sd16384, "-128x-128=16384");
        do_clear;
        apply_and_check(-8'sd128,  8'sd127, -32'sd16256,"-128x127=-16256");

        //---------------------------------------------------------------------
        // TEST 8 — Reset during accumulation
        //---------------------------------------------------------------------
        $display("--- Test 8: Reset During Accumulation ---");
        do_clear;
        apply_and_check(8'sd5, 8'sd5, 32'sd25, "5x5=25");
        // assert reset
        rst = 1;
        @(posedge clk);
        #1;
        rst = 0;
        if(acc_out === 32'sd0) begin
            $display("PASS | %-20s | acc reset to 0", "RESET");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL | %-20s | acc=%0d expected=0", "RESET", acc_out);
            fail_count = fail_count + 1;
        end

        //---------------------------------------------------------------------
        // SUMMARY
        //---------------------------------------------------------------------
        $display("============================================");
        $display("  PASSED : %0d", pass_count);
        $display("  FAILED : %0d", fail_count);
        $display("============================================");
        if(fail_count == 0)
            $display("  RESULT : ALL PASS — MAC Unit Correct");
        else
            $display("  RESULT : FAILURES DETECTED");
        $display("============================================");

        $finish;
    end

endmodule