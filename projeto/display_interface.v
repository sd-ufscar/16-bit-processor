// HEX[6:0] = gfedcba (segmentos ativos em zero).
module display_interface (
    input wire [15:0] ac, ir,
    input wire [7:0] pc, mar,
    input wire mw,
    input wire [15:0] mdr,
    input wire [1:0] select_reg,
    output wire [6:0] HEX0, HEX1, HEX2, HEX3,
    output wire [8:0] LEDR
);
    reg [15:0] word_display;
    always @* begin
        case (select_reg)
            2'b00: word_display=ac;
            2'b01: word_display=ir;
            2'b10: word_display=mdr;
            default: word_display={pc,mar};
        endcase
    end
    function [6:0] hex7;
        input [3:0] n;
        begin
            case (n)
                4'h0: hex7=7'b1000000;
                4'h1: hex7=7'b1111001;
                4'h2: hex7=7'b0100100;
                4'h3: hex7=7'b0110000;
                4'h4: hex7=7'b0011001;
                4'h5: hex7=7'b0010010;
                4'h6: hex7=7'b0000010;
                4'h7: hex7=7'b1111000;
                4'h8: hex7=7'b0000000;
                4'h9: hex7=7'b0010000;
                4'hA: hex7=7'b0001000;
                4'hB: hex7=7'b0000011;
                4'hC: hex7=7'b1000110;
                4'hD: hex7=7'b0100001;
                4'hE: hex7=7'b0000110;
                4'hF: hex7=7'b0001110;
                default: hex7=7'b1111111;
            endcase
        end
    endfunction
    assign HEX0=hex7(word_display[3:0]);
    assign HEX1=hex7(word_display[7:4]);
    assign HEX2=hex7(word_display[11:8]);
    assign HEX3=hex7(word_display[15:12]);
    assign LEDR={mw,pc};
endmodule
