# Processador de 16 bits em FPGA — µP3

Projeto da disciplina de Sistemas Digitais, do curso de Engenharia de Computação da Universidade Federal de São Carlos (UFSCar).

O circuito foi desenvolvido para a placa **Terasic DE1**, com FPGA **Cyclone II EP2C20F484C7**, utilizando o **Quartus II 13.0 SP1 (64 bits)**. A arquitetura segue o processador µP3 do capítulo 9 do livro *Rapid Prototyping of Digital Systems: SOPC Edition*. A entidade principal é o esquemático `de1_top.bdf`, com blocos auxiliares em Verilog. A execução é exclusivamente manual: cada pressão de KEY1 avança um estado da unidade de controle.

## Arquivos do projeto

- `projeto/de1_top.qpf`: projeto Quartus.
- `projeto/de1_top.qsf`: dispositivo, arquivos associados e atribuições de pinos.
- `projeto/de1_top.sdc`: restrições de temporização.
- `projeto/de1_top.bdf`: esquemático principal editável.
- `projeto/scomp.v`: processador de 16 bits, com unidade de controle Moore e ULA.
- `projeto/memory256.v`: RAM síncrona de 256 palavras de 16 bits.
- `projeto/clock_control.v`: sincronização das entradas, reset e pulso de avanço manual.
- `projeto/display_interface.v`: seleção de registradores, displays e LEDs.
- `projeto/*.bsf`: símbolos dos quatro componentes.
- `projeto/program.mif` e `projeto/program.hex`: programa e dados iniciais.
- `projeto/tb_scomp.v`, `projeto/tb_manual.v` e `projeto/sim*.do`: testbenches e scripts do ModelSim.
- [`projeto/LEIA-ME.md`](projeto/LEIA-ME.md): instruções complementares.
- `projeto/gerar_bdf.py` e `projeto/resultado_referencia.txt`: gerador de esquemático e resultados do modelo de referência.

Os arquivos da pasta `projeto/` correspondem ao pacote da versão manual.

## Funcionamento

O processador possui palavras de 16 bits, endereços de 8 bits e memória compartilhada entre instruções e dados. A instrução divide-se em opcode (8 bits superiores) e endereço (8 bits inferiores). A unidade de controle executa o ciclo de busca, decodificação e execução (Fetch, Decode, Execute).

| Opcode (hex) | Instrução | Operação |
|:--:|---|---|
| 00 | ADD | Soma o conteúdo da memória ao acumulador |
| 01 | STORE | Grava o acumulador na memória |
| 02 | LOAD | Carrega um dado da memória no acumulador |
| 03 | JUMP | Altera o contador de programa |
| 04 | JNEG | Desvia se o bit de sinal do acumulador for 1 |

O programa exigido na prática calcula A = B + C, com B = AAAA e C = 5555, armazenando FFFF no endereço 12.

| Endereço (hex) | Palavra | Significado |
|:--:|:--:|---|
| 00 | 0210 | LOAD 10 |
| 01 | 0011 | ADD 11 |
| 02 | 0112 | STORE 12 |
| 03 | 0212 | LOAD 12 (confirmação) |
| 04 | 0304 | JUMP 04 (laço infinito) |
| 10 | AAAA | B |
| 11 | 5555 | C |
| 12 | 0000 | A (valor inicial) |

### Controles da placa

| Entrada/saída | Função |
|---|---|
| KEY0 | Reset do processador |
| KEY1 | Um estado por pressionamento |
| SW2/SW1 | Seleção do registrador exibido |
| HEX3–HEX0 | Valor hexadecimal selecionado |
| LEDR[7:0] | Contador de programa (PC) |
| LEDR[8] | Habilitação de escrita (MW) |

| SW2 | SW1 | Saída selecionada |
|:--:|:--:|---|
| 0 | 0 | AC |
| 0 | 1 | IR |
| 1 | 0 | MDR |
| 1 | 1 | PC (dois dígitos) e MAR (dois dígitos) |

As demais chaves e botões não são utilizados. O clock de 50 MHz permanece ativo, mas a CPU e a RAM só avançam com o pulso de enable. Não há modo automático ou divisor de frequência.

## Abrir e compilar

1. Utilizar o Quartus II 13.0 SP1 com suporte à família Cyclone II.
2. Abrir [`projeto/de1_top.qpf`](projeto/de1_top.qpf), mantendo os arquivos associados na mesma pasta.
3. Conferir o dispositivo EP2C20F484C7 e abrir `de1_top.bdf`.
4. Executar **Processing > Start Compilation** e consultar os avisos.
5. Ligar a DE1, selecionar a posição RUN e conectar o USB-Blaster.
6. Em **Tools > Programmer**, escolher JTAG, adicionar `output_files/de1_top.sof`, marcar Program/Configure e iniciar a gravação.

## Testes na placa

Pressionar e soltar KEY0. Contar os pressionamentos de KEY1 a partir do reset, soltando o botão entre eles e sem reiniciar durante o teste.

| Pressões de KEY1 (total) | Verificação | Resultado esperado |
|:--:|---|---|
| 0 | Reset, SW2/SW1 = 00 | AC = 0000 |
| 4 | LOAD 10 | AC = AAAA |
| 7 | ADD 11 | AC = FFFF |
| 9 | Preparação do STORE | LEDR8 aceso |
| 10 | STORE 12 | LEDR8 apagado; escrita em RAM |
| 13 | Leitura de 12, SW2/SW1 = 10 | MDR = FFFF |
| 14 | LOAD 12, SW2/SW1 = 00 | AC = FFFF |
| 17 | JUMP 04, SW2/SW1 = 11 | PC = 04 (display 0404) |

Sem pressionar KEY1, os registradores mantêm seu estado. KEY0 não restaura a RAM; reprogramar a FPGA restaura o conteúdo inicial do MIF.

## Referências

- [Prática — Processador de 16 bits](Pr%C3%A1tica.pdf), Prof. Dr. Emerson Carlos Pedrino, DC/UFSCar.
- [Hamblen, Hall e Furman — Rapid Prototyping of Digital Systems: SOPC Edition](edddd8fa848a6ff8f0353f0b4be07d11.pdf), capítulo 9, seção 9.4, figura 9.13 (2008).
