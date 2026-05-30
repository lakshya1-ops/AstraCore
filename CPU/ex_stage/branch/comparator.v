//for branch decision logic
module comparator(
    input[31:0] operand_a,
    input[31:0] operand_b,
    input[2:0] funct3,
    output reg branch_taken
);

always @(*) 
    begin
        case(funct3)
        //beq
        3'b000:branch_taken=(operand_a==operand_b);

        //bne
        3'b001:branch_taken=(operand_a!=operand_b);

        //blt
        3'b100:branch_taken=($signed(operand_a)<$signed(operand_b));

        //bge
        3'b101:branch_taken=($signed(operand_a)>=$signed(operand_b));

        //bltu
        3'b110:branch_taken=(operand_a<operand_b);

        //bgeu
        3'b111:branch_taken=(operand_a>=operand_b);

        default:branch_taken=1'b0;

        endcase
    end
endmodule
