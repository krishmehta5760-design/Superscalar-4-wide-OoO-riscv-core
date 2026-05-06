// NexysVideo_Top.v - Architecture Explorer (Dual-Mode)
module NexysVideo_Top(
    input clk_100mhz_p,
    input clk_100mhz_n,
    input reset_btn,
    input sw_0,        // NEW: Dual-Mode Switch (Up: 25MHz Turbo, Down: 5Hz Visualizer)
    output uart_tx_pin,
    output [7:0] leds
);

    // 1. Clock Infrastructure
    wire clk_100mhz_buf;
    IBUFDS ibufds_inst (.I(clk_100mhz_p), .IB(clk_100mhz_n), .O(clk_100mhz_buf));

    wire clk_25mhz, locked;
    clk_wiz_0 clock_gen (.clk_in1(clk_100mhz_buf), .clk_out1(clk_25mhz), .reset(1'b0), .locked(locked));

    // 2. Dual-Mode Clock Divider (1 Hz Ultra-Slow Mode for Presentation)
    reg [23:0] clk_div;
    reg core_clk_slow;
    always @(posedge clk_25mhz) begin
        // 25MHz / (2 * 12.5M) = 1 Hz
        if (clk_div == 12500000 - 1) begin 
            clk_div <= 0;
            core_clk_slow <= ~core_clk_slow;
        end else begin
            clk_div <= clk_div + 1;
        end
    end

    wire core_clk_mux;
    BUFGMUX bugfmux_inst (
        .O(core_clk_mux), 
        .I0(core_clk_slow), 
        .I1(clk_25mhz), 
        .S(sw_0)
    );

    wire core_rst_n = locked && reset_btn;

    // 3. Processor Core Telemetry Wires
    wire [31:0] commit_pc, ins0_fetch, correct_pc; 
    wire [3:0] commit_valid;
    wire [5:0] rob_count;
    wire flush, mispredicted;

    // Granular Tracing Wires
    wire [3:0] valid_IQ;
    wire [6:0] prd_0_IQ, prd_1_IQ, prd_2_IQ, prd_3_IQ;
    wire [3:0] cdb_valid;
    wire [6:0] cdb_tag_0, cdb_tag_1, cdb_tag_2, cdb_tag_3;
    wire [6:0] commit_prd_0, commit_prd_1, commit_prd_2, commit_prd_3;

    TOP core_inst (
        .clk(core_clk_mux), 
        .rst(core_rst_n), 
        .pc(commit_pc),      
        .ins0(ins0_fetch),   
        .commit_valid(commit_valid),
        .flush(flush),
        .correct_pc(correct_pc),
        .rob_count(rob_count),    
        .mispredicted(mispredicted),
        
        // Granular Hooks
        .valid_IQ(valid_IQ),
        .prd_0_IQ(prd_0_IQ), .prd_1_IQ(prd_1_IQ), .prd_2_IQ(prd_2_IQ), .prd_3_IQ(prd_3_IQ),
        .cdb_valid(cdb_valid),
        .cdb_tag_0(cdb_tag_0), .cdb_tag_1(cdb_tag_1), .cdb_tag_2(cdb_tag_2), .cdb_tag_3(cdb_tag_3),
        .commit_prd_0(commit_prd_0), .commit_prd_1(commit_prd_1), .commit_prd_2(commit_prd_2), .commit_prd_3(commit_prd_3)
    );

    // 4. Performance Counters (Turbo Mode)
    reg [31:0] total_cycles;
    reg [31:0] total_commits;
    wire [2:0] commit_sum = commit_valid[0] + commit_valid[1] + commit_valid[2] + commit_valid[3];

    always @(posedge core_clk_mux or negedge core_rst_n) begin
        if (!core_rst_n) begin
            total_cycles <= 0;
            total_commits <= 0;
        end else begin
            total_cycles <= total_cycles + 1;
            total_commits <= total_commits + commit_sum;
        end
    end

    // 5. High-Speed UART (115200 Baud)
    wire uart_ready;
    reg uart_start;
    reg [7:0] uart_byte;
    uart_tx #(.CLK_FREQ(25000000), .BAUD_RATE(115200)) utx (
        .clk(clk_25mhz), .rst_n(core_rst_n), .data_in(uart_byte), .start(uart_start), .tx(uart_tx_pin), .ready(uart_ready)
    );

    // ----------------------------------------------------
    // PRIORITY MULTIPLEXER (Compress 4 lanes into 1 UART feed)
    // ----------------------------------------------------
    wire active_dispatch_valid = |valid_IQ;
    wire [6:0] active_dispatch_tag = valid_IQ[0] ? prd_0_IQ :
                                     valid_IQ[1] ? prd_1_IQ :
                                     valid_IQ[2] ? prd_2_IQ :
                                     valid_IQ[3] ? prd_3_IQ : 7'd0;

    wire active_cdb_valid = |cdb_valid;
    wire [6:0] active_cdb_tag = cdb_valid[0] ? cdb_tag_0 :
                                cdb_valid[1] ? cdb_tag_1 :
                                cdb_valid[2] ? cdb_tag_2 :
                                cdb_valid[3] ? cdb_tag_3 : 7'd0;

    wire active_commit_valid = |commit_valid;
    wire [6:0] active_commit_tag = commit_valid[0] ? commit_prd_0 :
                                   commit_valid[1] ? commit_prd_1 :
                                   commit_valid[2] ? commit_prd_2 :
                                   commit_valid[3] ? commit_prd_3 : 7'd0;

    // ASCII Converter for generic 32-bit to 64-bit string
    wire [63:0] ascii_cdb0, ascii_cdb1, ascii_cdb2, ascii_cdb3;
    hex_to_ascii h2a_cdb0 (.hex_in({25'd0, active_cdb_tag}), .ascii_out(ascii_cdb0));
    hex_to_ascii h2a_cdb1 (.hex_in({25'd0, cdb_tag_1}), .ascii_out(ascii_cdb1));
    hex_to_ascii h2a_cdb2 (.hex_in({25'd0, cdb_tag_2}), .ascii_out(ascii_cdb2));
    hex_to_ascii h2a_cdb3 (.hex_in({25'd0, cdb_tag_3}), .ascii_out(ascii_cdb3));

    wire [63:0] ascii_iq0, ascii_iq1, ascii_iq2, ascii_iq3;
    hex_to_ascii h2a_iq0 (.hex_in({25'd0, active_dispatch_tag}), .ascii_out(ascii_iq0));
    hex_to_ascii h2a_iq1 (.hex_in({25'd0, prd_1_IQ}), .ascii_out(ascii_iq1));
    hex_to_ascii h2a_iq2 (.hex_in({25'd0, prd_2_IQ}), .ascii_out(ascii_iq2));
    hex_to_ascii h2a_iq3 (.hex_in({25'd0, prd_3_IQ}), .ascii_out(ascii_iq3));

    wire [63:0] ascii_cmt0, ascii_cmt1, ascii_cmt2, ascii_cmt3;
    hex_to_ascii h2a_cmt0 (.hex_in({25'd0, active_commit_tag}), .ascii_out(ascii_cmt0));
    hex_to_ascii h2a_cmt1 (.hex_in({25'd0, commit_prd_1}), .ascii_out(ascii_cmt1));
    hex_to_ascii h2a_cmt2 (.hex_in({25'd0, commit_prd_2}), .ascii_out(ascii_cmt2));
    hex_to_ascii h2a_cmt3 (.hex_in({25'd0, commit_prd_3}), .ascii_out(ascii_cmt3));

    wire [63:0] ascii_cyc, ascii_tot_cmt;
    hex_to_ascii h2a_cyc (.hex_in(total_cycles), .ascii_out(ascii_cyc));
    hex_to_ascii h2a_tot (.hex_in(total_commits), .ascii_out(ascii_tot_cmt));

    // UART Controller - Triggered once per core cycle
    reg [6:0] state;
    reg tx_busy;
    reg core_clk_d1, core_clk_d2;
    wire core_clk_tick = core_clk_d1 && !core_clk_d2;

    always @(posedge clk_25mhz) begin
        core_clk_d1 <= core_clk_mux;
        core_clk_d2 <= core_clk_d1;
    end

    // Turbo mode timer (Update PC 20 times a second if running at 25MHz)
    reg [20:0] turbo_timer;
    wire turbo_tick = (turbo_timer == 1250000); 

    always @(posedge clk_25mhz or negedge core_rst_n) begin
        if (!core_rst_n) begin
            state <= 0;
            uart_start <= 0;
            turbo_timer <= 0;
            tx_busy <= 0;
        end else begin
            uart_start <= 0;
            if (sw_0) begin
                // TURBO MODE: Fire aggregated data periodically
                if (state == 0) begin
                    if (turbo_timer < 1250000) turbo_timer <= turbo_timer + 1;
                    else begin
                        turbo_timer <= 0;
                        if (uart_ready) begin uart_byte <= "T"; uart_start <= 1; tx_busy <= 1; state <= 50; end
                    end
                end else if (state >= 50 && state <= 68) begin
                    if (uart_ready && !tx_busy) begin
                        uart_start <= 1;
                        tx_busy <= 1;
                        case(state)
                            50: begin uart_byte <= ","; state <= 51; end
                            51: begin uart_byte <= ascii_cyc[63:56]; state <= 52; end
                            52: begin uart_byte <= ascii_cyc[55:48]; state <= 53; end
                            53: begin uart_byte <= ascii_cyc[47:40]; state <= 54; end
                            54: begin uart_byte <= ascii_cyc[39:32]; state <= 55; end
                            55: begin uart_byte <= ascii_cyc[31:24]; state <= 56; end
                            56: begin uart_byte <= ascii_cyc[23:16]; state <= 57; end
                            57: begin uart_byte <= ascii_cyc[15:8];  state <= 58; end
                            58: begin uart_byte <= ascii_cyc[7:0];   state <= 59; end
                            59: begin uart_byte <= ","; state <= 60; end
                            60: begin uart_byte <= ascii_tot_cmt[63:56]; state <= 61; end
                            61: begin uart_byte <= ascii_tot_cmt[55:48]; state <= 62; end
                            62: begin uart_byte <= ascii_tot_cmt[47:40]; state <= 63; end
                            63: begin uart_byte <= ascii_tot_cmt[39:32]; state <= 64; end
                            64: begin uart_byte <= ascii_tot_cmt[31:24]; state <= 65; end
                            65: begin uart_byte <= ascii_tot_cmt[23:16]; state <= 66; end
                            66: begin uart_byte <= ascii_tot_cmt[15:8];  state <= 67; end
                            67: begin uart_byte <= ascii_tot_cmt[7:0];   state <= 68; end
                            68: begin uart_byte <= "\n"; state <= 0; end
                        endcase
                    end else if (!uart_ready) begin
                        uart_start <= 0;
                        tx_busy <= 0;
                    end else uart_start <= 0;
                end else state <= 0;
            end else begin
                // VISUALIZER MODE (Slow Clock): Fire granular tags on every core tick
                if (state == 0) begin
                    if (core_clk_tick && uart_ready) begin
                        uart_byte <= "V"; uart_start <= 1; tx_busy <= 1; state <= 1;
                    end
                end else if (state > 0 && state <= 30) begin
                    if (uart_ready && !tx_busy) begin
                        uart_start <= 1;
                        tx_busy <= 1;
                        case(state)
                            1: begin uart_byte <= ","; state <= 2; end
                            // Dispatch 0
                            2: begin uart_byte <= active_dispatch_valid ? "1" : "0"; state <= 3; end
                            3: begin uart_byte <= active_dispatch_valid ? ascii_iq0[55:48] : "0"; state <= 4; end    // Extract High Nibble of the 8-bit tag
                            4: begin uart_byte <= active_dispatch_valid ? ascii_iq0[63:56] : "0"; state <= 5; end    // Extract Low Nibble of the 8-bit tag
                            5: begin uart_byte <= ","; state <= 6; end
                            
                            // Execute multiplexed
                            6: begin uart_byte <= active_cdb_valid ? "1" : "0"; state <= 7; end
                            7: begin uart_byte <= active_cdb_valid ? ascii_cdb0[55:48] : "0"; state <= 8; end
                            8: begin uart_byte <= active_cdb_valid ? ascii_cdb0[63:56] : "0"; state <= 9; end
                            9: begin uart_byte <= ","; state <= 10; end
                            
                            // Commit multiplexed
                            10: begin uart_byte <= active_commit_valid ? "1" : "0"; state <= 11; end
                            11: begin uart_byte <= active_commit_valid ? ascii_cmt0[55:48] : "0"; state <= 12; end
                            12: begin uart_byte <= active_commit_valid ? ascii_cmt0[63:56] : "0"; state <= 13; end
                            13: begin uart_byte <= "\n"; state <= 0; end
                        endcase
                    end else if (!uart_ready) begin
                        uart_start <= 0;
                        tx_busy <= 0;
                    end else uart_start <= 0;
                end else state <= 0;
            end
        end
    end

    assign leds[0] = locked;
    assign leds[1] = core_rst_n;
    assign leds[2] = sw_0; // Light up LED 2 when in Turbo
    assign leds[3] = flush; 

    //---------------------------------------------------------
    // 5. THE DEBUGGER (Restored ILA IP)
    //---------------------------------------------------------
    ila_0 your_debugger (
        .clk(clk_25mhz),
        .probe0(commit_valid[0]),
        .probe1(commit_pc),
        .probe2(ins0_fetch),
        .probe3(locked),
        .probe4(flush),
        .probe5(correct_pc)
    );

endmodule
