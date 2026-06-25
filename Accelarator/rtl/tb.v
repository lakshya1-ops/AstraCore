//=============================================================================
// tb_matrix_accelerator.v
// AstraCore Matrix Accelerator — Full System Testbench
// Author : Lakshya Chowdhury
// Project: AstraCore RISC-V SoC
//
// Tests complete accelerator via AXI-lite transactions:
//   1. Write matrix A via AXI
//   2. Write matrix B via AXI
//   3. Write START to CONTROL register
//   4. Poll STATUS until DONE
//   5. Read matrix C via AXI
//   6. Verify C against behavioral reference
//
// Tests:
//   Test 1: Identity × B = B
//   Test 2: All ones × All ones = 4
//   Test 3: Signed matrices
//   Test 4: Boundary values
//   Test 5: Second multiply after done
//=============================================================================

`include "accelerator_pkg.vh"

module tb_matrix_accelerator;

    //-------------------------------------------------------------------------
    // PARAMETERS
    //-------------------------------------------------------------------------
    localparam N   = `MATRIX_DIM;      // 4
    localparam DW  = `DATA_WIDTH;      // 8
    localparam AW  = `ACC_WIDTH;       // 32

    // AXI base address
    localparam BASE = 32'h10000300;

    //-------------------------------------------------------------------------
    // DUT PORTS
    //-------------------------------------------------------------------------
    reg         clk;
    reg         rst;

    // AXI-lite master signals
    reg  [31:0] AWADDR;
    reg         AWVALID;
    wire        AWREADY;

    reg  [31:0] WDATA;
    reg         WVALID;
    wire        WREADY;

    wire [1:0]  BRESP;
    wire        BVALID;
    reg         BREADY;

    reg  [31:0] ARADDR;
    reg         ARVALID;
    wire        ARREADY;

    wire [31:0] RDATA;
    wire        RVALID;
    reg         RREADY;
    wire [1:0]  RRESP;

    //-------------------------------------------------------------------------
    // TEST DATA
    //-------------------------------------------------------------------------
    reg signed [DW-1:0]  mat_a    [0:N-1][0:N-1];
    reg signed [DW-1:0]  mat_b    [0:N-1][0:N-1];
    reg signed [AW-1:0]  mat_c_exp[0:N-1][0:N-1];
    reg signed [AW-1:0]  mat_c_got[0:N-1][0:N-1];

    // Counters
    integer pass_count;
    integer fail_count;
    integer i, j, k;

    //-------------------------------------------------------------------------
    // CLOCK
    //-------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //-------------------------------------------------------------------------
    // DUT
    //-------------------------------------------------------------------------
    matrix_accelerator_top #(
        .MATRIX_DIM(N),
        .DATA_WIDTH(DW),
        .ACC_WIDTH (AW)
    ) dut (
        .clk    (clk),
        .rst    (rst),
        .AWADDR (AWADDR),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),
        .WDATA  (WDATA),
        .WVALID (WVALID),
        .WREADY (WREADY),
        .BRESP  (BRESP),
        .BVALID (BVALID),
        .BREADY (BREADY),
        .ARADDR (ARADDR),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),
        .RDATA  (RDATA),
        .RVALID (RVALID),
        .RREADY (RREADY),
        .RRESP  (RRESP)
    );

    //-------------------------------------------------------------------------
    // TASK: AXI write transaction
    //-------------------------------------------------------------------------
    task axi_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            AWADDR  = addr;
            AWVALID = 1;
            WDATA   = data;
            WVALID  = 1;
            BREADY  = 1;

            @(posedge clk);
            #1;

            AWVALID = 0;
            WVALID  = 0;

            @(posedge clk);
            while(!BVALID) @(posedge clk);
            #1;

            BREADY = 0;
            @(posedge clk);
        end
    endtask


    //-------------------------------------------------------------------------
    // TASK: AXI read transaction
    //-------------------------------------------------------------------------
   task axi_read;
        input  [31:0] addr;
        output [31:0] data;
        begin
            @(negedge clk);
            ARADDR  = addr;
            ARVALID = 1;
            RREADY  = 1;

            @(posedge clk);
            #1;

            ARVALID = 0;

            @(posedge clk);
            while(!RVALID) @(posedge clk);
            #1;

            data   = RDATA;
            RREADY = 0;
            @(posedge clk);
        end
    endtask
    //-------------------------------------------------------------------------
    // TASK: write matrix A to buffer via AXI
    //-------------------------------------------------------------------------
    task write_matrix_a;
        integer ti, tj;
        reg [31:0] addr;
        begin
            for(ti = 0; ti < N; ti = ti+1)
                for(tj = 0; tj < N; tj = tj+1) begin
                    // element [i][j] at offset REG_A_BASE + (i*N+j)*4
                    addr = BASE + `REG_A_BASE + ((ti*N + tj) * 4);
                    axi_write(addr, {{24{mat_a[ti][tj][DW-1]}}, mat_a[ti][tj]});
                end
        end
    endtask

    //-------------------------------------------------------------------------
    // TASK: write matrix B to buffer via AXI
    //-------------------------------------------------------------------------
    task write_matrix_b;
        integer ti, tj;
        reg [31:0] addr;
        begin
            for(ti = 0; ti < N; ti = ti+1)
                for(tj = 0; tj < N; tj = tj+1) begin
                    addr = BASE + `REG_B_BASE + ((ti*N + tj) * 4);
                    axi_write(addr, {{24{mat_b[ti][tj][DW-1]}}, mat_b[ti][tj]});
                end
        end
    endtask

    //-------------------------------------------------------------------------
    // TASK: start accelerator and wait for done
    //-------------------------------------------------------------------------
   task start_and_wait;
    reg [31:0] status;
    integer timeout;
    begin
        // write START=1
        axi_write(BASE + `REG_CONTROL, 32'h1);

        // wait a few cycles for FSM to leave IDLE and enter CLEAR
        repeat(3) @(posedge clk);

        // now poll until DONE=1
        status  = 0;
        timeout = 0;
        while(!status[`STATUS_DONE_BIT]) begin
            axi_read(BASE + `REG_STATUS, status);
            timeout = timeout + 1;
            if(timeout > 1000) begin
                $display("TIMEOUT: accelerator never asserted DONE");
                $finish;
            end
            @(posedge clk);
        end
    end
endtask

    //-------------------------------------------------------------------------
    // TASK: read matrix C from buffer via AXI
    //-------------------------------------------------------------------------
    task read_matrix_c;
        integer ti, tj;
        reg [31:0] addr;
        reg [31:0] rdata;
        begin
            for(ti = 0; ti < N; ti = ti+1)
                for(tj = 0; tj < N; tj = tj+1) begin
                    addr = BASE + `REG_C_BASE + ((ti*N + tj) * 4);
                    axi_read(addr, rdata);
                    mat_c_got[ti][tj] = $signed(rdata);
                end
        end
    endtask

    //-------------------------------------------------------------------------
    // TASK: compute expected result (behavioral reference)
    //-------------------------------------------------------------------------
    task compute_expected;
        integer ti, tj, tk;
        begin
            for(ti = 0; ti < N; ti = ti+1)
                for(tj = 0; tj < N; tj = tj+1) begin
                    mat_c_exp[ti][tj] = 0;
                    for(tk = 0; tk < N; tk = tk+1)
                        mat_c_exp[ti][tj] = mat_c_exp[ti][tj] +
                                            $signed(mat_a[ti][tk]) *
                                            $signed(mat_b[tk][tj]);
                end
        end
    endtask

    //-------------------------------------------------------------------------
    // TASK: check results
    //-------------------------------------------------------------------------
    task check_results;
        input [127:0] test_name;
        integer ti, tj;
        reg test_pass;
        begin
            test_pass = 1;
            for(ti = 0; ti < N; ti = ti+1)
                for(tj = 0; tj < N; tj = tj+1) begin
                    if(mat_c_got[ti][tj] === mat_c_exp[ti][tj]) begin
                        pass_count = pass_count + 1;
                    end else begin
                        $display("FAIL | %s | C[%0d][%0d] got=%0d exp=%0d",
                                  test_name, ti, tj,
                                  mat_c_got[ti][tj],
                                  mat_c_exp[ti][tj]);
                        fail_count = fail_count + 1;
                        test_pass  = 0;
                    end
                end
            if(test_pass)
                $display("PASS | %s | all %0d elements correct",
                          test_name, N*N);
        end
    endtask

    //-------------------------------------------------------------------------
    // TASK: run one complete matrix multiply
    //-------------------------------------------------------------------------
    task run_test;
        input [127:0] test_name;
        begin
            compute_expected;
            write_matrix_a;
            write_matrix_b;
            start_and_wait;
            read_matrix_c;
            check_results(test_name);
        end
    endtask

    //-------------------------------------------------------------------------
    // MAIN TEST
    //-------------------------------------------------------------------------
    initial begin

        $dumpfile("tb_matrix_accelerator.vcd");
        $dumpvars(0, tb_matrix_accelerator);

        // initialize
        pass_count = 0;
        fail_count = 0;
        rst        = 1;
        AWVALID    = 0;
        AWADDR     = 0;
        WVALID     = 0;
        WDATA      = 0;
        BREADY     = 0;
        ARVALID    = 0;
        ARADDR     = 0;
        RREADY     = 0;

        // hold reset
        repeat(4) @(posedge clk);
        rst = 0;
        repeat(2) @(posedge clk);

        $display("============================================");
        $display("  Matrix Accelerator Full System TB        ");
        $display("============================================");

        //---------------------------------------------------------------------
        // TEST 1 — Identity × B = B
        //---------------------------------------------------------------------
        $display("--- Test 1: Identity x B = B ---");
        for(i=0; i<N; i=i+1)
            for(j=0; j<N; j=j+1) begin
                mat_a[i][j] = (i==j) ? 8'sd1 : 8'sd0;
                mat_b[i][j] = i*N + j + 1;
            end
        run_test("IDENTITY x B");

        //---------------------------------------------------------------------
        // TEST 2 — All ones × All ones = 4
        //---------------------------------------------------------------------
        $display("--- Test 2: Ones x Ones = 4 ---");
        for(i=0; i<N; i=i+1)
            for(j=0; j<N; j=j+1) begin
                mat_a[i][j] = 8'sd1;
                mat_b[i][j] = 8'sd1;
            end
        run_test("ONES x ONES");

        //---------------------------------------------------------------------
        // TEST 3 — Signed matrices
        //---------------------------------------------------------------------
        $display("--- Test 3: Signed ---");
        for(i=0; i<N; i=i+1)
            for(j=0; j<N; j=j+1) begin
                mat_a[i][j] = -(i*N + j + 1);
                mat_b[i][j] =  (i*N + j + 1);
            end
        run_test("SIGNED");

        //---------------------------------------------------------------------
        // TEST 4 — Boundary 127 × 127
        //---------------------------------------------------------------------
        $display("--- Test 4: Boundary 127 x 127 ---");
        for(i=0; i<N; i=i+1)
            for(j=0; j<N; j=j+1) begin
                mat_a[i][j] = 8'sd127;
                mat_b[i][j] = 8'sd127;
            end
        run_test("127 x 127");

        //---------------------------------------------------------------------
        // TEST 5 — Second multiply after done
        //---------------------------------------------------------------------
        $display("--- Test 5: Second Multiply ---");
        for(i=0; i<N; i=i+1)
            for(j=0; j<N; j=j+1) begin
                mat_a[i][j] = 8'sd3;
                mat_b[i][j] = 8'sd3;
            end
        run_test("SECOND MULTIPLY");

        //---------------------------------------------------------------------
        // SUMMARY
        //---------------------------------------------------------------------
        $display("============================================");
        $display("  PASSED : %0d", pass_count);
        $display("  FAILED : %0d", fail_count);
        $display("============================================");
        if(fail_count == 0)
            $display("  RESULT : ALL PASS — Accelerator Correct");
        else
            $display("  RESULT : FAILURES DETECTED");
        $display("============================================");

        $finish;
    end

endmodule