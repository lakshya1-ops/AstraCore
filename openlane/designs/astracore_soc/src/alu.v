module alu(
    input[31:0] operand_a, //usually rs1
    input[31:0] operand_b, //either rs2 or imm_value
    input[3:0] alu_sel,//select which op to perform
    output reg[31:0] alu_result
);

always @(*)
    begin
        case(alu_sel)

        //add
        4'b0000:alu_result=operand_a+operand_b;

        //sub
        4'b0001:alu_result=operand_a-operand_b;

        //and
        4'b0010:alu_result=operand_a&operand_b;

        //or
        4'b0011:alu_result=operand_a|operand_b;

        //xor
        4'b0100:alu_result=operand_a^operand_b;

        //sll(shift left logic)
        4'b0101:alu_result=operand_a<<operand_b[4:0];// 5 bit shift amount as specified by rsiv and is only effective as 2^5=32

        //srl(shift right logic)
         4'b0110:alu_result=operand_a>>operand_b[4:0];

        //sra // preserve sign unlike prev 2
          4'b0111:alu_result=$signed(operand_a)>>>operand_b;

        //slt(set less than)
         4'b1000:alu_result=($signed(operand_a)<$signed(operand_b))?32'd1:32'd0;

        //sltu(set less than unsigned)
         4'b1001:alu_result=(operand_a<operand_b)?32'd1:32'd0;

         default:alu_result=32'b0;
        endcase
    end
endmodule
