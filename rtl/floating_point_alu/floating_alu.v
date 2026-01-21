`include "fp_utils.v"
`include "C:\Users\BHAVIK\Desktop\Bhavik_clg\Projects\vlsi_projects\FPGA-Calculator-Advance\rtl\alu_defines.v"

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
                    if (start) begin  
                        result <= special_result;
                        done <= 1'b1;
                        overflow <= 1'b0;
                        underflow <= 1'b0;
                    end else begin
                        done <= 1'b0;
                    end
                end
                
                default: begin
                    result <= `FP_ZERO;
                    done <= 1'b0;
                end
            endcase
        end
    end
    
    // fixed to float conversion
    function [31:0] fixed_to_float;
    input [31:0] fixed_val;
    reg sign;
    reg [7:0] exp;
    reg [22:0] mant;
    reg [31:0] abs_val;
    integer shift_pos;
    reg [31:0] shifted_val;  
    begin
        if (fixed_val == 32'h0) begin
            fixed_to_float = 32'h0;
        end else begin
            sign = fixed_val[31];
            abs_val = sign ? (~fixed_val + 1) : fixed_val;
           
            shift_pos = 31;
            while (shift_pos > 0 && abs_val[shift_pos] == 0)
                shift_pos = shift_pos - 1;
            
            exp = 127 + shift_pos - 14;
            
            if (shift_pos >= 23) begin
                // Shift right to align mantissa
                shifted_val = abs_val >> (shift_pos - 23);
                mant = shifted_val[22:0];
            end else begin
                // Shift left to align mantissa
                shifted_val = abs_val << (23 - shift_pos);
                mant = shifted_val[22:0];
            end
            
            fixed_to_float = {sign, exp, mant};
        end
    end
    endfunction
    
    // Float to Fixed conversion
    function [31:0] float_to_fixed;
        input [31:0] float_val;
        reg sign;
        reg [7:0] exp;
        reg [23:0] mant;
        reg signed [31:0] result;
        integer shift_amount;
        reg [31:0] shifted_mant; 
        begin
            sign = float_val[31];
            exp = float_val[30:23];
            mant = {1'b1, float_val[22:0]};
            
            // Handle special cases
            if (exp == 8'h00) begin
                float_to_fixed = 32'h0;
            end else if (exp == 8'hFF) begin
                float_to_fixed = sign ? 32'h80000000 : 32'h7FFFFFFF;
            end else begin
                // Calculate shift: exp - 127 - 23 + 14
                shift_amount = exp - 127 - 23 + 14;
                
                if (shift_amount >= 0) begin
                    shifted_mant = mant << shift_amount;
                end else begin
                    shifted_mant = mant >> (-shift_amount);
                end
                
                result = shifted_mant;
                float_to_fixed = sign ? (~result + 1) : result;
            end
        end
    endfunction

endmodule