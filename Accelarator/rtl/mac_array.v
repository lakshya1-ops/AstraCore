// mac_array.v

// Instantiates MATRIX_DIM x MATRIX_DIM processing elements.
// All PEs run in parallel — this is the speedup engine.
//
// For MATRIX_DIM=4:
//   16 PEs instantiated
//   PE[i][j] computes C[i][j] = dot(A_row_i, B_col_j)
//
// Data inputs:
//   a_row[i] — one element from row i of matrix A
//   b_col[j] — one element from col j of matrix B
//
// Each cycle during COMPUTE:
//   FSM presents a_row[i][k] and b_col[j][k] to PE[i][j]
//   PE[i][j] accumulates a[i][k] * b[k][j]
//   After MATRIX_DIM cycles — PE[i][j] holds C[i][j]
`include "accelerator_pkg.vh"

module mac_array #(
    parameter MATRIX_DIM = `MATRIX_DIM,     // N — default 4
    parameter DATA_WIDTH = `DATA_WIDTH,     // 8
    parameter ACC_WIDTH  = `ACC_WIDTH       // 32
)(
    input clk,
    input rst,

    // Control from FSM
    input  valid_in,   // do MAC this cycle
    input clear,      // reset all PEs

    // Matrix A inputs — one element per row per cycle
    // a_in[i] = A[i][k] for current k
    input  signed [DATA_WIDTH-1:0]  a_in [0:MATRIX_DIM-1],

    // Matrix B inputs — one element per column per cycle
    // b_in[j] = B[k][j] for current k
    input  signed [DATA_WIDTH-1:0] b_in [0:MATRIX_DIM-1],

    // Result matrix C — all elements available after computation
    // c_out[i][j] = C[i][j] = dot(A_row_i, B_col_j)
    output signed [ACC_WIDTH-1:0] c_out [0:MATRIX_DIM-1][0:MATRIX_DIM-1]
);

    genvar i, j;
    generate
        for(i = 0; i < MATRIX_DIM; i = i+1) begin : row
            for(j = 0; j < MATRIX_DIM; j = j+1) begin : col
                processing_element #(
                    .DATA_WIDTH(DATA_WIDTH),.ACC_WIDTH (ACC_WIDTH)) pe (
                    .clk     (clk),
                    .rst     (rst),
                    .valid_in(valid_in),        
                    .clear   (clear),           
                    .a       (a_in[i]),         // row i of A
                    .b       (b_in[j]),         // col j of B
                    .acc_out (c_out[i][j])      // result element C[i][j]
                );
            end
        end
    endgenerate

endmodule