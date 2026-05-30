//it is the main ram like memory
//dmem= data memory
// it is not used in r and I type opcode, they directly read from regfile in ID and write back into it
//only load/store use it as they transffer data btw reg and dmem
// memories used overall:-
    //1)IMEM:-stores program instruction
    //2)regfile:-small fast working memninside cpu,it stoes temporary results,operand,alu inputs , recent computed value
    //3)dmem- only used by lw and sw
        //lw:- leads dmem data into regfile
        //sw:- stores regfile data into dmem
//reg file stores inout data from all kinds like dmem,alu,results,operand,alu inputs temporarity
// while dmem file only take input from regfile to store it permam=nently, it also take alu input if it is in form of a=offset calculated address
 //without using sw we cannot store any value in dmem
module dmem(
    input clk,
    input mem_read,//read data from dmem by lw
    input mem_write,//write data into dmem using sw
    input[31:0] address,// comes fro,m alu after computing offset and all
    input[31:0] write_data,
    output reg[31:0] read_data
);
reg[31:0] memory[0:255];//32 memories each of 256 words

//memory write
always @(posedge clk)
    begin
        if(mem_write)
        memory[address[9:2]]<=write_data;
    end

 //memory read
always @(*)
    begin
        if(mem_read)
        read_data=memory[address[9:2]];
        else 
        read_data=32'b0;
    end
endmodule