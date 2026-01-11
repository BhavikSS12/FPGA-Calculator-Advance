`include "fp_utils.v"

module fp_alu (
    input wire clk,
    input wire reset,
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    input wire [3:0] operation,
    input wire start,
    output reg [31:0] result,
    output reg done,
    output reg overflow,
    output reg underflow,
    output reg invalid
);

    // Intermediate signals for each operation module
    wire [31:0] add_result, mul_result, div_result, special_result;
    wire add_done, mul_done, div_done;
    wire add_overflow, mul_overflow, div_overflow;
    wire add_underflow, mul_underflow, div_underflow;
    wire div_by_zero;
    
    // Module instantiations
    fp_adder adder (
        .clk(clk),
        .reset(reset),
        .a(operand_a),
        .b(operand_b),
        .sub(operation == `OP_SUB),
        .start(start && (operation == `OP_ADD || operation == `OP_SUB)),
        .result(add_result),
        .done(add_done),
        .overflow(add_overflow),
        .underflow(add_underflow)
    );
    
    fp_multiplier multiplier (
        .clk(clk),
        .reset(reset),
        .a(operand_a),
        .b(operand_b),
        .start(start && (operation == `OP_MUL)),
        .result(mul_result),
        .done(mul_done),
        .overflow(mul_overflow),
        .underflow(mul_underflow)
    );
    
    fp_divider divider (
        .clk(clk),
        .reset(reset),
        .a(operand_a),
        .b(operand_b),
        .start(start && (operation == `OP_DIV)),
        .result(div_result),
        .done(div_done),
        .div_by_zero(div_by_zero),
        .overflow(div_overflow),
        .underflow(div_underflow)
    );
    
    fp_special_ops special (
        .a(operand_a),
        .b(operand_b),
        .op_select(operation[1:0]),
        .result(special_result)
    );
    
    // Output multiplexer
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            result <= 32'h0;
            done <= 1'b0;
            overflow <= 1'b0;
            underflow <= 1'b0;
            invalid <= 1'b0;
        end else begin
            case (operation)
                `OP_ADD, `OP_SUB: begin
                    result <= add_result;
                    done <= add_done;
                    overflow <= add_overflow;
                    underflow <= add_underflow;
                end
                
                `OP_MUL: begin
                    result <= mul_result;
                    done <= mul_done;
                    overflow <= mul_overflow;
                    underflow <= mul_underflow;
                end
                
                `OP_DIV: begin
                    result <= div_result;
                    done <= div_done;
                    overflow <= div_overflow;
                    underflow <= div_underflow;
                    invalid <= div_by_zero;
                end
                
                `OP_ABS, `OP_NEG, `OP_MIN, `OP_MAX: begin
                    result <= special_result;
                    done <= 1'b1;
                    overflow <= 1'b0;
                    underflow <= 1'b0;
                end
                
                default: begin
                    result <= `FP_ZERO;
                    done <= 1'b0;
                end
            endcase
        end
    end

endmodule