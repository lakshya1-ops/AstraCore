// address_generator.v
// Generates read addresses for matrix_buffer during COMPUTE state.
// For matrix multiply C = A × B, 4×4:
//   Each cycle k (k=0 to N-1):
//     A addresses: A[0][k], A[1][k], A[2][k], A[3][k]  (one per row)
//     B addresses: B[k][0], B[k][1], B[k][2], B[k][3]  (one per col)

// Row-major addressing:
//   A[i][k] → addr = i*MATRIX_DIM + k
//   B[k][j] → addr = k*MATRIX_DIM + j

`include "accelerator_pkg.vh"

module address_generator #(
    parameter MATRIX_DIM = `MATRIX_DIM,
    parameter DATA_WIDTH = `DATA_WIDTH
)(
    // Current dot product index from FSM
    // k=0 to MATRIX_DIM-1 during COMPUTE state
    input  [`BUF_ADDR_WIDTH-1:0] k_in,

    // Row addresses for matrix A
    // a_addr[i] = address of A[i][k] in buf_a
    output [`BUF_ADDR_WIDTH-1:0] a_addr [0:MATRIX_DIM-1],

    // Column addresses for matrix B
    // b_addr[j] = address of B[k][j] in buf_b
    output [`BUF_ADDR_WIDTH-1:0] b_addr [0:MATRIX_DIM-1],

    // Result addresses for matrix C
    // c_addr[i][j] = address of C[i][j] in buf_c
    output [`BUF_ADDR_WIDTH-1:0] c_addr [0:MATRIX_DIM-1][0:MATRIX_DIM-1]
);

    //-------------------------------------------------------------------------
    // A ADDRESSES — one per row
    // A[i][k] in row-major → address = i*MATRIX_DIM + k
    // k changes every cycle — FSM drives k_in
    // i is fixed per output port — generate loop handles all rows
    genvar i, j;
    generate
        for(i = 0; i < MATRIX_DIM; i = i+1) begin : a_addr_gen
            assign a_addr[i] = i * MATRIX_DIM + k_in;
        end
    endgenerate

    // B ADDRESSES — one per column
    // B[k][j] in row-major → address = k*MATRIX_DIM + j
    // k changes every cycle — FSM drives k_in
    // j is fixed per output port — generate loop handles all cols
    generate
        for(j = 0; j < MATRIX_DIM; j = j+1) begin : b_addr_gen
            assign b_addr[j] = k_in * MATRIX_DIM + j;
        end
    endgenerate

    // C ADDRESSES — one per output element
    // C[i][j] in row-major → address = i*MATRIX_DIM + j
    // These are fixed — do not change with k
    // Generated once and held constant throughout computation
    generate
        for(i = 0; i < MATRIX_DIM; i = i+1) begin : c_addr_row
            for(j = 0; j < MATRIX_DIM; j = j+1) begin : c_addr_col
                assign c_addr[i][j] = i * MATRIX_DIM + j;
            end
        end
    endgenerate

endmodule