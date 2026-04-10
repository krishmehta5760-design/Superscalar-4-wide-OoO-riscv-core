module MUL_Unit(
    input clk,
    input rst,
    input flush,
    input hold,
    input [31:0] src1,
    input [31:0] src2,
    input [2:0] func3,
    input [6:0] prd_in,
    input valid_in,
    output reg [6:0] prd_out,
    output reg [31:0] result,
    output reg valid_out
);

    // Stage 1: Multiplication and capture
    reg [63:0] prod1;
    reg [2:0] f1;
    reg [6:0] p1;
    reg v1;

    // Stage 2: Pipeline propagation
    reg [63:0] prod2;
    reg [2:0] f2;
    reg [6:0] p2;
    reg v2;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            v1 <= 0; v2 <= 0; valid_out <= 0;
            prod1 <= 0; prod2 <= 0;
            f1 <= 0; f2 <= 0;
            p1 <= 0; p2 <= 0;
            result <= 0; prd_out <= 0;
        end else if (flush) begin
            v1 <= 0; v2 <= 0; valid_out <= 0;
        end else if (!hold) begin
            // Stage 1 Logic
            v1 <= valid_in;
            if (valid_in) begin
                f1 <= func3;
                p1 <= prd_in;
                // Handle different multiplication types
                case (func3)
                    3'b000: prod1 <= {32'd0, src1} * {32'd0, src2}; // MUL
                    3'b001: prod1 <= $signed({{32{src1[31]}}, src1}) * $signed({{32{src2[31]}}, src2}); // MULH
                    3'b010: prod1 <= $signed({{32{src1[31]}}, src1}) * $signed({32'b0, src2});          // MULHSU
                    3'b011: prod1 <= {32'd0, src1} * {32'd0, src2}; // MULHU
                    default: prod1 <= 64'd0;
                endcase
            end

            // Stage 2 Logic
            v2 <= v1;
            if (v1) begin
                f2 <= f1;
                p2 <= p1;
                prod2 <= prod1;
            end

            // Stage 3 Logic
            valid_out <= v2;
            if (v2) begin
                prd_out <= p2;
                if (f2 == 3'b000)
                    result <= prod2[31:0];
                else
                    result <= prod2[63:32];
            end
        end
    end

endmodule
