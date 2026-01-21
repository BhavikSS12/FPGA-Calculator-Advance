`include "fixed_utils.v"

module fixed_multiplier (
    input wire [31:0] a,
    input wire [31:0] b,
    output wire [31:0] result,
    output wire overflow
);
    wire signed [63:0] product;
    wire signed [63:0] product_shifted;
    
    // Multiply two Q18.14 numbers
    assign product = $signed(a) * $signed(b);
    
    // Shift right by 14 bits to maintain Q18.14 format
    assign product_shifted = product >>> 14;
    
    // Check for overflow: if bits [63:31] are not all same as bit [31]
    assign overflow = !(product_shifted[63:31] == {33{product_shifted[31]}});
    
    assign result = product_shifted[31:0];
endmodule