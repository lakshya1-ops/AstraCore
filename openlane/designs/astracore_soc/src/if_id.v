module if_id(
    input clk,
    input reset,
    input [31:0] pc_current,
    input [31:0] pc_plus4,
    input [31:0]instruction,
    input flush,

    output reg[31:0] id_pc_current,
    output reg[31:0] id_pc_plus4,
    output reg[31:0] id_instruction,
    input enable//for hazard detection
);
always @(posedge clk or posedge reset)
begin
    if(reset)
    begin
        id_pc_current<=32'b0;
        id_pc_plus4<=32'b0;
        id_instruction<=32'b0;
    end
    else if(flush)
begin
    id_pc_current <= 32'b0;
    id_pc_plus4 <= 32'b0;
    id_instruction <= 32'b0;
end
    else if(enable)
    begin
        id_pc_current<=pc_current;
        id_pc_plus4<=pc_plus4;
        id_instruction<=instruction;
    end

end
endmodule