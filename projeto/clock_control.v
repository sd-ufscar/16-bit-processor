// DE1 original: KEY ativo em zero, com debounce fisico na placa.
// CLOCK_50 permanece o clock comum. Um pressionamento de KEY1 gera
// um unico enable de um ciclo, sem divisor nem modo de execucao livre.
module clock_control (
    input wire clock,
    input wire [1:0] key,
    input wire [1:0] sw,
    output wire reset, enable,
    output wire [1:0] select_reg
);
    reg [1:0] reset_sync=2'b11, key_sync=2'b11;
    reg key_previous=1'b1;
    reg [1:0] sw_meta=0, sw_sync=0;
    always @(posedge clock) begin
        reset_sync <= {reset_sync[0], ~key[0]};
        key_sync <= {key_sync[0], key[1]};
        key_previous <= key_sync[1];
        sw_meta <= sw;
        sw_sync <= sw_meta;
    end
    assign reset=reset_sync[1];
    assign enable=!reset && key_previous && !key_sync[1];
    assign select_reg=sw_sync;
endmodule
