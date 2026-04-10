// NexysVideo_Top.v - Ultra-Stable 9600 Baud Version
module NexysVideo_Top(
    input clk_100mhz,
    input reset_btn,
    output uart_tx_pin,
    output [7:0] leds
);

    wire clk_25mhz, locked;
    clk_wiz_0 clock_gen (.clk_in1(clk_100mhz), .clk_out1(clk_25mhz), .reset(1'b0), .locked(locked));

    wire core_rst_n = locked && !reset_btn;
    wire [31:0] commit_pc; 
    wire [3:0] commit_valid;

    TOP core_inst (.clk(clk_25mhz), .rst(core_rst_n), .commit_valid(commit_valid), .pc(commit_pc));

    // UART - Switching to 9600 for maximum reliability
    wire uart_ready;
    reg uart_start;
    reg [7:0] uart_byte;
    uart_tx #(.CLK_FREQ(25000000), .BAUD_RATE(9600)) utx (
        .clk(clk_25mhz), .rst_n(core_rst_n), .data_in(uart_byte), .start(uart_start), .tx(uart_tx_pin), .ready(uart_ready)
    );

    wire [63:0] pc_ascii;
    hex_to_ascii h2a (.hex_in(commit_pc), .ascii_out(pc_ascii));

    reg [4:0] state;
    reg [23:0] timer;
    reg last_commit; // For edge detection

    always @(posedge clk_25mhz or negedge core_rst_n) begin
        if (!core_rst_n) begin
            state <= 0; uart_start <= 0; timer <= 0; last_commit <= 0;
        end else begin
            uart_start <= 0;
            if (timer > 0) timer <= timer - 1;
            else begin
                case (state)
                    0: begin // Wait for POSITIVE EDGE of commit
                        if (commit_valid[0] && !last_commit && uart_ready) begin
                            uart_byte <= "P"; uart_start <= 1; state <= 1; timer <= 5000;
                        end
                        last_commit <= commit_valid[0];
                    end
                    1:  if (uart_ready) begin uart_byte <= "C"; uart_start <= 1; state <= 2;  timer <= 5000; end
                    2:  if (uart_ready) begin uart_byte <= ":"; uart_start <= 1; state <= 3;  timer <= 5000; end
                    3:  if (uart_ready) begin uart_byte <= " "; uart_start <= 1; state <= 4;  timer <= 5000; end
                    4:  if (uart_ready) begin uart_byte <= pc_ascii[63:56]; uart_start <= 1; state <= 5; timer <= 5000; end
                    5:  if (uart_ready) begin uart_byte <= pc_ascii[55:48]; uart_start <= 1; state <= 6; timer <= 5000; end
                    6:  if (uart_ready) begin uart_byte <= pc_ascii[47:40]; uart_start <= 1; state <= 7; timer <= 5000; end
                    7:  if (uart_ready) begin uart_byte <= pc_ascii[39:32]; uart_start <= 1; state <= 8; timer <= 5000; end
                    8:  if (uart_ready) begin uart_byte <= pc_ascii[31:24]; uart_start <= 1; state <= 9; timer <= 5000; end
                    9:  if (uart_ready) begin uart_byte <= pc_ascii[23:16]; uart_start <= 1; state <= 10;timer <= 5000; end
                    10: if (uart_ready) begin uart_byte <= pc_ascii[15:8];  uart_start <= 1; state <= 11;timer <= 5000; end
                    11: if (uart_ready) begin uart_byte <= pc_ascii[7:0];   uart_start <= 1; state <= 12;timer <= 5000; end
                    12: if (uart_ready) begin uart_byte <= "\r";           uart_start <= 1; state <= 13;timer <= 5000; end
                    13: if (uart_ready) begin uart_byte <= "\n";           uart_start <= 1; state <= 0; timer <= 10000; end
                endcase
            end
        end
    end

    assign leds[2:0] = {uart_ready, core_rst_n, locked};
    assign leds[7:3] = commit_pc[6:2];

endmodule
