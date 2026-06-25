`ifndef ACCELERATOR_PKG_VH
`define ACCELERATOR_PKG_VH

// DATA PARAMETERS
`define DATA_WIDTH   8
`define ACC_WIDTH    32

// MATRIX PARAMETERS
`define MATRIX_DIM   4
`define NUM_ELEMENTS (`MATRIX_DIM * `MATRIX_DIM)

// AXI ADDRESS MAP
`define ACCEL_BASE        32'h10000300
`define REG_CONTROL       8'h00
`define REG_STATUS        8'h04
`define REG_DIM           8'h08
`define REG_A_BASE        8'h0C
`define REG_B_BASE        8'h4C
`define REG_C_BASE        8'h8C

// CONTROL REGISTER BITS
`define CTRL_START_BIT    0
`define CTRL_RESET_BIT    1

// STATUS REGISTER BITS
`define STATUS_BUSY_BIT   0
`define STATUS_DONE_BIT   1

// FSM STATES
`define FSM_IDLE          3'd0
`define FSM_LOAD          3'd1
`define FSM_COMPUTE       3'd2
`define FSM_DONE          3'd3
`define FSM_CLEAR         3'd4

// TIMING
`define PIPELINE_DEPTH    2

// BUFFER SIZING — FIX: 4 bits for 4x4 matrix (16 elements, addr 0-15)
`define BUF_DEPTH         (`MATRIX_DIM * `MATRIX_DIM)
`define BUF_ADDR_WIDTH    4     // FIX: was 8, now 4 — correct for 4x4

// AXI RESPONSE CODES
`define RESP_OKAY         2'b00
`define RESP_SLVERR       2'b10

`endif