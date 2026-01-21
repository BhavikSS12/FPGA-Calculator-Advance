`include "fp_utils.v"

module fp_divider (
    input wire clk,
    input wire reset,
    input wire [31:0] a,
    input wire [31:0] b,
    input wire start,
    output reg [31:0] result,
    output reg done,
    output reg div_by_zero,
    output reg overflow,
    output reg underflow
);

    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam DONE = 2'b10;
    
    wire sign_a = `FP_SIGN(a);
    wire sign_b = `FP_SIGN(b);
    wire [7:0] exp_a = `FP_EXP(a);
    wire [7:0] exp_b = `FP_EXP(b);
    wire [23:0] mant_a = `FP_MANT_FULL(a);
    wire [23:0] mant_b = `FP_MANT_FULL(b);
    
    wire a_is_zero = `IS_ZERO(a);
    wire b_is_zero = `IS_ZERO(b);
    wire a_is_inf = `IS_INF(a);
    wire b_is_inf = `IS_INF(b);
    
    reg result_sign;
    reg signed [9:0] result_exp_temp;
    reg [7:0] result_exp;
    reg [47:0] mant_quotient;
    reg [22:0] result_mant;
    
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            result <= 32'h0;
            done <= 1'b0;
            div_by_zero <= 1'b0;
            overflow <= 1'b0;
            underflow <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state <= COMPUTE;
                        div_by_zero <= 1'b0;
                        overflow <= 1'b0;
                        underflow <= 1'b0;
                    end
                end
                
                COMPUTE: begin
                    if (b_is_zero) begin
                        div_by_zero <= 1'b1;
                        if (a_is_zero) begin
                            result <= `FP_NAN;
                        end else begin
                            result_sign = sign_a ^ sign_b;
                            result <= {result_sign, 8'hFF, 23'h0};
                        end
                    end else if (a_is_zero) begin
                        result <= `FP_ZERO;
                    end else if (b_is_inf) begin
                        result <= `FP_ZERO;
                    end else if (a_is_inf) begin
                        result_sign = sign_a ^ sign_b;
                        result <= {result_sign, 8'hFF, 23'h0};
                    end else begin
                        result_sign = sign_a ^ sign_b;
                        result_exp_temp = exp_a - exp_b + 127;
                        
                        mant_quotient = ({mant_a, 24'h0} << 1) / mant_b;
                        
                        if (mant_quotient[24]) begin
                            result_mant = mant_quotient[24:2];
                            result_exp_temp = result_exp_temp + 1;
                        end else begin
                            result_mant = mant_quotient[23:1];
                        end
                        
                        if (result_exp_temp >= 255) begin
                            result_exp = 8'hFF;
                            result_mant = 23'h0;
                            overflow <= 1'b1;
                        end else if (result_exp_temp <= 0) begin
                            result_exp = 8'h00;
                            result_mant = 23'h0;
                            underflow <= 1'b1;
                        end else begin
                            result_exp = result_exp_temp[7:0];
                        end
                        
                        result <= {result_sign, result_exp, result_mant};
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