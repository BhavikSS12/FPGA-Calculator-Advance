
`ifndef FP_UTILS_V
`define FP_UTILS_V

// Operation codes
`define OP_ADD    4'b0000
`define OP_SUB    4'b0001
`define OP_MUL    4'b0010
`define OP_DIV    4'b0011
`define OP_SQRT   4'b0100
`define OP_ABS    4'b0101
`define OP_NEG    4'b0110
`define OP_CMP    4'b0111
`define OP_MIN    4'b1000
`define OP_MAX    4'b1001

// IEEE 754 Constants
`define FP_ZERO       32'h00000000
`define FP_ONE        32'h3F800000
`define FP_NEG_ONE    32'hBF800000
`define FP_INF        32'h7F800000
`define FP_NEG_INF    32'hFF800000
`define FP_NAN        32'h7FC00000

// Extract IEEE 754 components
`define FP_SIGN(x)    x[31]
`define FP_EXP(x)     x[30:23]
`define FP_MANT(x)    x[22:0]
`define FP_MANT_FULL(x) {1'b1, x[22:0]}

// Check special values
`define IS_ZERO(x)    ((`FP_EXP(x) == 8'h00) && (`FP_MANT(x) == 23'h0))
`define IS_INF(x)     ((`FP_EXP(x) == 8'hFF) && (`FP_MANT(x) == 23'h0))
`define IS_NAN(x)     ((`FP_EXP(x) == 8'hFF) && (`FP_MANT(x) != 23'h0))

`endif