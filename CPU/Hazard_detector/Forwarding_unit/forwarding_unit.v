module forwarding_unit(
    input [4:0] ex_rs1,//curret operaand 1 instruction
    input [4:0] ex_rs2,///current operand 2 instruction

    input[4:0] mem_rd,// prev instruction,currently in mem stage,,in thich rd of mem do we write instruction
    input mem_reg_write,//do we evven write instruction in mem here?
    
    input [4:0] wb_rd,//in which reg to write back?
    input wb_reg_write,//do we even write back to reg here?

    output reg [1:0] forward_a,//what to forward 
    output reg [1:0] forward_b
);
always @(*)
begin
    //default
    forward_a = 2'b00;
    forward_b = 2'b00;

    //ex hazard
    if((mem_reg_write) && (mem_rd!=5'b0) &&  (mem_rd == ex_rs1))
    begin
        forward_a = 2'b10; //control signal
    end

    if((mem_reg_write) && (mem_rd!=5'b0) &&  (mem_rd == ex_rs2))
    begin
        forward_b = 2'b10; //control signal
    end

    //mem hazard
    if(wb_reg_write && (wb_rd!=5'b0) &&  !(mem_reg_write&&(mem_rd != 5'b0) && (mem_rd == ex_rs1)) && (wb_rd == ex_rs1))
    begin
        forward_a = 2'b01;
    end

    if(wb_reg_write && (wb_rd!=5'b0) && !(mem_reg_write && (mem_rd!=5'b0) && (mem_rd==ex_rs2)) && (wb_rd==ex_rs2))
    begin
        forward_b = 2'b01;
    end
end
endmodule