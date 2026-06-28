/// Simple MAC wrapper. No control logic inside.
// FSM handles all timing and done generation.
// One PE computes one element of output matrix C.
// PE[i][j] computes C[i][j] = dot(A_row_i, B_col_j)
`include "accelerator_pkg.vh"

module processing_element #(
    parameter DATA_WIDTH = `DATA_WIDTH,
    parameter ACC_WIDTH  = `ACC_WIDTH
)(
    input clk,
    input rst, 
    input valid_in,   // enable MAC this cycle
    input clear,      // reset accumulator
    input  signed [DATA_WIDTH-1:0]  a,          // element from matrix A row
    input  signed [DATA_WIDTH-1:0]  b,          // element from matrix B col
    output signed [ACC_WIDTH-1:0]   acc_out     // accumulated result
);

    mac_unit #(.DATA_WIDTH(DATA_WIDTH),.ACC_WIDTH(ACC_WIDTH)) mac (
        .clk(clk),
        .rst(rst),
        .enable(valid_in),
        .clear(clear),
        .a(a),
        .b(b),
        .acc_out(acc_out)
    );

endmodule