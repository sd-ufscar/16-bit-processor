// Visualizador do uP3. Nenhum sinal de vídeo habilita a CPU.
// Snapshot coerente em handshake entre 50 MHz e clock de pixel de 25 MHz.
module vga_datapath(
    input wire clock, reset, enable,
    input wire [15:0] ac, ir, mdr,
    input wire [7:0] pc, mar,
    input wire mw,
    input wire [3:0] state_out,
    input wire [127:0] debug_words,
    input wire debug_valid,
    output wire [3:0] VGA_R, VGA_G, VGA_B,
    output wire VGA_HS, VGA_VS
);
    wire pclk, active;
    wire [9:0] x,y;
    wire r,g,b,ro,go,bo;
    VGA_SYNC sync_video(.clock_50Mhz(clock),.red(r),.green(g),.blue(b),
        .red_out(ro),.green_out(go),.blue_out(bo),.horiz_sync_out(VGA_HS),
        .vert_sync_out(VGA_VS),.video_on(active),.pixel_clock(pclk),
        .pixel_row(y),.pixel_column(x));
    assign VGA_R={4{ro}}; assign VGA_G={4{go}}; assign VGA_B={4{bo}};
    reg [15:0] step_count=0;
    reg [3:0] previous=0;
    reg [7:0] last_addr=0;
    reg mdr_valid=0;
    always @(posedge clock) begin
        if(reset) begin step_count<=0; previous<=0; last_addr<=0; mdr_valid<=0; end
        else if(enable) begin
            step_count<=step_count+1'b1;
            previous<=state_out; last_addr<=mar; mdr_valid<=!mw;
        end
    end
    reg request=0, req_meta=0, req_sync=0, ack=0;
    reg ack_meta=0, ack_sync=0, seen=0;
    reg [225:0] held=0, frame=0;
    always @(posedge clock) begin
        req_meta<=request; req_sync<=req_meta;
        // Bundle estável até o próximo pedido de quadro. A porta B conclui a
        // varredura antes do snapshot, inclusive após escrita na RAM.
        if(req_sync!=ack && debug_valid && !enable && !reset) begin
            held<={state_out,previous,step_count,ac,ir,pc,mar,mdr,mw,last_addr,mdr_valid,debug_words};
            ack<=req_sync;
        end
    end
    always @(posedge pclk) begin
        ack_meta<=ack; ack_sync<=ack_meta;
        if(x==0 && y==480 && ack_sync==request && seen==ack_sync) request<=~request;
        if(y>=480 && ack_sync!=seen) begin frame<=held; seen<=ack_sync; end
    end
    datapath_renderer renderer(.pixel_clock(pclk),.x(x),.y(y),.frame(frame),.red(r),.green(g),.blue(b));
endmodule
