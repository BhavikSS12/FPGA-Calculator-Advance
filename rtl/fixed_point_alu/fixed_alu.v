`include "fixed_utils.v"
`include "alu_defines.v"

module fixed_alu (
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
    output reg div_by_zero
);

    // State machine
    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam DONE_STATE = 2'b10;
    reg [31:0] temp_result;
    reg temp_overflow;
    
    // Internal computation wires
    wire [31:0] add_result;
    wire [31:0] sub_result;
    wire [31:0] mul_result;
    wire [31:0] div_result;
    wire [31:0] mod_result;
    wire [31:0] and_result;
    wire [31:0] or_result;
    wire [31:0] xor_result;
    wire [31:0] shl_result;
    wire [31:0] shr_result;
    wire [31:0] abs_result;
    wire [31:0] neg_result;
    wire [31:0] cmp_result;
    wire [31:0] min_result;
    wire [31:0] max_result;
    
    wire add_overflow, mul_overflow;
    
    // Instantiate sub-modules
    fixed_adder adder (
        .a(operand_a),
        .b(operand_b),
        .sub(operation == `OP_SUB),
        .result(add_result),
        .overflow(add_overflow)
    );
    
    fixed_multiplier multiplier (
        .a(operand_a),
        .b(operand_b),
        .result(mul_result),
        .overflow(mul_overflow)
    );
    
    fixed_divider divider (
        .a(operand_a),
        .b(operand_b),
        .quotient(div_result),
        .remainder(mod_result),
        .div_by_zero(div_by_zero)
    );
    
    // Simple combinational operations
    assign and_result = operand_a & operand_b;
    assign or_result = operand_a | operand_b;
    assign xor_result = operand_a ^ operand_b;
    assign shl_result = operand_a << operand_b[4:0];  // Shift by b bits
    assign shr_result = operand_a >>> operand_b[4:0]; // Arithmetic shift
    assign abs_result = operand_a[31] ? -operand_a : operand_a;
    assign neg_result = -operand_a;
    
    // Comparison (Q18.14 format)
    assign cmp_result = (operand_a == operand_b) ? `FIXED_ZERO :
                       (operand_a > operand_b) ? `FIXED_ONE : 
                       32'hFFFFC000; // -1.0 in Q18.14
    
    // Min/Max
    assign min_result = ($signed(operand_a) < $signed(operand_b)) ? operand_a : operand_b;
    assign max_result = ($signed(operand_a) > $signed(operand_b)) ? operand_a : operand_b;
    
    // Main control logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            result <= `FIXED_ZERO;
            done <= 1'b0;
            overflow <= 1'b0;
            underflow <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    overflow <= 1'b0;
                    underflow <= 1'b0;
                    if (start) begin
                        state <= COMPUTE;
                    end
                end
                
                COMPUTE: begin
                    case (operation)
                        `OP_ADD: begin
                            result <= add_result;
                            overflow <= add_overflow;
                        end
                        `OP_SUB: begin
                            result <= add_result; // Adder handles subtraction
                            overflow <= add_overflow;
                        end
                        `OP_MUL: begin
                            result <= mul_result;
                            overflow <= mul_overflow;
                        end
                        `OP_DIV: begin
                            result <= div_result;
                        end
                        `OP_MOD: begin
                            result <= mod_result;
                        end
                        `OP_AND: result <= and_result;
                        `OP_OR:  result <= or_result;
                        `OP_XOR: result <= xor_result;
                        `OP_SHL: result <= shl_result;
                        `OP_SHR: result <= shr_result;
                        `OP_ABS: result <= abs_result;
                        `OP_NEG: result <= neg_result;
                        `OP_CMP: result <= cmp_result;
                        `OP_MIN: result <= min_result;
                        `OP_MAX: result <= max_result;
                        default: result <= `FIXED_ZERO;
                    endcase
                    state <= DONE_STATE;
                end
                
                DONE_STATE: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule