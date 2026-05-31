module cpu_top(
    input clk,
    input reset,

    output [31:0] debug_pc,
    output [31:0] debug_instr,
    output [31:0] debug_alu_result,
    output [31:0] debug_wb,
    output [31:0] debug_mem
);
//IF stage
wire[31:0] pc_current;
wire[31:0] pc_plus4;
wire[31:0] next_pc;
wire[31:0] instruction;
wire comparator_branch_taken;

 //decoder outputs
wire[6:0] opcode;
wire[4:0] rd;
wire[2:0] funct3;
wire[4:0] rs1;
wire[4:0] rs2;
wire[6:0] funct7;


//control signal
wire alu_src;
wire mem_read;
wire mem_write;
wire reg_write;
wire branch;
wire jump;
wire jalr;
wire mem_branch;

wire[1:0] wb_sel;
wire[3:0] alu_sel;

//regfile signals
wire[31:0] rs1_data;
wire[31:0] rs2_data;
wire[31:0] writeback_data;

//immediate
wire[31:0] imm_out;

//alu
wire[31:0] alu_operand_b;
wire[31:0] alu_result;

//branch
wire branch_taken;
wire[31:0] branch_target;

//memory
wire[31:0] mem_data;

//jump target
wire[31:0] jal_target;
wire[31:0] jalr_target;


//NOW PIPELINING THINGS:----(BEEN ADDED LATER)
//IF_ID
wire[31:0] id_pc_current;
wire[31:0] id_pc_plus4;
wire[31:0] id_instruction;

//ID_EX
wire [31:0] ex_pc_current;
wire [31:0] ex_pc_plus4;
wire [31:0] ex_rs1_data;
wire [31:0] ex_rs2_data;
wire [31:0] ex_imm_out;
wire [4:0] ex_rd;
wire [2:0] ex_funct3;
wire [3:0] ex_alu_sel;
wire ex_alu_src;
wire ex_mem_write;
wire ex_reg_write;
wire [1:0] ex_wb_sel;
wire ex_branch;
wire ex_jump;
wire ex_jalr;
wire [4:0] ex_rs1;
wire [4:0] ex_rs2;
//EX_MEM:-
wire [31:0] mem_alu_result;
wire [31:0] mem_rs2_data;
wire [4:0] mem_rd;
wire [31:0] mem_pc_plus4;
wire mem_branch_taken;
wire [31:0] mem_branch_target;
wire [31:0] mem_jal_target;
wire [31:0] mem_jalr_target;
wire mem_mem_read;
wire mem_mem_write;
wire mem_reg_write;
wire [1:0] mem_wb_sel;
wire mem_jump;
wire mem_jalr;
wire real_ex_mem_read;
//mem_WB:- 
wire [31:0] wb_alu_result;
wire [31:0] wb_mem_data;
wire [31:0] wb_pc_plus4;
wire [4:0] wb_rd;
wire wb_reg_write;
wire [1:0] wb_wb_sel;




//FORWARDING STAGE:-
wire [1:0] forward_a;
wire [1:0] forward_b;
reg [31:0] forwarded_rs1_data;
reg [31:0] forwarded_rs2_data;


wire stall;
wire flush;
wire axi_busy;
assign axi_busy = 1'b0;
wire global_stall;

//performence counter:-
reg [31:0] cycle_counter;
reg [31:0] instr_counter;
reg [31:0] stall_counter;
reg [31:0] flush_counter;
wire wb_valid;



//pc register//


pc PC(
    .clk(clk),
    .reset(reset),
    .pc_enable(~global_stall),
    .pc_next(next_pc),
    .pc_current(pc_current)
);

pc_next PC_PLUS4(
    .pc_current(pc_current),
    .pc_next(pc_plus4)
);

//instruction memory
imem IMEM(
    .address(pc_current),
    .instruction(instruction)
);

//decoder
decoder DECODER(
    .instruction(id_instruction),
    .rd(rd),
    .opcode(opcode),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7)
);

//main control
main_control CONTROL(
    .mem_read(mem_read),
    .opcode(opcode),
    .alu_src(alu_src),
    .mem_write(mem_write),
    .reg_write(reg_write),
    .branch(branch),
    .jump(jump),
    .jalr(jalr),
    .wb_sel(wb_sel)
);

//alu control
alu_control ALU_CONTROL(
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .alu_sel(alu_sel)
);

//regfile
regfile REGFILE(
    .clk(clk),
    .reset(reset),
    .rd(wb_rd),
    .rs1(rs1),
    .rs2(rs2),
    .reg_write(wb_reg_write),
    .write_data(writeback_data),
    .read_data1(rs1_data),
    .read_data2(rs2_data)
);


//INITIATING FORWARDING:-
forwarding_unit FU(
    .ex_rs1(ex_rs1),
    .ex_rs2(ex_rs2),
    .mem_rd(mem_rd),
    .mem_reg_write(mem_reg_write),
    .wb_rd(wb_rd),
    .wb_reg_write(wb_reg_write),
    .forward_a(forward_a),
    .forward_b(forward_b)
);


always @(*)
begin
    //for operand a
    if(forward_a == 2'b00)
    begin
        forwarded_rs1_data = ex_rs1_data;
    end

    else if(forward_a == 2'b10)
    begin
        forwarded_rs1_data = mem_alu_result;
    end
    else if(forward_a == 2'b01)
    begin
        forwarded_rs1_data = writeback_data;
    end
    else
    begin
        forwarded_rs1_data = ex_rs1_data;
    end
    //for forward_b
    if(forward_b == 2'b00)
    begin
        forwarded_rs2_data = ex_rs2_data;
    end
    else if(forward_b == 2'b10)
    begin
        forwarded_rs2_data = mem_alu_result;
    end

    else if(forward_b == 2'b01)
    begin
        forwarded_rs2_data = writeback_data;
    end
    else
    begin
        forwarded_rs2_data = ex_rs2_data;
    end
end


//imm gen
imm_gen IMM_GEN(
    .instruction(id_instruction),
    .imm_out(imm_out)
);

//alu src mux
alu_src_mux ALU_SRC_MUX(
    .rs2_data(forwarded_rs2_data),
    .imm_data(ex_imm_out),
    .alu_src(ex_alu_src),
    .operand_b(alu_operand_b)
);

//ALU
alu ALU(
    .operand_a(forwarded_rs1_data),
    .operand_b(alu_operand_b),
    .alu_sel(ex_alu_sel),
    .alu_result(alu_result)
);

//comparator
comparator COMPARATOR(
    .operand_a(forwarded_rs1_data),
    .operand_b(forwarded_rs2_data),
    .funct3(ex_funct3),
    .branch_taken(comparator_branch_taken)
);

//branch target adder
branch_target_adder BRANCH_TARGET(
    .pc_current(ex_pc_current),
    .branch_imm(ex_imm_out),
    .branch_target(branch_target)
);

//data memory
dmem DMEM(
    .clk(clk),
    .mem_read(mem_mem_read),
    .mem_write(mem_mem_write), 
    .address(mem_alu_result),
    .write_data(mem_rs2_data),
    .read_data(mem_data)
);

//jal target
assign jal_target=ex_pc_current+ ex_imm_out;

//jalr_target
assign jalr_target = {alu_result[31:1],1'b0};

assign branch_taken =ex_branch && comparator_branch_taken;

//next pc mux
next_pc_mux NEXT_PC_MUX(
    .pc_plus4(pc_plus4),
    .branch_target(branch_target),
    .jal_target(jal_target),
    .jalr_target(jalr_target),
    .branch(ex_branch),
    .branch_taken(branch_taken),
    .jump(ex_jump),
    .jalr(ex_jalr),
    .next_pc(next_pc)
);

//writeback mux
writeback_mux WB_MUX(
    .alu_result(wb_alu_result),
    .mem_data(wb_mem_data),
    .pc_plus4(wb_pc_plus4),
    .wb_sel(wb_wb_sel),
    .writeback_data(writeback_data)
);


//NOW INSTANTIATING ALL PIPELINING MODULEZ:----
if_id IF_ID(
    .clk(clk),
    .reset(reset),
    .pc_current(pc_current),
    .pc_plus4(pc_plus4),
    .instruction(instruction),
    .id_pc_current(id_pc_current),
    .id_pc_plus4(id_pc_plus4),
    .id_instruction(id_instruction),
    .enable(~global_stall),
    .flush(flush)
);


id_ex ID_EX(
    .clk(clk),
    .reset(reset),
    // ID stage inputs
    .id_pc_current(id_pc_current),
    .id_pc_plus4(id_pc_plus4),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .imm_out(imm_out),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .funct3(funct3),
    .alu_sel(alu_sel),
    .flush(flush),
    // control input
    .alu_src(stall ? 1'b0 : alu_src),
    .mem_read(stall ? 1'b0 : mem_read),
    .mem_write(stall ? 1'b0 : mem_write),
    .reg_write(stall ? 1'b0 : reg_write),
    .wb_sel(stall ? 2'b00 : wb_sel),
    .branch(stall ? 1'b0 : branch),
    .jump(stall ? 1'b0 : jump),
    .jalr(stall ? 1'b0 : jalr),
    // EX outputs
    .ex_pc_current(ex_pc_current),
    .ex_pc_plus4(ex_pc_plus4),
    .ex_rs1_data(ex_rs1_data),
    .ex_rs2_data(ex_rs2_data),
    .ex_imm_out(ex_imm_out),
    .ex_rd(ex_rd),
    .ex_funct3(ex_funct3),
    .ex_alu_sel(ex_alu_sel),
    .ex_rs1(ex_rs1),
    .ex_rs2(ex_rs2),
    // control outputs
    .ex_alu_src(ex_alu_src),
    .ex_mem_read(real_ex_mem_read),
    .ex_mem_write(ex_mem_write),
    .ex_reg_write(ex_reg_write),
    .ex_wb_sel(ex_wb_sel),
    .ex_branch(ex_branch),
    .ex_jump(ex_jump),
    .ex_jalr(ex_jalr)
);

ex_mem EX_MEM(
    .clk(clk),
    .reset(reset),
    // EX stage inputs
    .alu_result(alu_result),
    .ex_rs2_data(forwarded_rs2_data),
    .ex_rd(ex_rd),
    .ex_pc_plus4(ex_pc_plus4),
    // branch/jump info
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .jal_target(jal_target),
    .jalr_target(jalr_target),
    // control inputs
    .ex_branch(ex_branch),
    .ex_mem_read(real_ex_mem_read),
    .ex_mem_write(ex_mem_write),
    .ex_reg_write(ex_reg_write),
    .ex_wb_sel(ex_wb_sel),
    .ex_jump(ex_jump),
    .ex_jalr(ex_jalr),
    // MEM stage outputs
    .mem_alu_result(mem_alu_result),
    .mem_rs2_data(mem_rs2_data),
    .mem_rd(mem_rd),
    .mem_pc_plus4(mem_pc_plus4),
    .mem_branch_taken(mem_branch_taken),
    .mem_branch_target(mem_branch_target),
    .mem_jal_target(mem_jal_target),
    .mem_jalr_target(mem_jalr_target),
    // control outputs
    .mem_branch(mem_branch),
    .mem_mem_read(mem_mem_read),
    .mem_mem_write(mem_mem_write),
    .mem_reg_write(mem_reg_write),
    .mem_wb_sel(mem_wb_sel),
    .mem_jump(mem_jump),
    .mem_jalr(mem_jalr)
);
mem_wb MEM_WB(
    .clk(clk),
    .reset(reset),
    // MEM input
    .mem_alu_result(mem_alu_result),
    .mem_data(mem_data),
    .mem_pc_plus4(mem_pc_plus4),
    .mem_rd(mem_rd),
    // control
    .mem_reg_write(mem_reg_write),
    .mem_wb_sel(mem_wb_sel),
    // WB outputs
    .wb_alu_result(wb_alu_result),
    .wb_mem_data(wb_mem_data),
    .wb_pc_plus4(wb_pc_plus4),
    .wb_rd(wb_rd),
    // control outputs
    .wb_reg_write(wb_reg_write),
    .wb_wb_sel(wb_wb_sel)
);

//hazard unit initiaztion
hazard_detection_unit HDU(
    .ex_mem_read(real_ex_mem_read),
    .ex_rd(ex_rd),
    .id_rs1(rs1),
    .id_rs2(rs2),
    .stall(stall)
);

assign flush =((ex_branch && branch_taken)|| ex_jump|| ex_jalr);


//cycle counter
assign wb_valid =
    (wb_rd != 5'b0) ||
    wb_reg_write ||
    mem_mem_write ||
    mem_branch ||
    mem_jump ||
    mem_jalr;

//cycle counter
always @(posedge clk)
begin
    if(reset)
    begin
        cycle_counter <= 0;
        instr_counter <= 0;
    end

    else
    begin
        cycle_counter <= cycle_counter + 1;

        if(wb_valid)
            instr_counter <= instr_counter + 1;
    end
end

//stall counteralways 
always @(posedge clk)
begin
    if(reset)
        stall_counter <= 0;

    else if(stall)
        stall_counter <= stall_counter + 1;
end

//flush counter
always @(posedge clk)
begin
    if(reset)
        flush_counter <= 0;

    else if(flush)
        flush_counter <= flush_counter + 1;
end
assign debug_pc         = pc_current;
assign debug_instr      = instruction;
assign debug_alu_result = alu_result;
assign debug_wb         = writeback_data;
assign debug_mem        = mem_data;

assign global_stall = stall || axi_busy;

endmodule







