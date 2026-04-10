module IF_ID(clk,rst,ins0_out_F,ins1_out_F,ins2_out_F,ins3_out_F,valid_out_F,ins0_out_D,ins1_out_D,ins2_out_D,ins3_out_D,valid_out_D,flush,
             pc_0_F, pc_1_F, pc_2_F, pc_3_F,pc_0_D, pc_1_D, pc_2_D, pc_3_D);

input clk,rst;

input [31:0] ins0_out_F,ins1_out_F,ins2_out_F,ins3_out_F;
input [3:0] valid_out_F;
input flush;
input  [31:0] pc_0_F,pc_1_F,pc_2_F,pc_3_F;

output reg [31:0] pc_0_D,pc_1_D,pc_2_D,pc_3_D;
output reg [31:0] ins0_out_D,ins1_out_D,ins2_out_D,ins3_out_D;
output reg [3:0] valid_out_D;

always@(posedge clk,negedge rst)begin

if(!rst || flush) {ins0_out_D,ins1_out_D,ins2_out_D,ins3_out_D,valid_out_D,pc_0_D,pc_1_D,pc_2_D,pc_3_D} <= 260'd0;

else begin

ins0_out_D <= ins0_out_F;
ins1_out_D <= ins1_out_F;
ins2_out_D <= ins2_out_F;
ins3_out_D <= ins3_out_F;
valid_out_D <= valid_out_F;

pc_0_D <= pc_0_F;
pc_1_D <= pc_1_F;
pc_2_D <= pc_2_F;
pc_3_D <= pc_3_F;

end

end

endmodule
