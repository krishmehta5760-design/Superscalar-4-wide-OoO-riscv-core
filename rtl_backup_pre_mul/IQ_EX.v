module IQ_EX(clk,rst,
             issue_prd_0,issue_prd_1,issue_prd_2,issue_prd_3,
             issue_imm_0,issue_imm_1,issue_imm_2,issue_imm_3,
             issue_func7_0,issue_func7_1,issue_func7_2,issue_func7_3,
             issue_func3_0,issue_func3_1,issue_func3_2,issue_func3_3,
             issue_opcode_0,issue_opcode_1,issue_opcode_2,issue_opcode_3,
             issue_has_dest,issue_is_branch,issue_is_jump,issue_is_jalr,issue_valid,
             src1_data_0,src1_data_1,src1_data_2,src1_data_3,
             src2_data_0,src2_data_1,src2_data_2,src2_data_3,
             ex_prd_0,ex_prd_1,ex_prd_2,ex_prd_3,
             ex_imm_0,ex_imm_1,ex_imm_2,ex_imm_3,
             ex_func7_0,ex_func7_1,ex_func7_2,ex_func7_3,
             ex_func3_0,ex_func3_1,ex_func3_2,ex_func3_3,
             ex_opcode_0,ex_opcode_1,ex_opcode_2,ex_opcode_3,
             ex_has_dest,ex_is_branch,ex_is_jump,ex_is_jalr,ex_valid,
             ex_src1_data_0,ex_src1_data_1,ex_src1_data_2,ex_src1_data_3,
             ex_src2_data_0,ex_src2_data_1,ex_src2_data_2,ex_src2_data_3,flush,
             issue_pc_0, issue_pc_1, issue_pc_2, issue_pc_3,ex_pc_0, ex_pc_1, ex_pc_2, ex_pc_3);

input clk,rst;
input [6:0] issue_prd_0,issue_prd_1,issue_prd_2,issue_prd_3;
input [31:0] issue_imm_0,issue_imm_1,issue_imm_2,issue_imm_3;
input [6:0] issue_func7_0,issue_func7_1,issue_func7_2,issue_func7_3;
input [2:0] issue_func3_0,issue_func3_1,issue_func3_2,issue_func3_3;
input [6:0] issue_opcode_0,issue_opcode_1,issue_opcode_2,issue_opcode_3;
input [3:0] issue_has_dest,issue_is_branch,issue_is_jump,issue_is_jalr,issue_valid;
input [31:0] src1_data_0,src1_data_1,src1_data_2,src1_data_3;
input [31:0] src2_data_0,src2_data_1,src2_data_2,src2_data_3;
input flush;
input  [31:0] issue_pc_0, issue_pc_1, issue_pc_2, issue_pc_3;

output reg [31:0] ex_pc_0, ex_pc_1, ex_pc_2, ex_pc_3;
output reg [6:0] ex_prd_0,ex_prd_1,ex_prd_2,ex_prd_3;
output reg [31:0] ex_imm_0,ex_imm_1,ex_imm_2,ex_imm_3;
output reg [6:0] ex_func7_0,ex_func7_1,ex_func7_2,ex_func7_3;
output reg [2:0] ex_func3_0,ex_func3_1,ex_func3_2,ex_func3_3;
output reg [6:0] ex_opcode_0,ex_opcode_1,ex_opcode_2,ex_opcode_3;
output reg [3:0] ex_has_dest,ex_is_branch,ex_is_jump,ex_is_jalr,ex_valid;
output reg [31:0] ex_src1_data_0,ex_src1_data_1,ex_src1_data_2,ex_src1_data_3;
output reg [31:0] ex_src2_data_0,ex_src2_data_1,ex_src2_data_2,ex_src2_data_3;

always@(posedge clk or negedge rst)begin

if(!rst || flush)begin
{ex_prd_0,ex_prd_1,ex_prd_2,ex_prd_3} <= 28'd0;
{ex_imm_0,ex_imm_1,ex_imm_2,ex_imm_3} <= 128'd0;
{ex_func7_0,ex_func7_1,ex_func7_2,ex_func7_3} <= 28'd0;
{ex_func3_0,ex_func3_1,ex_func3_2,ex_func3_3} <= 12'd0;
{ex_opcode_0,ex_opcode_1,ex_opcode_2,ex_opcode_3} <= 28'd0;
{ex_has_dest,ex_is_branch,ex_is_jump,ex_is_jalr,ex_valid} <= 20'd0;
{ex_src1_data_0,ex_src1_data_1,ex_src1_data_2,ex_src1_data_3} <= 128'd0;
{ex_src2_data_0,ex_src2_data_1,ex_src2_data_2,ex_src2_data_3} <= 128'd0;
{ex_pc_0,ex_pc_1,ex_pc_2,ex_pc_3} <= 128'd0;
end

else begin
ex_prd_0 <= issue_prd_0;
ex_prd_1 <= issue_prd_1;
ex_prd_2 <= issue_prd_2;
ex_prd_3 <= issue_prd_3;
ex_imm_0 <= issue_imm_0;
ex_imm_1 <= issue_imm_1;
ex_imm_2 <= issue_imm_2;
ex_imm_3 <= issue_imm_3;
ex_func7_0 <= issue_func7_0;
ex_func7_1 <= issue_func7_1;
ex_func7_2 <= issue_func7_2;
ex_func7_3 <= issue_func7_3;
ex_func3_0 <= issue_func3_0;
ex_func3_1 <= issue_func3_1;
ex_func3_2 <= issue_func3_2;
ex_func3_3 <= issue_func3_3;
ex_opcode_0 <= issue_opcode_0;
ex_opcode_1 <= issue_opcode_1;
ex_opcode_2 <= issue_opcode_2;
ex_opcode_3 <= issue_opcode_3;
ex_has_dest  <= issue_has_dest;
ex_is_branch <= issue_is_branch;
ex_is_jump   <= issue_is_jump;
ex_is_jalr   <= issue_is_jalr;
ex_valid     <= issue_valid;
ex_src1_data_0 <= src1_data_0;
ex_src1_data_1 <= src1_data_1;
ex_src1_data_2 <= src1_data_2;
ex_src1_data_3 <= src1_data_3;
ex_src2_data_0 <= src2_data_0;
ex_src2_data_1 <= src2_data_1;
ex_src2_data_2 <= src2_data_2;
ex_src2_data_3 <= src2_data_3;
ex_pc_0 <= issue_pc_0;
ex_pc_1 <= issue_pc_1;
ex_pc_2 <= issue_pc_2;
ex_pc_3 <= issue_pc_3;
end

end

endmodule