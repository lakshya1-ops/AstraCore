//=============================================================================
// cla_adder.v
// AstraCore Matrix Accelerator — Block Carry Lookahead Adder
// Author : Lakshya Chowdhury
// Project: AstraCore RISC-V SoC
//
// Architecture: Block/Hierarchical CLA
//   - True carry lookahead WITHIN each 4-bit group (O(1) per group)
//   - Ripple carry BETWEEN groups (O(N/4) total)
//   - Much faster than pure ripple carry (O(N))
//   - Correctly called: Block CLA or Hierarchical CLA
//
// WIDTH must be multiple of 4
// For non-multiple widths, pad externally before calling
//
// Used in:
//   1. wallace_multiplier.v → WIDTH=24 (padded from 21), lower 16 bits taken
//   2. mac_unit.v           → WIDTH=32
//=============================================================================

`include "accelerator_pkg.vh"

//=============================================================================
// 4-BIT CLA GROUP
// True carry lookahead within 4 bits
// All 4 carries computed in parallel from g, p, cin only
//=============================================================================
module cla_group(
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout,
    output       G,
    output       P
);

    wire [3:0] g, p;
    assign g = a & b;
    assign p = a ^ b;

    // True CLA — all carries fully expanded
    // NO carry depends on previous carry — all parallel
    wire c1, c2, c3, c4;

    assign c1 = g[0]
              | (p[0] & cin);

    assign c2 = g[1]
              | (p[1] & g[0])
              | (p[1] & p[0] & cin);

    assign c3 = g[2]
              | (p[2] & g[1])
              | (p[2] & p[1] & g[0])
              | (p[2] & p[1] & p[0] & cin);

    assign c4 = g[3]
              | (p[3] & g[2])
              | (p[3] & p[2] & g[1])
              | (p[3] & p[2] & p[1] & g[0])
              | (p[3] & p[2] & p[1] & p[0] & cin);

    assign sum[0] = p[0] ^ cin;
    assign sum[1] = p[1] ^ c1;
    assign sum[2] = p[2] ^ c2;
    assign sum[3] = p[3] ^ c3;

    assign cout = c4;

    assign G = g[3]
             | (p[3] & g[2])
             | (p[3] & p[2] & g[1])
             | (p[3] & p[2] & p[1] & g[0]);

    assign P = p[3] & p[2] & p[1] & p[0];

endmodule

//=============================================================================
// BLOCK CLA ADDER
// WIDTH must be multiple of 4
// Pad inputs externally if needed
//=============================================================================
module cla_adder #(
    parameter WIDTH = `ACC_WIDTH
)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              cin,
    output [WIDTH-1:0] sum,
    output             cout
);

    localparam GROUPS = WIDTH / 4;

    wire [GROUPS:0] carry;
    assign carry[0] = cin;

    genvar i;
    generate
        for(i = 0; i < GROUPS; i = i+1) begin : cla_groups
            cla_group group_i(
                .a   (a[4*i+3 : 4*i]),
                .b   (b[4*i+3 : 4*i]),
                .cin (carry[i]),
                .sum (sum[4*i+3 : 4*i]),
                .cout(carry[i+1]),
                .G   (),
                .P   ()
            );
        end
    endgenerate

    assign cout = carry[GROUPS];

endmodule