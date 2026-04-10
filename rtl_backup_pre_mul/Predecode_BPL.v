module Predecode_BPL(pc,ins0,ins1,ins2,ins3,IN0,IN1,IN2,IN3,pc_out,valid,pc_0, pc_1, pc_2, pc_3);
input [31:0] pc;
input [31:0] ins0,ins1,ins2,ins3;
output reg [31:0] IN0,IN1,IN2,IN3;
output reg [31:0] pc_out;
output reg [3:0] valid;
output reg [31:0] pc_0, pc_1, pc_2, pc_3;

wire [6:0] op0,op1,op2,op3;
wire branch0,branch1,branch2,branch3;
wire jump0,jump1,jump2,jump3;
wire jalr0,jalr1,jalr2,jalr3;


assign op0 = ins0[6:0];
assign op1 = ins1[6:0];
assign op2 = ins2[6:0];
assign op3 = ins3[6:0];

assign branch0 = (op0 == 7'b1100011);
assign branch1 = (op1 == 7'b1100011);
assign branch2 = (op2 == 7'b1100011);
assign branch3 = (op3 == 7'b1100011);

assign jump0 = (op0 == 7'b1101111);
assign jump1 = (op1 == 7'b1101111);
assign jump2 = (op2 == 7'b1101111);
assign jump3 = (op3 == 7'b1101111);

assign jalr0 = (op0 == 7'b1100111);
assign jalr1 = (op1 == 7'b1100111);
assign jalr2 = (op2 == 7'b1100111);
assign jalr3 = (op3 == 7'b1100111);

function [31:0] branch_target;
input [31:0] pc;
input [31:0] inst;
reg [12:0] imm;
begin

imm = {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
branch_target = pc + {{19{imm[12]}}, imm};

end
endfunction

function [31:0] jal_target;
input [31:0] pc;
input [31:0] inst;
reg [20:0] imm;
begin

imm = {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
jal_target = pc + {{11{imm[20]}}, imm};

end
endfunction

wire [31:0] br_tgt0,br_tgt1,br_tgt2,br_tgt3;
assign br_tgt0 = branch_target(pc, ins0);
assign br_tgt1 = branch_target(pc+4, ins1);
assign br_tgt2 = branch_target(pc+8, ins2);
assign br_tgt3 = branch_target(pc+12, ins3);

wire [31:0] jal_tgt0,jal_tgt1,jal_tgt2,jal_tgt3;
assign jal_tgt0 = jal_target(pc, ins0);
assign jal_tgt1 = jal_target(pc+4, ins1);
assign jal_tgt2 = jal_target(pc+8, ins2);
assign jal_tgt3 = jal_target(pc+12, ins3);

wire [31:0] jalr_tgt0,jalr_tgt1,jalr_tgt2,jalr_tgt3;

always@(*)begin

if((branch0 || jump0 || jalr0))begin

pc_out = (branch0 ? br_tgt0 : (jump0 ? jal_tgt0 : jalr_tgt0)); 
valid = 4'b0001;

end

else if((branch1 || jump1 || jalr1))begin

pc_out = (branch1 ? br_tgt1 : (jump1 ? jal_tgt1 : jalr_tgt1)); 
valid = 4'b0011;

end

else if((branch2 || jump2 || jalr2))begin

pc_out = (branch2 ? br_tgt2 : (jump2 ? jal_tgt2 : jalr_tgt2)); 
valid = 4'b0111;

end

else if((branch3 || jump3 || jalr3))begin

pc_out = (branch3 ? br_tgt3 : (jump3 ? jal_tgt3 : jalr_tgt3)); 
valid = 4'b1111;

end

else begin

pc_out = pc+16;
valid = 4'b1111;

end

end

always@(*)begin

IN0 = ins0;
IN1 = ins1;
IN2 = ins2;
IN3 = ins3;

pc_0 = pc;
pc_1 = pc + 4;
pc_2 = pc + 8;
pc_3 = pc + 12;

end

endmodule
