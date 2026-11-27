// RAM unificada. Porta A: CPU original; porta B: somente leitura para VGA.
module memory256 (
    input wire clock, mem_enable, mw,
    input wire [7:0] mar,
    input wire [15:0] ac,
    output wire [15:0] mdr,
    output reg [127:0] debug_words = 0,
    output reg debug_valid = 0
);
    // Lê 00..04 e 10..12 da própria RAM. Nunca escreve pela porta B.
    reg [3:0] scan = 0;
    wire [7:0] addr_b = (scan < 5) ? {4'b0,scan} : (8'h10 + {4'b0,scan} - 8'd5);
    wire [15:0] q_b;
    always @(posedge clock) begin
        // Descarta a varredura durante qualquer passo da CPU (inclusive STORE).
        if (mem_enable) begin scan <= 0; debug_valid <= 0; end
        else if (!debug_valid) begin
            if (scan != 0) debug_words[(scan-1)*16 +: 16] <= q_b;
            if (scan == 8) debug_valid <= 1;
            else scan <= scan + 1'b1;
        end
    end
`ifdef SIM_BEHAVIORAL
    reg [15:0] ram [0:255];
    reg [15:0] q, qb;
    initial $readmemh("program.hex", ram);
    always @(posedge clock) begin
        qb <= ram[addr_b];
        if (mem_enable) begin
            if (mw) begin ram[mar] <= ac; q <= ac; end
            else q <= ram[mar];
        end
    end
    assign mdr=q;
    assign q_b=qb;
`else
    altsyncram #(
        .operation_mode("BIDIR_DUAL_PORT"), .width_a(16), .widthad_a(8),
        .numwords_a(256), .width_byteena_a(1), .outdata_reg_a("UNREGISTERED"),
        .width_b(16), .widthad_b(8), .numwords_b(256), .width_byteena_b(1),
        .address_reg_b("CLOCK1"), .outdata_reg_b("UNREGISTERED"),
        .indata_reg_b("CLOCK1"), .wrcontrol_wraddress_reg_b("CLOCK1"),
        .byteena_reg_b("CLOCK1"),
        .clock_enable_input_a("NORMAL"), .clock_enable_output_a("BYPASS"),
        .clock_enable_input_b("NORMAL"), .clock_enable_output_b("BYPASS"),
        .read_during_write_mode_mixed_ports("DONT_CARE"),
        .init_file("program.mif"), .intended_device_family("Cyclone II"),
        .lpm_type("altsyncram"), .power_up_uninitialized("FALSE")
    ) memory (
        .clock0(clock), .clock1(clock), .clocken0(mem_enable), .clocken1(1'b1),
        .wren_a(mw), .address_a(mar), .data_a(ac), .q_a(mdr), .rden_a(1'b1),
        .wren_b(1'b0), .address_b(addr_b), .data_b(16'b0), .q_b(q_b), .rden_b(1'b1),
        .aclr0(1'b0), .aclr1(1'b0), .addressstall_a(1'b0), .addressstall_b(1'b0),
        .byteena_a(1'b1), .byteena_b(1'b1)
    );
`endif
endmodule
