module Rename_Dispatch(clk,rst,rs1_0,rs1_1,rs1_2,rs1_3,rs2_0,rs2_1,rs2_2,rs2_3,rd_0,rd_1,rd_2,rd_3,imm_0,imm_1,imm_2,imm_3,func7_0,func7_1,func7_2,func7_3,func3_0,func3_1,func3_2,func3_3,opcode_0,opcode_1,opcode_2,opcode_3,has_dest,is_branch,is_jump,is_jalr,is_load,is_store,valid_in,
                       rat_rs1_0,rat_rs1_1,rat_rs1_2,rat_rs1_3,rat_rs2_0,rat_rs2_1,rat_rs2_2,rat_rs2_3,rat_rd_0,rat_rd_1,rat_rd_2,rat_rd_3,rat_prs1_0,rat_prs1_1,rat_prs1_2,rat_prs1_3,rat_prs2_0,rat_prs2_1,rat_prs2_2,rat_prs2_3,rat_old_prd_0,rat_old_prd_1,rat_old_prd_2,rat_old_prd_3,rat_update_valid,rat_new_rd_0,rat_new_rd_1,rat_new_rd_2,rat_new_rd_3,rat_new_prd_0,rat_new_prd_1,rat_new_prd_2,rat_new_prd_3,
                       fl_alloc_req,fl_alloc_preg_0,fl_alloc_preg_1,fl_alloc_preg_2,fl_alloc_preg_3,fl_stall,
                       prs1_0,prs1_1,prs1_2,prs1_3,prs2_0,prs2_1,prs2_2,prs2_3,prd_0,prd_1,prd_2,prd_3,old_prd_0,old_prd_1,old_prd_2,old_prd_3,imm_out_0,imm_out_1,imm_out_2,imm_out_3,func7_out_0,func7_out_1,func7_out_2,func7_out_3,func3_out_0,func3_out_1,func3_out_2,func3_out_3,opcode_out_0,opcode_out_1,opcode_out_2,opcode_out_3,has_dest_out,is_branch_out,is_jump_out,is_jalr_out,is_load_out,is_store_out,valid_out,
                       stall,iq_queue_full,rd_out_0,rd_out_1,rd_out_2,rd_out_3,rob_almost_full_in,lsq_full,squashing,pc_0_in, pc_1_in, pc_2_in, pc_3_in,pc_0_out, pc_1_out, pc_2_out, pc_3_out);
                       
input clk,rst;

input [4:0] rs1_0,rs1_1,rs1_2,rs1_3;
input [4:0] rs2_0,rs2_1,rs2_2,rs2_3;
input [4:0] rd_0,rd_1,rd_2,rd_3;
input [31:0] imm_0,imm_1,imm_2,imm_3;
input [6:0] func7_0,func7_1,func7_2,func7_3;
input [2:0] func3_0,func3_1,func3_2,func3_3;
input [6:0] opcode_0,opcode_1,opcode_2,opcode_3;
input [3:0] has_dest,is_branch,is_jump,is_jalr,is_load,is_store;
input [3:0] valid_in;
input rob_almost_full_in;
input squashing;

output [4:0] rat_rs1_0,rat_rs1_1,rat_rs1_2,rat_rs1_3;
output [4:0] rat_rs2_0,rat_rs2_1,rat_rs2_2,rat_rs2_3;
output [4:0] rat_rd_0,rat_rd_1,rat_rd_2,rat_rd_3;
input [6:0] rat_prs1_0,rat_prs1_1,rat_prs1_2,rat_prs1_3;
input [6:0] rat_prs2_0,rat_prs2_1,rat_prs2_2,rat_prs2_3;
input [6:0] rat_old_prd_0,rat_old_prd_1,rat_old_prd_2,rat_old_prd_3;
output [4:0] rat_new_rd_0,rat_new_rd_1,rat_new_rd_2,rat_new_rd_3;
output [6:0] rat_new_prd_0,rat_new_prd_1,rat_new_prd_2,rat_new_prd_3;

output [3:0] fl_alloc_req;
input [6:0] fl_alloc_preg_0;
input [6:0] fl_alloc_preg_1;
input [6:0] fl_alloc_preg_2;
input [6:0] fl_alloc_preg_3;
input fl_stall,iq_queue_full,lsq_full;
input  [31:0] pc_0_in, pc_1_in, pc_2_in, pc_3_in;

output reg [31:0] pc_0_out, pc_1_out, pc_2_out, pc_3_out;
output reg [6:0] prs1_0,prs1_1,prs1_2,prs1_3;
output reg [6:0] prs2_0,prs2_1,prs2_2,prs2_3;
output reg [6:0] prd_0,prd_1,prd_2,prd_3;
output reg [6:0] old_prd_0,old_prd_1,old_prd_2,old_prd_3;
output reg [31:0] imm_out_0,imm_out_1,imm_out_2,imm_out_3;
output reg [6:0] func7_out_0,func7_out_1,func7_out_2,func7_out_3;
output reg [2:0] func3_out_0,func3_out_1,func3_out_2,func3_out_3;
output reg [6:0] opcode_out_0,opcode_out_1,opcode_out_2,opcode_out_3;
output reg [3:0] has_dest_out,is_branch_out,is_jump_out,is_jalr_out,is_load_out,is_store_out;
output reg [3:0] valid_out;
output reg [4:0] rd_out_0,rd_out_1,rd_out_2,rd_out_3;
output reg [3:0] rat_update_valid;

output reg stall;

//Rename-RAT  for combinational intracycle 
assign rat_rs1_0 = rs1_0;
assign rat_rs1_1 = rs1_1;
assign rat_rs1_2 = rs1_2;
assign rat_rs1_3 = rs1_3;

assign rat_rs2_0 = rs2_0;
assign rat_rs2_1 = rs2_1;
assign rat_rs2_2 = rs2_2;
assign rat_rs2_3 = rs2_3;

assign rat_rd_0 = rd_0;
assign rat_rd_1 = rd_1;
assign rat_rd_2 = rd_2;
assign rat_rd_3 = rd_3;

//Rename-RAT for sequential
assign rat_new_rd_0 = rd_0;
assign rat_new_rd_1 = rd_1;
assign rat_new_rd_2 = rd_2;
assign rat_new_rd_3 = rd_3;

assign rat_new_prd_0 = fl_alloc_preg_0;
assign rat_new_prd_1 = fl_alloc_preg_1;
assign rat_new_prd_2 = fl_alloc_preg_2;
assign rat_new_prd_3 = fl_alloc_preg_3;

//Rename-FreeList
assign fl_alloc_req[0] = valid_in[0] && has_dest[0] && (rd_0 != 5'd0) && !stall;
assign fl_alloc_req[1] = valid_in[1] && has_dest[1] && (rd_1 != 5'd0) && !stall;
assign fl_alloc_req[2] = valid_in[2] && has_dest[2] && (rd_2 != 5'd0) && !stall;
assign fl_alloc_req[3] = valid_in[3] && has_dest[3] && (rd_3 != 5'd0) && !stall;

always@(*)begin

stall = fl_stall || iq_queue_full || rob_almost_full_in || lsq_full || squashing;
rat_update_valid = stall ? 4'd0 : fl_alloc_req;

end

always@(posedge clk,negedge rst)begin

if(!rst) begin

{prs1_0, prs1_1, prs1_2, prs1_3} <= 28'd0;
{prs2_0, prs2_1, prs2_2, prs2_3} <= 28'd0;
{prd_0, prd_1, prd_2, prd_3} <= 28'd0;
{old_prd_0, old_prd_1, old_prd_2, old_prd_3} <= 28'd0;
{imm_out_0, imm_out_1, imm_out_2, imm_out_3} <= 128'd0;
{func7_out_0, func7_out_1, func7_out_2, func7_out_3} <= 28'd0;
{func3_out_0, func3_out_1, func3_out_2, func3_out_3} <= 12'd0;
{opcode_out_0, opcode_out_1, opcode_out_2, opcode_out_3} <= 28'd0;
{has_dest_out, is_branch_out, is_jump_out, is_jalr_out, is_load_out, is_store_out} <= 24'd0;
valid_out <= 4'd0;
{rd_out_0,rd_out_1,rd_out_2,rd_out_3} <= 20'd0;

end

else if(!stall) begin

prs1_0 <= rat_prs1_0;
prs1_1 <= rat_prs1_1;
prs1_2 <= rat_prs1_2;
prs1_3 <= rat_prs1_3;

prs2_0 <= rat_prs2_0;
prs2_1 <= rat_prs2_1;
prs2_2 <= rat_prs2_2;
prs2_3 <= rat_prs2_3;

prd_0 <= fl_alloc_preg_0;
prd_1 <= fl_alloc_preg_1;
prd_2 <= fl_alloc_preg_2;
prd_3 <= fl_alloc_preg_3;

old_prd_0 <= rat_old_prd_0;
old_prd_1 <= rat_old_prd_1;
old_prd_2 <= rat_old_prd_2;
old_prd_3 <= rat_old_prd_3;

imm_out_0 <= imm_0;
imm_out_1 <= imm_1;
imm_out_2 <= imm_2;
imm_out_3 <= imm_3;

func7_out_0 <= func7_0;
func7_out_1 <= func7_1;
func7_out_2 <= func7_2;
func7_out_3 <= func7_3;

func3_out_0 <= func3_0;
func3_out_1 <= func3_1;
func3_out_2 <= func3_2;
func3_out_3 <= func3_3;

opcode_out_0 <= opcode_0;
opcode_out_1 <= opcode_1;
opcode_out_2 <= opcode_2;
opcode_out_3 <= opcode_3;

has_dest_out <= has_dest;
is_branch_out <= is_branch;
is_jump_out <= is_jump;
is_jalr_out <= is_jalr;
is_load_out <= is_load;
is_store_out <= is_store;

valid_out <= valid_in;

rd_out_0 <= rd_0;  
rd_out_1 <= rd_1;  
rd_out_2 <= rd_2;  
rd_out_3 <= rd_3;  

pc_0_out <= pc_0_in;
pc_1_out <= pc_1_in;
pc_2_out <= pc_2_in;
pc_3_out <= pc_3_in;

end

else valid_out <= 4'd0;

end

endmodule
