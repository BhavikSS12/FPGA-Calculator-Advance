
`include "fixed_utils.v"

module fixed_multiplier (
    input wire [31:0] a,         // Q16.16
    input wire [31:0] b,         // Q16.16
    output wire [31:0] result,   // Q16.16
    output wire overflow
);

    // 32x32 = 64-bit multiplication
    wire signed [63:0] product;
    
    assign product = $signed(a) * $signed(b);
    
    // Extract Q16.16 result (shift right by 16 to align decimal point)
    // product[47:16] gives us the Q16.16 result
    assign result = product[47:16];
    
    // Overflow detection: check if upper bits are not sign extension
    assign overflow = (product[63:48] != {16{product[47]}});

endmodule