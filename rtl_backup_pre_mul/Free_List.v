module Free_List(clk,rst,alloc_req,alloc_preg_0,alloc_preg_1,alloc_preg_2,alloc_preg_3,stall,rob_free_valid,rob_free_preg_0,rob_free_preg_1,rob_free_preg_2,rob_free_preg_3);

input clk,rst;

input [3:0] alloc_req;
output reg [6:0] alloc_preg_0;
output reg [6:0] alloc_preg_1;
output reg [6:0] alloc_preg_2;
output reg [6:0] alloc_preg_3;

output reg stall;

input [3:0] rob_free_valid;
input [6:0] rob_free_preg_0;
input [6:0] rob_free_preg_1;
input [6:0] rob_free_preg_2;
input [6:0] rob_free_preg_3;

reg [6:0] free_list [0:95];
reg [6:0] fl_head;
reg [6:0] fl_tail;
reg [6:0] fl_count;

wire [2:0] total_req;
wire [2:0] total_free;

assign total_req = alloc_req[0] + alloc_req[1] + alloc_req[2] + alloc_req[3];

wire is_free_0 = rob_free_valid[0] && (rob_free_preg_0 >= 32);
wire is_free_1 = rob_free_valid[1] && (rob_free_preg_1 >= 32);
wire is_free_2 = rob_free_valid[2] && (rob_free_preg_2 >= 32);
wire is_free_3 = rob_free_valid[3] && (rob_free_preg_3 >= 32);

assign total_free = is_free_0 + is_free_1 + is_free_2 + is_free_3;

integer i;
integer offset;

always@(*)begin

stall = (fl_count < total_req);

offset = 0;

alloc_preg_0 = 0;
alloc_preg_1 = 0;
alloc_preg_2 = 0;
alloc_preg_3 = 0;

if (!stall && alloc_req[0]) begin
alloc_preg_0 = free_list[(fl_head + offset) % 96];
offset = offset + 1;
end

if (!stall && alloc_req[1]) begin
alloc_preg_1 = free_list[(fl_head + offset) % 96];
offset = offset + 1;
end

if (!stall && alloc_req[2]) begin
alloc_preg_2 = free_list[(fl_head + offset) % 96];
offset = offset + 1;
end

if (!stall && alloc_req[3]) begin
alloc_preg_3 = free_list[(fl_head + offset) % 96];
end

end

always@(posedge clk,negedge rst)begin

if(!rst)begin

for(i = 0; i < 96; i = i + 1)begin
free_list[i] <= (7'b0100000 + i[6:0]);
end

fl_head <= 7'd0;
fl_tail <= 7'd0;
fl_count <= 7'd96;

end

else begin

fl_head <= (!stall) ? ((fl_head + total_req) % 96) : fl_head;
fl_tail <= (fl_tail + total_free) % 96;
fl_count <= fl_count - ((!stall) ? total_req : 0) + total_free;

if(is_free_0) free_list[fl_tail] <= rob_free_preg_0;
if(is_free_1) free_list[(fl_tail + is_free_0) % 96] <= rob_free_preg_1;
if(is_free_2) free_list[(fl_tail + is_free_0 + is_free_1) % 96] <= rob_free_preg_2;
if(is_free_3) free_list[(fl_tail + is_free_0 + is_free_1 + is_free_2) % 96] <= rob_free_preg_3;

end

end

endmodule
