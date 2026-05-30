`timescale 1ns/1ps

module cpu_top_tb;

reg clk;
reg reset;

// DUT
cpu_top dut(
    .clk(clk),
    .reset(reset)
);

// CLOCK
always #5 clk = ~clk;

//=====================================
// INITIAL
//=====================================
initial
begin
    clk = 0;
    reset = 1;

    // dump waveform
    $dumpfile("cpu_pipeline.vcd");
    $dumpfile("wave.vcd");
    $dumpvars(0,cpu_top_tb);
    // reset release
    #20;
    reset = 0;

    // runtime
   #180;

    // final report
    final_report();

    $finish;
end

//=====================================
// CYCLE-BY-CYCLE MONITOR
//=====================================
always @(posedge clk)
begin
    $display("------------------------------------------------");
    $display("TIME = %0t",$time);

    // PC + instruction flow
    $display("PC = %h",dut.pc_current);
    $display("IF  INST = %h",dut.instruction);
    $display("ID  INST = %h",dut.id_instruction);

    // pipeline rd tracking
    $display("EX  RD   = %d",dut.ex_rd);
    $display("MEM RD   = %d",dut.mem_rd);
    $display("WB  RD   = %d",dut.wb_rd);

    // ALU + forwarding
    $display("ALU RES  = %h",dut.alu_result);
    $display("FWD_A    = %b",dut.forward_a);
    $display("FWD_B    = %b",dut.forward_b);

    // memory
    $display("MEM ALU  = %h",dut.mem_alu_result);
    $display("MEM DATA = %h",dut.mem_data);

    // WB
    $display("WB ALU   = %h",dut.wb_alu_result);
    $display("WB DATA  = %h",dut.writeback_data);

    // hazards
    $display("STALL = %b",dut.stall);
    $display("FLUSH = %b",dut.flush);

    // branch/jump
    $display("BRANCH TAKEN = %b",dut.branch_taken);
    $display("NEXT PC      = %h",dut.next_pc);

    // operands
    $display("RS1 DATA = %h",dut.forwarded_rs1_data);
    $display("RS2 DATA = %h",dut.forwarded_rs2_data);

    // control
    $display("REG WRITE = %b",dut.wb_reg_write);

end

//=====================================
// FINAL REPORT
//=====================================
task final_report;
begin

    $display("====================================");
    $display("FINAL CPU STATE");
    $display("====================================");

    $display("PC CURRENT      = %h",dut.pc_current);
    $display("NEXT PC         = %h",dut.next_pc);

    $display("====================================");
    $display("REGISTER FILE");
    $display("====================================");

    $display("x0  = %h",dut.REGFILE.registers[0]);
    $display("x1  = %h",dut.REGFILE.registers[1]);
    $display("x2  = %h",dut.REGFILE.registers[2]);
    $display("x3  = %h",dut.REGFILE.registers[3]);
    $display("x4  = %h",dut.REGFILE.registers[4]);
    $display("x5  = %h",dut.REGFILE.registers[5]);
    $display("x6  = %h",dut.REGFILE.registers[6]);
    $display("x7  = %h",dut.REGFILE.registers[7]);
    $display("x8  = %h",dut.REGFILE.registers[8]);
    $display("x9  = %h",dut.REGFILE.registers[9]);
    $display("x10 = %h",dut.REGFILE.registers[10]);
    $display("x11 = %h",dut.REGFILE.registers[11]);
    $display("x12 = %h",dut.REGFILE.registers[12]);
    $display("x13 = %h",dut.REGFILE.registers[13]);
    $display("x14 = %h",dut.REGFILE.registers[14]);
    $display("x15 = %h",dut.REGFILE.registers[15]);

    $display("====================================");
    $display("DATA MEMORY");
    $display("====================================");

    $display("MEM[0]  = %h",dut.DMEM.memory[0]);
    $display("MEM[1]  = %h",dut.DMEM.memory[1]);
    $display("MEM[2]  = %h",dut.DMEM.memory[2]);
    $display("MEM[3]  = %h",dut.DMEM.memory[3]);
    $display("MEM[4]  = %h",dut.DMEM.memory[4]);
    $display("MEM[5]  = %h",dut.DMEM.memory[5]);
    $display("MEM[6]  = %h",dut.DMEM.memory[6]);
    $display("MEM[7]  = %h",dut.DMEM.memory[7]);

    $display("====================================");
    $display("PIPELINE REGISTERS");
    $display("====================================");

    $display("IF/ID INST      = %h",dut.id_instruction);

    $display("ID/EX RD        = %d",dut.ex_rd);
    $display("ID/EX ALU SEL   = %b",dut.ex_alu_sel);

    $display("EX/MEM RD       = %d",dut.mem_rd);
    $display("EX/MEM ALU RES  = %h",dut.mem_alu_result);

    $display("MEM/WB RD       = %d",dut.wb_rd);
    $display("MEM/WB ALU RES  = %h",dut.wb_alu_result);

    $display("====================================");
    $display("HAZARD STATUS");
    $display("====================================");

    $display("STALL           = %b",dut.stall);
    $display("FLUSH           = %b",dut.flush);

    $display("====================================");
    $display("FORWARDING");
    $display("====================================");

    $display("FORWARD_A       = %b",dut.forward_a);
    $display("FORWARD_B       = %b",dut.forward_b);

    $display("====================================");
    $display("SIMULATION COMPLETE");
    $display("====================================");
    $display("====================================");
    $display("PERFORMANCE COUNTERS");
    $display("====================================");

    $display("TOTAL CYCLES      = %0d",dut.cycle_counter);
    $display("INSTRUCTIONS      = %0d",dut.instr_counter);
    $display("STALL COUNT       = %0d",dut.stall_counter);
    $display("FLUSH COUNT       = %0d",dut.flush_counter);
    $display("CPI = %f",
    dut.cycle_counter * 1.0 /
    dut.instr_counter);
end
endtask


endmodule