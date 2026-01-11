`include "fp_utils.v"

module fp_special_ops (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [1:0] op_select,  // 00=ABS, 01=NEG, 10=MIN, 11=MAX
    output reg [31:0] result
);

    localparam OP_ABS = 2'b00;
    localparam OP_NEG = 2'b01;
    localparam OP_MIN = 2'b10;
    localparam OP_MAX = 2'b11;
    
    wire sign_a = `FP_SIGN(a);
    wire sign_b = `FP_SIGN(b);
    wire [7:0] exp_a = `FP_EXP(a);
    wire [7:0] exp_b = `FP_EXP(b);
    wire [23:0] mant_a = `FP_MANT_FULL(a);
    wire [23:0] mant_b = `FP_MANT_FULL(b);
    
    always @(*) begin
        case (op_select)
            OP_ABS: begin
                result = {1'b0, a[30:0]};
            end
            
            OP_NEG: begin
                result = {~a[31], a[30:0]};
            end
            
            OP_MIN: begin
                if (sign_a != sign_b) begin
                    result = sign_a ? a : b;
                end else begin
                    if ((exp_a < exp_b) || ((exp_a == exp_b) && (mant_a < mant_b))) begin
                        result = sign_a ? b : a;
                    end else begin
                        result = sign_a ? a : b;
                    end
                end
            end
            
            OP_MAX: begin
                if (sign_a != sign_b) begin
                    result = sign_a ? b : a;
                end else begin
                    if ((exp_a < exp_b) || ((exp_a == exp_b) && (mant_a < mant_b))) begin
                        result = sign_a ? a : b;
                    end else begin
                        result = sign_a ? b : a;
                    end
                end
            end
            
            default: result = `FP_ZERO;
        endcase
    end

endmodule