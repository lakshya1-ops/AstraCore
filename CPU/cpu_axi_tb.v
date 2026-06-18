`timescale 1ns/1ps

module cpu_axi_tb;

reg clk;
reg reset;

cpu_axi_top dut(
    .clk(clk),
    .reset(reset)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

initial begin
    reset = 1'b1;
    #20;
    reset = 1'b0;
end

always @(posedge clk)
begin
    #1;

    $display(
        "pc=%h instr=%h wb_rd=%0d wb_we=%b wb_sel=%b wb_data=%h x5=%h axi_busy=%b",
        dut.pc_current,
        dut.instruction,
        dut.wb_rd,
        dut.wb_reg_write,
        dut.wb_wb_sel,
        dut.writeback_data,
        dut.REGFILE.registers[5],
        dut.axi_busy
    );
end

initial begin
    #2000;

    if(dut.REGFILE.registers[5] == 32'h00000001)
    begin
        $display("PASS: UART read test passed. x5 = %h", dut.REGFILE.registers[5]);
    end
    else
    begin
        $display("FAIL: UART read test failed. x5 = %h, expected 00000001", dut.REGFILE.registers[5]);
    end

    $finish;
end

endmodule