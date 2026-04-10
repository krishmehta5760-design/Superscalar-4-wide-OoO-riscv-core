module Data_Memory(clk,rst,addr,wdata,we,re,func3,rdata,ready);

input clk,rst;
input [31:0] addr;
input [31:0] wdata;
input we,re;
input [2:0] func3;
output reg [31:0] rdata;
output reg ready;

reg [7:0] mem [0:4095];

integer i;

always@(posedge clk or negedge rst)begin

if(!rst)begin

for(i = 0; i < 4096; i = i + 1) mem[i] <= 8'd0;

rdata <= 32'd0;
ready <= 1'b0;

end

else begin

ready <= 1'b0;

if(we)begin

case(func3)

3'b000: mem[addr[11:0]] <= wdata[7:0];

3'b001: begin

mem[addr[11:0]] <= wdata[7:0];
mem[addr[11:0]+1] <= wdata[15:8];

end

3'b010: begin

mem[addr[11:0]] <= wdata[7:0];
mem[addr[11:0]+1] <= wdata[15:8];
mem[addr[11:0]+2] <= wdata[23:16];
mem[addr[11:0]+3] <= wdata[31:24];

end

endcase

ready <= 1'b1;

end

if(re)begin

case(func3)

3'b000: rdata <= {{24{mem[addr[11:0]][7]}},mem[addr[11:0]]};

3'b001: rdata <= {{16{mem[addr[11:0]+1][7]}},mem[addr[11:0]+1],mem[addr[11:0]]};

3'b010: rdata <= {mem[addr[11:0]+3],mem[addr[11:0]+2],mem[addr[11:0]+1],mem[addr[11:0]]};

3'b100: rdata <= {24'd0,mem[addr[11:0]]};

3'b101: rdata <= {16'd0,mem[addr[11:0]+1],mem[addr[11:0]]};

endcase

ready <= 1'b1;

end

end

end

endmodule