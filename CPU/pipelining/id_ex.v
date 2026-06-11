module id_ex(
    input clk,
    input reset,
    input enable,
    //INPUT FROM ID STAGE
    input[31:0]id_pc_current,
    input[31:0]id_pc_plus4,
    input[31:0]rs1_data,
    input[31:0]rs2_data,
    input[31:0]imm_out,
    input[4:0]rd,
    input[2:0]funct3,
    input[3:0]alu_sel,
    input [4:0] rs1,
    input [4:0] rs2,
    //control signal
    input alu_src,
    input mem_read,
    input mem_write,
    input reg_write,
    input [1:0] wb_sel,
    input branch,
    input jump,
    input jalr,
    input flush,
    //output of this reg

    output reg [31:0] ex_pc_current,
    output reg [31:0] ex_pc_plus4,
    output reg [31:0] ex_rs1_data,
    output reg [31:0] ex_rs2_data,
    output reg [31:0] ex_imm_out,
    output reg [4:0] ex_rd,
    output reg [2:0] ex_funct3,
    output reg [3:0] ex_alu_sel,//alu select is generated in id stage
    //control output
    output reg ex_alu_src,//
    output reg ex_mem_read,
    output reg ex_mem_write,
    output reg ex_reg_write,
    output reg [1:0] ex_wb_sel,
    output reg ex_branch,
    output reg ex_jump,
    output reg ex_jalr,
    output reg [4:0] ex_rs1,
    output reg [4:0] ex_rs2
);
always @(posedge clk or posedge reset) //asynchronous clock
begin
   if(reset)
   begin
    ex_pc_current <= 32'b0;
    ex_pc_plus4   <= 32'b0;
    ex_rs1_data <= 32'b0;
    ex_rs2_data <= 32'b0;
    ex_imm_out <= 32'b0;
    ex_rd <= 5'b0;
    ex_funct3 <= 3'b0;
    ex_alu_sel <= 4'b0;
    ex_alu_src <= 1'b0;
    ex_mem_read  <= 1'b0;
    ex_mem_write <= 1'b0;
    ex_reg_write <= 1'b0;
    ex_wb_sel <= 2'b0;
    ex_branch <= 1'b0;
    ex_jump   <= 1'b0;
    ex_jalr   <= 1'b0;
    ex_rs1 <= 5'b0;
    ex_rs2 <= 5'b0;
   end
   else if(flush)
begin
    ex_pc_current <= 32'b0;
    ex_pc_plus4   <= 32'b0;
    ex_rs1_data <= 32'b0;
    ex_rs2_data <= 32'b0;
    ex_imm_out <= 32'b0;
    ex_rd <= 5'b0;
    ex_funct3 <= 3'b0;
    ex_alu_sel <= 4'b0;
    ex_alu_src <= 1'b0;
    ex_mem_read  <= 1'b0;
    ex_mem_write <= 1'b0;
    ex_reg_write <= 1'b0;
    ex_wb_sel <= 2'b0;
    ex_branch <= 1'b0;
    ex_jump   <= 1'b0;
    ex_jalr   <= 1'b0;
    ex_rs1 <= 5'b0;
    ex_rs2 <= 5'b0;
end
    else if(enable)
    begin

        ex_pc_current <= id_pc_current;
        ex_pc_plus4   <= id_pc_plus4;
        ex_rs1_data <= rs1_data;
        ex_rs2_data <= rs2_data;
        ex_imm_out <= imm_out;
        ex_rd <= rd;
        ex_funct3 <= funct3;
        ex_alu_sel <= alu_sel;
        ex_alu_src <= alu_src;
        ex_mem_read  <= mem_read;
        ex_mem_write <= mem_write;
        ex_reg_write <= reg_write;
        ex_wb_sel <= wb_sel;
        ex_branch <= branch;
        ex_jump   <= jump;
        ex_jalr   <= jalr;
        ex_rs1 <= rs1;
        ex_rs2 <= rs2;
    end

end

endmodule