// carry_save_adder.v
//not stand alone but especially designed for wallce tree mulitplier

//a2 b2 c2 -> sum2 carry2
//a3 b3 c3 -> sum3 carry3
//No connection between columns.

`include "accelerator_pkg.vh"

// HALF ADDER
module half_adder(
    input  a,       
    input  b,       
    output sum,     
    output carry
);
    assign sum   = a ^ b;    
    assign carry = a & b;     
endmodule

// FULL ADDER
module full_adder(
    input  a,           
    input  b,           
    input  cin,        
    output sum,         
    output cout         
);
    assign sum  = a ^ b ^ cin;              
    assign cout = (a & b)|(b & cin)|(a & cin); 
endmodule

// CARRY SAVE ADDER — WIDTH bits wide
module carry_save_adder #(
    parameter WIDTH = `DATA_WIDTH       
)(
    input  [WIDTH-1:0] a,               
    input  [WIDTH-1:0] b,               
    input  [WIDTH-1:0] c,    
    output [WIDTH-1:0] sum,          
    output [WIDTH-1:0] carry            
);

       genvar i;
    generate
        for(i = 0; i < WIDTH; i = i+1) begin : csa_bit
            full_adder fa(
                .a   (a[i]),        
                .b   (b[i]),        
                .cin (c[i]),        
                .sum (sum[i]),      
                .cout(carry[i])     
            );
        end
    endgenerate

endmodule