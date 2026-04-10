`timescale 1ns/1ps

module tb_TOP;

    // ════════════════════════════════════════════════════════════════
    //  Clock & Reset
    // ════════════════════════════════════════════════════════════════
    reg clk;
    reg rst;

    // ════════════════════════════════════════════════════════════════
    //  Instantiate the Unit Under Test (UUT)
    // ════════════════════════════════════════════════════════════════
    TOP uut (
        .clk(clk),
        .rst(rst)
    );

    // 100 MHz clock (10 ns period)
    always #5 clk = ~clk;

    // ════════════════════════════════════════════════════════════════
    //  Performance Counters
    // ════════════════════════════════════════════════════════════════
    integer cycle_count;
    integer total_commits;
    integer total_flushes;
    integer total_stalls;
    integer commits_this_cycle;
    integer done_cycle;
    reg     done_detected;

    // ════════════════════════════════════════════════════════════════
    //  Golden Model Expected Values (from golden_model_test.py)
    //  These are the final register values after all 256 instructions
    // ════════════════════════════════════════════════════════════════
    reg [31:0] expected [0:31];

    initial begin
        // x0 is always 0
        expected[ 0] = 32'h00000000;
        expected[ 1] = 32'h000000AA;  // 170
        expected[ 2] = 32'h00000055;  // 85
        expected[ 3] = 32'h000000FF;  // 255
        expected[ 4] = 32'h00003872;  // 14450
        expected[ 5] = 32'h00000055;  // 85
        expected[ 6] = 32'h00000000;  // 0
        expected[ 7] = 32'h000000FF;  // 255
        expected[ 8] = 32'h000000FF;  // 255
        expected[ 9] = 32'h000054AB;  // 21675
        expected[10] = 32'h000070E4;  // 28900
        expected[11] = 32'h000007D0;  // 2000
        expected[12] = 32'h000007D1;  // 2001
        expected[13] = 32'h000007D2;  // 2002
        expected[14] = 32'h000007D3;  // 2003
        expected[15] = 32'h000007D4;  // 2004
        expected[16] = 32'hFFFFFFFF;  // -1
        expected[17] = 32'h00000001;  // 1
        expected[18] = 32'h00000000;  // 0
        expected[19] = 32'h00000002;  // 2
        expected[20] = 32'h00000001;  // 1
        expected[21] = 32'h00000000;  // 0
        expected[22] = 32'h00000001;  // 1
        expected[23] = 32'hFFFFFFFF;  // -1
        expected[24] = 32'h00000001;  // 1
        expected[25] = 32'h80000000;  // MSB set
        expected[26] = 32'h00000001;  // 1
        expected[27] = 32'hFFFFFFFF;  // -1
        expected[28] = 32'h00000001;  // 1
        expected[29] = 32'h00000001;  // 1
        expected[30] = 32'hFFFFFFFF;  // -1
        expected[31] = 32'h00000063;  // 99 (DONE marker)
    end

    // ════════════════════════════════════════════════════════════════
    //  VCD Dump for Waveform Viewing
    // ════════════════════════════════════════════════════════════════
    // VCD dump disabled for faster debug
    // initial begin
    //     $dumpfile("processor_waves.vcd");
    //     $dumpvars(0, tb_TOP);
    // end

    // ════════════════════════════════════════════════════════════════
    //  Main Simulation Control
    // ════════════════════════════════════════════════════════════════
    initial begin
        clk = 0;
        rst = 0;  // Active-low reset asserted
        cycle_count   = 0;
        total_commits = 0;
        total_flushes = 0;
        total_stalls  = 0;
        done_cycle    = 0;
        done_detected = 0;

        $display("");
        $display("======================================================================");
        $display("  4-Wide OoO Superscalar RISC-V Core - 256 Instruction Test");
        $display("  Golden Model Verification Testbench");
        $display("======================================================================");
        $display("");

        // Hold reset for 100 ns
        #100;
        rst = 1;  // Release reset
        $display("[%0t] Reset released. Simulation starting...", $time);
        $display("");

        // Run for up to 20000 cycles (200000 ns)
        #200000;

        if (!done_detected) begin
            $display("");
            $display("======================================================================");
            $display("  WARNING: Simulation timed out after 15000 cycles!");
            $display("  The DONE marker (x31=99) was never committed.");
            $display("  Check for pipeline deadlocks.");
            $display("======================================================================");
        end

        // Final register dump & verification
        dump_final_state();
        verify_registers();
        print_summary();

        $finish;
    end

    // ════════════════════════════════════════════════════════════════
    //  Cycle-by-Cycle Monitor (on posedge clk, after reset)
    // ════════════════════════════════════════════════════════════════
    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= cycle_count + 1;

            // Count commits this cycle
            commits_this_cycle = uut.commit_valid[0] + uut.commit_valid[1] +
                                 uut.commit_valid[2] + uut.commit_valid[3];
            total_commits <= total_commits + commits_this_cycle;

            // Count flushes
            if (uut.flush)
                total_flushes <= total_flushes + 1;

            // Count stalls
            if (uut.stall)
                total_stalls <= total_stalls + 1;

            // ── Log commits with architectural register writes ──
            if (uut.commit_valid[0] && uut.commit_rd_0 != 5'd0) begin
                $display("[Cycle %4d] COMMIT: x%-2d = 0x%08h  (prd=%0d)",
                         cycle_count, uut.commit_rd_0, uut.commit_data_0, uut.commit_prd_0);
            end
            if (uut.commit_valid[1] && uut.commit_rd_1 != 5'd0) begin
                $display("[Cycle %4d] COMMIT: x%-2d = 0x%08h  (prd=%0d)",
                         cycle_count, uut.commit_rd_1, uut.commit_data_1, uut.commit_prd_1);
            end
            if (uut.commit_valid[2] && uut.commit_rd_2 != 5'd0) begin
                $display("[Cycle %4d] COMMIT: x%-2d = 0x%08h  (prd=%0d)",
                         cycle_count, uut.commit_rd_2, uut.commit_data_2, uut.commit_prd_2);
            end
            if (uut.commit_valid[3] && uut.commit_rd_3 != 5'd0) begin
                $display("[Cycle %4d] COMMIT: x%-2d = 0x%08h  (prd=%0d)",
                         cycle_count, uut.commit_rd_3, uut.commit_data_3, uut.commit_prd_3);
            end

            // ── Log flushes ──
            if (uut.flush) begin
                $display("[Cycle %4d] *** FLUSH *** (misprediction detected)", cycle_count);
            end

            // ── Log pipeline stalls ──
            if (uut.stall && (cycle_count % 500 == 0)) begin
                $display("[Cycle %4d] STALL active (rob_full=%b, fl_stall=%b, iq_full=%b, lsq_full=%b)",
                         cycle_count, uut.rob_full, uut.fl_stall, uut.queue_almost_full, uut.lsq_full);
            end

            // ── Detect DONE marker: x31 = 99 committed ──
            if (!done_detected) begin
                if ((uut.commit_valid[0] && uut.commit_rd_0 == 5'd31 && uut.commit_data_0 == 32'd99) ||
                    (uut.commit_valid[1] && uut.commit_rd_1 == 5'd31 && uut.commit_data_1 == 32'd99) ||
                    (uut.commit_valid[2] && uut.commit_rd_2 == 5'd31 && uut.commit_data_2 == 32'd99) ||
                    (uut.commit_valid[3] && uut.commit_rd_3 == 5'd31 && uut.commit_data_3 == 32'd99))
                begin
                    done_detected = 1;  // blocking assignment for immediate effect
                    done_cycle = cycle_count;
                    $display("");
                    $display("[Cycle %4d] *** DONE MARKER DETECTED: x31 = 99 ***", cycle_count);
                end
            end

            // ── Hard deadlock detection: 500 commit-less cycles ──
            if (cycle_count > 100 && commits_this_cycle == 0 && (cycle_count % 500 == 0)) begin
                $display("[Cycle %4d] WARNING: No commits. Total=%0d PC=0x%08h fl_stall=%b rob_full=%b iq_full=%b lsq_full=%b",
                         cycle_count, total_commits, uut.pc, uut.fl_stall, uut.rob_full, uut.queue_almost_full, uut.lsq_full);
            end

            // ── Periodic status print every 1000 cycles ──
            if (cycle_count % 1000 == 0 && cycle_count > 0) begin
                $display("[Cycle %4d] STATUS: Total commits=%0d PC=0x%08h stall=%b fl_stall=%b rob_full=%b iq_full=%b lsq_full=%b",
                         cycle_count, total_commits, uut.pc, uut.stall, uut.fl_stall, uut.rob_full, uut.queue_almost_full, uut.lsq_full);
            end
        end
    end

    // ════════════════════════════════════════════════════════════════
    //  Task: Dump final architectural register state (from RRF)
    // ════════════════════════════════════════════════════════════════
    task dump_final_state;
        integer i;
        begin
            $display("");
            $display("════════════════════════════════════════════════════════════════");
            $display("  FINAL ARCHITECTURAL REGISTER STATE (from RRF)");
            $display("════════════════════════════════════════════════════════════════");
            for (i = 0; i < 32; i = i + 1) begin
                if (uut.l.rrf[i] != 32'd0)
                    $display("  x%-2d = %10d  (0x%08h)", i, uut.l.rrf[i], uut.l.rrf[i]);
            end
            $display("════════════════════════════════════════════════════════════════");
        end
    endtask

    // ════════════════════════════════════════════════════════════════
    //  Task: Verify registers against golden model
    // ════════════════════════════════════════════════════════════════
    task verify_registers;
        integer i;
        integer pass_count;
        integer fail_count;
        reg [31:0] hw_val;
        reg [31:0] exp_val;
        begin
            $display("");
            $display("╔══════════════════════════════════════════════════════════════════╗");
            $display("║  GOLDEN MODEL VERIFICATION                                     ║");
            $display("╠══════════════════════════════════════════════════════════════════╣");

            pass_count = 0;
            fail_count = 0;

            for (i = 1; i < 32; i = i + 1) begin
                hw_val  = uut.l.rrf[i];
                exp_val = expected[i];
                if (hw_val == exp_val) begin
                    pass_count = pass_count + 1;
                    if (exp_val != 32'd0)  // only print non-zero matches
                        $display("║  x%-2d: HW=0x%08h  EXP=0x%08h  ✓ PASS                   ║", i, hw_val, exp_val);
                end else begin
                    fail_count = fail_count + 1;
                    $display("║  x%-2d: HW=0x%08h  EXP=0x%08h  ✗ FAIL <<<                ║", i, hw_val, exp_val);
                end
            end

            $display("╠══════════════════════════════════════════════════════════════════╣");
            if (fail_count == 0) begin
                $display("║  ★★★  ALL %2d REGISTERS MATCH — GOLDEN MODEL VERIFIED!  ★★★    ║", pass_count);
            end else begin
                $display("║  PASSED: %2d  |  FAILED: %2d  |  TOTAL: %2d                      ║", pass_count, fail_count, pass_count + fail_count);
            end
            $display("╚══════════════════════════════════════════════════════════════════╝");
        end
    endtask

    // ════════════════════════════════════════════════════════════════
    //  Task: Print performance summary
    // ════════════════════════════════════════════════════════════════
    task print_summary;
        real ipc;
        begin
            $display("");
            $display("╔══════════════════════════════════════════════════════════════════╗");
            $display("║  PERFORMANCE SUMMARY                                           ║");
            $display("╠══════════════════════════════════════════════════════════════════╣");
            $display("║  Total Cycles:        %6d                                    ║", cycle_count);
            $display("║  Total Commits:       %6d                                    ║", total_commits);
            if (cycle_count > 0) begin
                // Verilog doesn't have native real division in $display, so we compute manually
                ipc = (total_commits * 1.0) / (cycle_count * 1.0);
                $display("║  IPC:                 %1.4f                                    ║", ipc);
            end
            $display("║  Total Flushes:       %6d                                    ║", total_flushes);
            $display("║  Total Stall Cycles:  %6d                                    ║", total_stalls);
            $display("║  Done at Cycle:       %6d                                    ║", done_cycle);
            $display("║  Final PC:            0x%08h                               ║", uut.pc);
            $display("╚══════════════════════════════════════════════════════════════════╝");
            $display("");
        end
    endtask

endmodule
