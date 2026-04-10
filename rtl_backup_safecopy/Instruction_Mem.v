module Instruction_Mem(rst,pc,ins0,ins1,ins2,ins3);
input rst;
input [31:0] pc;
output reg [31:0] ins0;
output reg [31:0] ins1;
output reg [31:0] ins2;
output reg [31:0] ins3;
reg [31:0] inst_mem [0:255];

initial begin

$readmemh("program.mem", inst_mem);

end

always@(*)begin

if(!rst) {ins0,ins1,ins2,ins3} = 128'd0;

else begin

ins0 = inst_mem[(pc>>2) & 8'hFF]; 
ins1 = inst_mem[((pc>>2) & 8'hFF)+5'd1]; 
ins2 = inst_mem[((pc>>2) & 8'hFF)+5'd2]; 
ins3 = inst_mem[((pc>>2) & 8'hFF)+5'd3]; 

end

end

endmodule