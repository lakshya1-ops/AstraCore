// it generates alu_sel from given instruction(opcode+funct3+funct7(sometimes))
//it is not the main control unit
// belong to ID stage
module alu_control(
    input[6:0] opcode,
    input[2:0] funct3,
    input[6:0] funct7,
    output reg[3:0] alu_sel
);
always @(*)
    begin
        case(opcode)
        //rtype
        7'b0110011:
                begin
                    case(funct3)
                         // add/sub
                        3'b000:
                            begin
                                //add
                                if(funct7==7'b0000000)
                                    alu_sel=4'b0000;
                                //sub
                                else if(funct7==7'b0100000)
                                    alu_sel=4'b0001;

                                else
                                    alu_sel=4'b1111;
                            end 
                        //sll
                        3'b001: alu_sel=4'b0101;

                        //slt
                        3'b010:alu_sel=4'b1000;

                        //sltu
                        3'b011:alu_sel=4'b1001;

                        //xor
                        3'b100:alu_sel=4'b0100;

                        //srl/sra
                        3'b101:begin
                                //srl
                                if(funct7==7'b0000000)
                                    alu_sel=4'b0110;
                                //sra
                                else if(funct7==7'b0100000)
                                    alu_sel=4'b0111;

                                else
                                    alu_sel=4'b1111;
                                end
                        //or
                        3'b110:alu_sel=4'b0011;

                        //and
                        3'b111:alu_sel=4'b0010;

                        default:alu_sel=4'b1111;
                    endcase

                end

        //Itype
        7'b0010011:begin
                    case(funct3)
                        //addi
                        3'b000:alu_sel=4'b0000;

                        //slli
                        3'b001:alu_sel=4'b0101;

                        //slti
                        3'b010:alu_sel=4'b1000;

                        //sltiu
                        3'b011:alu_sel=4'b1001;

                        //xori
                        3'b100:alu_sel=4'b0100;

                        //srli/srai
                        3'b101:begin
                                //srli
                                if(funct7==7'b0000000)
                                 alu_sel=4'b0110;
                                //srai
                                else if(funct7==7'b0100000)
                                 alu_sel=4'b0111;

                                else
                                 alu_sel=4'b1111;
                                end

                        //ori
                        3'b110:alu_sel=4'b0011;

                        //andi
                        3'b111:alu_sel=4'b0010;

                        default:alu_sel=4'b1111;
                    endcase
                end
        // LUI
        7'b0110111:
                alu_sel = 4'b0000;

        // AUIPC
        7'b0010111:
                alu_sel = 4'b0000;

        // LOAD
        7'b0000011:
                alu_sel = 4'b0000;

        // STORE
        7'b0100011:
                alu_sel = 4'b0000;

         // JALR
        7'b1100111:
                alu_sel = 4'b0000;

        default: alu_sel=4'b1111;

        endcase
    end
endmodule