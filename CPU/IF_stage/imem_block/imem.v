// it will be storing memory of out instruction
//pc stores address of current instruction( eg pc=x63527, ie  fetch instruction stores in addr x63527)
//addr recieevs pc value( ie in imem block pc value willl come iwth name addr , samee thing)
module imem(
    input [31:0] address,
    output[31:0] instruction// caries fetched instructuion that was presrent in memory reg at "addr/pc" adress
);
    
    reg [31:0] memory[0:255];//instruction memory storage
    //out memory but has 256 set of instruction ie 256 unique adrres, so to select them we only need 8 byte data in pc/addr
    initial 
        begin
          $readmemh("CPU/program.mem", memory);
        end

    assign instruction =memory[address[9:2]];// 9:2contain 8 byte data that can store 256 diff addr to select from memory
    //0-1 its are ignores as they are always zero ie 4-0100,8-1000,C-1100.... and by ignoring them we get 4-..01 , 8-..10 ie we converted 4,8,C series to ,1,2,3 contineous address as better memory indexing
    // rest 31-10 bits are unused
endmodule