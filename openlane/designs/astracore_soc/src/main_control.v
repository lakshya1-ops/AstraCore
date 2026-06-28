// it is the central decision maker of cpu
//it takes opcodde from ID decoder and sends signal to EX stage on what to do exatly
//it doesnot compute anything it only generate control signals
//defined for each specific opcode
//plays role ID EX and MEM stage
module main_control(
    input[6:0] opcode,
    output reg alu_src,
    output reg mem_read,
    output reg mem_write,
    output reg reg_write,
    output reg mem_to_reg,
    output reg branch,
    output reg jalr,
    output reg jump,
    output reg[1:0] wb_sel
);

always @(*) 
begin
    //default values
    alu_src =1'b0;
    mem_read =1'b0;
    mem_write =1'b0;
    reg_write =1'b0;
    mem_to_reg =1'b0;
    branch =1'b0;
    jump =1'b0;
    wb_sel=2'b00;
    jalr=1'b0;

    case(opcode)

        //Rtype
        7'b0110011:begin
                    alu_src=1'b0;
                    reg_write=1'b1;
                    end

        //Itype
        7'b0010011:begin
                    alu_src=1'b1;
                    reg_write=1'b1;  
                    end
        //Load
        7'b0000011:begin
                    alu_src=1'b1;
                    reg_write=1'b1;  
                    mem_read=1'b1;
                    wb_sel=2'b01;
                    end
        //store
        7'b0100011:begin
                    alu_src=1'b1;
                    mem_write=1'b1;
                    end
        //branch
        7'b1100011:begin
                    branch=1'b1;
                    end
        //jal
        7'b1101111:begin
                    jump=1'b1;
                    reg_write=1'b1;
                     wb_sel=2'b10;
                    end
        //jalr
        7'b1100111:begin
                    alu_src=1'b1;
                    jalr=1'b1;
                    reg_write=1'b1;
                     wb_sel=2'b10;
                    end
        //lui
        7'b0110111:begin
                    alu_src=1'b1;
                    reg_write=1'b1;
                    end
        //auipc
        7'b0010111:begin
                    alu_src=1'b1;
                    reg_write=1'b1;
                    end
        default:begin
                alu_src =1'b0;
                mem_read =1'b0;
                mem_write =1'b0;
                reg_write =1'b0;
                mem_to_reg =1'b0;
                branch =1'b0;
                jump =1'b0;
                wb_sel=2'b00;
                jalr=1'b0;
                end
    endcase
end
endmodule