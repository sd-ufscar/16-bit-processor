// RAM unificada de 256 palavras de 16 bits. Sintese: M4K / ALTSYNCRAM.
module memory256 (
    input wire clock, mem_enable, mw,
    input wire [7:0] mar,
    input wire [15:0] ac,
    output wire [15:0] mdr
);
`ifdef SIM_BEHAVIORAL
    // Modelo opcional para simuladores sem a biblioteca Altera.
    // program.hex contem exatamente a mesma imagem de program.mif.
    reg [15:0] ram [0:255];
    reg [15:0] q;
    initial $readmemh("program.hex", ram);
    always @(posedge clock) if (mem_enable) begin
        if (mw) begin ram[mar] <= ac; q <= ac; end
        else q <= ram[mar];
    end
    assign mdr=q;
`else
    altsyncram #(
        .operation_mode("SINGLE_PORT"), .width_a(16), .widthad_a(8),
        .numwords_a(256), .width_byteena_a(1), .outdata_reg_a("UNREGISTERED"),
        .clock_enable_input_a("NORMAL"), .clock_enable_output_a("BYPASS"),
        .init_file("program.mif"), .intended_device_family("Cyclone II"),
        .lpm_type("altsyncram"), .power_up_uninitialized("FALSE")
    ) memory (
        .clock0(clock), .clocken0(mem_enable), .wren_a(mw),
        .address_a(mar), .data_a(ac), .q_a(mdr), .rden_a(1'b1),
        .aclr0(1'b0), .aclr1(1'b0), .addressstall_a(1'b0),
        .byteena_a(1'b1)
    );
`endif
endmodule
