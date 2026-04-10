module EX_WB(clk,rst,
             alu_result_0,alu_result_1,alu_result_2,alu_result_3,
             alu_prd_0,alu_prd_1,alu_prd_2,alu_prd_3,
             alu_has_dest_0,alu_has_dest_1,alu_has_dest_2,alu_has_dest_3,
             alu_valid_0,alu_valid_1,alu_valid_2,alu_valid_3,
             alu_branch_taken_0,alu_branch_taken_1,alu_branch_taken_2,alu_branch_taken_3,
             alu_is_branch_0,alu_is_branch_1,alu_is_branch_2,alu_is_branch_3,
             alu3_stalled,
             wb_result_0,wb_result_1,wb_result_2,wb_result_3,
             wb_prd_0,wb_prd_1,wb_prd_2,wb_prd_3,
             wb_has_dest_0,wb_has_dest_1,wb_has_dest_2,wb_has_dest_3,
             wb_valid_0,wb_valid_1,wb_valid_2,wb_valid_3,
             wb_branch_taken_0,wb_branch_taken_1,wb_branch_taken_2,wb_branch_taken_3,
             wb_is_branch_0,wb_is_branch_1,wb_is_branch_2,wb_is_branch_3,
             alu_pc_0, alu_pc_1, alu_pc_2, alu_pc_3,wb_pc_0, wb_pc_1, wb_pc_2, wb_pc_3);
input clk,rst;
input [31:0] alu_result_0,alu_result_1,alu_result_2,alu_result_3;
input [6:0]  alu_prd_0,alu_prd_1,alu_prd_2,alu_prd_3;
input        alu_has_dest_0,alu_has_dest_1,alu_has_dest_2,alu_has_dest_3;
input        alu_valid_0,alu_valid_1,alu_valid_2,alu_valid_3;
input        alu_branch_taken_0,alu_branch_taken_1,alu_branch_taken_2,alu_branch_taken_3;
input        alu_is_branch_0,alu_is_branch_1,alu_is_branch_2,alu_is_branch_3;
input        alu3_stalled;
input  [31:0] alu_pc_0, alu_pc_1, alu_pc_2, alu_pc_3;
output reg [31:0] wb_pc_0, wb_pc_1, wb_pc_2, wb_pc_3;
output reg [31:0] wb_result_0,wb_result_1,wb_result_2,wb_result_3;
output reg [6:0]  wb_prd_0,wb_prd_1,wb_prd_2,wb_prd_3;
output reg        wb_has_dest_0,wb_has_dest_1,wb_has_dest_2,wb_has_dest_3;
output reg        wb_valid_0,wb_valid_1,wb_valid_2,wb_valid_3;
output reg        wb_branch_taken_0,wb_branch_taken_1,wb_branch_taken_2,wb_branch_taken_3;
output reg        wb_is_branch_0,wb_is_branch_1,wb_is_branch_2,wb_is_branch_3;

always@(posedge clk or negedge rst)begin

if(!rst)begin
{wb_result_0,wb_result_1,wb_result_2,wb_result_3} <= 128'd0;
{wb_prd_0,wb_prd_1,wb_prd_2,wb_prd_3} <= 28'd0;
{wb_has_dest_0,wb_has_dest_1,wb_has_dest_2,wb_has_dest_3} <= 4'd0;
{wb_valid_0,wb_valid_1,wb_valid_2,wb_valid_3} <= 4'd0;
{wb_branch_taken_0,wb_branch_taken_1,wb_branch_taken_2,wb_branch_taken_3} <= 4'd0;
{wb_is_branch_0,wb_is_branch_1,wb_is_branch_2,wb_is_branch_3} <= 4'd0;
{wb_pc_0,wb_pc_1,wb_pc_2,wb_pc_3} <= 128'd0;
end

else begin
wb_result_0       <= alu_result_0;
wb_result_1       <= alu_result_1;
wb_result_2       <= alu_result_2;
wb_prd_0          <= alu_prd_0;
wb_prd_1          <= alu_prd_1;
wb_prd_2          <= alu_prd_2;
wb_has_dest_0     <= alu_has_dest_0;
wb_has_dest_1     <= alu_has_dest_1;
wb_has_dest_2     <= alu_has_dest_2;
wb_valid_0        <= alu_valid_0;
wb_valid_1        <= alu_valid_1;
wb_valid_2        <= alu_valid_2;
wb_branch_taken_0 <= alu_branch_taken_0;
wb_branch_taken_1 <= alu_branch_taken_1;
wb_branch_taken_2 <= alu_branch_taken_2;
wb_is_branch_0    <= alu_is_branch_0;
wb_is_branch_1    <= alu_is_branch_1;
wb_is_branch_2    <= alu_is_branch_2;
// slot 3: hold if CDB gave channel to LSQ this cycle
if(!alu3_stalled)begin
wb_result_3       <= alu_result_3;
wb_prd_3          <= alu_prd_3;
wb_has_dest_3     <= alu_has_dest_3;
wb_valid_3        <= alu_valid_3;
wb_branch_taken_3 <= alu_branch_taken_3;
wb_is_branch_3    <= alu_is_branch_3;
wb_pc_0 <= alu_pc_0;
wb_pc_1 <= alu_pc_1;
wb_pc_2 <= alu_pc_2;
wb_pc_3 <= alu_pc_3;
end

end

end

endmodule