
`ifndef FP_UTILS_V
`define FP_UTILS_V

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

`define FP_IS_GREATER(a, b) \
    ((`FP_SIGN(a) == 0 && `FP_SIGN(b) == 1) || \
     (`FP_SIGN(a) == `FP_SIGN(b) && \
     ((`FP_EXP(a) > `FP_EXP(b)) || \
     ((`FP_EXP(a) == `FP_EXP(b)) && (`FP_MANT(a) > `FP_MANT(b))))))

`endif