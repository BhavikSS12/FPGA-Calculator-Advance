`include "fp_utils.v"

module fp_adder (
    input wire clk,
    input wire reset,
    input wire [31:0] a,
    input wire [31:0] b,
    input wire sub,          // 1 for subtraction, 0 for addition
    input wire start,
    output reg [31:0] result,
    output reg done,
    output reg overflow,
    output reg underflow
);

    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam DONE = 2'b10;
    
    // IEEE 754 component extraction
    wire sign_a = `FP_SIGN(a);
    wire sign_b = sub ? ~`FP_SIGN(b) : `FP_SIGN(b);
    wire [7:0] exp_a = `FP_EXP(a);
    wire [7:0] exp_b = `FP_EXP(b);
    wire [23:0] mant_a = `FP_MANT_FULL(a);
    wire [23:0] mant_b = `FP_MANT_FULL(b);
    
    wire a_is_zero = `IS_ZERO(a);
    wire b_is_zero = `IS_ZERO(b);
    wire a_is_inf = `IS_INF(a);
    wire b_is_inf = `IS_INF(b);
    
    reg signed [8:0] exp_diff;
    reg [7:0] larger_exp;
    reg [24:0] mant_a_aligned, mant_b_aligned;
    reg [24:0] mant_sum;
    reg result_sign;
    reg [7:0] result_exp;
    reg signed [5:0] shift_amt;
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            result <= 32'h0;
            done <= 1'b0;
            overflow <= 1'b0;
            underflow <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state <= COMPUTE;
                        overflow <= 1'b0;
                        underflow <= 1'b0;
                    end
                end
                
                COMPUTE: begin
                    // Handle special cases
                    if (a_is_zero) begin
                        result <= sub ? {~b[31], b[30:0]} : b;
                    end else if (b_is_zero) begin
                        result <= a;
                    end else if (a_is_inf || b_is_inf) begin
                        if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
                            result <= `FP_NAN;
                        end else if (a_is_inf) begin
                            result <= a;
                        end else begin
                            result <= {sign_b, b[30:0]};
                        end
                    end else begin
                        // Align exponents
                        exp_diff = exp_a - exp_b;
                        
                        if (exp_diff >= 0) begin
                            larger_exp = exp_a;
                            mant_a_aligned = {mant_a, 1'b0};
                            shift_amt = (exp_diff > 24) ? 24 : exp_diff;
                            mant_b_aligned = {mant_b, 1'b0} >> shift_amt;
                        end else begin
                            larger_exp = exp_b;
                            mant_b_aligned = {mant_b, 1'b0};
                            shift_amt = ((-exp_diff) > 24) ? 24 : (-exp_diff);
                            mant_a_aligned = {mant_a, 1'b0} >> shift_amt;
                        end
                        
                        // Add or subtract mantissas
                        if (sign_a == sign_b) begin
                            mant_sum = mant_a_aligned + mant_b_aligned;
                            result_sign = sign_a;
                        end else begin
                            if (mant_a_aligned >= mant_b_aligned) begin
                                mant_sum = mant_a_aligned - mant_b_aligned;
                                result_sign = sign_a;
                            end else begin
                                mant_sum = mant_b_aligned - mant_a_aligned;
                                result_sign = sign_b;
                            end
                        end
                        
                        // Normalize
                        result_exp = larger_exp;
                        
                        if (mant_sum[24]) begin
                            mant_sum = mant_sum >> 1;
                            result_exp = result_exp + 1;
                        end else begin
                            for (i = 23; i >= 0; i = i - 1) begin
                                if (mant_sum[i] == 1'b1 || result_exp == 0 || mant_sum == 0) begin
                                    i = -1; // Break loop
                                end else begin
                                    mant_sum = mant_sum << 1;
                                    result_exp = result_exp - 1;
                                end
                            end
                        end
                        
                        result <= {result_sign, result_exp, mant_sum[22:0]};
                    end
                    
                    state <= DONE;
                end
                
                DONE: begin
                    done <= 1'b1;
                    if (!start)
                        state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule