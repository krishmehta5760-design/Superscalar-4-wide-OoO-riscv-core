module Instruction_Mem(rst,pc,ins0,ins1,ins2,ins3);
input rst;
input [31:0] pc;
output reg [31:0] ins0;
output reg [31:0] ins1;
output reg [31:0] ins2;
output reg [31:0] ins3;
reg [31:0] inst_mem [0:255];

initial begin
    // HARDCODED FALLBACK: If program.mem fail to load, we have real instructions here.
    // This is our minimal test: li x1,1; li x2,2; add x3,x2,x1; nop; ...
    inst_mem[0] = 32'h00100093; 
    inst_mem[1] = 32'h00200113; 
    inst_mem[2] = 32'h001101b3; 
    inst_mem[3] = 32'h00000013; 
    inst_mem[4] = 32'h00000013;
    inst_mem[5] = 32'h00000013;
    inst_mem[6] = 32'h00000013;
    inst_mem[7] = 32'h00000013;

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