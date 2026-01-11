
`include "fixed_point/fixed_utils.v"

module number_converter (
    input wire [31:0] data_in,
    input wire convert_to_float,     // 1=fixed->float, 0=float->fixed
    output reg [31:0] data_out
);

    always @(*) begin
        if (convert_to_float) begin
            // Convert Q16.16 fixed-point to IEEE 754 float
            reg sign;
            reg [7:0] exponent;
            reg [22:0] mantissa;
            reg [31:0] abs_fixed;
            integer leading_zeros;
            
            sign = data_in[31];
            abs_fixed = sign ? -data_in : data_in;
            
            // Find position of leading 1
            if (abs_fixed == 0) begin
                data_out = 32'h0;  // Zero
            end else begin
                // Simplified conversion (full implementation would normalize)
                // This is a basic approximation
                exponent = 8'd127 + 8'd16;  // Adjust for Q16.16 format
                mantissa = abs_fixed[31:9];
                data_out = {sign, exponent, mantissa};
            end
        end else begin
            // Convert IEEE 754 float to Q16.16 fixed-point
            reg sign;
            reg [7:0] exponent;
            reg [23:0] mantissa;
            reg signed [31:0] result;
            integer shift;
            
            sign = data_in[31];
            exponent = data_in[30:23];
            mantissa = {1'b1, data_in[22:0]};  // Add implicit 1
            
            // Calculate shift amount
            shift = exponent - 127 - 23 + 16;  // Adjust for Q16.16
            
            if (shift >= 0) begin
                result = mantissa << shift;
            end else begin
                result = mantissa >> (-shift);
            end
            
            data_out = sign ? -result : result;
        end
    end

endmodule