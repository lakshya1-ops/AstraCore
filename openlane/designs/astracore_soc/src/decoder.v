module decoder(
    input[31:0] instruction,
    output[6:0] opcode,
    output[4:0] rd,
    output[2:0] funct3,
    output[4:0] rs1,
    output[4:0] rs2,
    output[6:0] funct7
);

assign opcode=instruction[6:0];//tells instruction type(R,I,L,S,B)

assign rd=instruction[11:7];//destination register

assign funct3=instruction[14:12];//exact operation to be performed like add sub etc

assign rs1=instruction[19:15];//source reg 1

assign rs2=instruction[24:20];//source reg 2

assign funct7=instruction[31:25];// either contain exact operation to be performed like add sub etc or CONTAIN IMMEDIATE VALUE FOR I TYPE OPCODE OPERATION

// in case of immediate value use we whole 20:31 bits of instruction are used in storing imm value in place of rs2 and funct7

//WE USED BOTH FUNCT7 AND FUNCT3 FOR OPERARTOION DETERMINING AS NUMBER OF OP>>2^3 ie 8

endmodule