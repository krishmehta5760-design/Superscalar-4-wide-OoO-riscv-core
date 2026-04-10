module RAT(clk,rst,rs1_0,rs1_1,rs1_2,rs1_3,rs2_0,rs2_1,rs2_2,rs2_3,rd_0,rd_1,rd_2,rd_3,update_valid,new_rd_0,new_rd_1,new_rd_2,new_rd_3,new_prd_0,new_prd_1,new_prd_2,new_prd_3,prs1_0,prs1_1,prs1_2,prs1_3,prs2_0,prs2_1,prs2_2,prs2_3,old_prd_0,old_prd_1,old_prd_2,old_prd_3,flush_valid,flush_rd,flush_prd);

input clk,rst;

input [4:0] rs1_0,rs1_1,rs1_2,rs1_3;
input [4:0] rs2_0,rs2_1,rs2_2,rs2_3;
input [4:0] rd_0,rd_1,rd_2,rd_3;

input [3:0] update_valid;
input [4:0] new_rd_0,new_rd_1,new_rd_2,new_rd_3;
input [6:0] new_prd_0,new_prd_1,new_prd_2,new_prd_3;
input flush_valid;
input [4:0] flush_rd;
input [6:0] flush_prd;

output reg [6:0] prs1_0,prs1_1,prs1_2,prs1_3;
output reg [6:0] prs2_0,prs2_1,prs2_2,prs2_3;
output reg [6:0] old_prd_0,old_prd_1,old_prd_2,old_prd_3;

reg [6:0] RAT_main [0:31];
reg [6:0] RAT_temp [0:31];

integer i;

always@(*)begin

for (i = 0; i < 32; i = i + 1) begin
RAT_temp[i] = RAT_main[i];
end

//INSTRUCTION 0

prs1_0 = (rs1_0!=5'd0) ? RAT_temp[rs1_0] : 7'd0; 
prs2_0 = (rs2_0!=5'd0) ? RAT_temp[rs2_0] : 7'd0; 
old_prd_0 = ((update_valid[0]) && (rd_0!=5'd0)) ? RAT_temp[rd_0] : 7'd0;

if((update_valid[0]) && (new_rd_0!=5'd0))begin 

RAT_temp[new_rd_0] = new_prd_0;

end

//INSTRUCTION 1

prs1_1 = (rs1_1!=5'd0) ? RAT_temp[rs1_1] : 7'd0; 
prs2_1 = (rs2_1!=5'd0) ? RAT_temp[rs2_1] : 7'd0; 
old_prd_1 = ((update_valid[1]) && (rd_1!=5'd0)) ? RAT_temp[rd_1] : 7'd0;

if((update_valid[1]) && (new_rd_1!=5'd0))begin

RAT_temp[new_rd_1] = new_prd_1;

end

//INSTRUCTION 2

prs1_2 = (rs1_2!=5'd0) ? RAT_temp[rs1_2] : 7'd0; 
prs2_2 = (rs2_2!=5'd0) ? RAT_temp[rs2_2] : 7'd0; 
old_prd_2 = ((update_valid[2]) && (rd_2!=5'd0)) ? RAT_temp[rd_2] : 7'd0;

if((update_valid[2]) && (new_rd_2!=5'd0))begin

RAT_temp[new_rd_2] = new_prd_2;

end

//INSTRUCTION 3

prs1_3 = (rs1_3!=5'd0) ? RAT_temp[rs1_3] : 7'd0; 
prs2_3 = (rs2_3!=5'd0) ? RAT_temp[rs2_3] : 7'd0; 
old_prd_3 = ((update_valid[3]) && (rd_3!=5'd0)) ? RAT_temp[rd_3] : 7'd0;

if((update_valid[3]) && (new_rd_3!=5'd0))begin

RAT_temp[new_rd_3] = new_prd_3;

end 

end

always@(posedge clk,negedge rst)begin

if(!rst)begin

for(i = 0; i < 32; i = i + 1)begin
RAT_main[i] <= i[6:0];
end

end

else begin

if(flush_valid && flush_rd != 5'd0)begin // restore one entry per cycle from ROB walkback
RAT_main[flush_rd] <= flush_prd;
end 

else begin

if((update_valid[0]) && (new_rd_0!=5'd0))begin
RAT_main[new_rd_0] <= new_prd_0;
end

if((update_valid[1]) && (new_rd_1!=5'd0))begin
RAT_main[new_rd_1] <= new_prd_1;
end

if((update_valid[2]) && (new_rd_2!=5'd0))begin
RAT_main[new_rd_2] <= new_prd_2;
end

if((update_valid[3]) && (new_rd_3!=5'd0))begin
RAT_main[new_rd_3] <= new_prd_3;

end

end

end

end

endmodule
