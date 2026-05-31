`timescale 1ns/1ps

module axi_soc_tb;

    astracore_soc_top dut();

    // Clock
    initial begin
        dut.clk = 0;
        forever #5 dut.clk = ~dut.clk;
    end

    initial begin

        // Reset
        dut.reset = 1;

        dut.mem_mem_read  = 0;
        dut.mem_mem_write = 0;
        dut.mem_addr      = 0;
        dut.mem_wdata     = 0;

        #20;
        dut.reset = 0;

        //--------------------------------
        // WRITE 15 TO ADDRESS 16
        //--------------------------------

        @(posedge dut.clk);

        dut.mem_addr      = 32'd16;
        dut.mem_wdata     = 32'd15;
        dut.mem_mem_write = 1'b1;

        @(posedge dut.clk);

        dut.mem_mem_write = 1'b0;

        repeat(5) @(posedge dut.clk);

        //--------------------------------
        // READ ADDRESS 16
        //--------------------------------

        dut.mem_addr     = 32'd16;
        dut.mem_mem_read = 1'b1;

        @(posedge dut.clk);

        dut.mem_mem_read = 1'b0;

        repeat(5) @(posedge dut.clk);

        //--------------------------------
        // CHECK
        //--------------------------------

        $display("mem_rdata = %d", dut.mem_rdata);

        if(dut.mem_rdata == 32'd15)
            $display("PASS");
        else
            $display("FAIL");

        #20;
        $finish;

    end

endmodule