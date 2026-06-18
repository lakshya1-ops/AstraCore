//=============================================================================
// wallace_multiplier.v
// AstraCore Matrix Accelerator — Wallace Tree Multiplier
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
//   Partial products: 8 rows of TREE_WIDTH bits
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
    localparam PP_WIDTH   = 2 * WIDTH;          // 16 for WIDTH=8
    localparam TREE_WIDTH = PP_WIDTH + 5;        // 21 — prevents MSB loss

    //-------------------------------------------------------------------------
    // STAGE 1 — SIGN EXTRACTION AND MAGNITUDE CONVERSION
    //
    // For two's complement:
    //   if MSB=1 → negative → magnitude = ~x + 1 (negate)
    //   if MSB=0 → positive → magnitude = x
    //
    // Final sign = a_sign XOR b_sign
    // negative × negative = positive
    // positive × negative = negative
    // negative × positive = negative
    // positive × positive = positive
    //-------------------------------------------------------------------------
    wire                  a_sign, b_sign, prod_sign;
    wire [WIDTH-1:0]      a_mag,  b_mag;

    assign a_sign    = a[WIDTH-1];              // MSB = sign bit
    assign b_sign    = b[WIDTH-1];
    assign prod_sign = a_sign ^ b_sign;         // XOR gives output sign

    // Convert to unsigned magnitude
    // if negative: magnitude = two's complement negate = ~x + 1
    // if positive: magnitude = x as is
    assign a_mag = a_sign ? (~a + 1'b1) : a;
    assign b_mag = b_sign ? (~b + 1'b1) : b;

    //-------------------------------------------------------------------------
    // STAGE 2 — UNSIGNED PARTIAL PRODUCT GENERATION
    //
    // Standard unsigned shift-and-add:
    // pp[i] = b_mag[i] ? (a_mag << i) : 0
    //
    // Each pp[i] is TREE_WIDTH bits wide (zero extended)
    // No sign handling needed — magnitudes are always positive
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
    //
    // Reduces 8 partial product rows to 2 using CSA levels:
    //
    // Level 1: (pp0, pp1, pp2) → (s10, c10)     8 → 6
    //          (pp3, pp4, pp5) → (s11, c11)
    //          pp6, pp7 pass through
    //
    // Level 2: (s10, c10<<1, pp6) → (s20, c20)  6 → 4
    //          (s11, c11<<1, pp7) → (s21, c21)
    //
    // Level 3: (s20, c20<<1, s21) → (s30, c30)  4 → 3
    //          c21 passes through
    //
    // Level 4: (s30, c30<<1, c21<<1) → (s40,c40) 3 → 2
    //
    // Final  : CLA(s40, c40<<1) → unsigned_product
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
    // c21 passes through to level 4

    //--- Level 4 ---
    carry_save_adder #(.WIDTH(TREE_WIDTH)) csa_l4_0(
        .a(s30), .b(c30 << 1), .c(c21 << 1),
        .sum(s40),  .carry(c40)
    );

    //-------------------------------------------------------------------------
    // STAGE 4 — FINAL CLA ADDITION
    // Adds last two rows to get unsigned magnitude of product
    //-------------------------------------------------------------------------
    wire [TREE_WIDTH-1:0] cla_sum;
    wire                  cla_cout;

    cla_adder #(.WIDTH(TREE_WIDTH)) final_adder(
        .a   (s40),
        .b   (c40 << 1),
        .cin (1'b0),
        .sum (cla_sum),
        .cout(cla_cout)
    );

    // unsigned magnitude result — truncate to PP_WIDTH
    wire [PP_WIDTH-1:0] unsigned_product;
    assign unsigned_product = cla_sum[PP_WIDTH-1:0];

    //-------------------------------------------------------------------------
    // STAGE 5 — SIGN CORRECTION
    //
    // if prod_sign=0 → result positive → output = unsigned_product
    // if prod_sign=1 → result negative → output = -unsigned_product
    //                                           = ~unsigned_product + 1
    //
    // Special case: -128 × -128 = 16384
    // unsigned_product = 16384 = 16'h4000
    // prod_sign = 1 ^ 1 = 0 → positive → correct
    //
    // Special case: -128 × 1 = -128
    // unsigned_product = 128 = 16'h0080
    // prod_sign = 1 ^ 0 = 1 → negate → -128 → correct
    //-------------------------------------------------------------------------
    assign product = prod_sign ?
                 -$signed(unsigned_product) :
                  $signed(unsigned_product);

endmodule