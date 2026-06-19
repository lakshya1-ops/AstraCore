//=============================================================================
// mac_unit.v
// AstraCore Matrix Accelerator — Multiply Accumulate Unit
// Author : Lakshya Chowdhury
// Project: AstraCore RISC-V SoC
//
// Single MAC unit:
//   Combinational : wallace_multiplier + cla_adder
//   Registered    : accumulator flip flop
//
// Latency: 1 cycle
//   Cycle N  : a,b presented, product computed, added to acc
//   Cycle N+1: acc_out holds new accumulated value
//
// clear  : synchronous reset of accumulator (between dot products)
// enable : gate accumulation (hold when low)
//=============================================================================

`include "accelerator_pkg.vh"

module mac_unit #(
    parameter DATA_WIDTH = `DATA_WIDTH,
    parameter ACC_WIDTH  = `ACC_WIDTH
)(
    input clk,
    input rst,
    input enable,
    input clear,
    input  signed [DATA_WIDTH-1:0] a,
    input  signed [DATA_WIDTH-1:0] b,
    output reg signed [ACC_WIDTH-1:0] acc_out     // CHANGE 1: signed
);

    //-------------------------------------------------------------------------
    // STAGE 1 — MULTIPLICATION (combinational)
    //-------------------------------------------------------------------------
    wire signed [2*DATA_WIDTH-1:0] product;

    wallace_multiplier #(.WIDTH(DATA_WIDTH)) multiplier (
        .a(a),
        .b(b),
        .product(product)
    );

    //-------------------------------------------------------------------------
    // STAGE 2 — SIGN EXTENSION (combinational)
    //-------------------------------------------------------------------------
    wire signed [ACC_WIDTH-1:0] product_extended;   // CHANGE 2: signed

    assign product_extended = {{(ACC_WIDTH-2*DATA_WIDTH){product[2*DATA_WIDTH-1]}},
                                product};

    //-------------------------------------------------------------------------
    // STAGE 3 — ACCUMULATION USING CLA (combinational)
    //-------------------------------------------------------------------------
    wire signed [ACC_WIDTH-1:0] acc_next;

    cla_adder #(.WIDTH(ACC_WIDTH)) acc_adder (
        .a(acc_out),
        .b(product_extended),
        .cin(1'b0),
        .sum(acc_next),
        .cout()                 // CHANGE 3: unconnected — cout meaningless for signed
    );

    //-------------------------------------------------------------------------
    // ACCUMULATOR REGISTER
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if(rst)
            acc_out <= {ACC_WIDTH{1'b0}};
        else if(clear)
            acc_out <= {ACC_WIDTH{1'b0}};
        else if(enable)
            acc_out <= acc_next;
    end

endmodule