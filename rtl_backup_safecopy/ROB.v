module ROB(
    input clk,
    input rst,

    input [6:0] prd_0,prd_1,prd_2,prd_3,
    input [6:0] old_prd_0, old_prd_1, old_prd_2, old_prd_3,
    input [4:0] rd_0,rd_1,rd_2,rd_3,
    input [3:0] has_dest_in,
    input [3:0] is_branch_in,
    input [3:0] is_jump_in,
    input [3:0] is_jalr_in,
    input [3:0] is_load_in,
    input [3:0] is_store_in,
    input [3:0] valid_in,
    input stall,               

    input [3:0] cdb_valid,
    input [6:0] cdb_tag_0,cdb_tag_1,cdb_tag_2,cdb_tag_3,

    output reg [3:0] rob_free_valid,
    output reg [6:0] rob_free_preg_0, rob_free_preg_1, rob_free_preg_2, rob_free_preg_3,

    output reg [3:0] commit_valid,
    output reg [4:0] commit_rd_0, commit_rd_1, commit_rd_2, commit_rd_3,
    output reg [6:0] commit_prd_0, commit_prd_1, commit_prd_2, commit_prd_3,

    output reg rob_full,
    output reg rob_almost_full,
    
    output reg rob_store_commit,
    
    input lsq_store_ready,
    
    input  flush,
    output reg squashing,
    output reg rat_restore_valid,
    output reg [4:0] rat_restore_rd,
    output reg [6:0] rat_restore_prd,
    output reg [6:0] rat_restore_new_prd

);

localparam ROB_DEPTH = 32;

reg [6:0] rob_prd [0:ROB_DEPTH-1];
reg [6:0] rob_old_prd  [0:ROB_DEPTH-1];
reg [4:0] rob_rd [0:ROB_DEPTH-1];
reg rob_has_dest [0:ROB_DEPTH-1];
reg rob_is_branch [0:ROB_DEPTH-1];
reg rob_is_jump [0:ROB_DEPTH-1];
reg rob_is_jalr [0:ROB_DEPTH-1];
reg rob_is_load [0:ROB_DEPTH-1];
reg rob_is_store [0:ROB_DEPTH-1];
reg rob_done [0:ROB_DEPTH-1];
reg rob_valid [0:ROB_DEPTH-1]; 

reg [4:0] rob_head;   
reg [4:0] rob_tail;   
wire [5:0] rob_count;  

integer i;

reg [2:0] num_incoming;
reg [5:0] free_slots;

assign rob_count = (rob_valid[0] + rob_valid[1] + rob_valid[2] + rob_valid[3] +
                    rob_valid[4] + rob_valid[5] + rob_valid[6] + rob_valid[7] +
                    rob_valid[8] + rob_valid[9] + rob_valid[10] + rob_valid[11] +
                    rob_valid[12] + rob_valid[13] + rob_valid[14] + rob_valid[15] +
                    rob_valid[16] + rob_valid[17] + rob_valid[18] + rob_valid[19] +
                    rob_valid[20] + rob_valid[21] + rob_valid[22] + rob_valid[23] +
                    rob_valid[24] + rob_valid[25] + rob_valid[26] + rob_valid[27] +
                    rob_valid[28] + rob_valid[29] + rob_valid[30] + rob_valid[31]);

always @(*)begin
    num_incoming = valid_in[0] + valid_in[1] + valid_in[2] + valid_in[3];
    free_slots = ROB_DEPTH - rob_count;
    rob_full = (rob_count >= ROB_DEPTH - 4); // Leave margin for 4-wide dispatch
    rob_almost_full = (num_incoming > free_slots);
end

wire cdb_match [0:ROB_DEPTH-1];
genvar g;

generate
    for (g = 0; g < ROB_DEPTH; g = g + 1) begin
        assign cdb_match[g] = rob_valid[g] && !rob_done[g] && (
            (cdb_valid[0] && (rob_prd[g] == cdb_tag_0)) ||
            (cdb_valid[1] && (rob_prd[g] == cdb_tag_1)) ||
            (cdb_valid[2] && (rob_prd[g] == cdb_tag_2)) ||
            (cdb_valid[3] && (rob_prd[g] == cdb_tag_3)));
    end
endgenerate

wire ready_0 = (rob_count > 0) && rob_valid[rob_head] && rob_done[rob_head] && (!rob_is_store[rob_head] || lsq_store_ready);
wire is_store_0 = rob_is_store[rob_head];

wire ready_1 = ready_0 && (rob_count > 1) && rob_valid[(rob_head+1)%ROB_DEPTH] && rob_done[(rob_head+1)%ROB_DEPTH] 
               && (!rob_is_store[(rob_head+1)%ROB_DEPTH] || (lsq_store_ready && !is_store_0));
wire is_store_1 = rob_is_store[(rob_head+1)%ROB_DEPTH];

wire ready_2 = ready_1 && (rob_count > 2) && rob_valid[(rob_head+2)%ROB_DEPTH] && rob_done[(rob_head+2)%ROB_DEPTH] 
               && (!rob_is_store[(rob_head+2)%ROB_DEPTH] || (lsq_store_ready && !is_store_0 && !is_store_1));
wire is_store_2 = rob_is_store[(rob_head+2)%ROB_DEPTH];

wire ready_3 = ready_2 && (rob_count > 3) && rob_valid[(rob_head+3)%ROB_DEPTH] && rob_done[(rob_head+3)%ROB_DEPTH] 
               && (!rob_is_store[(rob_head+3)%ROB_DEPTH] || (lsq_store_ready && !is_store_0 && !is_store_1 && !is_store_2));
wire is_store_3 = rob_is_store[(rob_head+3)%ROB_DEPTH];

wire [2:0] num_commits = ready_3 ? 3'd4 : 
                         (ready_2 ? 3'd3 : 
                         (ready_1 ? 3'd2 : 
                         (ready_0 ? 3'd1 : 3'd0)));

always @(posedge clk or negedge rst)begin

    if(!rst)begin
        for(i = 0; i < ROB_DEPTH; i = i + 1)begin
            rob_prd[i]       <= 7'd0;
            rob_old_prd[i]   <= 7'd0;
            rob_rd[i]        <= 5'd0;
            rob_has_dest[i]  <= 1'b0;
            rob_is_branch[i] <= 1'b0;
            rob_is_jump[i]   <= 1'b0;
            rob_is_jalr[i]   <= 1'b0;
            rob_is_load[i]   <= 1'b0;
            rob_is_store[i]  <= 1'b0;
            rob_done[i]      <= 1'b0;
            rob_valid[i]     <= 1'b0;
        end
        rob_head         <= 5'd0;
        rob_tail         <= 5'd0;
        // rob_count is now a wire
        commit_valid     <= 4'b0000;
        commit_rd_0      <= 5'd0;
        commit_rd_1      <= 5'd0;
        commit_rd_2      <= 5'd0;
        commit_rd_3      <= 5'd0;
        commit_prd_0     <= 7'd0;
        commit_prd_1     <= 7'd0;
        commit_prd_2     <= 7'd0;
        commit_prd_3     <= 7'd0;
        rob_free_valid   <= 4'd0;
        rob_free_preg_0  <= 7'd0;
        rob_free_preg_1  <= 7'd0;
        rob_free_preg_2  <= 7'd0;
        rob_free_preg_3  <= 7'd0;
        rob_store_commit <= 1'b0;
        squashing        <= 0;
        rat_restore_valid <= 0;
        rat_restore_rd    <= 0;
        rat_restore_prd   <= 0;
        rat_restore_new_prd <= 0;
    end 

    // FLUSH: sequential walkback to restore RAT state
    else if(flush || squashing) begin
        if(flush && !squashing) begin
            squashing <= 1'b1;
            rat_restore_valid <= 1'b0;
        end 
        else if(squashing) begin
            // 1. Commit the branch (head) while squashing
            if(ready_0) begin
                if(rob_has_dest[rob_head] && rob_old_prd[rob_head] >= 7'd32) begin
                    rob_free_valid[0] <= 1'b1;
                    rob_free_preg_0  <= rob_old_prd[rob_head];
                end
                rob_valid[rob_head] <= 1'b0;
                rob_head <= (rob_head + 1) % ROB_DEPTH;
            end

            // 2. Squash exit logic: Stop ONLY when we've walked all the way back to the head
            if(rob_tail == rob_head) begin
                squashing <= 1'b0;
                rat_restore_valid <= 1'b0;
                rat_restore_new_prd <= 7'd0;
            end 
            else begin
                // Restore logic for tail-1
                if(rob_has_dest[rob_tail == 0 ? 31 : rob_tail - 1] && (rob_rd[rob_tail == 0 ? 31 : rob_tail - 1] != 5'd0)) begin
                    rat_restore_valid   <= 1'b1;
                    rat_restore_rd      <= rob_rd[rob_tail == 0 ? 31 : rob_tail - 1];
                    rat_restore_prd     <= rob_old_prd[rob_tail == 0 ? 31 : rob_tail - 1];
                    rat_restore_new_prd <= rob_prd[rob_tail == 0 ? 31 : rob_tail - 1];
                end 
                else begin
                    rat_restore_valid <= 1'b0;
                    rat_restore_new_prd <= 7'd0;
                end
                
                rob_valid[rob_tail == 0 ? 31 : rob_tail - 1] <= 1'b0;
                rob_tail <= (rob_tail == 0 ? 31 : rob_tail - 1); // RETRACT THE TAIL
            end
        end

        // During squash/flush, we allow the HEAD instruction to commit normally
        // to resolve the deadlock between BPU and ROB head.
        // We do not reset commit_valid and rob_free_valid here; they are calculated below.
    end


    else begin

        commit_valid     <= 4'b0000;
        commit_rd_0      <= 5'd0;
        commit_rd_1      <= 5'd0;
        commit_rd_2      <= 5'd0;
        commit_rd_3      <= 5'd0;
        commit_prd_0     <= 7'd0;
        commit_prd_1     <= 7'd0;
        commit_prd_2     <= 7'd0;
        commit_prd_3     <= 7'd0;
        rob_free_valid   <= 4'b0000;
        rob_free_preg_0  <= 7'd0;
        rob_free_preg_1  <= 7'd0;
        rob_free_preg_2  <= 7'd0;
        rob_free_preg_3  <= 7'd0;
        rob_store_commit <= 1'b0;

        for(i = 0; i < ROB_DEPTH; i = i + 1)begin
            if (cdb_match[i]) rob_done[i] <= 1'b1;
        end

        if(ready_0)begin
            if(rob_has_dest[rob_head] && rob_rd[rob_head] != 5'd0)begin
                commit_valid[0] <= 1'b1;
                commit_rd_0    <= rob_rd[rob_head];
                commit_prd_0   <= rob_prd[rob_head];
            end
            if(rob_has_dest[rob_head] && rob_old_prd[rob_head] >= 7'd32)begin
                rob_free_valid[0] <= 1'b1;
                rob_free_preg_0  <= rob_old_prd[rob_head];
            end
            if(rob_is_store[rob_head]) rob_store_commit <= 1'b1;
            rob_valid[rob_head] <= 1'b0;
        end
        if(ready_1)begin
            if(rob_has_dest[(rob_head+1)%ROB_DEPTH] && rob_rd[(rob_head+1)%ROB_DEPTH] != 5'd0)begin
                commit_valid[1] <= 1'b1;
                commit_rd_1    <= rob_rd[(rob_head+1)%ROB_DEPTH];
                commit_prd_1   <= rob_prd[(rob_head+1)%ROB_DEPTH];
            end
            if(rob_has_dest[(rob_head+1)%ROB_DEPTH] && rob_old_prd[(rob_head+1)%ROB_DEPTH] >= 7'd32)begin
                rob_free_valid[1] <= 1'b1;
                rob_free_preg_1  <= rob_old_prd[(rob_head+1)%ROB_DEPTH];
            end
            if(rob_is_store[(rob_head+1)%ROB_DEPTH]) rob_store_commit <= 1'b1;
            rob_valid[(rob_head+1)%ROB_DEPTH] <= 1'b0;
        end
        if(ready_2)begin
            if(rob_has_dest[(rob_head+2)%ROB_DEPTH] && rob_rd[(rob_head+2)%ROB_DEPTH] != 5'd0)begin
                commit_valid[2] <= 1'b1;
                commit_rd_2    <= rob_rd[(rob_head+2)%ROB_DEPTH];
                commit_prd_2   <= rob_prd[(rob_head+2)%ROB_DEPTH];
            end
            if(rob_has_dest[(rob_head+2)%ROB_DEPTH] && rob_old_prd[(rob_head+2)%ROB_DEPTH] >= 7'd32)begin
                rob_free_valid[2] <= 1'b1;
                rob_free_preg_2  <= rob_old_prd[(rob_head+2)%ROB_DEPTH];
            end
            if(rob_is_store[(rob_head+2)%ROB_DEPTH]) rob_store_commit <= 1'b1;
            rob_valid[(rob_head+2)%ROB_DEPTH] <= 1'b0;
        end
        if(ready_3)begin
            if(rob_has_dest[(rob_head+3)%ROB_DEPTH] && rob_rd[(rob_head+3)%ROB_DEPTH] != 5'd0)begin
                commit_valid[3] <= 1'b1;
                commit_rd_3    <= rob_rd[(rob_head+3)%ROB_DEPTH];
                commit_prd_3   <= rob_prd[(rob_head+3)%ROB_DEPTH];
            end
            if(rob_has_dest[(rob_head+3)%ROB_DEPTH] && rob_old_prd[(rob_head+3)%ROB_DEPTH] >= 7'd32)begin
                rob_free_valid[3] <= 1'b1;
                rob_free_preg_3  <= rob_old_prd[(rob_head+3)%ROB_DEPTH];
            end
            if(rob_is_store[(rob_head+3)%ROB_DEPTH]) rob_store_commit <= 1'b1;
            rob_valid[(rob_head+3)%ROB_DEPTH] <= 1'b0;
        end

        rob_head <= (rob_head + num_commits) % ROB_DEPTH;

        if(!stall && !rob_full)begin
            if(valid_in[0])begin
                rob_prd [rob_tail]       <= prd_0;
                rob_old_prd [rob_tail]   <= old_prd_0;
                rob_rd [rob_tail]        <= rd_0;
                rob_has_dest [rob_tail]  <= has_dest_in[0];
                rob_is_branch[rob_tail]  <= is_branch_in[0];
                rob_is_jump [rob_tail]   <= is_jump_in[0];
                rob_is_jalr [rob_tail]   <= is_jalr_in[0];
                rob_is_load [rob_tail]   <= is_load_in[0];
                rob_is_store [rob_tail]  <= is_store_in[0];
                rob_done [rob_tail]      <= (!has_dest_in[0]);
                rob_valid [rob_tail]     <= 1'b1;
            end

            if(valid_in[1])begin
                rob_prd [(rob_tail+1) % ROB_DEPTH]       <= prd_1;
                rob_old_prd [(rob_tail+1) % ROB_DEPTH]   <= old_prd_1;
                rob_rd [(rob_tail+1) % ROB_DEPTH]        <= rd_1;
                rob_has_dest [(rob_tail+1) % ROB_DEPTH]  <= has_dest_in[1];
                rob_is_branch[(rob_tail+1) % ROB_DEPTH]  <= is_branch_in[1];
                rob_is_jump [(rob_tail+1) % ROB_DEPTH]   <= is_jump_in[1];
                rob_is_jalr [(rob_tail+1) % ROB_DEPTH]   <= is_jalr_in[1];
                rob_is_load [(rob_tail+1) % ROB_DEPTH]   <= is_load_in[1];
                rob_is_store [(rob_tail+1) % ROB_DEPTH]  <= is_store_in[1];
                rob_done [(rob_tail+1) % ROB_DEPTH]      <= (!has_dest_in[1]);
                rob_valid [(rob_tail+1) % ROB_DEPTH]     <= 1'b1;
            end

            if(valid_in[2])begin
                rob_prd [(rob_tail+2) % ROB_DEPTH]       <= prd_2;
                rob_old_prd [(rob_tail+2) % ROB_DEPTH]   <= old_prd_2;
                rob_rd [(rob_tail+2) % ROB_DEPTH]        <= rd_2;
                rob_has_dest [(rob_tail+2) % ROB_DEPTH]  <= has_dest_in[2];
                rob_is_branch[(rob_tail+2) % ROB_DEPTH]  <= is_branch_in[2];
                rob_is_jump [(rob_tail+2) % ROB_DEPTH]   <= is_jump_in[2];
                rob_is_jalr [(rob_tail+2) % ROB_DEPTH]   <= is_jalr_in[2];
                rob_is_load [(rob_tail+2) % ROB_DEPTH]   <= is_load_in[2];
                rob_is_store [(rob_tail+2) % ROB_DEPTH]  <= is_store_in[2];
                rob_done [(rob_tail+2) % ROB_DEPTH]      <= (!has_dest_in[2]);
                rob_valid [(rob_tail+2) % ROB_DEPTH]     <= 1'b1;
            end

            if(valid_in[3])begin
                rob_prd [(rob_tail+3) % ROB_DEPTH]       <= prd_3;
                rob_old_prd [(rob_tail+3) % ROB_DEPTH]   <= old_prd_3;
                rob_rd [(rob_tail+3) % ROB_DEPTH]        <= rd_3;
                rob_has_dest [(rob_tail+3) % ROB_DEPTH]  <= has_dest_in[3];
                rob_is_branch[(rob_tail+3) % ROB_DEPTH]  <= is_branch_in[3];
                rob_is_jump [(rob_tail+3) % ROB_DEPTH]   <= is_jump_in[3];
                rob_is_jalr [(rob_tail+3) % ROB_DEPTH]   <= is_jalr_in[3];
                rob_is_load [(rob_tail+3) % ROB_DEPTH]   <= is_load_in[3];
                rob_is_store [(rob_tail+3) % ROB_DEPTH]  <= is_store_in[3];
                rob_done [(rob_tail+3) % ROB_DEPTH]      <= (!has_dest_in[3]);
                rob_valid [(rob_tail+3) % ROB_DEPTH]     <= 1'b1;
            end
        end 

        // Pointer and State Management
        if(squashing && rob_count > 1) begin
            rob_tail  <= (rob_tail == 0 ? 31 : rob_tail - 1);
        end
        else if(!squashing && !stall && !rob_full) begin
            rob_tail  <= (rob_tail + num_incoming) % ROB_DEPTH;
        end
    end
    
end

endmodule