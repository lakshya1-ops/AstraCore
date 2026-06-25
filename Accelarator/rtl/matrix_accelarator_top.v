//=============================================================================
// matrix_accelerator_top.v
// AstraCore Matrix Accelerator — Top Level
// Author : Lakshya Chowdhury
// Project: AstraCore RISC-V SoC
//
// Connects all accelerator blocks:
//   axi_accel_slave   — AXI-lite interface to CPU bus
//   accel_regbank     — control/status registers
//   accelerator_fsm   — sequencing state machine
//   address_generator — generates buffer read addresses
//   matrix_buffer     — stores A, B, C matrices
//   mac_array         — NxN parallel compute engine
//
// This module is instantiated in cpu_axi_top.v as a new AXI slave.
//=============================================================================

`include "axi_defs.vh"
`include "accelerator_pkg.vh"

module matrix_accelerator_top #(
    parameter MATRIX_DIM = `MATRIX_DIM,
    parameter DATA_WIDTH = `DATA_WIDTH,
    parameter ACC_WIDTH  = `ACC_WIDTH
)(
    input           clk,
    input           rst,

    //-------------------------------------------------------------------------
    // AXI-LITE SLAVE PORTS — connects to cpu_axi_top.v bus
    //-------------------------------------------------------------------------
    input  [31:0]   AWADDR,
    input           AWVALID,
    output          AWREADY,

    input  [31:0]   WDATA,
    input           WVALID,
    output          WREADY,

    output [1:0]    BRESP,
    output          BVALID,
    input           BREADY,

    input  [31:0]   ARADDR,
    input           ARVALID,
    output          ARREADY,

    output [31:0]   RDATA,
    output          RVALID,
    input           RREADY,
    output [1:0]    RRESP
);

    //-------------------------------------------------------------------------
    // INTERNAL WIRES — between blocks
    //-------------------------------------------------------------------------

    // axi_accel_slave → accel_regbank
    wire            reg_wr_en;
    wire [7:0]      reg_wr_addr;
    wire [31:0]     reg_wr_data;
    wire [7:0]      reg_rd_addr;
    wire [31:0]     reg_rd_data;

    // axi_accel_slave → matrix_buffer (CPU write)
    wire            cpu_wr_en;
    wire            cpu_sel_a;
    wire [`BUF_ADDR_WIDTH-1:0] cpu_wr_addr;
    wire [DATA_WIDTH-1:0]      cpu_wr_data;

    // axi_accel_slave → matrix_buffer (CPU read)
    wire [`BUF_ADDR_WIDTH-1:0] cpu_rd_addr;
    wire [ACC_WIDTH-1:0]       cpu_rd_data;

    // accel_regbank → accelerator_fsm
    wire            start_pulse;
    wire [7:0]      dim_reg;

    // accelerator_fsm → accel_regbank
    wire            fsm_busy;
    wire            fsm_done;

    // accelerator_fsm → mac_array
    wire            valid_in;
    wire            clear;

    // accelerator_fsm → address_generator
    wire [`BUF_ADDR_WIDTH-1:0] k_out;

    // accelerator_fsm → matrix_buffer
    wire            accel_wr_en;

    // address_generator → matrix_buffer
    wire [`BUF_ADDR_WIDTH-1:0] a_addr [0:MATRIX_DIM-1];
    wire [`BUF_ADDR_WIDTH-1:0] b_addr [0:MATRIX_DIM-1];
    wire [`BUF_ADDR_WIDTH-1:0] c_addr [0:MATRIX_DIM-1][0:MATRIX_DIM-1];

    // matrix_buffer → mac_array
    wire signed [DATA_WIDTH-1:0] accel_a_data [0:MATRIX_DIM-1];
    wire signed [DATA_WIDTH-1:0] accel_b_data [0:MATRIX_DIM-1];

    // mac_array → matrix_buffer
    wire signed [ACC_WIDTH-1:0] c_out [0:MATRIX_DIM-1][0:MATRIX_DIM-1];

    //-------------------------------------------------------------------------
    // AXI ACCEL SLAVE
    //-------------------------------------------------------------------------
    axi_accel_slave #(
        .MATRIX_DIM(MATRIX_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
    ) u_axi_slave (
        .clk        (clk),
        .rst        (rst),
        .AWADDR     (AWADDR),
        .AWVALID    (AWVALID),
        .AWREADY    (AWREADY),
        .WDATA      (WDATA),
        .WVALID     (WVALID),
        .WREADY     (WREADY),
        .BRESP      (BRESP),
        .BVALID     (BVALID),
        .BREADY     (BREADY),
        .ARADDR     (ARADDR),
        .ARVALID    (ARVALID),
        .ARREADY    (ARREADY),
        .RDATA      (RDATA),
        .RVALID     (RVALID),
        .RREADY     (RREADY),
        .RRESP      (RRESP),
        .reg_wr_en  (reg_wr_en),
        .reg_wr_addr(reg_wr_addr),
        .reg_wr_data(reg_wr_data),
        .reg_rd_addr(reg_rd_addr),
        .reg_rd_data(reg_rd_data),
        .cpu_wr_en  (cpu_wr_en),
        .cpu_sel_a  (cpu_sel_a),
        .cpu_wr_addr(cpu_wr_addr),
        .cpu_wr_data(cpu_wr_data),
        .cpu_rd_addr(cpu_rd_addr),
        .cpu_rd_data(cpu_rd_data)
    );

    //-------------------------------------------------------------------------
    // REGISTER BANK
    //-------------------------------------------------------------------------
    accel_regbank u_regbank (
        .clk        (clk),
        .rst        (rst),
        .reg_wr_en  (reg_wr_en),
        .reg_wr_addr(reg_wr_addr),
        .reg_wr_data(reg_wr_data),
        .reg_rd_addr(reg_rd_addr),
        .reg_rd_data(reg_rd_data),
        .start_pulse(start_pulse),
        .dim_reg    (dim_reg),
        .fsm_busy   (fsm_busy),
        .fsm_done   (fsm_done)
    );

    //-------------------------------------------------------------------------
    // FSM
    //-------------------------------------------------------------------------
    accelerator_fsm #(
        .MATRIX_DIM(MATRIX_DIM)
    ) u_fsm (
        .clk        (clk),
        .rst        (rst),
        .start_pulse(start_pulse),
        .dim_reg    (dim_reg),
        .fsm_busy   (fsm_busy),
        .fsm_done   (fsm_done),
        .valid_in   (valid_in),
        .clear      (clear),
        .k_out      (k_out),
        .accel_wr_en(accel_wr_en)
    );

    //-------------------------------------------------------------------------
    // ADDRESS GENERATOR
    //-------------------------------------------------------------------------
    address_generator #(
        .MATRIX_DIM(MATRIX_DIM),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_addr_gen (
        .k_in  (k_out),
        .a_addr(a_addr),
        .b_addr(b_addr),
        .c_addr(c_addr)
    );

    //-------------------------------------------------------------------------
    // MATRIX BUFFER
    //-------------------------------------------------------------------------
    matrix_buffer #(
        .MATRIX_DIM(MATRIX_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
    ) u_buffer (
        .clk          (clk),
        .rst          (rst),
        .cpu_wr_en    (cpu_wr_en),
        .cpu_sel_a    (cpu_sel_a),
        .cpu_wr_addr  (cpu_wr_addr),
        .cpu_wr_data  (cpu_wr_data),
        .cpu_rd_addr  (cpu_rd_addr),
        .cpu_rd_data  (cpu_rd_data),
        .accel_a_addr (a_addr),
        .accel_b_addr (b_addr),
        .accel_a_data (accel_a_data),
        .accel_b_data (accel_b_data),
        .accel_wr_en  (accel_wr_en),
        .accel_c_addr (c_addr),
        .accel_c_data (c_out)
    );

    //-------------------------------------------------------------------------
    // MAC ARRAY
    //-------------------------------------------------------------------------
    mac_array #(
        .MATRIX_DIM(MATRIX_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
    ) u_mac_array (
        .clk     (clk),
        .rst     (rst),
        .valid_in(valid_in),
        .clear   (clear),
        .a_in    (accel_a_data),
        .b_in    (accel_b_data),
        .c_out   (c_out)
    );

endmodule