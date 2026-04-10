module CDB(wb_valid_0,wb_valid_1,wb_valid_2,wb_valid_3,
           wb_prd_0,wb_prd_1,wb_prd_2,wb_prd_3,
           wb_result_0,wb_result_1,wb_result_2,wb_result_3,
           wb_has_dest_0,wb_has_dest_1,wb_has_dest_2,wb_has_dest_3,
           lsq_cdb_valid,lsq_cdb_tag,lsq_cdb_data,
           cdb_valid,cdb_tag_0,cdb_tag_1,cdb_tag_2,cdb_tag_3,
           cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3,
           alu3_stalled);

input wb_valid_0,wb_valid_1,wb_valid_2,wb_valid_3;
input [6:0] wb_prd_0,wb_prd_1,wb_prd_2,wb_prd_3;
input [31:0] wb_result_0,wb_result_1,wb_result_2,wb_result_3;
input wb_has_dest_0,wb_has_dest_1,wb_has_dest_2,wb_has_dest_3;
input lsq_cdb_valid;
input [6:0] lsq_cdb_tag;
input [31:0] lsq_cdb_data;

output [3:0] cdb_valid;
output [6:0] cdb_tag_0,cdb_tag_1,cdb_tag_2,cdb_tag_3;
output [31:0] cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3;
output alu3_stalled;

// channels 0,1,2 are dedicated to ALU0,1,2 — no contention possible
assign cdb_valid[0]  = wb_valid_0 && wb_has_dest_0;
assign cdb_valid[1]  = wb_valid_1 && wb_has_dest_1;
assign cdb_valid[2]  = wb_valid_2 && wb_has_dest_2;
assign cdb_tag_0     = wb_prd_0;
assign cdb_tag_1     = wb_prd_1;
assign cdb_tag_2     = wb_prd_2;
assign cdb_data_0    = wb_result_0;
assign cdb_data_1    = wb_result_1;
assign cdb_data_2    = wb_result_2;

// channel 3: LSQ gets priority over ALU3
// reason: loads are on the critical path of dependent instructions
// ALU3 result will retry next cycle via the WB register which still holds it
wire alu3_wants  = wb_valid_3 && wb_has_dest_3;
wire lsq_wants   = lsq_cdb_valid;

assign cdb_valid[3]  = lsq_wants  ? 1'b1         : alu3_wants;
assign cdb_tag_3     = lsq_wants  ? lsq_cdb_tag  : wb_prd_3;
assign cdb_data_3    = lsq_wants  ? lsq_cdb_data : wb_result_3;

// tell the pipeline ALU3 did not get its slot this cycle
assign alu3_stalled  = alu3_wants && lsq_wants;

endmodule