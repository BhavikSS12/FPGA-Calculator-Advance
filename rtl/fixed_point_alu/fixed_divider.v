`include "fixed_utils.v"

module fixed_divider (
    input wire [31:0] a,              // Q18.14 dividend
    input wire [31:0] b,              // Q18.14 divisor
    output wire [31:0] quotient,      // Q18.14 result
    output wire [31:0] remainder,     // Q18.14 remainder
    output wire div_by_zero
);
    wire signed [63:0] a_extended;
    wire signed [63:0] quotient_temp;
    wire signed [63:0] remainder_temp;
    
    // Check for division by zero
    assign div_by_zero = (b == 32'h0);
    
    // Shift dividend left by 14 bits to maintain Q18.14 format
    assign a_extended = {a, 14'h0};
    
    // Perform division (if not divide by zero)
    assign quotient_temp = div_by_zero ? 64'h0 : (a_extended / $signed(b));
    assign remainder_temp = div_by_zero ? 64'h0 : (a_extended % $signed(b));
    
    assign quotient = quotient_temp[31:0];
    assign remainder = remainder_temp[31:0];
endmodule