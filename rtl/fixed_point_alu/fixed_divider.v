
`include "fixed_utils.v"

module fixed_divider (
    input wire [31:0] a,              // Q16.16 dividend
    input wire [31:0] b,              // Q16.16 divisor
    output wire [31:0] quotient,      // Q16.16 result
    output wire [31:0] remainder,     // Q16.16 remainder
    output wire div_by_zero
);

    wire signed [63:0] a_extended;
    wire signed [63:0] quotient_temp;
    wire signed [63:0] remainder_temp;
    
    // Check for division by zero
    assign div_by_zero = (b == 32'h0);
    
    // Shift dividend left by 16 to maintain Q16.16 format
    assign a_extended = {a, 16'h0};
    
    // Perform division (if not divide by zero)
    assign quotient_temp = div_by_zero ? 64'h0 : (a_extended / $signed(b));
    assign remainder_temp = div_by_zero ? 64'h0 : (a_extended % $signed(b));
    
    assign quotient = quotient_temp[31:0];
    assign remainder = remainder_temp[31:0];

endmodule