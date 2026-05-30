module alu_src_mux(
    input[31:0] rs2_data,
    input[31:0] imm_data,
    input alu_src,
    output[31:0] operand_b
);

assign operand_b=(alu_src)?imm_data:rs2_data;
endmodule