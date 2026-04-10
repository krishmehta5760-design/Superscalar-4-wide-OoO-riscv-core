module LSQ(clk,rst,
           prs1_0,prs1_1,prs1_2,prs1_3,
           prs2_0,prs2_1,prs2_2,prs2_3,
           prd_0,prd_1,prd_2,prd_3,
           imm_0,imm_1,imm_2,imm_3,
           func3_0,func3_1,func3_2,func3_3,
           is_load_in,is_store_in,valid_in,
           prf_ready,
           prs1_rd_addr_0,prs1_rd_addr_1,prs1_rd_addr_2,prs1_rd_addr_3,
           prs2_rd_addr_0,prs2_rd_addr_1,prs2_rd_addr_2,prs2_rd_addr_3,
           prs1_rd_data_0,prs1_rd_data_1,prs1_rd_data_2,prs1_rd_data_3,
           prs2_rd_data_0,prs2_rd_data_1,prs2_rd_data_2,prs2_rd_data_3,
           cdb_valid,cdb_tag_0,cdb_tag_1,cdb_tag_2,cdb_tag_3,
           cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3,
           rob_store_commit,
           lsq_cdb_valid,lsq_cdb_tag,lsq_cdb_data,
           mem_addr,mem_wdata,mem_we,mem_re,mem_func3,
           mem_rdata,mem_ready,
           lsq_full,stall,lsq_store_ready,
           flush);

input clk,rst;

input [6:0] prs1_0,prs1_1,prs1_2,prs1_3;
input [6:0] prs2_0,prs2_1,prs2_2,prs2_3;
input [6:0] prd_0,prd_1,prd_2,prd_3;
input [31:0] imm_0,imm_1,imm_2,imm_3;
input [2:0] func3_0,func3_1,func3_2,func3_3;
input [3:0] is_load_in,is_store_in,valid_in;

input [127:0] prf_ready;
input flush;

output [6:0] prs1_rd_addr_0,prs1_rd_addr_1,prs1_rd_addr_2,prs1_rd_addr_3;
output [6:0] prs2_rd_addr_0,prs2_rd_addr_1,prs2_rd_addr_2,prs2_rd_addr_3;
input [31:0] prs1_rd_data_0,prs1_rd_data_1,prs1_rd_data_2,prs1_rd_data_3;
input [31:0] prs2_rd_data_0,prs2_rd_data_1,prs2_rd_data_2,prs2_rd_data_3;

input [3:0] cdb_valid;
input [6:0] cdb_tag_0,cdb_tag_1,cdb_tag_2,cdb_tag_3;
input [31:0] cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3;

input rob_store_commit;

output reg lsq_cdb_valid;
output reg [6:0] lsq_cdb_tag;
output reg [31:0] lsq_cdb_data;

output reg [31:0] mem_addr;
output reg [31:0] mem_wdata;
output reg mem_we,mem_re;
output reg [2:0] mem_func3;
input [31:0] mem_rdata;
input mem_ready;

output reg lsq_full;
input stall;

output lsq_store_ready;
assign lsq_store_ready = lsq_valid[lsq_head] &&
                         lsq_is_store[lsq_head] &&
                         lsq_addr_ready[lsq_head] &&
                         lsq_data_ready[lsq_head]; 

localparam LSQ_DEPTH = 8;

reg [6:0] lsq_prs1 [0:LSQ_DEPTH-1];
reg [6:0] lsq_prs2 [0:LSQ_DEPTH-1];
reg [6:0] lsq_prd  [0:LSQ_DEPTH-1];
reg [31:0] lsq_imm  [0:LSQ_DEPTH-1];
reg [2:0]  lsq_func3 [0:LSQ_DEPTH-1];
reg lsq_is_load  [0:LSQ_DEPTH-1];
reg lsq_is_store [0:LSQ_DEPTH-1];

reg lsq_addr_ready [0:LSQ_DEPTH-1];//the base address like from where to load or to where to store is ready or no
reg lsq_data_ready [0:LSQ_DEPTH-1];//for stores to know the value which we want to store is ready or no
reg [31:0] lsq_addr [0:LSQ_DEPTH-1];//the actual computed base address
reg [31:0] lsq_store_data [0:LSQ_DEPTH-1];//for stores ..the actual compute data which is to be stored

reg lsq_issued [0:LSQ_DEPTH-1];//used for loads since while loading when the data and address is ready they send a signal to 
                               //memory(mem_re) saying everything is ready for loading and then memory takes 1 cycle to load
                               //the data(mem_ready)thus this causes duplication of req to load which is solved by this signal
reg lsq_valid  [0:LSQ_DEPTH-1];

reg [2:0] lsq_head;
reg [2:0] lsq_tail;
reg [3:0] lsq_count;

reg load_sent;

reg [2:0] lsq_ptr;

reg [2:0] issued_load_idx;

integer i;

reg [2:0] num_incoming;

reg any_load_in_flight;

reg store_fwd_hit;
reg [31:0] store_fwd_data;
reg older_store_unresolved;

integer j;
always@(*) begin
    any_load_in_flight = 1'b0;
    for(j = 0; j < LSQ_DEPTH; j = j + 1)
        if(lsq_valid[j] && lsq_is_load[j] && lsq_issued[j])
            any_load_in_flight = 1'b1;
end

always@(*)begin

num_incoming = 0;

if(valid_in[0] && (is_load_in[0] || is_store_in[0])) num_incoming = num_incoming + 1;

if(valid_in[1] && (is_load_in[1] || is_store_in[1])) num_incoming = num_incoming + 1;

if(valid_in[2] && (is_load_in[2] || is_store_in[2])) num_incoming = num_incoming + 1;

if(valid_in[3] && (is_load_in[3] || is_store_in[3])) num_incoming = num_incoming + 1;

lsq_full = (lsq_count == LSQ_DEPTH);

end

assign prs1_rd_addr_0 = prs1_0;
assign prs1_rd_addr_1 = prs1_1;
assign prs1_rd_addr_2 = prs1_2;
assign prs1_rd_addr_3 = prs1_3;

assign prs2_rd_addr_0 = prs2_0;
assign prs2_rd_addr_1 = prs2_1;
assign prs2_rd_addr_2 = prs2_2;
assign prs2_rd_addr_3 = prs2_3;

function [31:0] cdb_forward;
input [6:0] tag;
input [31:0] d0,d1,d2,d3;
begin

if(cdb_valid[0] && tag == cdb_tag_0) cdb_forward = d0;

else if(cdb_valid[1] && tag == cdb_tag_1) cdb_forward = d1;

else if(cdb_valid[2] && tag == cdb_tag_2) cdb_forward = d2;

else if(cdb_valid[3] && tag == cdb_tag_3) cdb_forward = d3;

else cdb_forward = 32'd0;

end

endfunction

function cdb_match_tag;
input [6:0] tag;
begin

cdb_match_tag = (cdb_valid[0] && tag == cdb_tag_0) ||
                (cdb_valid[1] && tag == cdb_tag_1) ||
                (cdb_valid[2] && tag == cdb_tag_2) ||
                (cdb_valid[3] && tag == cdb_tag_3);
                
end

endfunction

function addr_rdy;
input [6:0] prs1; 
begin

addr_rdy = prf_ready[prs1] || cdb_match_tag(prs1) || (prs1 == 7'd0);

end

endfunction

function data_rdy;
input [6:0] prs2;
begin

data_rdy = prf_ready[prs2] || cdb_match_tag(prs2) || (prs2 == 7'd0);

end

endfunction

reg load_done;
reg store_done;

always @(*) begin
load_done = mem_ready;
store_done = rob_store_commit && lsq_valid[lsq_head] &&
lsq_is_store[lsq_head] &&
lsq_addr_ready[lsq_head] &&
lsq_data_ready[lsq_head];
end

always@(posedge clk or negedge rst)begin

if(!rst || flush)begin

for(i = 0; i < LSQ_DEPTH; i = i + 1)begin
lsq_prs1[i]       <= 7'd0;
lsq_prs2[i]       <= 7'd0;
lsq_prd[i]        <= 7'd0;
lsq_imm[i]        <= 32'd0;
lsq_func3[i]      <= 3'd0;
lsq_is_load[i]    <= 1'b0;
lsq_is_store[i]   <= 1'b0;
lsq_addr_ready[i] <= 1'b0;
lsq_data_ready[i] <= 1'b0;
lsq_addr[i]       <= 32'd0;
lsq_store_data[i] <= 32'd0;
lsq_issued[i]     <= 1'b0;
lsq_valid[i]      <= 1'b0;
end

lsq_head      <= 3'd0;
lsq_tail      <= 3'd0;
lsq_count     <= 4'd0;
lsq_cdb_valid <= 1'b0;
lsq_cdb_tag   <= 7'd0;
lsq_cdb_data  <= 32'd0;
mem_addr      <= 32'd0;
mem_wdata     <= 32'd0;
mem_we        <= 1'b0;
mem_re        <= 1'b0;
mem_func3     <= 3'd0;
issued_load_idx <= 3'd0;

end

else begin

lsq_cdb_valid <= 1'b0;
lsq_cdb_tag   <= 7'd0;
lsq_cdb_data  <= 32'd0;
mem_we        <= 1'b0;
mem_re        <= 1'b0;

// ── 1. CDB wakeup: update addr/data readiness and capture values ──────────
for(i = 0; i < LSQ_DEPTH; i = i + 1)begin

if(lsq_valid[i])begin

if(!lsq_addr_ready[i] && cdb_match_tag(lsq_prs1[i]))begin

lsq_addr_ready[i] <= 1'b1;
lsq_addr[i] <= cdb_forward(lsq_prs1[i],cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3) + lsq_imm[i];

end

if(!lsq_data_ready[i] && lsq_is_store[i] && cdb_match_tag(lsq_prs2[i]))begin
lsq_data_ready[i] <= 1'b1;
lsq_store_data[i] <= cdb_forward(lsq_prs2[i],cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3);
end

end

end

// ── 2. Issue load: first unissued load with address ready ────────────
// FIX: A load must NOT issue if ANY older store has unresolved address
load_sent = 1'b0;
store_fwd_hit = 1'b0;
store_fwd_data = 32'd0;

for(i = 0; i < LSQ_DEPTH; i = i + 1) begin
  if(!load_sent && !any_load_in_flight && !store_done
     && lsq_valid[i] && lsq_is_load[i]
     && lsq_addr_ready[i] && !lsq_issued[i]) begin

    // Check if any older store has unresolved address
    // "older" means between lsq_head (inclusive) and i (exclusive) in circular order
    older_store_unresolved = 1'b0;
    for(j = 0; j < LSQ_DEPTH; j = j + 1) begin
      if(lsq_valid[j] && lsq_is_store[j] && (!lsq_addr_ready[j] || !lsq_data_ready[j])) begin
        if(lsq_head <= i[2:0]) begin
          if(j[2:0] >= lsq_head && j[2:0] < i[2:0])
            older_store_unresolved = 1'b1;
        end else begin
          if(j[2:0] >= lsq_head || j[2:0] < i[2:0])
            older_store_unresolved = 1'b1;
        end
      end
    end

    if(!older_store_unresolved) begin
      // Safe to issue — scan for store forwarding
      store_fwd_hit  = 1'b0;
      store_fwd_data = 32'd0;
      for(j = 0; j < LSQ_DEPTH; j = j + 1) begin
        if(lsq_valid[j] && lsq_is_store[j]
           && lsq_addr_ready[j] && lsq_data_ready[j]
           && (lsq_addr[j] == lsq_addr[i]))
        begin
          store_fwd_hit  = 1'b1;
          store_fwd_data = lsq_store_data[j];
        end
      end

      if(store_fwd_hit) begin
        // forward: broadcast on LSQ CDB, retire load entry
        lsq_cdb_valid <= 1'b1;
        lsq_cdb_tag   <= lsq_prd[i];
        lsq_cdb_data  <= store_fwd_data;
        lsq_valid[i]  <= 1'b0;
        if(i == lsq_head) lsq_head <= (lsq_head + 1) % LSQ_DEPTH;
      end else begin
        mem_re <= 1'b1;
        mem_addr <= lsq_addr[i];
        mem_func3 <= lsq_func3[i];
        lsq_issued[i] <= 1'b1;
        issued_load_idx <= i;
      end
      load_sent = 1'b1;
    end
  end
end

// ── 3. Load result from memory → broadcast on CDB ────────────────────────
if(mem_ready) begin
lsq_cdb_valid <= 1'b1;
lsq_cdb_data  <= mem_rdata;
lsq_cdb_tag   <= lsq_prd[issued_load_idx];

lsq_valid[issued_load_idx]  <= 1'b0;
lsq_issued[issued_load_idx] <= 1'b0;

if(issued_load_idx == lsq_head) lsq_head <= (lsq_head + 1) % LSQ_DEPTH;
        
end

// ── 4. Issue store: only when ROB commits it (head must be a store) ───────
if(rob_store_commit && lsq_valid[lsq_head] && lsq_is_store[lsq_head] &&
   lsq_addr_ready[lsq_head] && lsq_data_ready[lsq_head])begin
mem_we              <= 1'b1;
mem_addr            <= lsq_addr[lsq_head];
mem_wdata           <= lsq_store_data[lsq_head];
mem_func3           <= lsq_func3[lsq_head];
lsq_valid[lsq_head] <= 1'b0;
lsq_head            <= (lsq_head + 1) % LSQ_DEPTH;
end

// ── 5. Dispatch: enqueue incoming loads and stores ────────────────────────
if(!stall && !lsq_full)begin

lsq_ptr = 3'd0;

// -------- Instruction 0 --------
if(valid_in[0] && (is_load_in[0] || is_store_in[0])) begin
    lsq_prs1[(lsq_tail+lsq_ptr)%LSQ_DEPTH]       <= prs1_0;
    lsq_prs2[(lsq_tail+lsq_ptr)%LSQ_DEPTH]       <= prs2_0;
    lsq_prd[(lsq_tail+lsq_ptr)%LSQ_DEPTH]        <= prd_0;
    lsq_imm[(lsq_tail+lsq_ptr)%LSQ_DEPTH]        <= imm_0;
    lsq_func3[(lsq_tail+lsq_ptr)%LSQ_DEPTH]      <= func3_0;
    lsq_is_load[(lsq_tail+lsq_ptr)%LSQ_DEPTH]    <= is_load_in[0];
    lsq_is_store[(lsq_tail+lsq_ptr)%LSQ_DEPTH]   <= is_store_in[0];
    lsq_issued[(lsq_tail+lsq_ptr)%LSQ_DEPTH]     <= 1'b0;

    lsq_addr_ready[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= addr_rdy(prs1_0);
    lsq_data_ready[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= is_store_in[0] ? data_rdy(prs2_0) : 1'b1;

    lsq_addr[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 
        prf_ready[prs1_0] ? (prs1_rd_data_0 + imm_0) :
        cdb_match_tag(prs1_0) ? (cdb_forward(prs1_0,cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3) + imm_0) : 32'd0;

    lsq_store_data[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 
        prf_ready[prs2_0] ? prs2_rd_data_0 :
        cdb_match_tag(prs2_0) ? cdb_forward(prs2_0,cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3) : 32'd0;

    lsq_valid[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 1'b1;
    lsq_ptr = lsq_ptr + 1;
end

// -------- Instruction 1 --------
if(valid_in[1] && (is_load_in[1] || is_store_in[1])) begin
    lsq_prs1[(lsq_tail+lsq_ptr)%LSQ_DEPTH]       <= prs1_1;
    lsq_prs2[(lsq_tail+lsq_ptr)%LSQ_DEPTH]       <= prs2_1;
    lsq_prd[(lsq_tail+lsq_ptr)%LSQ_DEPTH]        <= prd_1;
    lsq_imm[(lsq_tail+lsq_ptr)%LSQ_DEPTH]        <= imm_1;
    lsq_func3[(lsq_tail+lsq_ptr)%LSQ_DEPTH]      <= func3_1;
    lsq_is_load[(lsq_tail+lsq_ptr)%LSQ_DEPTH]    <= is_load_in[1];
    lsq_is_store[(lsq_tail+lsq_ptr)%LSQ_DEPTH]   <= is_store_in[1];
    lsq_issued[(lsq_tail+lsq_ptr)%LSQ_DEPTH]     <= 1'b0;

    lsq_addr_ready[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= addr_rdy(prs1_1);
    lsq_data_ready[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= is_store_in[1] ? data_rdy(prs2_1) : 1'b1;

    lsq_addr[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 
        prf_ready[prs1_1] ? (prs1_rd_data_1 + imm_1) :
        cdb_match_tag(prs1_1) ? (cdb_forward(prs1_1,cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3) + imm_1) : 32'd0;

    lsq_store_data[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 
        prf_ready[prs2_1] ? prs2_rd_data_1 :
        cdb_match_tag(prs2_1) ? cdb_forward(prs2_1,cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3) : 32'd0;

    lsq_valid[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 1'b1;
    lsq_ptr = lsq_ptr + 1;
end

// -------- Instruction 2 --------
if(valid_in[2] && (is_load_in[2] || is_store_in[2])) begin
    lsq_prs1[(lsq_tail+lsq_ptr)%LSQ_DEPTH]       <= prs1_2;
    lsq_prs2[(lsq_tail+lsq_ptr)%LSQ_DEPTH]       <= prs2_2;
    lsq_prd[(lsq_tail+lsq_ptr)%LSQ_DEPTH]        <= prd_2;
    lsq_imm[(lsq_tail+lsq_ptr)%LSQ_DEPTH]        <= imm_2;
    lsq_func3[(lsq_tail+lsq_ptr)%LSQ_DEPTH]      <= func3_2;
    lsq_is_load[(lsq_tail+lsq_ptr)%LSQ_DEPTH]    <= is_load_in[2];
    lsq_is_store[(lsq_tail+lsq_ptr)%LSQ_DEPTH]   <= is_store_in[2];
    lsq_issued[(lsq_tail+lsq_ptr)%LSQ_DEPTH]     <= 1'b0;

    lsq_addr_ready[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= addr_rdy(prs1_2);
    lsq_data_ready[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= is_store_in[2] ? data_rdy(prs2_2) : 1'b1;

    lsq_addr[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 
        prf_ready[prs1_2] ? (prs1_rd_data_2 + imm_2) :
        cdb_match_tag(prs1_2) ? (cdb_forward(prs1_2,cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3) + imm_2) : 32'd0;

    lsq_store_data[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 
        prf_ready[prs2_2] ? prs2_rd_data_2 :
        cdb_match_tag(prs2_2) ? cdb_forward(prs2_2,cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3) : 32'd0;

    lsq_valid[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 1'b1;
    lsq_ptr = lsq_ptr + 1;
end

// -------- Instruction 3 --------
if(valid_in[3] && (is_load_in[3] || is_store_in[3])) begin
    lsq_prs1[(lsq_tail+lsq_ptr)%LSQ_DEPTH]       <= prs1_3;
    lsq_prs2[(lsq_tail+lsq_ptr)%LSQ_DEPTH]       <= prs2_3;
    lsq_prd[(lsq_tail+lsq_ptr)%LSQ_DEPTH]        <= prd_3;
    lsq_imm[(lsq_tail+lsq_ptr)%LSQ_DEPTH]        <= imm_3;
    lsq_func3[(lsq_tail+lsq_ptr)%LSQ_DEPTH]      <= func3_3;
    lsq_is_load[(lsq_tail+lsq_ptr)%LSQ_DEPTH]    <= is_load_in[3];
    lsq_is_store[(lsq_tail+lsq_ptr)%LSQ_DEPTH]   <= is_store_in[3];
    lsq_issued[(lsq_tail+lsq_ptr)%LSQ_DEPTH]     <= 1'b0;

    lsq_addr_ready[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= addr_rdy(prs1_3);
    lsq_data_ready[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= is_store_in[3] ? data_rdy(prs2_3) : 1'b1;

    lsq_addr[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 
        prf_ready[prs1_3] ? (prs1_rd_data_3 + imm_3) :
        cdb_match_tag(prs1_3) ? (cdb_forward(prs1_3,cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3) + imm_3) : 32'd0;

    lsq_store_data[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 
        prf_ready[prs2_3] ? prs2_rd_data_3 :
        cdb_match_tag(prs2_3) ? cdb_forward(prs2_3,cdb_data_0,cdb_data_1,cdb_data_2,cdb_data_3) : 32'd0;

    lsq_valid[(lsq_tail+lsq_ptr)%LSQ_DEPTH] <= 1'b1;
    lsq_ptr = lsq_ptr + 1;
end

// -------- Tail update --------
lsq_tail <= (lsq_tail + num_incoming) % LSQ_DEPTH;

    if(!stall && !lsq_full)begin
        lsq_count <= lsq_count + num_incoming
                     - (load_done  ? 1 : 0)
                     - (store_done ? 1 : 0);
                     
    end

    else begin
        lsq_count <= lsq_count
                     - (load_done  ? 1 : 0)
                     - (store_done ? 1 : 0);
    end

end

end

end

endmodule