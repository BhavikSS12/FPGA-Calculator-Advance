`ifndef FIXED_UTILS_V
`define FIXED_UTILS_V

// Fixed-point format: Q18.14 (18 integer bits, 14 fractional bits)
`define FIXED_WIDTH      32
`define FIXED_INT_BITS   18
`define FIXED_FRAC_BITS  14
`define FIXED_POINT_POS  14

// Extract integer and fractional parts
`define FIXED_INT(x)     x[31:14]
`define FIXED_FRAC(x)    x[13:0]

// Useful constants in Q18.14 format
`define FIXED_ZERO       32'h00000000
`define FIXED_ONE        32'h00004000  // 1.0 (1 << 14)
`define FIXED_HALF       32'h00002000  // 0.5 (1 << 13)
`define FIXED_MAX        32'h7FFFFFFF  // Max positive
`define FIXED_MIN        32'h80000000  // Max negative

// Overflow detection
`define FIXED_IS_OVERFLOW(x, y, sum) ((x[31] == y[31]) && (sum[31] != x[31]))

`endif