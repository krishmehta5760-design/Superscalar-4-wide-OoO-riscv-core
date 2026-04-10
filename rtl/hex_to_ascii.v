module hex_to_ascii (
    input [31:0] hex_in,
    output [63:0] ascii_out
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : hex_loop
            wire [3:0] hex_digit = hex_in[i*4 +: 4];
            assign ascii_out[(7-i)*8 +: 8] = (hex_digit < 10) ? (hex_digit + 8'h30) : (hex_digit + 8'h37);
        end
    endgenerate
endmodule
