// accel_regbank.v
// Register Map:
//   0x00 — CONTROL : START bit (write only, reads 0)
//   0x04 — STATUS  : BUSY bit[0], DONE bit[1]
//   0x08 — DIM     : read-only, always returns MATRIX_DIM

`include "accelerator_pkg.vh"

module accel_regbank(
    input           clk,
    input           rst,

    // AXI slave interface
    input           reg_wr_en,
    input  [7:0]    reg_wr_addr,
    input  [31:0]   reg_wr_data,
    input  [7:0]    reg_rd_addr,
    output reg [31:0] reg_rd_data,

    // FSM interface
    output reg      start_pulse,
    output [7:0]    dim_reg,           // always MATRIX_DIM
    input           fsm_busy,
    input           fsm_done
);
// STATUS REGISTER
    reg [31:0] status_reg;

    always @(posedge clk) begin
        if(rst)
            status_reg <= 32'h0;
        else begin
            status_reg[`STATUS_BUSY_BIT] <= fsm_busy;
            status_reg[`STATUS_DONE_BIT] <= fsm_done;
        end
    end

   // START PULSE
   always @(posedge clk) begin
        if(rst)
            start_pulse <= 1'b0;
        else
            start_pulse <= reg_wr_en &&
                           (reg_wr_addr == `REG_CONTROL) &&
                           reg_wr_data[`CTRL_START_BIT];
    end

    // DIM — read only constant (FIX 2)
    // Hardware is always 4x4 — no runtime reconfiguration
    assign dim_reg = `MATRIX_DIM;

    // REGISTER READ — combinational
    always @(*) begin
        case(reg_rd_addr)
            `REG_CONTROL : reg_rd_data = 32'h0;
            `REG_STATUS  : reg_rd_data = status_reg;
            `REG_DIM     : reg_rd_data = `MATRIX_DIM;  // always 4
            default      : reg_rd_data = 32'hDEADBEEF;
        endcase
    end

endmodule