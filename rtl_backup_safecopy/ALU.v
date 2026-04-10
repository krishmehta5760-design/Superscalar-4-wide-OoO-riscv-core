module ALU(opcode,func3,func7,src1,src2,imm,valid_in,prd_in,has_dest_in,is_branch_in,is_jump_in,is_jalr_in,
           result,branch_taken,valid_out,prd_out,has_dest_out,is_branch_out,pc_in);

input [6:0] opcode;
input [2:0] func3;
input [6:0] func7;
input [31:0] src1,src2,imm;
input valid_in;
input [6:0] prd_in;
input has_dest_in,is_branch_in,is_jump_in,is_jalr_in;
input [31:0] pc_in;

output reg [31:0] result;
output reg branch_taken;
output valid_out;
output [6:0] prd_out;
output has_dest_out;
output is_branch_out;

assign is_branch_out = is_branch_in;
assign valid_out    = valid_in;
assign prd_out      = prd_in;
assign has_dest_out = has_dest_in;

always@(*)begin
result       = 32'd0;
branch_taken = 1'b0;

case(opcode)

7'b0110011: begin
case({func7,func3})
10'b0000000_000: result = src1 + src2;
10'b0100000_000: result = src1 - src2;
10'b0000000_001: result = src1 << src2[4:0];
10'b0000000_010: result = ($signed(src1) < $signed(src2)) ? 32'd1 : 32'd0;
10'b0000000_011: result = (src1 < src2) ? 32'd1 : 32'd0;
10'b0000000_100: result = src1 ^ src2;
10'b0000000_101: result = src1 >> src2[4:0];
10'b0100000_101: result = $signed(src1) >>> src2[4:0];
10'b0000000_110: result = src1 | src2;
10'b0000000_111: result = src1 & src2;
// 10'b0000001_000: result = src1 * src2; // Handled by MUL_Unit
// 10'b0000001_001: result = ($signed({{32{src1[31]}},src1}) * $signed({{32{src2[31]}},src2})) >> 32; // Handled by MUL_Unit
// 10'b0000001_010: result = ($signed({{32{src1[31]}},src1}) * {{32'd0},src2}) >> 32; // Handled by MUL_Unit
// 10'b0000001_011: result = ({32'd0,src1} * {32'd0,src2}) >> 32; // Handled by MUL_Unit
10'b0000001_100: result = (src2 == 0) ? 32'hffffffff : $signed(src1) / $signed(src2);
10'b0000001_101: result = (src2 == 0) ? 32'hffffffff : src1 / src2;
10'b0000001_110: result = (src2 == 0) ? src1 : $signed(src1) % $signed(src2);
10'b0000001_111: result = (src2 == 0) ? src1 : src1 % src2;
default: result = 32'd0;
endcase
end

7'b0010011: begin
case(func3)
3'b000: result = src1 + imm;
3'b010: result = ($signed(src1) < $signed(imm)) ? 32'd1 : 32'd0;
3'b011: result = (src1 < imm) ? 32'd1 : 32'd0;
3'b100: result = src1 ^ imm;
3'b110: result = src1 | imm;
3'b111: result = src1 & imm;
3'b001: result = src1 << imm[4:0];
3'b101: result = (func7[5]) ? ($signed(src1) >>> imm[4:0]) : (src1 >> imm[4:0]);
default: result = 32'd0;
endcase
end

7'b0110111: result = imm;

7'b1100011: begin
result = 32'd0;
case(func3)
3'b000: branch_taken = (src1 == src2);
3'b001: branch_taken = (src1 != src2);
3'b100: branch_taken = ($signed(src1) < $signed(src2));
3'b101: branch_taken = ($signed(src1) >= $signed(src2));
3'b110: branch_taken = (src1 < src2);
3'b111: branch_taken = (src1 >= src2);
default: branch_taken = 1'b0;
endcase
end

7'b1100111: begin // JALR
// In this core's architecture, ALU computes the target for branch/jump tracking,
// but for JAL/JALR it MUST write PC+4 to the destination register.
result = pc_in + 4;
end

7'b1101111: begin // JAL
result = pc_in + 4;
end

default: result = 32'd0;

endcase
end

endmodule