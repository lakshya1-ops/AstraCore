// it will be storing memory of out instruction
//pc stores address of current instruction( eg pc=x63527, ie  fetch instruction stores in addr x63527)
//addr recieevs pc value( ie in imem block pc value willl come iwth name addr , samee thing)
module imem(
    input [31:0] address,
    output[31:0] instruction// caries fetched instructuion that was presrent in memory reg at "addr/pc" adress
);
    
    reg [31:0] memory[0:255];//instruction memory storage
    //out memory but has 256 set of instruction ie 256 unique adrres, so to select them we only need 8 byte data in pc/addr
    integer i;
    initial begin
        // Fill full instruction memory with NOPs first.
        // NOP = addi x0, x0, 0
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'h00000013;

        // Then overwrite starting locations with your real program.
        $readmemh("CPU/program.mem", memory);
    end

    assign instruction = memory[address[9:2]];

endmodule