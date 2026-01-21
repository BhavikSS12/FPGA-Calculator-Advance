`include "fixed_point_alu/fixed_utils.v"

module number_converter (
    input wire [31:0] data_in,
    input wire convert_to_float,
    output reg [31:0] data_out
);

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
                
                // Find leading 1 bit position (from MSB)
                shift_pos = 31;
                while (shift_pos > 0 && abs_val[shift_pos] == 0)
                    shift_pos = shift_pos - 1;
                
                // Calculate exponent (127 bias + position - 16 for Q16.16)
                exp = 127 + shift_pos - 16;
                
                // Shift the leading 1 to bit position 23, then take lower 23 bits
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
                // Calculate shift: exp - 127 - 23 + 16
                shift_amount = exp - 127 - 23 + 16;
                
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
    
    always @(*) begin
        if (convert_to_float)
            data_out = fixed_to_float(data_in);
        else
            data_out = float_to_fixed(data_in);
    end

endmodule
