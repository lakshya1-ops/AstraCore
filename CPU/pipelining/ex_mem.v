module ex_mem(
    input clk,
    input reset,
    input enable,
    // INPUTS FROM EX STAGE
    input[31:0] alu_result,
    input[31:0] ex_rs2_data,
    input[4:0] ex_rd,
    input [31:0] ex_pc_plus4,
    input ex_branch,
   // branch/jump info
    input branch_taken,

    input [31:0] branch_target,
    input [31:0] jal_target,
    input [31:0] jalr_target,
     // CONTROL SIGNALS
    input ex_mem_read,
    input ex_mem_write,
    input ex_reg_write,
    input [1:0] ex_wb_sel,
    input ex_jump,
    input ex_jalr,
    // OUTPUTS TO MEM STAGE
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_rs2_data,
    output reg [4:0] mem_rd,
    output reg [31:0] mem_pc_plus4,
    // branch/jump info
    output reg mem_branch_taken,
    output reg [31:0] mem_branch_target,
    output reg [31:0] mem_jal_target,
    output reg [31:0] mem_jalr_target,
  // CONTROL OUTPUTS
    output reg mem_mem_read,
    output reg mem_mem_write,
    output reg mem_reg_write,
    output reg [1:0] mem_wb_sel,
    output reg mem_jump,
    output reg mem_jalr,
    output reg mem_branch
);

always @(posedge clk or posedge reset)
begin

   if(reset)
    begin
        mem_branch <= 1'b0;
        mem_alu_result <= 32'b0;
        mem_rs2_data <= 32'b0;
        mem_rd <= 5'b0;
        mem_pc_plus4 <= 32'b0;
        mem_branch_taken <= 1'b0;
        mem_branch_target <= 32'b0;
        mem_jal_target    <= 32'b0;
        mem_jalr_target   <= 32'b0;
        mem_mem_read  <= 1'b0;
        mem_mem_write <= 1'b0;
        mem_reg_write <= 1'b0;
        mem_wb_sel <= 2'b0;
        mem_jump <= 1'b0;
        mem_jalr <= 1'b0;

    end
else if(enable)
    begin
        mem_alu_result <= alu_result;
        mem_rs2_data <= ex_rs2_data;
        mem_rd <= ex_rd;
        mem_pc_plus4 <= ex_pc_plus4;
        mem_branch_taken <= branch_taken;
        mem_branch_target <= branch_target;
        mem_jal_target    <= jal_target;
        mem_jalr_target   <= jalr_target;
        mem_mem_read  <= ex_mem_read;
        mem_mem_write <= ex_mem_write;
        mem_reg_write <= ex_reg_write;
        mem_wb_sel <= ex_wb_sel;
        mem_jump <= ex_jump;
        mem_jalr <= ex_jalr;
        mem_branch <= ex_branch;
    end

end

endmodule


