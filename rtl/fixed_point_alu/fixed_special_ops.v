`include "fixed_utils.v"

module fixed_special_operations (
    input wire clk,
    input wire reset,
    input wire [31:0] operand_a,
    input wire [31:0] operand_b,
    input wire [3:0] operation,
    input wire start,
    output reg [31:0] result,
    output reg done,
    output reg overflow
);

    // Operation codes for special operations
    localparam OP_SQRT     = 4'h0;  // Square root
    localparam OP_POW2     = 4'h1;  // Power of 2 (a^2)
    localparam OP_POW3     = 4'h2;  // Power of 3 (a^3)
    localparam OP_RECIP    = 4'h3;  // Reciprocal (1/a)
    localparam OP_AVG      = 4'h4;  // Average (a+b)/2
    localparam OP_LERP     = 4'h5;  // Linear interpolation
    localparam OP_CLAMP    = 4'h6;  // Clamp value between min and max
    localparam OP_ROUND    = 4'h7;  // Round to nearest integer
    localparam OP_MAD      = 4'h8;  // Multiply-accumulate (a*b + result)

    // State machine
    reg [2:0] state;
    localparam IDLE = 3'b000;
    localparam COMPUTE = 3'b001;
    localparam ITERATE = 3'b010;
    localparam DONE_STATE = 3'b011;

    // Iteration counter for iterative operations
    reg [4:0] iteration;
    reg [31:0] temp_x, temp_estimate;
    
    // Internal wires
    wire signed [63:0] mul_temp;
    wire signed [63:0] div_temp;
    wire [31:0] sqrt_result;
    wire [31:0] recip_result;
    
    // Square root using Newton-Raphson (iterative)
    // x_{n+1} = (x_n + a/x_n) / 2
    wire signed [63:0] sqrt_div;
    wire signed [31:0] sqrt_avg;
    assign sqrt_div = ({operand_a, 14'h0} / $signed(temp_estimate));
    assign sqrt_avg = ($signed(temp_estimate) + sqrt_div[31:0]) >>> 1;

    // Reciprocal using Newton-Raphson
    // x_{n+1} = x_n * (2 - a*x_n)
    wire signed [63:0] recip_mul;
    wire signed [63:0] recip_sub;
    wire signed [31:0] recip_next;
    assign recip_mul = ($signed(operand_a) * $signed(temp_estimate)) >>> 14;
    assign recip_sub = (`FIXED_ONE << 1) - recip_mul[31:0];
    assign recip_next = (($signed(temp_estimate) * recip_sub) >>> 14);

    // Combinational operations
    wire [31:0] pow2_result;
    wire [31:0] pow3_result;
    wire [31:0] avg_result;
    wire [31:0] round_result;
    wire [31:0] mad_result;

    // Power of 2: a * a
    assign mul_temp = ($signed(operand_a) * $signed(operand_a)) >>> 14;
    assign pow2_result = mul_temp[31:0];

    // Power of 3: a * a * a
    wire signed [63:0] pow3_temp1, pow3_temp2;
    assign pow3_temp1 = ($signed(operand_a) * $signed(operand_a)) >>> 14;
    assign pow3_temp2 = (pow3_temp1[31:0] * $signed(operand_a)) >>> 14;
    assign pow3_result = pow3_temp2[31:0];

    // Average: (a + b) / 2
    assign avg_result = ($signed(operand_a) + $signed(operand_b)) >>> 1;

    // Round to nearest integer
    wire [31:0] rounded_with_half;
    assign rounded_with_half = $signed(operand_a) + `FIXED_HALF;
    assign round_result = {rounded_with_half[31:14], 14'h0};

    // Multiply-accumulate: a * b + current result
    wire signed [63:0] mad_mul;
    assign mad_mul = ($signed(operand_a) * $signed(operand_b)) >>> 14;
    assign mad_result = mad_mul[31:0] + result;

    // Main state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            result <= `FIXED_ZERO;
            done <= 1'b0;
            overflow <= 1'b0;
            iteration <= 0;
            temp_estimate <= 0;
            temp_x <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    overflow <= 1'b0;
                    if (start) begin
                        iteration <= 0;
                        state <= COMPUTE;
                        
                        // Initialize iterative operations
                        case (operation)
                            OP_SQRT: begin
                                // Initial guess: use operand_a >> 1 as starting point
                                temp_estimate <= (operand_a >>> 1) + `FIXED_ONE;
                                temp_x <= operand_a;
                            end
                            OP_RECIP: begin
                                // Initial guess for 1/a: crude approximation
                                if (operand_a != 0) begin
                                    temp_estimate <= 32'h00010000; // Start with rough estimate
                                    temp_x <= operand_a;
                                end else begin
                                    temp_estimate <= `FIXED_MAX; // Division by zero
                                end
                            end
                        endcase
                    end
                end

                COMPUTE: begin
                    case (operation)
                        OP_SQRT: begin
                            if (operand_a == 0) begin
                                result <= `FIXED_ZERO;
                                state <= DONE_STATE;
                            end else if (operand_a[31]) begin
                                // Negative input
                                result <= `FIXED_ZERO;
                                overflow <= 1'b1;
                                state <= DONE_STATE;
                            end else begin
                                state <= ITERATE;
                            end
                        end

                        OP_RECIP: begin
                            if (operand_a == 0) begin
                                result <= `FIXED_MAX;
                                overflow <= 1'b1;
                                state <= DONE_STATE;
                            end else begin
                                state <= ITERATE;
                            end
                        end

                        OP_POW2: begin
                            result <= pow2_result;
                            state <= DONE_STATE;
                        end

                        OP_POW3: begin
                            result <= pow3_result;
                            state <= DONE_STATE;
                        end

                        OP_AVG: begin
                            result <= avg_result;
                            state <= DONE_STATE;
                        end

                        OP_ROUND: begin
                            result <= round_result;
                            state <= DONE_STATE;
                        end

                        OP_MAD: begin
                            result <= mad_result;
                            state <= DONE_STATE;
                        end

                        default: begin
                            result <= `FIXED_ZERO;
                            state <= DONE_STATE;
                        end
                    endcase
                end

                ITERATE: begin
                    // Newton-Raphson iterations (5-6 iterations for convergence)
                    if (iteration < 6) begin
                        iteration <= iteration + 1;
                        case (operation)
                            OP_SQRT: begin
                                temp_estimate <= sqrt_avg;
                            end
                            OP_RECIP: begin
                                temp_estimate <= recip_next;
                            end
                        endcase
                    end else begin
                        // Done iterating
                        result <= temp_estimate;
                        state <= DONE_STATE;
                    end
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