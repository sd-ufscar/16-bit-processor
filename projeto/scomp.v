// uP3 - Unidade de controle Moore e caminho de dados (cap. 9).
// MAR seleciona o endereco; MDR e a saida sincrona da RAM externa ao bloco.
module scomp (
    input wire clock, reset, enable,
    input wire [15:0] mdr,
    output reg [15:0] ac, ir,
    output reg [7:0] pc,
    output reg [7:0] mar,
    output wire mw, mem_enable
);
    localparam RESET_PC=4'd0, FETCH=4'd1, DECODE=4'd2,
        EXEC_ADD=4'd3, EXEC_STORE=4'd4, EXEC_STORE2=4'd5,
        EXEC_LOAD=4'd6, EXEC_JUMP=4'd7, EXEC_NOP=4'd8;
    reg [3:0] state;
    initial begin state=RESET_PC; pc=0; ir=0; ac=0; end

    // O endereco da RAM e registrado internamente pelo altsyncram.
    always @* begin
        case (state)
            RESET_PC: mar=8'h00;
            DECODE, EXEC_STORE, EXEC_JUMP: mar=ir[7:0];
            default: mar=pc;
        endcase
    end
    assign mw = (state == EXEC_STORE) && !reset;
    assign mem_enable = enable && !reset;

    always @(posedge clock) begin
        if (reset) begin
            state <= RESET_PC; pc <= 0; ac <= 0; ir <= 0;
        end else if (enable) begin
            case (state)
                RESET_PC: state <= FETCH;
                FETCH: begin
                    ir <= mdr; pc <= pc + 8'd1; state <= DECODE;
                end
                DECODE: begin
                    case (ir[15:8])
                        8'h00: state <= EXEC_ADD;
                        8'h01: state <= EXEC_STORE;
                        8'h02: state <= EXEC_LOAD;
                        8'h03: state <= EXEC_JUMP;
                        8'h04: state <= ac[15] ? EXEC_JUMP : EXEC_NOP;
                        default: state <= EXEC_NOP;
                    endcase
                end
                EXEC_ADD: begin ac <= ac + mdr; state <= FETCH; end
                EXEC_LOAD: begin ac <= mdr; state <= FETCH; end
                EXEC_STORE: state <= EXEC_STORE2;
                EXEC_STORE2: state <= FETCH;
                EXEC_JUMP: begin pc <= ir[7:0]; state <= FETCH; end
                EXEC_NOP: state <= FETCH;
                default: state <= RESET_PC;
            endcase
        end
    end
endmodule
