module writeback_mux(
    input [31:0] alu_result,
    input [31:0] mem_data,
    input [31:0] pc_plus4,
    input [1:0] wb_sel,
    output reg [31:0] writeback_data
);
always @(*)
begin
    case(wb_sel)
    //alu result
    2'b00:writeback_data=alu_result;
    //mem data
    2'b01:writeback_data=mem_data;
    //pc_plus4
    2'b10:writeback_data=pc_plus4;

    default:writeback_data=32'b0;
    endcase
end
endmodule
