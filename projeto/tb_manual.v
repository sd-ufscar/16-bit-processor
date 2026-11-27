`timescale 1ns/1ps
module tb_manual;
    reg clock=0;
    reg [1:0] key=2'b11, sw=2'b00;
    wire reset, enable, mw, mem_enable;
    wire [1:0] select_reg;
    wire [15:0] ac, ir, mdr;
    wire [7:0] pc, mar;
    integer pulses=0, writes=0;
    always #10 clock=~clock;
    clock_control control(clock,key,sw,reset,enable,select_reg);
    scomp cpu(.clock(clock),.reset(reset),.enable(enable),.mdr(mdr),.ac(ac),.ir(ir),.pc(pc),.mar(mar),.mw(mw),.mem_enable(mem_enable));
    memory256 ram(.clock(clock),.mem_enable(mem_enable),.mw(mw),.mar(mar),.ac(ac),.mdr(mdr));
    always @(posedge clock) begin
        if (enable) pulses=pulses+1;
        if (mem_enable && mw) writes=writes+1;
    end
    task press;
        begin
            @(negedge clock); key[1]=0;
            repeat(20) @(negedge clock);
            key[1]=1;
            repeat(10) @(negedge clock);
        end
    endtask
    initial begin
        @(negedge clock); key[0]=0;
        repeat(10) @(negedge clock); key[0]=1;
        repeat(50) @(negedge clock);
        if(pulses!=0 || pc!==0 || ac!==0) begin $display("FAIL idle"); $stop; end
        repeat(4) press;
        if(pulses!=4 || ac!==16'hAAAA) begin $display("FAIL LOAD/button"); $stop; end
        repeat(3) press;
        if(pulses!=7 || ac!==16'hFFFF) begin $display("FAIL ADD/button"); $stop; end
        repeat(2) press;
        repeat(50) @(negedge clock);
        if(writes!=0 || pulses!=9) begin $display("FAIL pause before STORE"); $stop; end
        press;
        if(writes!=1 || pulses!=10) begin $display("FAIL STORE/button"); $stop; end
        repeat(3) press;
        sw=2'b10;
        repeat(10) @(negedge clock);
        if(pulses!=13 || mdr!==16'hFFFF || select_reg!==2'b10) begin $display("FAIL readback"); $stop; end
        press;
        repeat(12) press;
        if(pulses!=26 || pc!==8'h04 || ac!==16'hFFFF || writes!=1) begin $display("FAIL JUMP/button"); $stop; end
        $display("PASS manual: one pulse per press, idle, LOAD, ADD, STORE, READBACK, JUMP");
        $finish;
    end
endmodule
