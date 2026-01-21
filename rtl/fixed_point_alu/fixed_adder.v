`include "fixed_utils.v"

module fixed_adder (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire sub,              // 1=subtract, 0=add
    output wire [31:0] result,
    output wire overflow
);
    wire [31:0] b_effective;
    wire [32:0] sum_extended;
    
    // Two's complement for subtraction
    assign b_effective = sub ? -b : b;
    
    // 33-bit addition to detect overflow
    assign sum_extended = {a[31], a} + {b_effective[31], b_effective};
    
    assign result = sum_extended[31:0];
    
    // Overflow: sign bits of inputs match but result differs
    assign overflow = (a[31] == b_effective[31]) && 
                     (result[31] != a[31]);
endmodule