`include "alu_defines.v"

module calculator_top (
    input wire clk,
    input wire reset,
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    input wire [3:0] operation,
    input wire alu_mode,           // 0=Fixed, 1=Float
    input wire start,
    output wire [31:0] result,
    output wire done,
    output wire overflow,
    output wire underflow,
    output wire div_by_zero
);

    // Fixed-point ALU signals
    wire [31:0] fixed_result;
    wire fixed_done;
    wire fixed_overflow;
    wire fixed_underflow;
    wire fixed_div_by_zero;
    
    // Floating-point ALU signals  
    wire [31:0] float_result;
    wire float_done;
    wire float_overflow;
    wire float_underflow;
    wire float_div_by_zero;
    
    // Instantiate Fixed-Point ALU
    fixed_alu fixed_alu_inst (
        .clk(clk),
        .reset(reset),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .operation(operation),
        .start(start && (alu_mode == `MODE_FIXED)),
        .result(fixed_result),
        .done(fixed_done),
        .overflow(fixed_overflow),
        .underflow(fixed_underflow),
        .div_by_zero(fixed_div_by_zero)
    );
    
    fp_alu float_alu_inst (
        .clk(clk),
        .reset(reset),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .operation(operation),
        .start(start && (alu_mode == `MODE_FLOAT)),
        .result(float_result),
        .done(float_done),
        .overflow(float_overflow),
        .underflow(float_underflow),
        .invalid(float_div_by_zero)
    );
    
    assign result = (alu_mode == `MODE_FIXED) ? fixed_result : float_result;
    assign done = (alu_mode == `MODE_FIXED) ? fixed_done : float_done;
    assign overflow = (alu_mode == `MODE_FIXED) ? fixed_overflow : float_overflow;
    assign underflow = (alu_mode == `MODE_FIXED) ? fixed_underflow : float_underflow;
    assign div_by_zero = (alu_mode == `MODE_FIXED) ? fixed_div_by_zero : float_div_by_zero;
    
endmodule