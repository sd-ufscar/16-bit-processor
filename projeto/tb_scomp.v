`timescale 1ns/1ps
module tb_scomp;
    reg clock=0, reset=1, enable=0;
    wire [15:0] ac, ir, mdr;
    wire [7:0] pc, mar;
    wire mw, mem_enable;
    integer writes=0;
    always #10 clock=~clock;
    scomp cpu(.clock(clock),.reset(reset),.enable(enable),.mdr(mdr),.ac(ac),.ir(ir),.pc(pc),.mar(mar),.mw(mw),.mem_enable(mem_enable));
    memory256 ram(.clock(clock),.mem_enable(mem_enable),.mw(mw),.mar(mar),.ac(ac),.mdr(mdr));
    always @(posedge clock) if (mem_enable && mw) begin
        if (mar!==8'h12 || ac!==16'hFFFF) begin $display("FAIL STORE"); $stop; end
        writes=writes+1;
    end
    task step;
        input integer n;
        begin
            @(negedge clock); enable=1;
            repeat(n) @(negedge clock);
            enable=0;
        end
    endtask
    initial begin
        $dumpfile("tb_scomp.vcd"); $dumpvars(0,tb_scomp);
        repeat(3) @(negedge clock); reset=0;
        step(4);
        if(ac!==16'hAAAA || pc!==8'h01) begin $display("FAIL LOAD"); $stop; end
        step(3);
        if(ac!==16'hFFFF || pc!==8'h02) begin $display("FAIL ADD"); $stop; end
        step(2); // FETCH e DECODE: pausa antes da escrita
        repeat(5) @(negedge clock);
        if(writes!=0 || mw!==1'b1) begin $display("FAIL PAUSE"); $stop; end
        step(2);
        if(writes!=1) begin $display("FAIL WRITE COUNT"); $stop; end
        step(2); // FETCH, DECODE: MDR recebe MEM(12)
        if(mdr!==16'hFFFF || ir!==16'h0212) begin $display("FAIL READBACK"); $stop; end
        step(1);
        if(ac!==16'hFFFF || pc!==8'h04) begin $display("FAIL LOAD RESULT"); $stop; end
        step(12);
        if(ac!==16'hFFFF || pc!==8'h04 || ir!==16'h0304 || writes!=1) begin $display("FAIL JUMP"); $stop; end
        $display("PASS: LOAD, ADD, STORE, PAUSE, READBACK, JUMP"); $finish;
    end
endmodule
