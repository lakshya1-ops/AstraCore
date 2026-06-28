// matrix_buffer.v
`include "accelerator_pkg.vh"

module matrix_buffer #(
    parameter MATRIX_DIM = `MATRIX_DIM,
    parameter DATA_WIDTH = `DATA_WIDTH,
    parameter ACC_WIDTH  = `ACC_WIDTH
)(
    input clk,
    input rst,

    // CPU write port — A and B
    input cpu_wr_en,
    input cpu_sel_a,
    input  [`BUF_ADDR_WIDTH-1:0] cpu_wr_addr,
    input  [DATA_WIDTH-1:0] cpu_wr_data,

    // CPU read port — C (combinational)
    input  [`BUF_ADDR_WIDTH-1:0] cpu_rd_addr,
    output [ACC_WIDTH-1:0] cpu_rd_data,    // wire — combinational

    // Accelerator read port — A and B (flat packed)
    input  [MATRIX_DIM*`BUF_ADDR_WIDTH-1:0] accel_a_addr_flat,
    input  [MATRIX_DIM*`BUF_ADDR_WIDTH-1:0] accel_b_addr_flat,
    output [MATRIX_DIM*DATA_WIDTH-1:0] accel_a_data_flat,
    output [MATRIX_DIM*DATA_WIDTH-1:0] accel_b_data_flat,
    // Accelerator write port — C (flat packed)
    input accel_wr_en,
    input  [MATRIX_DIM*MATRIX_DIM*`BUF_ADDR_WIDTH-1:0] accel_c_addr_flat,
    input  [MATRIX_DIM*MATRIX_DIM*ACC_WIDTH-1:0] accel_c_data_flat
);

    localparam DEPTH = MATRIX_DIM * MATRIX_DIM;

    // BUFFER DECLARATIONS
    reg [DATA_WIDTH-1:0]    buf_a [0:DEPTH-1];
    reg [DATA_WIDTH-1:0]    buf_b [0:DEPTH-1];
    reg [ACC_WIDTH-1:0]     buf_c [0:DEPTH-1];

    integer wi, wj, idx, idx2;

   // UNPACK flat accelerator read addresses
    wire [`BUF_ADDR_WIDTH-1:0] accel_a_addr [0:MATRIX_DIM-1];
    wire [`BUF_ADDR_WIDTH-1:0] accel_b_addr [0:MATRIX_DIM-1];

    genvar i, j;
    generate
        for(i = 0; i < MATRIX_DIM; i = i+1) begin : unpack_a_addr
            assign accel_a_addr[i] =
                   accel_a_addr_flat[i*`BUF_ADDR_WIDTH +: `BUF_ADDR_WIDTH];
        end
        for(i = 0; i < MATRIX_DIM; i = i+1) begin : unpack_b_addr
            assign accel_b_addr[i] =
                   accel_b_addr_flat[i*`BUF_ADDR_WIDTH +: `BUF_ADDR_WIDTH];
        end
    endgenerate

     // UNPACK flat accelerator write addresses and data
     wire [`BUF_ADDR_WIDTH-1:0] accel_c_addr [0:MATRIX_DIM-1][0:MATRIX_DIM-1];
    wire signed [ACC_WIDTH-1:0] accel_c_data [0:MATRIX_DIM-1][0:MATRIX_DIM-1];

    generate
        for(i = 0; i < MATRIX_DIM; i = i+1) begin : unpack_c_row
            for(j = 0; j < MATRIX_DIM; j = j+1) begin : unpack_c_col
                assign accel_c_addr[i][j] =
                       accel_c_addr_flat[(i*MATRIX_DIM+j)*`BUF_ADDR_WIDTH
                                         +: `BUF_ADDR_WIDTH];
                assign accel_c_data[i][j] =
                       accel_c_data_flat[(i*MATRIX_DIM+j)*ACC_WIDTH
                                         +: ACC_WIDTH];
            end
        end
    endgenerate

   // CPU WRITE — buf_a and buf_b
    always @(posedge clk) begin
        if(rst) begin
            for(idx = 0; idx < DEPTH; idx = idx+1) begin
                buf_a[idx] <= {DATA_WIDTH{1'b0}};
                buf_b[idx] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if(cpu_wr_en) begin
            if(cpu_sel_a)
                buf_a[cpu_wr_addr] <= cpu_wr_data;
            else
                buf_b[cpu_wr_addr] <= cpu_wr_data;
        end
    end

    // ACCELERATOR WRITE — buf_c
    always @(posedge clk) begin
        if(rst) begin
            for(idx2 = 0; idx2 < DEPTH; idx2 = idx2+1)
                buf_c[idx2] <= {ACC_WIDTH{1'b0}};
        end
        else if(accel_wr_en) begin
            for(wi = 0; wi < MATRIX_DIM; wi = wi+1)
                for(wj = 0; wj < MATRIX_DIM; wj = wj+1)
                    buf_c[accel_c_addr[wi][wj]] <= accel_c_data[wi][wj];
        end
    end

    
    // CPU reads C buffer
    assign cpu_rd_data = buf_c[cpu_rd_addr];

    // Accelerator reads A and B — pack into flat output
    generate
        for(i = 0; i < MATRIX_DIM; i = i+1) begin : pack_a_data
            assign accel_a_data_flat[i*DATA_WIDTH +: DATA_WIDTH] =
                   $signed(buf_a[accel_a_addr[i]]);
        end
        for(i = 0; i < MATRIX_DIM; i = i+1) begin : pack_b_data
            assign accel_b_data_flat[i*DATA_WIDTH +: DATA_WIDTH] =
                   $signed(buf_b[accel_b_addr[i]]);
        end
    endgenerate

endmodule