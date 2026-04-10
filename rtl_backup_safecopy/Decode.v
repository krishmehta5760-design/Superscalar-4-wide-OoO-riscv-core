module Decode(ins_0,ins_1,ins_2,ins_3,valid_in,opcode_0,opcode_1,opcode_2,opcode_3,rs1_0,rs1_1,rs1_2,rs1_3,rs2_0,rs2_1,rs2_2,rs2_3,rd_0,rd_1,rd_2,rd_3,imm_0,imm_1,imm_2,imm_3,func7_0,func7_1,func7_2,func7_3,func3_0,func3_1,func3_2,func3_3,has_dest,is_branch,is_jump,is_jalr,is_load,is_store,valid_out);

input [31:0] ins_0,ins_1,ins_2,ins_3;
input [3:0] valid_in;

output reg [6:0] opcode_0,opcode_1,opcode_2,opcode_3;
output reg [4:0] rs1_0,rs1_1,rs1_2,rs1_3;
output reg [4:0] rs2_0,rs2_1,rs2_2,rs2_3;
output reg [4:0] rd_0,rd_1,rd_2,rd_3;
output reg [31:0] imm_0,imm_1,imm_2,imm_3;
output reg [6:0] func7_0,func7_1,func7_2,func7_3;
output reg [2:0] func3_0,func3_1,func3_2,func3_3;
        
output reg [3:0] has_dest,is_branch,is_jump,is_jalr,is_load,is_store;
output reg [3:0] valid_out;

always@(*)begin

opcode_0 = ins_0[6:0];
opcode_1 = ins_1[6:0];
opcode_2 = ins_2[6:0];
opcode_3 = ins_3[6:0];
valid_out = valid_in;

{rs1_0,rs1_1,rs1_2,rs1_3,rs2_0,rs2_1,rs2_2,rs2_3,rd_0,rd_1,rd_2,rd_3,imm_0,imm_1,imm_2,imm_3,func7_0,func7_1,func7_2,func7_3,func3_0,func3_1,func3_2,func3_3,has_dest,is_branch,is_jump,is_jalr,is_load,is_store} = 252'd0;

if(valid_in[0])begin

case(opcode_0)

7'b0110011: begin //R-type

            rs1_0 = ins_0[19:15];
            rs2_0 = ins_0[24:20];
            rd_0 = ins_0[11:7];
            func7_0 = ins_0[31:25];
            func3_0 = ins_0[14:12];
            has_dest[0] = 1'b1;
            
            end
            
7'b0010011: begin //I-type

            rs1_0 = ins_0[19:15];
            rd_0 = ins_0[11:7];
            imm_0 = {{20{ins_0[31]}},ins_0[31:20]};
            func3_0 = ins_0[14:12];
            has_dest[0] = 1'b1;
            
            end
            
7'b0000011: begin //Load-type

            rs1_0 = ins_0[19:15];
            rd_0 = ins_0[11:7];
            imm_0 = {{20{ins_0[31]}},ins_0[31:20]};
            func3_0 = ins_0[14:12];
            has_dest[0] = 1'b1;
            is_load[0] = 1'b1;
            
            end
            
7'b0100011: begin //S-type

            rs1_0 = ins_0[19:15];
            rs2_0 = ins_0[24:20];
            imm_0 = {{20{ins_0[31]}},ins_0[31:25],ins_0[11:7]};
            func3_0 = ins_0[14:12];
            is_store[0] = 1'b1;
            
            end
            
7'b1100011: begin //SB-type

            rs1_0 = ins_0[19:15];
            rs2_0 = ins_0[24:20];
            imm_0 = {{19{ins_0[31]}},ins_0[31],ins_0[7],ins_0[30:25],ins_0[11:8],1'b0};
            func3_0 = ins_0[14:12];
            is_branch[0] = 1'b1;
            
            end
            
7'b1101111: begin //Jal-type

            rd_0 = ins_0[11:7];
            imm_0 = {{11{ins_0[31]}},ins_0[31],ins_0[19:12],ins_0[20],ins_0[30:21],1'b0};
            has_dest[0] = 1'b1;
            is_jump[0] = 1'b1;
            
            end
            
7'b1100111: begin //Jalr-type

            rs1_0 = ins_0[19:15];
            rd_0 = ins_0[11:7];
            imm_0 = {{20{ins_0[31]}},ins_0[31:20]};
            func3_0 = ins_0[14:12];
            has_dest[0] = 1'b1;
            is_jalr[0] = 1'b1;
            
            end
            
endcase

end

if(valid_in[1])begin

case(opcode_1)

7'b0110011: begin //R-type

            rs1_1 = ins_1[19:15];
            rs2_1 = ins_1[24:20];
            rd_1 = ins_1[11:7];
            func7_1 = ins_1[31:25];
            func3_1 = ins_1[14:12];
            has_dest[1] = 1'b1;
            
            end
            
7'b0010011: begin //I-type

            rs1_1 = ins_1[19:15];
            rd_1 = ins_1[11:7];
            imm_1 = {{20{ins_1[31]}},ins_1[31:20]};
            func3_1 = ins_1[14:12];
            has_dest[1] = 1'b1;
            
            end
            
7'b0000011: begin //Load-type

            rs1_1 = ins_1[19:15];
            rd_1 = ins_1[11:7];
            imm_1 = {{20{ins_1[31]}},ins_1[31:20]};
            func3_1 = ins_1[14:12];
            has_dest[1] = 1'b1;
            is_load[1] = 1'b1;
            
            end
            
7'b0100011: begin //S-type

            rs1_1 = ins_1[19:15];
            rs2_1 = ins_1[24:20];
            imm_1 = {{20{ins_1[31]}},ins_1[31:25],ins_1[11:7]};
            func3_1 = ins_1[14:12];
            is_store[1] = 1'b1;
            
            end
            
7'b1100011: begin //SB-type

            rs1_1 = ins_1[19:15];
            rs2_1 = ins_1[24:20];
            imm_1 = {{19{ins_1[31]}},ins_1[31],ins_1[7],ins_1[30:25],ins_1[11:8],1'b0};
            func3_1 = ins_1[14:12];
            is_branch[1] = 1'b1;
            
            end
            
7'b1101111: begin //Jal-type

            rd_1 = ins_1[11:7];
            imm_1 = {{11{ins_1[31]}},ins_1[31],ins_1[19:12],ins_1[20],ins_1[30:21],1'b0};
            has_dest[1] = 1'b1;
            is_jump[1] = 1'b1;
            
            end
            
7'b1100111: begin //Jalr-type

            rs1_1 = ins_1[19:15];
            rd_1 = ins_1[11:7];
            imm_1 = {{20{ins_1[31]}},ins_1[31:20]};
            func3_1 = ins_1[14:12];
            has_dest[1] = 1'b1;
            is_jalr[1] = 1'b1;
            
            end
            
endcase

end

if(valid_in[2])begin

case(opcode_2)

7'b0110011: begin //R-type

            rs1_2 = ins_2[19:15];
            rs2_2 = ins_2[24:20];
            rd_2 = ins_2[11:7];
            func7_2 = ins_2[31:25];
            func3_2 = ins_2[14:12];
            has_dest[2] = 1'b1;
            
            end
            
7'b0010011: begin //I-type

            rs1_2 = ins_2[19:15];
            rd_2 = ins_2[11:7];
            imm_2 = {{20{ins_2[31]}},ins_2[31:20]};
            func3_2 = ins_2[14:12];
            has_dest[2] = 1'b1;
            
            end
            
7'b0000011: begin //Load-type

            rs1_2 = ins_2[19:15];
            rd_2 = ins_2[11:7];
            imm_2 = {{20{ins_2[31]}},ins_2[31:20]};
            func3_2 = ins_2[14:12];
            has_dest[2] = 1'b1;
            is_load[2] = 1'b1;
            
            end
            
7'b0100011: begin //S-type

            rs1_2 = ins_2[19:15];
            rs2_2 = ins_2[24:20];
            imm_2 = {{20{ins_2[31]}},ins_2[31:25],ins_2[11:7]};
            func3_2 = ins_2[14:12];
            is_store[2] = 1'b1;
            
            end
            
7'b1100011: begin //SB-type

            rs1_2 = ins_2[19:15];
            rs2_2 = ins_2[24:20];
            imm_2 = {{19{ins_2[31]}},ins_2[31],ins_2[7],ins_2[30:25],ins_2[11:8],1'b0};
            func3_2 = ins_2[14:12];
            is_branch[2] = 1'b1;
            
            end
            
7'b1101111: begin //Jal-type

            rd_2 = ins_2[11:7];
            imm_2 = {{11{ins_2[31]}},ins_2[31],ins_2[19:12],ins_2[20],ins_2[30:21],1'b0};
            has_dest[2] = 1'b1;
            is_jump[2] = 1'b1;
            
            end
            
7'b1100111: begin //Jalr-type

            rs1_2 = ins_2[19:15];
            rd_2 = ins_2[11:7];
            imm_2 = {{20{ins_2[31]}},ins_2[31:20]};
            func3_2 = ins_2[14:12];
            has_dest[2] = 1'b1;
            is_jalr[2] = 1'b1;
            
            end
            
endcase

end

if(valid_in[3])begin

case(opcode_3)

7'b0110011: begin //R-type

            rs1_3 = ins_3[19:15];
            rs2_3 = ins_3[24:20];
            rd_3 = ins_3[11:7];
            func7_3 = ins_3[31:25];
            func3_3 = ins_3[14:12];
            has_dest[3] = 1'b1;
            
            end
            
7'b0010011: begin //I-type

            rs1_3 = ins_3[19:15];
            rd_3 = ins_3[11:7];
            imm_3 = {{20{ins_3[31]}},ins_3[31:20]};
            func3_3 = ins_3[14:12];
            has_dest[3] = 1'b1;
            
            end
            
7'b0000011: begin //Load-type

            rs1_3 = ins_3[19:15];
            rd_3 = ins_3[11:7];
            imm_3 = {{20{ins_3[31]}},ins_3[31:20]};
            func3_3 = ins_3[14:12];
            has_dest[3] = 1'b1;
            is_load[3] = 1'b1;
            
            end
            
7'b0100011: begin //S-type

            rs1_3 = ins_3[19:15];
            rs2_3 = ins_3[24:20];
            imm_3 = {{20{ins_3[31]}},ins_3[31:25],ins_3[11:7]};
            func3_3 = ins_3[14:12];
            is_store[3] = 1'b1;
            
            end
            
7'b1100011: begin //SB-type

            rs1_3 = ins_3[19:15];
            rs2_3 = ins_3[24:20];
            imm_3 = {{19{ins_3[31]}},ins_3[31],ins_3[7],ins_3[30:25],ins_3[11:8],1'b0};
            func3_3 = ins_3[14:12];
            is_branch[3] = 1'b1;
            
            end
            
7'b1101111: begin //Jal-type

            rd_3 = ins_3[11:7];
            imm_3 = {{11{ins_3[31]}},ins_3[31],ins_3[19:12],ins_3[20],ins_3[30:21],1'b0};
            has_dest[3] = 1'b1;
            is_jump[3] = 1'b1;
            
            end
            
7'b1100111: begin //Jalr-type

            rs1_3 = ins_3[19:15];
            rd_3 = ins_3[11:7];
            imm_3 = {{20{ins_3[31]}},ins_3[31:20]};
            func3_3 = ins_3[14:12];
            has_dest[3] = 1'b1;
            is_jalr[3] = 1'b1;
            
            end
            
endcase

end

end

endmodule
