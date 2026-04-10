module RRF(clk,rst,commit_valid,
           commit_rd_0,commit_rd_1,commit_rd_2,commit_rd_3,
           commit_data_0,commit_data_1,commit_data_2,commit_data_3,
           rd_addr_0,rd_addr_1,rd_data_0,rd_data_1);

input clk,rst;
input [3:0] commit_valid;
input [4:0] commit_rd_0,commit_rd_1,commit_rd_2,commit_rd_3;
input [31:0] commit_data_0,commit_data_1,commit_data_2,commit_data_3;
input [4:0] rd_addr_0,rd_addr_1;
output [31:0] rd_data_0,rd_data_1;

reg [31:0] rrf [0:31];

integer i;

assign rd_data_0 = rrf[rd_addr_0];
assign rd_data_1 = rrf[rd_addr_1];

always@(posedge clk or negedge rst)begin

if(!rst)begin

for(i = 0; i < 32; i = i + 1) rrf[i] <= 32'd0;

end

else begin

if(commit_valid[0] && commit_rd_0 != 5'd0) rrf[commit_rd_0] <= commit_data_0;
if(commit_valid[1] && commit_rd_1 != 5'd0) rrf[commit_rd_1] <= commit_data_1;
if(commit_valid[2] && commit_rd_2 != 5'd0) rrf[commit_rd_2] <= commit_data_2;
if(commit_valid[3] && commit_rd_3 != 5'd0) rrf[commit_rd_3] <= commit_data_3;

end

end

endmodule