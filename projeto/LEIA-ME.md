# µP3 – Processador de 16 bits com visualização VGA

DE1 original (Cyclone II EP2C20F484C7), Quartus II 13.0 SP1 (64 bits).
Base: arquivos-fonte do projeto manual UP3_DE1_Verilog_Manual.7z fornecido pelo usuário. O BDF continua como entidade principal. O programa MIF e o controle manual original foram preservados; a CPU ganhou uma saída de diagnóstico de estado, sem alterar suas transições. A RAM passou de uma porta para duas, com a porta B exclusivamente de leitura para o VGA. Nenhum clock de vídeo avança a CPU.

## Abrir e programar
1. Extraia todo o ZIP para uma pasta sem espaços ou acentos (por exemplo, C:\FPGA\UP3_DE1_VGA). Não mova os arquivos individualmente; `program.mif` e `tela.hex` precisam estar junto do projeto.
2. Abra `de1_top.qpf` em File > Open Project. Abra `de1_top.bdf` para visualizar os cinco blocos.
3. Confira Assignments > Device: Cyclone II, EP2C20F484C7 (DE1 original, não DE1-SoC).
4. Processing > Start Compilation. O QSF já contém os arquivos e pinos da DE1, inclusive os 14 pinos VGA. O SDC declara o clock de 50 MHz e deriva o clock da PLL.
5. Conecte o monitor ao conector VGA e selecione a entrada VGA no monitor. Ligue a DE1 e deixe RUN/PROG em RUN. Conecte USB-Blaster.
6. Tools > Programmer > JTAG: adicione `output_files/de1_top.sof` criado pela nova compilação, marque Program/Configure e clique Start.
7. Pressione e solte KEY0. A tela deve aparecer em 640 x 480, cerca de 59,52 Hz (pixel clock 25 MHz). Aguarde o próximo quadro após cada pressionamento. Pressione e solte KEY1 para avançar um único estado. KEY0 não restaura a RAM; reprogramar a FPGA restaura o MIF.

## Arquitetura
- `clock_control.v`: sincronizador e pulso de enable por pressão de KEY1. Sem modo automático.
- `scomp.v`: CPU (PC, IR, AC, ULA, máquina Moore, MAR e sinais de RAM); nova saída `state_out`.
- `memory256.v`: ALTSYNCRAM de 256 x 16, porta A original com enable e porta B de diagnóstico. A porta B varre os endereços 00..04 e 10..12; seus valores vêm da mesma RAM, sem cópia de dados independente. Após cada passo, a leitura de diagnóstico recomeça; qualquer colisão com STORE é descartada. A tabela não é um dump das 256 posições.
- `display_interface.v`: mantém HEX e LEDs como na versão anterior.
- `vga_datapath.v`: contador de passos, último estado, endereço efetivamente apresentado à RAM no último passo e validade do MDR. Handshake transfere um snapshot estável para o domínio de 25 MHz e aplica-o durante o blanking vertical.
- `VGA_SYNC.vhd`: adaptação do arquivo fornecido, com contadores exatos 800 x 525, vídeo ativo 640 x 480, pulsos HS/VS negativos e alinhamento do pipeline de desenho. `VGA_SYNC_original.txt` mantém o original para comparação, fora da compilação.
- `Video_PLL.vhd`: arquivo PLL fornecido, inalterado; converte 50 MHz em 25 MHz. Os dois VHDL são os únicos módulos de temporização VHDL; CPU, memória e desenho são Verilog.
- `datapath_renderer.v`, `font8.v` e `tela.hex`: mapa de tiles, caracteres e caminhos destacados, sem framebuffer externo. `gerar_tela.py` gera os arquivos de tela e a prévia; não precisa ser executado para compilar. `gerar_bdf.py` reproduz o BDF e os BSF.
- `preview_ADD.png`: prévia de referência produzida pelo mapa e fonte do renderer; não é foto do monitor nem captura de simulação RTL.

## Leitura da tela
Todos os números são hexadecimais, inclusive PASSO (por exemplo, 10 pressões = 000A). ESTADO é a ação que será executada na próxima pressão; ULTIMO indica o estado já executado. OP é a instrução em IR. Setas azuis destacam os caminhos relevantes ao estado; escrita em RAM é vermelha quando STORE está preparado. Os traçados são um esquema didático, não o RTL Viewer. A ULA mostra seus operandos AC e MDR, e OUT mostra a soma combinacional antes de ser gravada em AC no estado EXEC ADD. Nos outros estados, OUT fica em traços. PC+1 é a próxima contagem sequencial; MAR é o endereço atualmente selecionado pela CPU (pode diferir do último endereço realmente usado na RAM). ULT. END RAM mostra esse último endereço, inclusive em escrita. MDR VALIDO = 0 após reset ou STORE, quando o valor de leitura não deve ser interpretado; aparece como traços. MW = 1 é habilitação de escrita pendente; a gravação efetiva ocorre no próximo KEY1. NEG é o bit de sinal AC[15]. Os rótulos LOAD, ADD etc. ao lado da tabela são os papéis das posições no programa original, não um desassemblador dinâmico.

## Controles físicos
KEY0 reset; KEY1 avanço de estado; SW2/SW1 selecionam os displays físicos (00 AC, 01 IR, 10 MDR, 11 PC+MAR); LEDR[7:0] PC e LEDR8 MW. A VGA sempre mostra todos os registradores simultaneamente, independentemente das chaves. Outros botões e chaves não utilizados.

## Testes na placa (contagem de pressões decimal)
| Pressões | PASSO na tela | Resultado |
|---:|:---:|---|
| 0 | 0000 | AC=0000, PC=00, IR=0000; aguardar sem pressionar KEY1: CPU parada |
| 1 | 0001 | MDR=0210; estado FETCH |
| 2 | 0002 | IR=0210, PC=01, estado DECODE |
| 3 | 0003 | MDR=AAAA, estado EXEC LOAD |
| 4 | 0004 | AC=AAAA |
| 5 | 0005 | IR=0011, PC=02 |
| 6 | 0006 | EXEC ADD; AC=AAAA, MDR=5555, OUT=FFFF; setas azuis na ULA |
| 7 | 0007 | AC=FFFF |
| 8 | 0008 | IR=0112, PC=03 |
| 9 | 0009 | EXEC STORE; MW=1, caminho de escrita vermelho |
| 10 | 000A | MEM[12]=FFFF na tabela, MW=0; MDR não válido |
| 11 | 000B | FETCH preparado |
| 12 | 000C | IR=0212, PC=04 |
| 13 | 000D | MDR=FFFF lido da RAM |
| 14 | 000E | AC=FFFF, LOAD de confirmação concluído |
| 15 | 000F | IR=0304, PC=05 |
| 16 | 0010 | EXEC JUMP |
| 17 | 0011 | PC=04; continuar pressionando KEY1 mantém o laço 04/05 |

## Simulação e verificações
No ModelSim-Altera, execute a partir desta pasta `do sim_vga.do` (RAM comportamental) ou `do sim_vga_ram_real.do` (ALTSYNCRAM, biblioteca altera_mf_ver). Testa a leitura de diagnóstico da RAM, operandos da ULA, STORE e caracteres dinâmicos do desenho. Os scripts `sim.do`, `sim_comportamental.do` e `sim_manual.do` foram mantidos para testes da CPU. O teste da VGA não simula a PLL ou o conector físico. `python verificar_vga.py` testa o modelo de referência, a imagem MIF/HEX, a unicidade da pinagem e os campos da ROM de tela; o resultado está em `verificacao_vga.txt`.

## Referências e limitações
Prática, slides 4, 7 e 11; Hamblen, Hall e Furman, Rapid Prototyping of Digital Systems, cap. 9, seção 9.4 e figura 9.13. VGA baseado nos módulos fornecidos pelo usuário; pinagem de vídeo: Terasic DE1 User Manual, tabela 4.8 (https://www.terasic.com.tw/attachment/archive/83/DE1_UserManual_v1018.pdf).
A versão anterior do .7z tinha relatório Quartus bem-sucedido, mas os relatórios e SOF antigos foram excluídos por não representarem a nova versão. Nesta máquina não há Quartus, ModelSim nem DE1 física: a nova síntese (incluindo ALTSYNCRAM bidirecional, PLL e BDF atualizado), a simulação RTL e a saída real no monitor ainda precisam ser verificadas. Não há SOF pré-compilado. A prévia e o modelo de referência não comprovam a síntese nem temporização.
