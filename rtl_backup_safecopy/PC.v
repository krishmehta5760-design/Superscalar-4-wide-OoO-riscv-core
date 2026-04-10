module PC(clk,rst,next,pc,flush,correct_pc,hold);
input clk,rst;
input [31:0] next;
input flush;
input [31:0] correct_pc;
input hold;
output reg [31:0] pc;

always@(posedge clk,negedge rst)begin

if(!rst) pc <= 32'd0;

else if(flush) pc <= correct_pc;

else if(hold) pc <= pc;

else pc <= next;

end

endmodule
