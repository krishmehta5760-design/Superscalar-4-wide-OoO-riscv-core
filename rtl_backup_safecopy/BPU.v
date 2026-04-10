module BPU(clk,rst,
           wb_valid_0,wb_valid_1,wb_valid_2,wb_valid_3,
           wb_is_branch_0,wb_is_branch_1,wb_is_branch_2,wb_is_branch_3,
           wb_branch_taken_0,wb_branch_taken_1,wb_branch_taken_2,wb_branch_taken_3,
           predicted_taken,
           mispredicted,flush,wb_pc_0, wb_pc_1, wb_pc_2, wb_pc_3,correct_pc);
input clk,rst;
input wb_valid_0,wb_valid_1,wb_valid_2,wb_valid_3;
input wb_is_branch_0,wb_is_branch_1,wb_is_branch_2,wb_is_branch_3;
input wb_branch_taken_0,wb_branch_taken_1,wb_branch_taken_2,wb_branch_taken_3;
input predicted_taken;
input  [31:0] wb_pc_0, wb_pc_1, wb_pc_2, wb_pc_3;
output reg [31:0] correct_pc;
output reg mispredicted;
output reg flush;
always@(posedge clk or negedge rst)begin
if(!rst)begin
mispredicted <= 1'b0;
flush        <= 1'b0;
correct_pc <= 0;
end
else begin
mispredicted <= 1'b0;
flush        <= 1'b0;
correct_pc <= 0;
if(wb_valid_0 && wb_is_branch_0 && (wb_branch_taken_0 != predicted_taken))

begin mispredicted<=1; flush<=1; correct_pc <= wb_pc_0 + 4; end
else if (wb_valid_1 && wb_is_branch_1 && (wb_branch_taken_1 != predicted_taken))
begin mispredicted<=1; flush<=1; correct_pc <= wb_pc_1 + 4; end
else if (wb_valid_2 && wb_is_branch_2 && (wb_branch_taken_2 != predicted_taken))
begin mispredicted<=1; flush<=1; correct_pc <= wb_pc_2 + 4; end
else if (wb_valid_3 && wb_is_branch_3 && (wb_branch_taken_3 != predicted_taken))
begin mispredicted<=1; flush<=1; correct_pc <= wb_pc_3 + 4; end
            
end
end
endmodule