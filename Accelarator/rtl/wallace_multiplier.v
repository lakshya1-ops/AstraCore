//=============================================================================
// wallace_multiplier.v
// AstraCore Matrix Accelerator — Signed Wallace Tree Multiplier
// Author : Lakshya Chowdhury
// Project: AstraCore RISC-V SoC
//
// Signed multiplication via sign-magnitude separation:
//   Step 1 : Extract sign bits
//   Step 2 : Convert to unsigned magnitudes
//   Step 3 : Unsigned Wallace tree multiplication
//   Step 4 : Correct output sign
//
// For WIDTH=8:
//   Inputs  : two signed   8-bit integers (-128 to +127)
//   Output  : signed      16-bit result
//   Internal: unsigned     8-bit magnitudes into Wallace tree
//   Partial products: 8 rows of TREE_WIDTH=21 bits
//   CLA operates on CLA_WIDTH=24 (padded to multiple of 4)
//=============================================================================

`include "accelerator_pkg.vh"

module wallace_multiplier #(
    parameter WIDTH = `DATA_WIDTH
)(
    input  signed [WIDTH-1:0]   a,
    input  signed [WIDTH-1:0]   b,
    output signed [2*WIDTH-1:0] product
);

    //-------------------------------------------------------------------------
    // LOCAL PARAMETERS
    //-------------------------------------------------------------------------
    localparam PP_WIDTH   = 2 * WIDTH;                      // 16 for WIDTH=8
    localparam TREE_WIDTH = PP_WIDTH + 5;                   // 21 — internal CSA width
    localparam CLA_WIDTH  = ((TREE_WIDTH + 3) / 4) * 4;    // 24 — padded to multiple of 4

    //-------------------------------------------------------------------------
    // STAGE 1 — SIGN EXTRACTION AND MAGNITUDE CONVERSION
    //-------------------------------------------------------------------------
    wire                  a_sign, b_sign, prod_sign;
    wire [WIDTH-1:0]      a_mag,  b_mag;

    assign a_sign    = a[WIDTH-1];
    assign b_sign    = b[WIDTH-1];
    assign prod_sign = a_sign ^ b_sign;

    assign a_mag = a_sign ? (~a + 1'b1) : a;
    assign b_mag = b_sign ? (~b + 1'b1) : b;

    //-------------------------------------------------------------------------
    // STAGE 2 — UNSIGNED PARTIAL PRODUCT GENERATION
    //-------------------------------------------------------------------------
    wire [TREE_WIDTH-1:0] pp [0:WIDTH-1];

    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i+1) begin : pp_gen
            assign pp[i] = b_mag[i] ?
                           ({{(TREE_WIDTH-WIDTH){1'b0}}, a_mag} << i) :
                           {TREE_WIDTH{1'b0}};
        end
    endgenerate

    //-------------------------------------------------------------------------
    // STAGE 3 — WALLACE TREE CSA REDUCTION
    // 8 partial products → 2 values via 4 CSA levels
    //-------------------------------------------------------------------------

    // Level 1
    wire [TREE_WIDTH-1:0] s10, c10, s11, c11;

    // Level 2
    wire [TREE_WIDTH-1:0] s20, c20, s21, c21;

    // Level 3
    wire [TREE_WIDTH-1:0] s30, c30;

    // Level 4
    wire [TREE_WIDTH-1:0] s40, c40;

    //--- Level 1 ---
    carry_save_adder #(.WIDTH(TREE_WIDTH)) csa_l1_0(
        .a(pp[0]), .b(pp[1]), .c(pp[2]),
        .sum(s10),  .carry(c10)
    );
    carry_save_adder #(.WIDTH(TREE_WIDTH)) csa_l1_1(
        .a(pp[3]), .b(pp[4]), .c(pp[5]),
        .sum(s11),  .carry(c11)
    );

    //--- Level 2 ---
    carry_save_adder #(.WIDTH(TREE_WIDTH)) csa_l2_0(
        .a(s10), .b(c10 << 1), .c(pp[6]),
        .sum(s20),  .carry(c20)
    );
    carry_save_adder #(.WIDTH(TREE_WIDTH)) csa_l2_1(
        .a(s11), .b(c11 << 1), .c(pp[7]),
        .sum(s21),  .carry(c21)
    );

    //--- Level 3 ---
    carry_save_adder #(.WIDTH(TREE_WIDTH)) csa_l3_0(
        .a(s20), .b(c20 << 1), .c(s21),
        .sum(s30),  .carry(c30)
    );

    //--- Level 4 ---
    carry_save_adder #(.WIDTH(TREE_WIDTH)) csa_l4_0(
        .a(s30), .b(c30 << 1), .c(c21 << 1),
        .sum(s40),  .carry(c40)
    );

    //-------------------------------------------------------------------------
    // STAGE 4 — FINAL CLA ADDITION
    // Pad TREE_WIDTH=21 to CLA_WIDTH=24 before feeding CLA
    // Take lower PP_WIDTH=16 bits as unsigned product
    //-------------------------------------------------------------------------
    wire [CLA_WIDTH-1:0] cla_a, cla_b, cla_result;
    wire                 cla_cout;

    // Zero pad from TREE_WIDTH to CLA_WIDTH
    assign cla_a = {{(CLA_WIDTH-TREE_WIDTH){1'b0}}, s40};
    assign cla_b = {{(CLA_WIDTH-TREE_WIDTH){1'b0}}, c40 << 1};

    cla_adder #(.WIDTH(CLA_WIDTH)) final_adder(
        .a   (cla_a),
        .b   (cla_b),
        .cin (1'b0),
        .sum (cla_result),
        .cout(cla_cout)
    );

    // Take lower 16 bits — upper bits guaranteed zero for valid INT8 inputs
    wire [PP_WIDTH-1:0] unsigned_product;
    assign unsigned_product = cla_result[PP_WIDTH-1:0];

    //-------------------------------------------------------------------------
    // STAGE 5 — SIGN CORRECTION
    //-------------------------------------------------------------------------
    assign product = prod_sign ?
                     -$signed(unsigned_product) :
                      $signed(unsigned_product);

    // Simulation check
    // synthesis translate_off
    always @(*) begin
        if(cla_cout)
            $display("WARNING: wallace_multiplier overflow");
    end
    // synthesis translate_off

endmodule