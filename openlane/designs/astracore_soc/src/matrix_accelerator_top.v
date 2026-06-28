// matrix_accelerator_top.v

`include "accelerator_pkg.vh"

module matrix_accelerator_top #(
    parameter MATRIX_DIM = `MATRIX_DIM,
    parameter DATA_WIDTH = `DATA_WIDTH,
    parameter ACC_WIDTH  = `ACC_WIDTH
)(
    input clk,
    input rst,

    // AXI-lite ports
    input [31:0] AWADDR,
    input AWVALID,
    output AWREADY,

    input [31:0] WDATA,
    input WVALID,
    output WREADY,

    output[1:0] BRESP,
    output BVALID,
    input BREADY,

    input[31:0] ARADDR,
    input ARVALID,
    output ARREADY,

    output [31:0]   RDATA,
    output RVALID,
    input RREADY,
    output [1:0] RRESP
);

    // INTERNAL WIRES — scalar signals unchanged
    wire reg_wr_en;
    wire [7:0] reg_wr_addr;
    wire [31:0] reg_wr_data;
    wire [7:0] reg_rd_addr;
    wire [31:0] reg_rd_data;

    wire cpu_wr_en;
    wire cpu_sel_a;
    wire [`BUF_ADDR_WIDTH-1:0] cpu_wr_addr;
    wire [DATA_WIDTH-1:0] cpu_wr_data;

    wire [`BUF_ADDR_WIDTH-1:0] cpu_rd_addr;
    wire [ACC_WIDTH-1:0] cpu_rd_data;

    wire start_pulse;
    wire [7:0] dim_reg;
    wire fsm_busy;
    wire fsm_done;
    wire valid_in;
    wire clear;
    wire [`BUF_ADDR_WIDTH-1:0] k_out;
    wire accel_wr_en;

   // FLAT PACKED WIRES — between address_generator, matrix_buffer, mac_array
    wire [MATRIX_DIM*`BUF_ADDR_WIDTH-1:0] a_addr_flat;
    wire [MATRIX_DIM*`BUF_ADDR_WIDTH-1:0] b_addr_flat;
    wire [MATRIX_DIM*MATRIX_DIM*`BUF_ADDR_WIDTH-1:0]   c_addr_flat;

    wire [MATRIX_DIM*DATA_WIDTH-1:0] accel_a_data_flat;
    wire [MATRIX_DIM*DATA_WIDTH-1:0] accel_b_data_flat;

    wire [MATRIX_DIM*MATRIX_DIM*ACC_WIDTH-1:0] c_out_flat;

   // AXI ACCEL SLAVE
    axi_accel_slave #(
        .MATRIX_DIM(MATRIX_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
    ) u_axi_slave (
        .clk (clk),
        .rst (rst),
        .AWADDR (AWADDR),
        .AWVALID (AWVALID),
        .AWREADY (AWREADY),
        .WDATA (WDATA),
        .WVALID (WVALID),
        .WREADY (WREADY),
        .BRESP (BRESP),
        .BVALID (BVALID),
        .BREADY (BREADY),
        .ARADDR (ARADDR),
        .ARVALID (ARVALID),
        .ARREADY (ARREADY),
        .RDATA (RDATA),
        .RVALID (RVALID),
        .RREADY (RREADY),
        .RRESP (RRESP),
        .reg_wr_en (reg_wr_en),
        .reg_wr_addr(reg_wr_addr),
        .reg_wr_data(reg_wr_data),
        .reg_rd_addr(reg_rd_addr),
        .reg_rd_data(reg_rd_data),
        .cpu_wr_en (cpu_wr_en),
        .cpu_sel_a (cpu_sel_a),
        .cpu_wr_addr(cpu_wr_addr),
        .cpu_wr_data(cpu_wr_data),
        .cpu_rd_addr(cpu_rd_addr),
        .cpu_rd_data(cpu_rd_data)
    );

    // REGISTER BANK
   accel_regbank u_regbank (
        .clk (clk),
        .rst (rst),
        .reg_wr_en (reg_wr_en),
        .reg_wr_addr(reg_wr_addr),
        .reg_wr_data(reg_wr_data),
        .reg_rd_addr(reg_rd_addr),
        .reg_rd_data(reg_rd_data),
        .start_pulse(start_pulse),
        .dim_reg (dim_reg),
        .fsm_busy (fsm_busy),
        .fsm_done (fsm_done)
    );

   // FSM
   accelerator_fsm #(
        .MATRIX_DIM(MATRIX_DIM)
    ) u_fsm (
        .clk (clk),
        .rst (rst),
        .start_pulse(start_pulse),
        .dim_reg (dim_reg),
        .fsm_busy (fsm_busy),
        .fsm_done (fsm_done),
        .valid_in (valid_in),
        .clear (clear),
        .k_out (k_out),
        .accel_wr_en(accel_wr_en)
    );

    // ADDRESS GENERATOR — flat outputs
    address_generator #(
        .MATRIX_DIM(MATRIX_DIM),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_addr_gen (
        .k_in (k_out),
        .a_addr_flat(a_addr_flat),
        .b_addr_flat(b_addr_flat),
        .c_addr_flat(c_addr_flat)
    );
     // MATRIX BUFFER — flat ports
    matrix_buffer #(
        .MATRIX_DIM(MATRIX_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
    ) u_buffer (
        .clk (clk),
        .rst (rst),
        .cpu_wr_en (cpu_wr_en),
        .cpu_sel_a (cpu_sel_a),
        .cpu_wr_addr (cpu_wr_addr),
        .cpu_wr_data (cpu_wr_data),
        .cpu_rd_addr (cpu_rd_addr),
        .cpu_rd_data (cpu_rd_data),
        .accel_a_addr_flat(a_addr_flat),
        .accel_b_addr_flat(b_addr_flat),
        .accel_a_data_flat(accel_a_data_flat),
        .accel_b_data_flat(accel_b_data_flat),
        .accel_wr_en (accel_wr_en),
        .accel_c_addr_flat(c_addr_flat),
        .accel_c_data_flat(c_out_flat)
    );

    // MAC ARRAY — flat ports
    mac_array #(
        .MATRIX_DIM(MATRIX_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
    ) u_mac_array (
        .clk (clk),
        .rst (rst),
        .valid_in  (valid_in),
        .clear (clear),
        .a_in_flat (accel_a_data_flat),
        .b_in_flat (accel_b_data_flat),
        .c_out_flat(c_out_flat)
    );

endmodule