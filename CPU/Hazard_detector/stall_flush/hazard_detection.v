module hazard_detection_unit(
    input ex_mem_read,
    input [4:0] ex_rd,
    input [4:0] id_rs1,
    input [4:0] id_rs2,
    output reg stall
);
always @(*)
begin
    stall = 1'b0;
    if(ex_mem_read && (ex_rd != 5'b0) && ((ex_rd == id_rs1) || (ex_rd == id_rs2))) //Does current ID-stage instruction needthe same register that LOAD instruction will produce?
    begin
        stall = 1'b1;
    end
end
endmodule