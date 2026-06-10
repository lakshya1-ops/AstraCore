//to convert instruction bits into useable 32 bit immediate value 
module imm_gen(
    input[31:0] instruction,
    output reg[31:0] imm_out
);

wire[6:0] opcode;

assign opcode=instruction[6:0];

always @(*)//ie immediate changes instantly when instruction changes
    begin
        case(opcode)//Values of opcode used here are official ISA RISV encoding for diff operations(R,I,S,U)
       
        //IType
        //no rs2 here
        // so imm value is used in rs2 and funct7
        7'b0010011,7'b0000011,7'b1100111: imm_out={{20{instruction[31]}},instruction[31:20]};//converted 12bit immediate vlaue into 32 bit


        //stype
        //(as it contain both rs2 and immediate value but donot contain rd becsuse it doesnot write in register it only stores the  data)
        //hence it cintain imm value in place of rd and funct7
        7'b0100011:imm_out={{20{instruction[31]}},instruction[31:25],instruction[11:7]};
    

        //b type
        //no rd as they donot write any value in regfile back thy only change control flow
        //info b type needs:- rs1,rs2,branch offset,funct3,opcode
        //here, imm[12]=instruction[31] , imm[11]=instruction[7] , imm[10:5]=instruction[30:25] and imm[4:1]=instruction[11:0] and imm[0]=0
        //imm[0]=0as branch jumps in multiple of 2
        7'b1100011:imm_out={{19{instruction[31]}},instruction[31],instruction[7],instruction[31:25],instruction[11:8],1'b0};


        //Utype
        // do two things:-{only large imm value and rd and opcode needed as input}
                //1) LUI:- stores a large immediate value to rd
                //2)AUIPC:-this adds the large imm value stores in pc and make new pc=pc+immvalue
        //so here both rs1 and rs2 along with func7 and func3 are replaced by immediate value 
        // 20 upper bit are taken from instruction and rest lower bits are kept 0
        7'b0110111,7'b0010111: imm_out={instruction[31:12],12'b0};


        //Jtype
        //it does 2 operaton simultaneously:-jump to another instruction and stores address in register
        // it needed jump offset and rd as ip
        //here imm value stored as:-inst[31]=imm[20],inst[30:21]=imm[10:1],inst[20]=imm[11],inst[19:12]=imm[19:12]
        7'b1101111:imm_out={{11{instruction[31]}},instruction[31],instruction[19:12],instruction[20],instruction[30:21],1'b0};
    
        default: imm_out=32'b0;
        endcase
    end
endmodule