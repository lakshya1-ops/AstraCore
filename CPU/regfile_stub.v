module regfile(
    input clk,
    input reset,
    input reg_write,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] write_data,
    output reg [31:0] read_data1,
    output reg [31:0] read_data2
);

always @(*) begin
    read_data1 = 32'b0;
    read_data2 = 32'b0;
end

endmodule
