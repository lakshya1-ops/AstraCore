module mem_wb(

    input clk,
    input reset,
    input enable,
    // INPUTS FROM MEM STAGE
    input [31:0] mem_alu_result,
    input [31:0] mem_data,
    input [31:0] mem_pc_plus4,
    input [4:0] mem_rd,
    // CONTROL SIGNALS
    input mem_reg_write,
    input [1:0] mem_wb_sel,

    // OUTPUTS TO WB STAGE
    output reg [31:0] wb_alu_result,
    output reg [31:0] wb_mem_data,
    output reg [31:0] wb_pc_plus4,
    output reg [4:0] wb_rd,
    // CONTROL OUTPUTS
    output reg wb_reg_write,
    output reg [1:0] wb_wb_sel
);
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        wb_alu_result <= 32'b0;
        wb_mem_data <= 32'b0;
        wb_pc_plus4 <= 32'b0;
        wb_rd <= 5'b0;
        wb_reg_write <= 1'b0;
        wb_wb_sel <= 2'b0;
    end
    else if(enable)
    begin
        wb_alu_result <= mem_alu_result;
        wb_mem_data <= mem_data;
        wb_pc_plus4 <= mem_pc_plus4;
        wb_rd <= mem_rd;
        wb_reg_write <= mem_reg_write;
        wb_wb_sel <= mem_wb_sel;
    end
end
endmodule