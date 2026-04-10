`timescale 1ns / 1ps
module RE_IQ(clk,rst,
             prs1_0_R,prs1_1_R,prs1_2_R,prs1_3_R,
             prs2_0_R,prs2_1_R,prs2_2_R,prs2_3_R,
             prd_0_R,prd_1_R,prd_2_R,prd_3_R,
             old_prd_0_R,old_prd_1_R,old_prd_2_R,old_prd_3_R,
             imm_out_0_R,imm_out_1_R,imm_out_2_R,imm_out_3_R,
             func7_out_0_R,func7_out_1_R,func7_out_2_R,func7_out_3_R,
             func3_out_0_R,func3_out_1_R,func3_out_2_R,func3_out_3_R,
             opcode_out_0_R,opcode_out_1_R,opcode_out_2_R,opcode_out_3_R,
             has_dest_out_R,is_branch_out_R,is_jump_out_R,is_jalr_out_R,is_load_out_R,is_store_out_R,
             valid_out_R,stall_R,rd_0_R,rd_1_R,rd_2_R,rd_3_R,
             prs1_0_IQ,prs1_1_IQ,prs1_2_IQ,prs1_3_IQ,
             prs2_0_IQ,prs2_1_IQ,prs2_2_IQ,prs2_3_IQ,
             prd_0_IQ,prd_1_IQ,prd_2_IQ,prd_3_IQ,
             old_prd_0_IQ,old_prd_1_IQ,old_prd_2_IQ,old_prd_3_IQ,
             imm_0_IQ,imm_1_IQ,imm_2_IQ,imm_3_IQ,
             func7_0_IQ,func7_1_IQ,func7_2_IQ,func7_3_IQ,
             func3_0_IQ,func3_1_IQ,func3_2_IQ,func3_3_IQ,
             opcode_0_IQ,opcode_1_IQ,opcode_2_IQ,opcode_3_IQ,
             has_dest_IQ,is_branch_IQ,is_jump_IQ,is_jalr_IQ,is_load_IQ,is_store_IQ,
             valid_IQ,rd_0_IQ,rd_1_IQ,rd_2_IQ,rd_3_IQ,flush,pc_0_R, pc_1_R, pc_2_R, pc_3_R,pc_0_IQ, pc_1_IQ, pc_2_IQ, pc_3_IQ);

input clk,rst;
input [6:0] prs1_0_R,prs1_1_R,prs1_2_R,prs1_3_R;
input [6:0] prs2_0_R,prs2_1_R,prs2_2_R,prs2_3_R;
input [6:0] prd_0_R,prd_1_R,prd_2_R,prd_3_R;
input [6:0] old_prd_0_R,old_prd_1_R,old_prd_2_R,old_prd_3_R;
input [31:0] imm_out_0_R,imm_out_1_R,imm_out_2_R,imm_out_3_R;
input [6:0] func7_out_0_R,func7_out_1_R,func7_out_2_R,func7_out_3_R;
input [2:0] func3_out_0_R,func3_out_1_R,func3_out_2_R,func3_out_3_R;
input [6:0] opcode_out_0_R,opcode_out_1_R,opcode_out_2_R,opcode_out_3_R;
input [3:0] has_dest_out_R,is_branch_out_R,is_jump_out_R,is_jalr_out_R,is_load_out_R,is_store_out_R;
input [3:0] valid_out_R;
input stall_R;
input [4:0] rd_0_R,rd_1_R,rd_2_R,rd_3_R;
input flush;
input  [31:0] pc_0_R, pc_1_R, pc_2_R, pc_3_R;

output reg [31:0] pc_0_IQ, pc_1_IQ, pc_2_IQ, pc_3_IQ;
output reg [6:0] prs1_0_IQ,prs1_1_IQ,prs1_2_IQ,prs1_3_IQ;
output reg [6:0] prs2_0_IQ,prs2_1_IQ,prs2_2_IQ,prs2_3_IQ;
output reg [6:0] prd_0_IQ,prd_1_IQ,prd_2_IQ,prd_3_IQ;
output reg [6:0] old_prd_0_IQ,old_prd_1_IQ,old_prd_2_IQ,old_prd_3_IQ;
output reg [31:0] imm_0_IQ,imm_1_IQ,imm_2_IQ,imm_3_IQ;
output reg [6:0] func7_0_IQ,func7_1_IQ,func7_2_IQ,func7_3_IQ;
output reg [2:0] func3_0_IQ,func3_1_IQ,func3_2_IQ,func3_3_IQ;
output reg [6:0] opcode_0_IQ,opcode_1_IQ,opcode_2_IQ,opcode_3_IQ;
output reg [3:0] has_dest_IQ,is_branch_IQ,is_jump_IQ,is_jalr_IQ,is_load_IQ,is_store_IQ;
output reg [3:0] valid_IQ;
output reg [4:0] rd_0_IQ,rd_1_IQ,rd_2_IQ,rd_3_IQ;

always@(posedge clk or negedge rst)begin

if(!rst || flush)begin

{prs1_0_IQ,prs1_1_IQ,prs1_2_IQ,prs1_3_IQ} <= 28'd0;
{prs2_0_IQ,prs2_1_IQ,prs2_2_IQ,prs2_3_IQ} <= 28'd0;
{prd_0_IQ,prd_1_IQ,prd_2_IQ,prd_3_IQ} <= 28'd0;
{old_prd_0_IQ,old_prd_1_IQ,old_prd_2_IQ,old_prd_3_IQ} <= 28'd0;
{imm_0_IQ,imm_1_IQ,imm_2_IQ,imm_3_IQ} <= 128'd0;
{func7_0_IQ,func7_1_IQ,func7_2_IQ,func7_3_IQ} <= 28'd0;
{func3_0_IQ,func3_1_IQ,func3_2_IQ,func3_3_IQ} <= 12'd0;
{opcode_0_IQ,opcode_1_IQ,opcode_2_IQ,opcode_3_IQ} <= 28'd0;
{has_dest_IQ,is_branch_IQ,is_jump_IQ,is_jalr_IQ,is_load_IQ,is_store_IQ} <= 24'd0;
valid_IQ <= 4'd0;
{rd_0_IQ,rd_1_IQ,rd_2_IQ,rd_3_IQ} <= 20'd0;
{pc_0_IQ, pc_1_IQ, pc_2_IQ, pc_3_IQ} <= 128'd0;

end

else if(!stall_R)begin

prs1_0_IQ <= prs1_0_R;
prs1_1_IQ <= prs1_1_R;
prs1_2_IQ <= prs1_2_R;
prs1_3_IQ <= prs1_3_R;
prs2_0_IQ <= prs2_0_R;
prs2_1_IQ <= prs2_1_R;
prs2_2_IQ <= prs2_2_R;
prs2_3_IQ <= prs2_3_R;
prd_0_IQ <= prd_0_R;
prd_1_IQ <= prd_1_R;
prd_2_IQ <= prd_2_R;
prd_3_IQ <= prd_3_R;
old_prd_0_IQ <= old_prd_0_R;
old_prd_1_IQ <= old_prd_1_R;
old_prd_2_IQ <= old_prd_2_R;
old_prd_3_IQ <= old_prd_3_R;
imm_0_IQ <= imm_out_0_R;
imm_1_IQ <= imm_out_1_R;
imm_2_IQ <= imm_out_2_R;
imm_3_IQ <= imm_out_3_R;
func7_0_IQ <= func7_out_0_R;
func7_1_IQ <= func7_out_1_R;
func7_2_IQ <= func7_out_2_R;
func7_3_IQ <= func7_out_3_R;
func3_0_IQ <= func3_out_0_R;
func3_1_IQ <= func3_out_1_R;
func3_2_IQ <= func3_out_2_R;
func3_3_IQ <= func3_out_3_R;
opcode_0_IQ <= opcode_out_0_R;
opcode_1_IQ <= opcode_out_1_R;
opcode_2_IQ <= opcode_out_2_R;
opcode_3_IQ <= opcode_out_3_R;
has_dest_IQ <= has_dest_out_R;
is_branch_IQ <= is_branch_out_R;
is_jump_IQ <= is_jump_out_R;
is_jalr_IQ <= is_jalr_out_R;
is_load_IQ <= is_load_out_R;
is_store_IQ <= is_store_out_R;
valid_IQ <= valid_out_R;
rd_0_IQ <= rd_0_R;  
rd_1_IQ <= rd_1_R;  
rd_2_IQ <= rd_2_R;  
rd_3_IQ <= rd_3_R;
pc_0_IQ <= pc_0_R;
pc_1_IQ <= pc_1_R;
pc_2_IQ <= pc_2_R;
pc_3_IQ <= pc_3_R;

end

else valid_IQ <= 4'd0;

end

endmodule