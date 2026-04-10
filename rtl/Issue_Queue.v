module IssueQueue(
input clk,
input rst,

input [6:0] prs1_0, prs1_1, prs1_2, prs1_3,
input [6:0] prs2_0, prs2_1, prs2_2, prs2_3,
input [6:0] prd_0, prd_1, prd_2, prd_3,
input [6:0] old_prd_0, old_prd_1, old_prd_2, old_prd_3,
input [31:0] imm_0, imm_1, imm_2, imm_3,
input [6:0] func7_0, func7_1, func7_2, func7_3,
input [2:0] func3_0, func3_1, func3_2, func3_3,
input [6:0] opcode_0, opcode_1, opcode_2, opcode_3,
input [3:0] has_dest_in,
input [3:0] is_branch_in,
input [3:0] is_jump_in,
input [3:0] is_jalr_in,
input [3:0] is_load_in,
input [3:0] is_store_in,
input [3:0] valid_in,

input [127:0] prf_ready,

input [3:0] cdb_valid,
input [6:0] cdb_tag_0, cdb_tag_1, cdb_tag_2, cdb_tag_3,
input flush,
input  [31:0] pc_0, pc_1, pc_2, pc_3,

output reg [31:0] issue_pc_0, issue_pc_1, issue_pc_2, issue_pc_3,
output reg [6:0] issue_prs1_0, issue_prs1_1, issue_prs1_2, issue_prs1_3,
output reg [6:0] issue_prs2_0, issue_prs2_1, issue_prs2_2, issue_prs2_3,
output reg [6:0] issue_prd_0, issue_prd_1, issue_prd_2, issue_prd_3,
output reg [6:0] issue_old_prd_0, issue_old_prd_1, issue_old_prd_2, issue_old_prd_3,
output reg [31:0] issue_imm_0, issue_imm_1, issue_imm_2, issue_imm_3,
output reg [6:0] issue_func7_0, issue_func7_1, issue_func7_2, issue_func7_3,
output reg [2:0] issue_func3_0, issue_func3_1, issue_func3_2, issue_func3_3,
output reg [6:0] issue_opcode_0, issue_opcode_1, issue_opcode_2, issue_opcode_3,
output reg [3:0] issue_has_dest,
output reg [3:0] issue_is_branch,
output reg [3:0] issue_is_jump,
output reg [3:0] issue_is_jalr,
output reg [3:0] issue_valid,
output reg issue_is_mul_3,

output reg queue_full,
output reg queue_almost_full
);

reg [6:0] iq_prs1 [0:15];
reg [6:0] iq_prs2 [0:15];
reg [6:0] iq_prd [0:15];
reg [6:0] iq_old_prd [0:15];
reg [31:0] iq_imm [0:15];
reg [6:0] iq_func7 [0:15];
reg [2:0] iq_func3 [0:15];
reg [6:0] iq_opcode [0:15];
reg [15:0] iq_has_dest;
reg [15:0] iq_is_branch;
reg [15:0] iq_is_jump;
reg [15:0] iq_is_jalr;

reg [15:0] iq_src1_ready;
reg [15:0] iq_src2_ready;

reg [15:0] iq_valid;

reg [3:0] iq_age [0:15];

reg [31:0] iq_pc [0:15];

wire [15:0] ready_mask;
wire [15:0] is_mul;
integer i, j;

genvar g;

generate
for(g = 0; g < 16; g = g + 1)begin 
    assign ready_mask[g] = iq_valid[g] && iq_src1_ready[g] && iq_src2_ready[g];
    assign is_mul[g]     = iq_valid[g] && (iq_opcode[g] == 7'b0110011) && (iq_func7[g] == 7'b0000001);
end
endgenerate

// ─────────────────────────────────────────────────────────────
// Select up to 4 entries to issue this cycle
// ─────────────────────────────────────────────────────────────
reg [4:0] selected_indices [0:3];

always @(*) begin
    selected_indices[0] = 5'd16;
    selected_indices[1] = 5'd16;
    selected_indices[2] = 5'd16;
    selected_indices[3] = 5'd16;

    // Slots 0-2: non-MUL instructions
    for(i = 0; i < 16; i = i + 1)
        if(ready_mask[i] && !is_mul[i] && selected_indices[0] == 5'd16)
            selected_indices[0] = i[4:0];

    for(i = 0; i < 16; i = i + 1)
        if(ready_mask[i] && !is_mul[i] && (i != selected_indices[0]) && selected_indices[1] == 5'd16)
            selected_indices[1] = i[4:0];

    for(i = 0; i < 16; i = i + 1)
        if(ready_mask[i] && !is_mul[i] && (i != selected_indices[0]) && (i != selected_indices[1]) && selected_indices[2] == 5'd16)
            selected_indices[2] = i[4:0];

    // Slot 3: MUL first, fall back to any remaining ALU
    for(i = 0; i < 16; i = i + 1)
        if(ready_mask[i] && is_mul[i] && selected_indices[3] == 5'd16)
            selected_indices[3] = i[4:0];

    if(selected_indices[3] == 5'd16) begin
        for(i = 0; i < 16; i = i + 1)
            if(ready_mask[i] && !is_mul[i] &&
               (i != selected_indices[0]) && (i != selected_indices[1]) && (i != selected_indices[2]) &&
               selected_indices[3] == 5'd16)
                selected_indices[3] = i[4:0];
    end
end

// ─────────────────────────────────────────────────────────────
// Free slot allocation — KEY FIX:
//   A slot is "available" if it is currently invalid OR if it
//   is being issued this cycle (selected_indices). This makes
//   the issue-slot frees visible to dispatch in the same cycle,
//   preventing the "full IQ drops incoming instruction" deadlock.
// ─────────────────────────────────────────────────────────────
reg [3:0] free_slot [0:3];
reg       free_slot_valid [0:3];

// Helper wire: slot i is vacated this cycle
wire [15:0] slot_being_issued;
generate
for(g = 0; g < 16; g = g + 1) begin
    assign slot_being_issued[g] = (selected_indices[0] == g[4:0]) ||
                                   (selected_indices[1] == g[4:0]) ||
                                   (selected_indices[2] == g[4:0]) ||
                                   (selected_indices[3] == g[4:0]);
end
endgenerate

wire [15:0] slot_available;
generate
for(g = 0; g < 16; g = g + 1)
    assign slot_available[g] = !iq_valid[g] || slot_being_issued[g];
endgenerate

always@(*) begin
    free_slot[0] = 4'd0; free_slot_valid[0] = 0;
    free_slot[1] = 4'd0; free_slot_valid[1] = 0;
    free_slot[2] = 4'd0; free_slot_valid[2] = 0;
    free_slot[3] = 4'd0; free_slot_valid[3] = 0;

    for(i = 0; i < 16; i = i + 1)
        if(slot_available[i] && !free_slot_valid[0])
            begin free_slot[0] = i[3:0]; free_slot_valid[0] = 1; end

    for(i = 0; i < 16; i = i + 1)
        if(slot_available[i] && (i != free_slot[0]) && !free_slot_valid[1])
            begin free_slot[1] = i[3:0]; free_slot_valid[1] = 1; end

    for(i = 0; i < 16; i = i + 1)
        if(slot_available[i] && (i != free_slot[0]) && (i != free_slot[1]) && !free_slot_valid[2])
            begin free_slot[2] = i[3:0]; free_slot_valid[2] = 1; end

    for(i = 0; i < 16; i = i + 1)
        if(slot_available[i] && (i != free_slot[0]) && (i != free_slot[1]) && (i != free_slot[2]) && !free_slot_valid[3])
            begin free_slot[3] = i[3:0]; free_slot_valid[3] = 1; end
end

// ─────────────────────────────────────────────────────────────
// Queue occupancy — uses effective free count (after issues)
// ─────────────────────────────────────────────────────────────
reg [4:0] num_free_entries;
reg [4:0] effective_free;
reg [3:0] num_incoming;

always @(*) begin
    num_free_entries = 0;
    for(i = 0; i < 16; i = i + 1)
        if(!iq_valid[i]) num_free_entries = num_free_entries + 1;

    // Account for slots freed by issue this cycle
    effective_free = num_free_entries;
    if (selected_indices[0] != 5'd16) effective_free = effective_free + 1;
    if (selected_indices[1] != 5'd16) effective_free = effective_free + 1;
    if (selected_indices[2] != 5'd16) effective_free = effective_free + 1;
    if (selected_indices[3] != 5'd16) effective_free = effective_free + 1;

    // NOTE: num_incoming must NOT feed into queue_almost_full because
    // valid_in depends on stall which depends on queue_almost_full,
    // creating a combinational loop that hangs the simulator.
    // Use a fixed threshold of 4 (max dispatch width) instead.
    num_incoming = 0;
    if(valid_in[0] && !is_load_in[0] && !is_store_in[0]) num_incoming = num_incoming + 1;
    if(valid_in[1] && !is_load_in[1] && !is_store_in[1]) num_incoming = num_incoming + 1;
    if(valid_in[2] && !is_load_in[2] && !is_store_in[2]) num_incoming = num_incoming + 1;
    if(valid_in[3] && !is_load_in[3] && !is_store_in[3]) num_incoming = num_incoming + 1;

    queue_full         = (effective_free == 0);
    queue_almost_full  = (effective_free < 5'd4);  // stall when can't accept full 4-wide dispatch
end

// ─────────────────────────────────────────────────────────────
// CDB wakeup combinatorial logic
// ─────────────────────────────────────────────────────────────
wire [15:0] wakeup_src1;
wire [15:0] wakeup_src2;
wire [3:0] cdb_match_src1 [0:15];
wire [3:0] cdb_match_src2 [0:15];

generate
for(g = 0; g < 16; g = g + 1)begin 
    assign cdb_match_src1[g][0] = (cdb_valid[0] && (iq_prs1[g] == cdb_tag_0));
    assign cdb_match_src1[g][1] = (cdb_valid[1] && (iq_prs1[g] == cdb_tag_1));
    assign cdb_match_src1[g][2] = (cdb_valid[2] && (iq_prs1[g] == cdb_tag_2));
    assign cdb_match_src1[g][3] = (cdb_valid[3] && (iq_prs1[g] == cdb_tag_3));

    assign cdb_match_src2[g][0] = (cdb_valid[0] && (iq_prs2[g] == cdb_tag_0));
    assign cdb_match_src2[g][1] = (cdb_valid[1] && (iq_prs2[g] == cdb_tag_1));
    assign cdb_match_src2[g][2] = (cdb_valid[2] && (iq_prs2[g] == cdb_tag_2));
    assign cdb_match_src2[g][3] = (cdb_valid[3] && (iq_prs2[g] == cdb_tag_3));

    assign wakeup_src1[g] = |cdb_match_src1[g];
    assign wakeup_src2[g] = |cdb_match_src2[g];
end
endgenerate

// ─────────────────────────────────────────────────────────────
// Sequential: issue, wakeup, dispatch
// ─────────────────────────────────────────────────────────────
always @(posedge clk or negedge rst)begin
    if (!rst) begin
        for (i = 0; i < 16; i = i + 1) begin
            iq_prs1[i] <= 7'd0; iq_prs2[i] <= 7'd0; iq_prd[i] <= 7'd0; iq_old_prd[i] <= 7'd0;
            iq_imm[i] <= 32'd0; iq_func7[i] <= 7'd0; iq_func3[i] <= 3'd0; iq_opcode[i] <= 7'd0;
            iq_has_dest[i] <= 1'b0; iq_is_branch[i] <= 1'b0; iq_is_jump[i] <= 1'b0; iq_is_jalr[i] <= 1'b0;
            iq_src1_ready[i] <= 1'b0; iq_src2_ready[i] <= 1'b0; iq_valid[i] <= 1'b0; iq_age[i] <= 4'd0;
        end
        issue_pc_0 <= 32'd0; issue_pc_1 <= 32'd0; issue_pc_2 <= 32'd0; issue_pc_3 <= 32'd0;
        issue_prs1_0 <= 7'd0; issue_prs1_1 <= 7'd0; issue_prs2_0 <= 7'd0; issue_prs2_1 <= 7'd0;
        issue_prd_0 <= 7'd0; issue_prd_1 <= 7'd0; issue_prd_2 <= 7'd0; issue_prd_3 <= 7'd0;
        issue_valid <= 4'd0; issue_is_mul_3 <= 1'b0;
    end else if(flush) begin
        for (i = 0; i < 16; i = i + 1) begin
            iq_prs1[i] <= 7'd0; iq_prs2[i] <= 7'd0; iq_prd[i] <= 7'd0; iq_old_prd[i] <= 7'd0;
            iq_imm[i] <= 32'd0; iq_func7[i] <= 7'd0; iq_func3[i] <= 3'd0; iq_opcode[i] <= 7'd0;
            iq_has_dest[i] <= 1'b0; iq_is_branch[i] <= 1'b0; iq_is_jump[i] <= 1'b0; iq_is_jalr[i] <= 1'b0;
            iq_src1_ready[i] <= 1'b0; iq_src2_ready[i] <= 1'b0; iq_valid[i] <= 1'b0; iq_age[i] <= 4'd0;
        end
        issue_pc_0 <= 32'd0; issue_pc_1 <= 32'd0; issue_pc_2 <= 32'd0; issue_pc_3 <= 32'd0;
        issue_prs1_0 <= 7'd0; issue_prs1_1 <= 7'd0; issue_prs2_0 <= 7'd0; issue_prs2_1 <= 7'd0;
        issue_prd_0 <= 7'd0; issue_prd_1 <= 7'd0; issue_prd_2 <= 7'd0; issue_prd_3 <= 7'd0;
        issue_valid <= 4'd0; issue_is_mul_3 <= 1'b0;
    end else begin
        issue_valid <= 4'd0;
        issue_is_mul_3 <= 1'b0;

        // ── Issue selected entries ──
        if (selected_indices[0] != 5'd16) begin
            issue_pc_0       <= iq_pc[selected_indices[0]];
            issue_prs1_0     <= iq_prs1[selected_indices[0]];
            issue_prs2_0     <= iq_prs2[selected_indices[0]];
            issue_prd_0      <= iq_prd[selected_indices[0]];
            issue_old_prd_0  <= iq_old_prd[selected_indices[0]];
            issue_imm_0      <= iq_imm[selected_indices[0]];
            issue_func7_0    <= iq_func7[selected_indices[0]];
            issue_func3_0    <= iq_func3[selected_indices[0]];
            issue_opcode_0   <= iq_opcode[selected_indices[0]];
            issue_has_dest[0]   <= iq_has_dest[selected_indices[0]];
            issue_is_branch[0]  <= iq_is_branch[selected_indices[0]];
            issue_is_jump[0]    <= iq_is_jump[selected_indices[0]];
            issue_is_jalr[0]    <= iq_is_jalr[selected_indices[0]];
            issue_valid[0]   <= 1'b1;
            iq_valid[selected_indices[0]] <= 1'b0;
        end
        if (selected_indices[1] != 5'd16) begin
            issue_pc_1       <= iq_pc[selected_indices[1]];
            issue_prs1_1     <= iq_prs1[selected_indices[1]];
            issue_prs2_1     <= iq_prs2[selected_indices[1]];
            issue_prd_1      <= iq_prd[selected_indices[1]];
            issue_old_prd_1  <= iq_old_prd[selected_indices[1]];
            issue_imm_1      <= iq_imm[selected_indices[1]];
            issue_func7_1    <= iq_func7[selected_indices[1]];
            issue_func3_1    <= iq_func3[selected_indices[1]];
            issue_opcode_1   <= iq_opcode[selected_indices[1]];
            issue_has_dest[1]   <= iq_has_dest[selected_indices[1]];
            issue_is_branch[1]  <= iq_is_branch[selected_indices[1]];
            issue_is_jump[1]    <= iq_is_jump[selected_indices[1]];
            issue_is_jalr[1]    <= iq_is_jalr[selected_indices[1]];
            issue_valid[1]   <= 1'b1;
            iq_valid[selected_indices[1]] <= 1'b0;
        end
        if (selected_indices[2] != 5'd16) begin
            issue_pc_2       <= iq_pc[selected_indices[2]];
            issue_prs1_2     <= iq_prs1[selected_indices[2]];
            issue_prs2_2     <= iq_prs2[selected_indices[2]];
            issue_prd_2      <= iq_prd[selected_indices[2]];
            issue_old_prd_2  <= iq_old_prd[selected_indices[2]];
            issue_imm_2      <= iq_imm[selected_indices[2]];
            issue_func7_2    <= iq_func7[selected_indices[2]];
            issue_func3_2    <= iq_func3[selected_indices[2]];
            issue_opcode_2   <= iq_opcode[selected_indices[2]];
            issue_has_dest[2]   <= iq_has_dest[selected_indices[2]];
            issue_is_branch[2]  <= iq_is_branch[selected_indices[2]];
            issue_is_jump[2]    <= iq_is_jump[selected_indices[2]];
            issue_is_jalr[2]    <= iq_is_jalr[selected_indices[2]];
            issue_valid[2]   <= 1'b1;
            iq_valid[selected_indices[2]] <= 1'b0;
        end
        if (selected_indices[3] != 5'd16) begin
            issue_pc_3       <= iq_pc[selected_indices[3]];
            issue_prs1_3     <= iq_prs1[selected_indices[3]];
            issue_prs2_3     <= iq_prs2[selected_indices[3]];
            issue_prd_3      <= iq_prd[selected_indices[3]];
            issue_old_prd_3  <= iq_old_prd[selected_indices[3]];
            issue_imm_3      <= iq_imm[selected_indices[3]];
            issue_func7_3    <= iq_func7[selected_indices[3]];
            issue_func3_3    <= iq_func3[selected_indices[3]];
            issue_opcode_3   <= iq_opcode[selected_indices[3]];
            issue_has_dest[3]   <= iq_has_dest[selected_indices[3]];
            issue_is_branch[3]  <= iq_is_branch[selected_indices[3]];
            issue_is_jump[3]    <= iq_is_jump[selected_indices[3]];
            issue_is_jalr[3]    <= iq_is_jalr[selected_indices[3]];
            issue_valid[3]   <= 1'b1;
            issue_is_mul_3   <= is_mul[selected_indices[3]];
            iq_valid[selected_indices[3]] <= 1'b0;
        end

        // ── CDB wakeup: update src ready bits for waiting entries ──
        for(i = 0; i < 16; i = i + 1)begin
            if(iq_valid[i])begin
                if(!iq_src1_ready[i] && wakeup_src1[i]) iq_src1_ready[i] <= 1'b1;
                if(!iq_src2_ready[i] && wakeup_src2[i]) iq_src2_ready[i] <= 1'b1;
            end
        end

        // ── Dispatch incoming instructions into free slots ──
        // src ready: check PRF ready array + CDB bypass (in case producer
        // is completing the same cycle as this instruction is being allocated)
        if(valid_in[0] && !is_load_in[0] && !is_store_in[0] && free_slot_valid[0])begin
            iq_prs1[free_slot[0]] <= prs1_0; iq_prs2[free_slot[0]] <= prs2_0; iq_prd[free_slot[0]] <= prd_0;
            iq_old_prd[free_slot[0]] <= old_prd_0; iq_imm[free_slot[0]] <= imm_0; iq_func7[free_slot[0]] <= func7_0;
            iq_func3[free_slot[0]] <= func3_0; iq_opcode[free_slot[0]] <= opcode_0;
            iq_has_dest[free_slot[0]] <= has_dest_in[0];
            iq_is_branch[free_slot[0]] <= is_branch_in[0]; iq_is_jump[free_slot[0]] <= is_jump_in[0]; iq_is_jalr[free_slot[0]] <= is_jalr_in[0];
            iq_pc[free_slot[0]] <= pc_0; iq_valid[free_slot[0]] <= 1'b1; iq_age[free_slot[0]] <= 4'd0;
            iq_src1_ready[free_slot[0]] <= prf_ready[prs1_0]
                || (cdb_valid[0] && (prs1_0 == cdb_tag_0)) || (cdb_valid[1] && (prs1_0 == cdb_tag_1))
                || (cdb_valid[2] && (prs1_0 == cdb_tag_2)) || (cdb_valid[3] && (prs1_0 == cdb_tag_3))
                || (prs1_0 == 7'd0);
            iq_src2_ready[free_slot[0]] <= prf_ready[prs2_0]
                || (cdb_valid[0] && (prs2_0 == cdb_tag_0)) || (cdb_valid[1] && (prs2_0 == cdb_tag_1))
                || (cdb_valid[2] && (prs2_0 == cdb_tag_2)) || (cdb_valid[3] && (prs2_0 == cdb_tag_3))
                || (prs2_0 == 7'd0);
        end
        if(valid_in[1] && !is_load_in[1] && !is_store_in[1] && free_slot_valid[1])begin
            iq_prs1[free_slot[1]] <= prs1_1; iq_prs2[free_slot[1]] <= prs2_1; iq_prd[free_slot[1]] <= prd_1;
            iq_old_prd[free_slot[1]] <= old_prd_1; iq_imm[free_slot[1]] <= imm_1; iq_func7[free_slot[1]] <= func7_1;
            iq_func3[free_slot[1]] <= func3_1; iq_opcode[free_slot[1]] <= opcode_1;
            iq_has_dest[free_slot[1]] <= has_dest_in[1];
            iq_is_branch[free_slot[1]] <= is_branch_in[1]; iq_is_jump[free_slot[1]] <= is_jump_in[1]; iq_is_jalr[free_slot[1]] <= is_jalr_in[1];
            iq_pc[free_slot[1]] <= pc_1; iq_valid[free_slot[1]] <= 1'b1; iq_age[free_slot[1]] <= 4'd0;
            iq_src1_ready[free_slot[1]] <= prf_ready[prs1_1]
                || (cdb_valid[0] && (prs1_1 == cdb_tag_0)) || (cdb_valid[1] && (prs1_1 == cdb_tag_1))
                || (cdb_valid[2] && (prs1_1 == cdb_tag_2)) || (cdb_valid[3] && (prs1_1 == cdb_tag_3))
                || (prs1_1 == 7'd0);
            iq_src2_ready[free_slot[1]] <= prf_ready[prs2_1]
                || (cdb_valid[0] && (prs2_1 == cdb_tag_0)) || (cdb_valid[1] && (prs2_1 == cdb_tag_1))
                || (cdb_valid[2] && (prs2_1 == cdb_tag_2)) || (cdb_valid[3] && (prs2_1 == cdb_tag_3))
                || (prs2_1 == 7'd0);
        end
        if(valid_in[2] && !is_load_in[2] && !is_store_in[2] && free_slot_valid[2])begin
            iq_prs1[free_slot[2]] <= prs1_2; iq_prs2[free_slot[2]] <= prs2_2; iq_prd[free_slot[2]] <= prd_2;
            iq_old_prd[free_slot[2]] <= old_prd_2; iq_imm[free_slot[2]] <= imm_2; iq_func7[free_slot[2]] <= func7_2;
            iq_func3[free_slot[2]] <= func3_2; iq_opcode[free_slot[2]] <= opcode_2;
            iq_has_dest[free_slot[2]] <= has_dest_in[2];
            iq_is_branch[free_slot[2]] <= is_branch_in[2]; iq_is_jump[free_slot[2]] <= is_jump_in[2]; iq_is_jalr[free_slot[2]] <= is_jalr_in[2];
            iq_pc[free_slot[2]] <= pc_2; iq_valid[free_slot[2]] <= 1'b1; iq_age[free_slot[2]] <= 4'd0;
            iq_src1_ready[free_slot[2]] <= prf_ready[prs1_2]
                || (cdb_valid[0] && (prs1_2 == cdb_tag_0)) || (cdb_valid[1] && (prs1_2 == cdb_tag_1))
                || (cdb_valid[2] && (prs1_2 == cdb_tag_2)) || (cdb_valid[3] && (prs1_2 == cdb_tag_3))
                || (prs1_2 == 7'd0);
            iq_src2_ready[free_slot[2]] <= prf_ready[prs2_2]
                || (cdb_valid[0] && (prs2_2 == cdb_tag_0)) || (cdb_valid[1] && (prs2_2 == cdb_tag_1))
                || (cdb_valid[2] && (prs2_2 == cdb_tag_2)) || (cdb_valid[3] && (prs2_2 == cdb_tag_3))
                || (prs2_2 == 7'd0);
        end
        if(valid_in[3] && !is_load_in[3] && !is_store_in[3] && free_slot_valid[3])begin
            iq_prs1[free_slot[3]] <= prs1_3; iq_prs2[free_slot[3]] <= prs2_3; iq_prd[free_slot[3]] <= prd_3;
            iq_old_prd[free_slot[3]] <= old_prd_3; iq_imm[free_slot[3]] <= imm_3; iq_func7[free_slot[3]] <= func7_3;
            iq_func3[free_slot[3]] <= func3_3; iq_opcode[free_slot[3]] <= opcode_3;
            iq_has_dest[free_slot[3]] <= has_dest_in[3];
            iq_is_branch[free_slot[3]] <= is_branch_in[3]; iq_is_jump[free_slot[3]] <= is_jump_in[3]; iq_is_jalr[free_slot[3]] <= is_jalr_in[3];
            iq_pc[free_slot[3]] <= pc_3; iq_valid[free_slot[3]] <= 1'b1; iq_age[free_slot[3]] <= 4'd0;
            iq_src1_ready[free_slot[3]] <= prf_ready[prs1_3]
                || (cdb_valid[0] && (prs1_3 == cdb_tag_0)) || (cdb_valid[1] && (prs1_3 == cdb_tag_1))
                || (cdb_valid[2] && (prs1_3 == cdb_tag_2)) || (cdb_valid[3] && (prs1_3 == cdb_tag_3))
                || (prs1_3 == 7'd0);
            iq_src2_ready[free_slot[3]] <= prf_ready[prs2_3]
                || (cdb_valid[0] && (prs2_3 == cdb_tag_0)) || (cdb_valid[1] && (prs2_3 == cdb_tag_1))
                || (cdb_valid[2] && (prs2_3 == cdb_tag_2)) || (cdb_valid[3] && (prs2_3 == cdb_tag_3))
                || (prs2_3 == 7'd0);
        end

        // ── Age counters ──
        for(i = 0; i < 16; i = i + 1)
            if(iq_valid[i] && iq_age[i] < 4'd15) iq_age[i] <= iq_age[i] + 1;
    end
end
endmodule
