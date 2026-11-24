# Pratica - Processador uP3 de 16 bits | DE1 / Quartus II 13.0 SP1

## Abrir e compilar
1. Extraia a pasta em um caminho sem acentos ou espacos, por exemplo C:\FPGA\UP3_DE1_Verilog_Manual.
2. No Quartus II, File > Open Project, abra de1_top.qpf.
3. Abra de1_top.bdf pelo Project Navigator. Este e o esquematico real, editavel, e a entidade top-level. Nao existe um de1_top.v que o substitua.
4. Confirme Assignments > Device: Cyclone II, EP2C20F484C7 (DE1 original, nao DE1-SoC).
5. Processing > Start Compilation. O QSF contem a pinagem; o SDC define o clock de 50 MHz.
6. Tools > Programmer, Hardware Setup: USB-Blaster, JTAG. Selecione output_files/de1_top.sof, Program/Configure, Start. Placa ligada e chave RUN/PROG em RUN.

## Esquematico
- clock_control: sincroniza botoes e chaves, produz reset e um pulso de enable por pressionamento. Os botoes KEY da DE1 original possuem debounce fisico; nao ha divisor de frequencia.
- scomp: unidade de controle Moore, PC, IR, AC, ULA e sinais de memoria.
- memory256: RAM de 256 x 16, ALTSYNCRAM, MIF de inicializacao.
- display_interface: multiplexador e decodificadores de sete segmentos.
Os fios/barramentos de mesmo nome sao conectados eletricamente pelo Quartus, mesmo quando desenhados como ramos separados. Os cinco sinais AC, IR, PC, MAR e MW tem conexoes continuas entre CPU e interface. Os quatro BSF permitem reinserir os blocos. Para atualizar um simbolo apos mudar portas, abra o .v e use File > Create/Update > Create Symbol Files for Current File.

## Operacao
- KEY0: reset ativo em zero (nao restaura RAM; reprogramar a FPGA restaura o MIF).
- KEY1: avanca um estado por pressionamento. Solte o botao antes do proximo passo.
- SW0: nao conectado ao projeto.
- SW2 SW1=00: AC; 01: IR; 10: MDR; 11: PC (dois digitos) e MAR (dois digitos).
- LEDR[7:0] mostra PC; LEDR[8] mostra o estado STORE habilitado (escrita efetiva na borda com enable).

## Programa exigido
Todos os enderecos e valores sao hexadecimais.

00: 0210 LOAD 10 (AAAA)
01: 0011 ADD 11 (5555)
02: 0112 STORE 12 (FFFF)
03: 0212 LOAD 12 (confirma FFFF)
04: 0304 JUMP 04 (laco infinito)
10: AAAA; 11: 5555; 12: 0000 (inicial).

Com SW2/SW1=00, pressione e solte KEY0. Pressione e solte KEY1 quatro vezes para exibir AAAA; no setimo pressionamento aparece FFFF. No decimo pressionamento, a RAM recebe FFFF em 12. Para demonstrar a leitura, avance ate o passo 13 apos reset e selecione MDR (SW2=1, SW1=0); ele deve mostrar FFFF. No passo 14, LOAD confirma o resultado no AC. Sem novos pressionamentos, CPU e RAM permanecem no estado atual. No laco final, PC alterna 04/05 durante fetch e jump.

## Simulacao
No ModelSim-Altera, Transcript: cd {C:/FPGA/UP3_DE1_Verilog_Manual}; do sim.do
A biblioteca altera_mf_ver deve estar mapeada. Se indisponivel, execute do sim_comportamental.do, que usa uma RAM equivalente de teste e program.hex (mesma imagem do MIF).
O testbench testa CPU e RAM, incluindo a pausa e a confirmacao de leitura. O testbench tb_manual.v testa a interface de botoes integrada a CPU e RAM; execute do sim_manual.do (RAM comportamental). JNEG foi implementado mas nao faz parte do programa de teste exigido. Para editar o programa, mantenha MIF e HEX consistentes.

## Referencias e limitacoes
Pratica, slides 4, 7 e 11; Hamblen, Hall e Furman, Rapid Prototyping of Digital Systems, cap. 9, sec. 9.4 (pp. impressas 182-185) e figura 9.13. Adaptacao com atribuicoes nao bloqueantes, RAM separada, controle de enable e JNEG.
Projeto escrito para Quartus II 13.0 SP1, mas nao compilado aqui: Quartus, ModelSim e a DE1 fisica nao estao disponiveis. O BDF e os BSF foram gerados em formato textual nativo, com verificacao estrutural; precisam ser abertos/compilados no Quartus para confirmar interpretacao e sintese. Nenhum SOF precompilado. O arquivo gerar_bdf.py e opcional, apenas reproduz os esquematicos, nao e necessario no Quartus.
