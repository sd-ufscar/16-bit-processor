`timescale 1ns/1ps
// Teste da RAM real (quando biblioteca Altera disponível) ou comportamental,
// e dos caracteres do renderer. Nao testa a PLL nem os pinos VGA.
module tb_vga;
    reg clock=0, reset=1, enable=0;
    always #10 clock=~clock;
    wire [15:0] ac,ir,mdr;
    wire [7:0] pc,mar;
    wire mw,mem_enable,debug_valid;
    wire [3:0] state_out;
    wire [127:0] debug_words;
    scomp cpu(.clock(clock),.reset(reset),.enable(enable),.mdr(mdr),.ac(ac),.ir(ir),.pc(pc),.mar(mar),.mw(mw),.mem_enable(mem_enable),.state_out(state_out));
    memory256 ram(.clock(clock),.mem_enable(mem_enable),.mw(mw),.mar(mar),.ac(ac),.mdr(mdr),.debug_words(debug_words),.debug_valid(debug_valid));
    reg [225:0] frame=0;
    reg [9:0] x=0,y=0;
    wire r,g,b;
    datapath_renderer draw(.pixel_clock(clock),.x(x),.y(y),.frame(frame),.red(r),.green(g),.blue(b));
    task step;
        input integer count;
        begin @(negedge clock); enable=1; repeat(count) @(negedge clock); enable=0;
            repeat(12) @(negedge clock);
            if(!debug_valid) begin $display("FAIL debug_valid"); $stop; end
        end
    endtask
    task glyph;
        input integer col,row;
        input [7:0] expected;
        begin x=col*16; y=row*16;
            repeat(2) @(negedge clock);
            if(draw.ch!==expected) begin $display("FAIL tile (%0d,%0d) expected %c actual %c",col,row,expected,draw.ch); $stop; end
        end
    endtask
    initial begin
        repeat(3) @(negedge clock); reset=0;
        repeat(12) @(negedge clock);
        if(debug_words[15:0]!==16'h0210 || debug_words[95:80]!==16'hAAAA || debug_words[127:112]!==16'h0000) begin $display("FAIL initial RAM table"); $stop; end
        step(6);
        if(state_out!==4'd3 || ac!==16'hAAAA || mdr!==16'h5555) begin $display("FAIL ADD operands"); $stop; end
        frame={state_out,4'd2,16'd6,ac,ir,pc,mar,mdr,mw,8'h11,1'b1,debug_words};
        glyph(7,10,"5"); glyph(14,10,"A"); glyph(10,12,"F"); glyph(13,12,"F");
        glyph(30,13,"0"); glyph(33,13,"0");
        step(4);
        if(debug_words[127:112]!==16'hFFFF || ac!==16'hFFFF) begin $display("FAIL RAM write/diagnostic port"); $stop; end
        frame={state_out,4'd4,16'd10,ac,ir,pc,mar,mdr,mw,8'h12,1'b0,debug_words};
        glyph(30,13,"F"); glyph(33,13,"F"); glyph(10,26,"-");
        step(3);
        if(mdr!==16'hFFFF) begin $display("FAIL readback"); $stop; end
        $display("PASS: RAM scan, ADD operands, ALU result, STORE and dynamic VGA characters"); $finish;
    end
endmodule
