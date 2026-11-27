// Renderer de tiles 16x16. ROM de tela com leitura sincrona (1 ciclo).
module datapath_renderer(input wire pixel_clock, input wire [9:0] x,y,
    input wire [225:0] frame, output wire red,green,blue);
    wire [3:0] state_now, prev;
    wire [15:0] steps, ac, ir, mdr;
    wire [7:0] pc, mar, last_addr;
    wire mw, mdr_valid;
    wire [127:0] mem;
    assign {state_now,prev,steps,ac,ir,pc,mar,mdr,mw,last_addr,mdr_valid,mem}=frame;
    wire [15:0] sum=ac+mdr;
    wire [7:0] next_pc=pc+8'd1;
    // Multiplicação por 40 via somas: linha*32 + linha*8 + coluna.
    wire [10:0] row_index={5'b0,y[9:4]};
    wire [10:0] tile_addr=(row_index<<5)+(row_index<<3)+{5'b0,x[9:4]};
    reg [20:0] tile_rom [0:2047];
    initial $readmemh("tela.hex",tile_rom);
    reg [20:0] tile=0;
    reg [2:0] gx=0,gy=0;
    always @(posedge pixel_clock) begin
        tile<=tile_rom[tile_addr];
        gx<=x[3:1]; gy<=y[3:1];
    end
    wire [4:0] field=tile[12:8];
    wire [3:0] ix=tile[16:13], group_id=tile[20:17];
    reg [7:0] ch;
    reg [119:0] str;
    reg [15:0] number;
    reg [2:0] digits;
    reg unknown_value;
    function [7:0] hexchar;
        input [3:0] n;
        begin hexchar=(n<10)?(8'h30+{4'b0,n}):(8'h41+{4'b0,n}-8'd10); end
    endfunction
    function [119:0] statename;
        input [3:0] st;
        begin case(st)
            4'd0: statename="RESET PC       ";
            4'd1: statename="FETCH          ";
            4'd2: statename="DECODE         ";
            4'd3: statename="EXEC ADD       ";
            4'd4: statename="EXEC STORE     ";
            4'd5: statename="STORE2         ";
            4'd6: statename="EXEC LOAD      ";
            4'd7: statename="EXEC JUMP      ";
            4'd8: statename="EXEC NOP       ";
            default: statename="INVALIDO       ";
        endcase end
    endfunction
    function [119:0] opname;
        input [7:0] op;
        begin case(op)
            8'h00: opname="ADD            ";
            8'h01: opname="STORE          ";
            8'h02: opname="LOAD           ";
            8'h03: opname="JUMP           ";
            8'h04: opname="JNEG           ";
            default: opname="NOP            ";
        endcase end
    endfunction
    // Texto da acao que sera executada no proximo KEY1.
    function [119:0] action1;
        input [3:0] st;
        begin case(st)
            4'd0: action1="LER MEM 00     ";
            4'd1: action1="IR <- MDR      ";
            4'd2: action1="MAR <- IR ADDR ";
            4'd3: action1="AC <- AC+MDR   ";
            4'd4: action1="MEM[MAR] <- AC ";
            4'd5: action1="LER PROX. INST ";
            4'd6: action1="AC <- MDR      ";
            4'd7: action1="PC <- IR ADDR  ";
            4'd8: action1="MANTER PC      ";
            default: action1="               ";
        endcase end
    endfunction
    function [119:0] action2;
        input [3:0] st;
        begin case(st)
            4'd0: action2="PREPARAR FETCH ";
            4'd1: action2="PC <- PC+1     ";
            4'd2: action2="LER OPERANDO   ";
            4'd3: action2="LER PROX. INST ";
            4'd4: action2="ESCREVER RAM   ";
            4'd5: action2="RETORNAR FETCH ";
            4'd6: action2="LER PROX. INST ";
            4'd7: action2="LER DESTINO    ";
            4'd8: action2="LER PROX. INST ";
            default: action2="               ";
        endcase end
    endfunction
    always @* begin
        ch=tile[7:0]; str="               "; number=0; digits=0; unknown_value=0;
        case(field)
            1: begin number=steps; digits=4; end
            2: str=statename(state_now);
            3: if(steps!=0) str=statename(prev); else str="---            ";
            4: if(steps>=2) str=opname(ir[15:8]); else str="---            ";
            5: begin number=ir; digits=4; end
            6: begin number={8'b0,ir[15:8]}; digits=2; end
            7: begin number=ac; digits=4; end
            8,14: begin number=mdr; digits=4; unknown_value=!mdr_valid; end
            9: if(state_now==3) str="ADD            "; else str="---            ";
            10: begin number=sum; digits=4; unknown_value=state_now!=3 || !mdr_valid; end
            11: begin number={8'b0,pc}; digits=2; end
            12: begin number={8'b0,next_pc}; digits=2; end
            13: begin number={8'b0,mar}; digits=2; end
            15: begin number={15'b0,mw}; digits=1; end
            16,17,18,19,20,21,22,23: begin number=mem[(field-16)*16 +:16]; digits=4; end
            24: begin number={15'b0,ac[15]}; digits=1; end
            25: begin number={8'b0,last_addr}; digits=2; unknown_value=steps==0; end
            26: begin number={15'b0,mdr_valid}; digits=1; end
            27: begin number={8'b0,ir[7:0]}; digits=2; end
            28: str=action1(state_now);
            29: str=action2(state_now);
            default: ;
        endcase
        if(field!=0) begin
            if(digits!=0) begin
                if(unknown_value) ch=8'h2D;
                else ch=hexchar((number >> ((digits-1-ix)*4)) & 16'h000F);
            end else if(ix<15) ch=str[119-ix*8 -:8];
            else ch=8'h20;
        end
    end
    wire ink;
    font8 fnt(.ch(ch),.x(gx),.y(gy),.ink(ink));
    reg active_path;
    always @* begin
        case(group_id)
            1: active_path=state_now==1;
            2: active_path=state_now==2 || state_now==7;
            3: active_path=state_now==3;
            4: active_path=state_now==6;
            5: active_path=state_now==4;
            6: active_path=state_now==0 || state_now==1 || state_now==3 || state_now==5 || state_now==6 || state_now==8;
            7: active_path=1;
            8: active_path=state_now!=4;
            9: active_path=state_now==3 || state_now==4;
            10: active_path=1;
            default: active_path=0;
        endcase
    end
    // Fundo branco; preto inativo; azul ativo; vermelho para escrita.
    assign red = !ink || (active_path && group_id==5);
    assign green = !ink;
    assign blue = !ink || (active_path && group_id!=5);
endmodule
