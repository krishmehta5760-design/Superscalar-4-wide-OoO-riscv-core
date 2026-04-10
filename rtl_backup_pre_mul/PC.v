module PC(clk,rst,next,pc,flush,correct_pc);
input clk,rst;
input [31:0] next;
input flush;
input [31:0] correct_pc;
output reg [31:0] pc;

always@(posedge clk,negedge rst)begin

if(!rst) pc <= 32'd0;

else if(flush) pc <= correct_pc;

else pc <= next;

end

endmodule
