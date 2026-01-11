
`ifndef ALU_DEFINES_V
`define ALU_DEFINES_V

// Operation codes (shared between fixed and floating point)
`define OP_ADD      4'b0000
`define OP_SUB      4'b0001
`define OP_MUL      4'b0010
`define OP_DIV      4'b0011
`define OP_MOD      4'b0100   // Only for fixed-point
`define OP_AND      4'b0101   // Only for fixed-point
`define OP_OR       4'b0110   // Only for fixed-point
`define OP_XOR      4'b0111   // Only for fixed-point
`define OP_SHL      4'b1000   // Shift left
`define OP_SHR      4'b1001   // Shift right
`define OP_ABS      4'b1010
`define OP_NEG      4'b1011
`define OP_CMP      4'b1100
`define OP_MIN      4'b1101
`define OP_MAX      4'b1110
`define OP_SQRT     4'b1111   // Mainly for floating-point

// ALU mode selection
`define MODE_FIXED   1'b0
`define MODE_FLOAT   1'b1

`endif