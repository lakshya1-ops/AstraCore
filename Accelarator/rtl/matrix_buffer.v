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
    input                               cpu_wr_en,
    input                               cpu_sel_a,
    input  [`BUF_ADDR_WIDTH-1:0]        cpu_wr_addr,
    input  [DATA_WIDTH-1:0]             cpu_wr_data,

    // CPU read port — C (combinational)
    input  [`BUF_ADDR_WIDTH-1:0]        cpu_rd_addr,
    output [ACC_WIDTH-1:0]              cpu_rd_data,    // wire — combinational

    // Accelerator read port — A and B (combinational)
    input  [`BUF_ADDR_WIDTH-1:0]        accel_a_addr [0:MATRIX_DIM-1],
    input  [`BUF_ADDR_WIDTH-1:0]        accel_b_addr [0:MATRIX_DIM-1],
    output signed [DATA_WIDTH-1:0]      accel_a_data [0:MATRIX_DIM-1],
    output signed [DATA_WIDTH-1:0]      accel_b_data [0:MATRIX_DIM-1],

    // Accelerator write port — C
    input                               accel_wr_en,
    input  [`BUF_ADDR_WIDTH-1:0]        accel_c_addr [0:MATRIX_DIM-1][0:MATRIX_DIM-1],
    input  signed [ACC_WIDTH-1:0]       accel_c_data [0:MATRIX_DIM-1][0:MATRIX_DIM-1]
);

    localparam DEPTH = MATRIX_DIM * MATRIX_DIM;

    reg [DATA_WIDTH-1:0]    buf_a [0:DEPTH-1];
    reg [DATA_WIDTH-1:0]    buf_b [0:DEPTH-1];
    reg [ACC_WIDTH-1:0]     buf_c [0:DEPTH-1];

    integer wi, wj, idx;

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
            for(idx = 0; idx < DEPTH; idx = idx+1)
                buf_c[idx] <= {ACC_WIDTH{1'b0}};
        end
        else if(accel_wr_en) begin
            for(wi = 0; wi < MATRIX_DIM; wi = wi+1)
                for(wj = 0; wj < MATRIX_DIM; wj = wj+1)
                    buf_c[accel_c_addr[wi][wj]] <= accel_c_data[wi][wj];
        end
    end

    // COMBINATIONAL READS — FIX Bug 2
    
    // CPU reads C buffer — combinational
    assign cpu_rd_data = buf_c[cpu_rd_addr];

    // Accelerator reads A and B — combinational
    genvar i;
    generate
        for(i = 0; i < MATRIX_DIM; i = i+1) begin : a_read
            assign accel_a_data[i] = $signed(buf_a[accel_a_addr[i]]);
        end
        for(i = 0; i < MATRIX_DIM; i = i+1) begin : b_read
            assign accel_b_data[i] = $signed(buf_b[accel_b_addr[i]]);
        end
    endgenerate

endmodule