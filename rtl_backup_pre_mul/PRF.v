module PRF(clk,rst,rd_prs1_0, rd_prs1_1, rd_prs1_2, rd_prs1_3,rd_prs2_0, rd_prs2_1, rd_prs2_2, rd_prs2_3,rd_data_prs1_0, rd_data_prs1_1, rd_data_prs1_2, rd_data_prs1_3,rd_data_prs2_0, rd_data_prs2_1, rd_data_prs2_2, rd_data_prs2_3,alloc_valid,alloc_prd_0, alloc_prd_1, alloc_prd_2, alloc_prd_3,
           cdb_valid,cdb_tag_0,  cdb_tag_1,  cdb_tag_2,  cdb_tag_3,cdb_data_0, cdb_data_1, cdb_data_2, cdb_data_3,prf_ready,commit_prd_0,commit_prd_1,commit_prd_2,commit_prd_3,commit_data_0,commit_data_1,commit_data_2,commit_data_3,
           lsq_rd_prs1_0,lsq_rd_prs1_1,lsq_rd_prs1_2,lsq_rd_prs1_3,lsq_rd_prs2_0,lsq_rd_prs2_1,lsq_rd_prs2_2,lsq_rd_prs2_3,lsq_data_prs1_0,lsq_data_prs1_1,lsq_data_prs1_2,lsq_data_prs1_3,lsq_data_prs2_0,lsq_data_prs2_1,lsq_data_prs2_2,lsq_data_prs2_3,
           exec_rd_prs1_0,exec_rd_prs1_1,exec_rd_prs1_2,exec_rd_prs1_3,exec_rd_prs2_0,exec_rd_prs2_1,exec_rd_prs2_2,exec_rd_prs2_3,exec_data_prs1_0,exec_data_prs1_1,exec_data_prs1_2,exec_data_prs1_3,exec_data_prs2_0,exec_data_prs2_1,exec_data_prs2_2,exec_data_prs2_3);

input clk;
input rst;

input [6:0] lsq_rd_prs1_0,lsq_rd_prs1_1,lsq_rd_prs1_2,lsq_rd_prs1_3;
input [6:0] lsq_rd_prs2_0,lsq_rd_prs2_1,lsq_rd_prs2_2,lsq_rd_prs2_3;
output [31:0] lsq_data_prs1_0,lsq_data_prs1_1,lsq_data_prs1_2,lsq_data_prs1_3;
output [31:0] lsq_data_prs2_0,lsq_data_prs2_1,lsq_data_prs2_2,lsq_data_prs2_3;

input [6:0] exec_rd_prs1_0,exec_rd_prs1_1,exec_rd_prs1_2,exec_rd_prs1_3;
input [6:0] exec_rd_prs2_0,exec_rd_prs2_1,exec_rd_prs2_2,exec_rd_prs2_3;
output [31:0] exec_data_prs1_0,exec_data_prs1_1,exec_data_prs1_2,exec_data_prs1_3;
output [31:0] exec_data_prs2_0,exec_data_prs2_1,exec_data_prs2_2,exec_data_prs2_3;

input [6:0]  rd_prs1_0, rd_prs1_1, rd_prs1_2, rd_prs1_3;
input [6:0]  rd_prs2_0, rd_prs2_1, rd_prs2_2, rd_prs2_3;
output [31:0] rd_data_prs1_0, rd_data_prs1_1, rd_data_prs1_2, rd_data_prs1_3;
output [31:0] rd_data_prs2_0, rd_data_prs2_1, rd_data_prs2_2, rd_data_prs2_3;

input [3:0] alloc_valid;
input [6:0] alloc_prd_0, alloc_prd_1, alloc_prd_2, alloc_prd_3;

input [3:0] cdb_valid;
input [6:0] cdb_tag_0,  cdb_tag_1,  cdb_tag_2,  cdb_tag_3;
input [31:0] cdb_data_0, cdb_data_1, cdb_data_2, cdb_data_3;

input  [6:0]  commit_prd_0, commit_prd_1, commit_prd_2, commit_prd_3;
output [31:0] commit_data_0, commit_data_1, commit_data_2, commit_data_3;

output [127:0] prf_ready;

reg [31:0] prf_data [0:127];
reg prf_rdy [0:127];

integer i;

assign lsq_data_prs1_0 = (lsq_rd_prs1_0 == 7'd0) ? 32'd0 : prf_data[lsq_rd_prs1_0];
assign lsq_data_prs1_1 = (lsq_rd_prs1_1 == 7'd0) ? 32'd0 : prf_data[lsq_rd_prs1_1];
assign lsq_data_prs1_2 = (lsq_rd_prs1_2 == 7'd0) ? 32'd0 : prf_data[lsq_rd_prs1_2];
assign lsq_data_prs1_3 = (lsq_rd_prs1_3 == 7'd0) ? 32'd0 : prf_data[lsq_rd_prs1_3];
assign lsq_data_prs2_0 = (lsq_rd_prs2_0 == 7'd0) ? 32'd0 : prf_data[lsq_rd_prs2_0];
assign lsq_data_prs2_1 = (lsq_rd_prs2_1 == 7'd0) ? 32'd0 : prf_data[lsq_rd_prs2_1];
assign lsq_data_prs2_2 = (lsq_rd_prs2_2 == 7'd0) ? 32'd0 : prf_data[lsq_rd_prs2_2];
assign lsq_data_prs2_3 = (lsq_rd_prs2_3 == 7'd0) ? 32'd0 : prf_data[lsq_rd_prs2_3];

assign commit_data_0 = (commit_prd_0 == 7'd0) ? 32'd0 : prf_data[commit_prd_0];
assign commit_data_1 = (commit_prd_1 == 7'd0) ? 32'd0 : prf_data[commit_prd_1];
assign commit_data_2 = (commit_prd_2 == 7'd0) ? 32'd0 : prf_data[commit_prd_2];
assign commit_data_3 = (commit_prd_3 == 7'd0) ? 32'd0 : prf_data[commit_prd_3];

assign rd_data_prs1_0 = (rd_prs1_0 == 7'd0) ? 32'd0 : prf_data[rd_prs1_0];//these are purely combinational so even though data might not be computed yet, it is always wired to rd_data_prs
assign rd_data_prs1_1 = (rd_prs1_1 == 7'd0) ? 32'd0 : prf_data[rd_prs1_1];//these are purely combinational so even though data might not be computed yet, it is always wired to rd_data_prs
assign rd_data_prs1_2 = (rd_prs1_2 == 7'd0) ? 32'd0 : prf_data[rd_prs1_2];//these are purely combinational so even though data might not be computed yet, it is always wired to rd_data_prs
assign rd_data_prs1_3 = (rd_prs1_3 == 7'd0) ? 32'd0 : prf_data[rd_prs1_3];//these are purely combinational so even though data might not be computed yet, it is always wired to rd_data_prs

assign rd_data_prs2_0 = (rd_prs2_0 == 7'd0) ? 32'd0 : prf_data[rd_prs2_0];//these are purely combinational so even though data might not be computed yet, it is always wired to rd_data_prs
assign rd_data_prs2_1 = (rd_prs2_1 == 7'd0) ? 32'd0 : prf_data[rd_prs2_1];//these are purely combinational so even though data might not be computed yet, it is always wired to rd_data_prs
assign rd_data_prs2_2 = (rd_prs2_2 == 7'd0) ? 32'd0 : prf_data[rd_prs2_2];//these are purely combinational so even though data might not be computed yet, it is always wired to rd_data_prs
assign rd_data_prs2_3 = (rd_prs2_3 == 7'd0) ? 32'd0 : prf_data[rd_prs2_3];//these are purely combinational so even though data might not be computed yet, it is always wired to rd_data_prs

assign exec_data_prs1_0 = (exec_rd_prs1_0 == 7'd0) ? 32'd0 : prf_data[exec_rd_prs1_0];
assign exec_data_prs1_1 = (exec_rd_prs1_1 == 7'd0) ? 32'd0 : prf_data[exec_rd_prs1_1];
assign exec_data_prs1_2 = (exec_rd_prs1_2 == 7'd0) ? 32'd0 : prf_data[exec_rd_prs1_2];
assign exec_data_prs1_3 = (exec_rd_prs1_3 == 7'd0) ? 32'd0 : prf_data[exec_rd_prs1_3];

assign exec_data_prs2_0 = (exec_rd_prs2_0 == 7'd0) ? 32'd0 : prf_data[exec_rd_prs2_0];
assign exec_data_prs2_1 = (exec_rd_prs2_1 == 7'd0) ? 32'd0 : prf_data[exec_rd_prs2_1];
assign exec_data_prs2_2 = (exec_rd_prs2_2 == 7'd0) ? 32'd0 : prf_data[exec_rd_prs2_2];
assign exec_data_prs2_3 = (exec_rd_prs2_3 == 7'd0) ? 32'd0 : prf_data[exec_rd_prs2_3];

genvar g;

generate

for(g = 0; g < 128; g = g + 1)begin

assign prf_ready[g] = (g == 0) ? 1'b1 : prf_rdy[g];

end
    
endgenerate

always@(posedge clk or negedge rst)begin

if(!rst)begin

for(i = 0; i < 128; i = i + 1)begin

prf_data[i] <= 32'd0;
prf_rdy[i]  <= 1'b1;
    
end

end 

else begin
//checks if new preg is assigned to dest reg by free list...if yes then it will be marked as not ready
if(alloc_valid[0] && alloc_prd_0 != 7'd0) prf_rdy[alloc_prd_0] <= 1'b0;

if(alloc_valid[1] && alloc_prd_1 != 7'd0) prf_rdy[alloc_prd_1] <= 1'b0;

if(alloc_valid[2] && alloc_prd_2 != 7'd0) prf_rdy[alloc_prd_2] <= 1'b0;

if(alloc_valid[3] && alloc_prd_3 != 7'd0) prf_rdy[alloc_prd_3] <= 1'b0;
//checks all 4 cdb if they broadcasted any data 
if(cdb_valid[0] && cdb_tag_0 != 7'd0)begin

prf_data[cdb_tag_0] <= cdb_data_0;
prf_rdy[cdb_tag_0] <= 1'b1;
    
end

if(cdb_valid[1] && cdb_tag_1 != 7'd0)begin

prf_data[cdb_tag_1] <= cdb_data_1;
prf_rdy[cdb_tag_1] <= 1'b1;
    
end

if(cdb_valid[2] && cdb_tag_2 != 7'd0)begin

prf_data[cdb_tag_2] <= cdb_data_2;
prf_rdy[cdb_tag_2] <= 1'b1;
    
end

if(cdb_valid[3] && cdb_tag_3 != 7'd0)begin

prf_data[cdb_tag_3] <= cdb_data_3;
prf_rdy[cdb_tag_3] <= 1'b1;
    
end

end
    
end

endmodule