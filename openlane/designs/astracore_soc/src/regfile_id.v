module regfile(
    input clk,
    input reset,
    input reg_write,
    input[4:0] rs1,
    input[4:0] rs2,
    input[4:0] rd,
    input[31:0] write_data,
    output[31:0] read_data1,
    output[31:0] read_data2

);
reg[31:0] registers[31:0];
integer i;

always @(posedge clk or posedge reset)
    begin
        if(reset)
        begin
        for(i=0;i<32;i=i+1)
        registers[i]<=32'b0;
        end

        else if(reg_write && (rd!=5'b0))//cant write in 5'b0 as it is always kept 1
        begin
            registers[rd]<=write_data;//writing data in designated register
        end
    end

assign read_data1=(rs1 == 5'b0)?32'b0:registers[rs1];//reads rs1

assign read_data2=(rs2==5'b0)?32'b0:registers[rs2];//reads rs2

endmodule
