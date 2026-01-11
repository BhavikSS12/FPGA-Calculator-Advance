
`include "common/alu_defines.v"

module calculator_top (
    input wire clk,
    input wire reset,
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    input wire [3:0] operation,
    input wire alu_mode,           // 0=Fixed, 1=Float
    input wire start,
    output reg [31:0] result,
    output reg done,
    output reg overflow,
    output reg underflow,
    output reg div_by_zero
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
    
    // Instantiate Floating-Point ALU (use your fp_alu.v from before)
    // For now, placeholder - you would instantiate fp_alu here
    assign float_result = 32'h0;
    assign float_done = 1'b0;
    assign float_overflow = 1'b0;
    assign float_underflow = 1'b0;
    assign float_div_by_zero = 1'b0;
    
    // Output multiplexer
    always @(*) begin
        if (alu_mode == `MODE_FIXED) begin
            result = fixed_result;
            done = fixed_done;
            overflow = fixed_overflow;
            underflow = fixed_underflow;
            div_by_zero = fixed_div_by_zero;
        end else begin
            result = float_result;
            done = float_done;
            overflow = float_overflow;
            underflow = float_underflow;
            div_by_zero = float_div_by_zero;
        end
    end

endmodule