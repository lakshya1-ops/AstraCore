// accelerator_fsm.v
// Timing for 4x4 matrix:
//   1 cycle  CLEAR
//   4 cycles COMPUTE (k=0,1,2,3)
//   1 cycle  WRITEBACK
//   1 cycle  DONE assertion
//   → START to DONE assertion = 6 cycles
`include "accelerator_pkg.vh"
module accelerator_fsm #(
    parameter MATRIX_DIM = `MATRIX_DIM
)(
    input clk,
    input rst,

    // From regbank
    input start_pulse,
    input [7:0] dim_reg,

    // To regbank — combinational outputs
    output reg fsm_busy,
    output reg fsm_done,

    // To MAC array — combinational outputs
    output reg valid_in,
    output reg clear,

    // To address generator — wire from k_counter
    output [`BUF_ADDR_WIDTH-1:0] k_out,

    // To matrix buffer — combinational output
    output reg accel_wr_en
);

  // FSM STATE ENCODING
    localparam IDLE      = 3'd0;
    localparam CLEAR     = 3'd1;
    localparam COMPUTE   = 3'd2;
    localparam WRITEBACK = 3'd3;
    localparam DONE      = 3'd4;

    reg [2:0] state, next_state;

    // K COUNTER — only registered signal besides state
    reg [`BUF_ADDR_WIDTH-1:0] k_counter;

    // k_out is a wire — direct combinational connection to k_counter
    assign k_out = k_counter;

    // STATE REGISTER — clocked
    always @(posedge clk) begin
        if(rst)
            state <= IDLE;
        else
            state <= next_state;
    end

   // K COUNTER — clocked
    always @(posedge clk) begin
        if(rst)
            k_counter <= 0;
        else begin
            case(state)
                CLEAR   : k_counter <= 0;
                COMPUTE : begin
                    if(k_counter < dim_reg - 1)
                        k_counter <= k_counter + 1;
                end
                default : k_counter <= 0;
            endcase
        end
    end
 // NEXT STATE LOGIC — combinational
    always @(*) begin
        next_state = state;

        case(state)
            IDLE : begin
                if(start_pulse)
                    next_state = CLEAR;
            end

            CLEAR : begin
                next_state = COMPUTE;
            end

            COMPUTE : begin
                if(k_counter == dim_reg - 1)
                    next_state = WRITEBACK;
            end

            WRITEBACK : begin
                next_state = DONE;
            end

            DONE : begin
                if(start_pulse)
                    next_state = CLEAR;
            end

            default : next_state = IDLE;
        endcase
    end

   always @(*) begin
        // default all outputs low
        fsm_busy    = 1'b0;
        fsm_done    = 1'b0;
        valid_in    = 1'b0;
        clear       = 1'b0;
        accel_wr_en = 1'b0;

        case(state)
            IDLE : begin
                fsm_busy = 1'b0;
                fsm_done = 1'b0;
            end

            CLEAR : begin
                fsm_busy = 1'b1;
                clear    = 1'b1;
            end

            COMPUTE : begin
                fsm_busy = 1'b1;
                valid_in = 1'b1;
            end

            WRITEBACK : begin
                fsm_busy    = 1'b1;
                accel_wr_en = 1'b1;
            end

            DONE : begin
                fsm_done = 1'b1;
            end
        endcase
    end

endmodule