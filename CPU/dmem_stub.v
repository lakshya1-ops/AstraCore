module dmem(
    input clk,
    input mem_read,
    input mem_write,
    input [31:0] address,
    input [31:0] write_data,
    output reg [31:0] read_data
);

always @(*) begin
    read_data = 32'b0;
end

endmodule
