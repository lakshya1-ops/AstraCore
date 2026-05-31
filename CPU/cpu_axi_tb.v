`timescale 1ns/1ps

module cpu_axi_tb;

reg clk;
reg reset;

wire [31:0] debug_pc;
wire [31:0] debug_instr;
wire [31:0] debug_alu_result;
wire [31:0] debug_wb;
wire [31:0] debug_mem;

cpu_axi_top dut(
    .clk(clk),
    .reset(reset),

    .debug_pc(debug_pc),
    .debug_instr(debug_instr),
    .debug_alu_result(debug_alu_result),
    .debug_wb(debug_wb),
    .debug_mem(debug_mem)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    reset = 1;
    #20;
    reset = 0;

    #2000;
    $finish;
end

initial begin
    $monitor(
        "t=%0t PC=%h INSTR=%h WB=%h",
        $time,
        debug_pc,
        debug_instr,
        debug_wb
    );
end
initial begin
    #250000;

    $display("MEM[0] = %h",
        dut.slave.memory[0]);
$display("MEM[0] = %d", dut.slave.memory[0]);
    $finish;
end

endmodule