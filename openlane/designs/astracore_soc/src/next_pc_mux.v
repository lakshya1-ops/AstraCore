module next_pc_mux(
    input[31:0] pc_plus4,
    input[31:0] branch_target,
    input[31:0] jal_target,
    input[31:0] jalr_target,
    input branch,
    input branch_taken,
    input jump,
    input jalr,
    output reg[31:0] next_pc//nothing but output of pc next
);

always @(*)
begin
    //jalr
    if(jalr)
    next_pc={jalr_target[31:1],1'b0};

    //jal
    else if(jump)
    next_pc=jal_target;

    //branch
    else if(branch && branch_taken)
    next_pc=branch_target;

    else
    next_pc=pc_plus4;
end
endmodule