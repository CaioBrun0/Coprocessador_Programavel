**Universidade Estadual de Feira de Santana (UEFS)**  
**Departamento de Tecnologia - Área de Eletrônica**  
**Disciplina: Sistemas Digitais (TEC499) - 2026.2**  
**Autores: Felipe Gomes e Caio Bruno Oliveira**
---

# Problema #2 — Coprocessador Gráfico Programável

## Descrição do Projeto

Este projeto transforma o núcleo gráfico desenvolvido no Problema 1 (background, sprites e polígonos) em um coprocessador gráfico programável na FPGA Cyclone V da DE1-SoC. Em vez de controlar cada módulo gráfico individualmente, a aplicação passa a enviar instruções de 32 bits ao coprocessador; o hardware busca, decodifica e executa cada instrução, acionando a unidade funcional correspondente.

O processador ARM (HPS) executa uma aplicação em C que usa um driver em Assembly ARM (`gpu_driver.s`); o driver mapeia o coprocessador via `/dev/mem` e envia as instruções por MMIO (ponte Lightweight HPS-to-FPGA) para uma fila (FIFO) interna. Uma unidade de controle (FSM) retira as instruções da fila, armazena-as no Registrador de Instrução (IR), decodifica os campos e atualiza o datapath que alimenta os motores gráficos. O compositor, a unidade de controle de quadro e o controlador VGA operam continuamente, independentes da execução das instruções.

O ambiente de desenvolvimento utilizado foi o Quartus Prime Lite (25.1std) e a linguagem de descrição de hardware foi Verilog.

<img width="600" alt="Placa DE1-SoC" src="https://github.com/user-attachments/assets/4e606e05-cef6-4a21-8f5b-80f50d49108b" />

*Imagem da placa DE1-SoC retirada do site da Altera*

## Sumário
 
1. [Levantamento de Requisitos](#1-levantamento-de-requisitos)
2. [Requisitos Atendidos e Como Foram Cumpridos](#2-requisitos-atendidos-e-como-foram-cumpridos)
3. [Softwares Utilizados](#3-softwares-utilizados)
4. [Hardware Usado nos Testes](#4-hardware-usado-nos-testes)
5. [Arquitetura do Sistema](#5-arquitetura-do-sistema)
6. [Instalação e Configuração](#6-instalação-e-configuração)
7. [Testes e Funcionamento](#7-testes-e-funcionamento)
8. [Análise dos Resultados](#8-análise-dos-resultados)
9. [Referências](#9-referências)


## 1. Levantamento de Requisitos

### 1.1 Requisitos Funcionais

- **RF01:** O coprocessador deve possuir uma ISA de 32 bits, definida e documentada pela equipe.
- **RF02:** Deve implementar o ciclo de busca/execução de instruções, com unidade de busca, Registrador de Instrução (IR) e Unidade de Controle.
- **RF03:** Deve possuir datapath, banco de registradores, Unidade Lógica e Aritmética (ULA) e registradores de estado/status.
- **RF04:** Os motores de background, sprites e polígonos devem ser tratados como unidades funcionais acionadas por instruções.
- **RF05:** Deve haver unidade de controle de quadro, compositor e controlador VGA operando continuamente, independentemente da execução das instruções.
- **RF06:** Deve existir mecanismo de sincronização com o VGA.
- **RF07:** Deve existir mecanismo de comunicação do tipo valid, busy e done.
- **RF08:** Toda operação deve ocorrer como consequência da execução de uma instrução da ISA.
- **RF09:** As instruções devem ser obtidas por busca síncrona ou por busca assíncrona*.
- **RF10:** Deve haver pelo menos um programa de demonstração da ISA da equipe, com sintaxe definida.

### 1.2 Requisitos Não Funcionais

- **RNF01:** O núcleo deve ser descrito em Verilog e implementado na FPGA da DE1-SoC.
- **RNF02:** A arquitetura deve ser modular, separando busca/controle, datapath, memórias, unidades funcionais e saída de vídeo.
- **RNF03:** O núcleo deve estar preparado para ser controlado por um driver Linux em Assembly ARM e por uma aplicação em C (etapas posteriores).
- **RNF04:** Entregar RTL completo, projeto Quartus compilável, repositório organizado e README com a documentação exigida.
- **RNF05:** Validar com testbench por módulo principal e testbench de integração.
- **RNF06:** Apresentar relatório de síntese, utilização de recursos, frequência máxima e análise de timing.
- **RNF07:** A demonstração deve ser feita na placa; vídeo ou simulação não a substituem.

## 2. Requisitos Atendidos e Como Foram Cumpridos
 
Para cada requisito atendido são indicados o(s) módulo(s), como foi cumprido e um espaço para registrar como foi demonstrado na placa.
 
### RF01 / RF08 — ISA de 32 bits; toda operação é consequência de uma instrução
 
**Módulo:** `mvp_interface_bg.v`.
 
**Como foi cumprido:** Foi definida uma ISA de 32 bits, em que cada instrução endereça uma unidade funcional (*engine*) e uma operação (*reg*) dentro dela. Todas as ações gráficas dinâmicas (scroll, cor de fundo, posição/padrão/flags de sprite, retângulo, triângulo e escrita na paleta) só acontecem como resultado da execução de uma instrução. A especificação completa está na seção 5.3.
 
**Demonstração:** Execução interativa do binário `gpu_cli` na DE1-SoC, enviando instruções de movimentação, visibilidade, troca de cor e scroll pelo terminal, observando a atualização imediata na saída VGA. 

### RF02 / RF09 — Unidade de busca, IR e Unidade de Controle (busca assíncrona)
 
**Módulos:** `gpu_top.v` (interface Avalon-MM e FIFO), `fifo_32bcomand` (IP `scfifo`, 256 × 32 bits), `mvp_interface_bg.v` (FSM).
 
**Como foi cumprido:** A busca é assíncrona: o ARM escreve instruções no offset `0x00` do `gpu_top`, que as enfileira na FIFO, sem relação de temporização com o coprocessador. A unidade de busca é a lógica que retira palavras da FIFO (`fifo_rdreq`), e a palavra lida é armazenada no IR (`command_reg`). A Unidade de Controle é uma FSM de 5 estados:
 
| Estado | Ação |
| :--- | :--- |
| `IDLE` | Se a FIFO não está vazia, solicita a leitura (`fifo_rdreq`) |
| `WAIT_FIFO` | Espera a latência de leitura da FIFO |
| `READ_FIFO` | Captura a palavra no IR (`command_reg`) |
| `EXECUTE` | Decodifica engine / reg / valor e atualiza o datapath |
| `HOLD` | Estado de acomodação antes de retornar a `IDLE` |

 **Demonstração:** Envio contínuo de pacotes de 32 bits em rajada durante o modo `demo_tudo` (~72 instruções por quadro a 60 FPS), demonstrando o enfileiramento na FIFO e a decodificação sem perda de pacotes.
 
### RF03 — Datapath
 
**Módulos:** `mvp_interface_bg.v`, `gpu_top.v`, `ghrd_top.v`.
 
**Como foi cumprido:** O datapath é formado pelos campos decodificados do IR (`cmd_engine`, `cmd_reg`, `cmd_value`), por registradores de rascunho (*staging*) de retângulo, triângulo e paleta, pelo bloco de normalização do scroll (comparação e subtração) e pelos registradores de saída que alimentam os motores gráficos. Esses sinais saem do `gpu_top` por um conduit (`video_out`) exportado do Qsys para o `ghrd_top`. Retângulos e triângulos são atualizados em duas etapas (rascunho/commit): as instruções de vértices gravam em registradores internos e a instrução `*_STYLE` aplica todos os valores de uma vez, evitando que a primitiva pisque ou "teleporte".
 
### RF04 — Motores gráficos como unidades funcionais
 
#### Motor de Background
 
**Módulos:** `background_renderer.v`, `ram_tilemap_2port` (`tilemap_back.mif`), `ram_tile` (`tile_back.mif`).
 
**Como foi cumprido:** O motor renderiza um tilemap de 40×30 posições com tiles 8×8 (256 padrões) e é acionado pelas instruções `BG_SCROLL` (deslocamento horizontal/vertical com repetição *wrap-around*) e `BG_COLOR` (cor sólida de fundo). O endereço do tilemap é `tile_y × 40 + tile_x`, calculado sem multiplicador.
 
**Demonstração:** Acionamento do menu Background na placa para deslocar o cenário horizontalmente, verticalmente e na diagonal com efeito de *wrap-around* contínuo (320×240).
 
#### Motor de Sprites
 
**Módulos:** `motor_sprite.v`, `rom_memoria2` (`espace_invasor.mif`).
 
**Como foi cumprido:** O motor mantém uma OAM com atributos de 32 sprites 16×16 (X, Y, padrão, habilitação, espelhamento H e V), editada por instrução: `SPR_ID` seleciona o sprite e `SPR_POS`, `SPR_TILE` e `SPR_FLAGS` gravam seus atributos por pulsos de escrita seletivos. Cada sprite usa 4 subtiles 8×8, o espelhamento inverte as coordenadas dentro do sprite, e a detecção de hit é feita por varredura paralela dos 32 slots. Em sobreposição, vence o sprite de menor ID.
 
**Demonstração:** Seleção individual de sprites por ID (0 a 31) via menu para alterar coordenadas (X, Y), trocar o padrão gráfico (tile) e aplicar espelhamento horizontal/vertical.
 
#### Rasterizador de Polígonos
 
**Módulo:** `rasterizador_poligonos.v`.
 
**Como foi cumprido:** Retângulos (comparação de limites) e triângulos (funções de aresta com aritmética inteira, independente da ordem dos vértices, usando 6 blocos DSP) são configurados pelas instruções `RECT_*` e `TRI_*`.
 
**Demonstração:** Renderização simultânea do retângulo e do triângulo via menu Polígonos, testando a translação de coordenadas, alteração de cor e alternância de visibilidade (mostrar/esconder).
 
### RF05 / RF06 — Unidade de Controle de Quadro, operação contínua e sincronização com o VGA
 
**Módulos:** `ghrd_top.v`, `vga_driver.v`.
 
**Como foi cumprido:** O `vga_driver` (máquinas de estados horizontal e vertical, 640×480 @ 60 Hz com pixel clock de 25 MHz) gera continuamente as coordenadas `next_x` / `next_y`, que são convertidas em coordenadas lógicas 320×240 (deslocamento de 1 bit, ampliação 2×2) e distribuídas aos motores gráficos. A lógica de controle de quadro, em `ghrd_top`, gera o pulso `fim_de_quadro` quando o último pixel visível (639, 479) é varrido e o exporta ao Qsys (conduit `vblank`) e ao `gpu_top`, servindo de referência de sincronização com o vídeo. VGA, controle de quadro e compositor não dependem da execução de instruções: continuam operando mesmo com a FIFO vazia.
 
Um contador de power-on reset (255 ciclos) mantém o sistema em reset após a energização, garantindo saída estável na inicialização.
 
**Demonstração:** Exibição contínua e estável do quadro no monitor VGA a 640×480 @ 60 Hz mesmo quando o programa em C aguarda entrada do usuário no menu (FIFO vazia).
 
### RF05 — Compositor (com paleta programável)
 
**Módulos:** `ghrd_top.v` (compositor), `paleta_ram` (`paleta.mif`).
 
**Como foi cumprido:** O compositor combina, a cada pixel, as camadas com prioridade fixa, aplicando a transparência (índice 0) antes da seleção do pixel final:
 
| Prioridade | Camada | Origem |
| :---: | :--- | :--- |
| 1 (maior) | Sprites | `motor_sprite` |
| 2 | Polígonos (triângulo sobre retângulo) | `rasterizador_poligonos` |
| 3 | Background (tilemap) | `background_renderer` |
| 4 | Frame buffer (VRAM) | `ram_framebuffer` |
| 5 (menor) | Cor sólida de fundo | instrução `BG_COLOR` |
 
```verilog
wire [7:0] final_pixel_index =
    (spr_active && spr_color != 8'd0) ? spr_color :
    poligonos_visiveis                ? poly_color :
    (bkg_color != 8'd0)               ? bkg_color  :
    (vram_color != 8'd0)              ? vram_color :
                                        bg_color_solid;
```
 
O índice final de 8 bits é convertido em RGB 24 bits pela `paleta_ram` (256 entradas), reprogramável por instrução (`PAL_RED_ADDR` + `PAL_GB_WRITE`).
 
**Demonstração:** Validação visual da sobreposição de prioridades (Sprites sobre Polígonos e Polígonos sobre o Background) com recorte automático do índice 0 (transparente) e troca de índices da paleta.
 
### RF05 — Controlador VGA
 
**Módulo:** `vga_driver.v`.
 
**Como foi cumprido:** Saída em 640×480 @ ~60 Hz pela interface VGA da DE1-SoC, com sinais RGB zerados fora da região ativa. Os parâmetros de temporização estão na seção 5.2.
 
### RF10 / RNF03 — Aplicação em C e Driver em Assembly ARM
 
**Arquivos:** `gpu_driver.s` (Assembly ARM), `gpu.c` / `gpu.h`, `main.c`, `background.c`, `sprites.c`, `poligonos.c`, `entrada.c`, `Makefile`.
 
**Como foi cumprido:** A solução é dividida em duas camadas.
 
**Driver em Assembly ARM (`gpu_driver.s`)** — único código que toca o hardware. Compilado para ARMv7 (Cortex-A9), Linux EABI, sintaxe GNU `as`, e usa chamadas de sistema diretamente (`open`, `mmap2`, `munmap`, `close`). Exporta quatro funções:
 
| Função | Descrição |
| :--- | :--- |
| `gpu_init()` | Abre `/dev/mem` (`O_RDWR \| O_SYNC`) e mapeia a página do coprocessador (base `0xFF200000`, ponte Lightweight HPS-to-FPGA, offset 0 do `gpu_top_0` no Qsys). Retorna 0 ou -1 |
| `gpu_close()` | Desfaz o mapeamento (`munmap` + `close`) |
| `gpu_write_cmd(cmd)` | Consulta o bit 0 do status (FIFO cheia) por polling com timeout; quando há espaço, escreve o comando de 32 bits em `REG_CMD` (offset `0x00`) e executa `dmb`. Retorna 0 ou -1 |
| `gpu_read_status()` | Lê o registrador de status (offset `0x04`) |
 
**Aplicação em C.** `gpu.c` monta a instrução com a macro `GPU_CMD(eng, reg, val)` (`[30:27]` engine, `[26:23]` reg, `[22:0]` valor) e a entrega ao driver, sem acessar o hardware diretamente. Os módulos `background.c`, `sprites.c` e `poligonos.c` expõem funções de alto nível (`bg_scroll`, `spr_mover`, `spr_espelhar`, `ret_mover`, `tri_mover` etc.) e mantêm o estado em software; o hardware recebe sempre a forma completa. A aplicação (`main.c`) é um menu interativo (polígonos, sprites, background, demonstração "tudo" e reset), com uma demo que anima 32 sprites, um retângulo, um triângulo e o scroll do fundo a ~60 quadros/s (≈ 72 instruções por quadro).
 
O software respeita o handshake *busy*: antes de cada escrita, o driver verifica a flag "FIFO cheia" e só envia quando há espaço.
 
**Demonstração:** Compilação e execução do `sudo ./gpu_cli` no Linux do HPS, navegando por todas as opções do menu interativo, executando a animação conjunta (`demo_tudo`) e acionando o reset geral da tela.
 
### RNF01 / RNF02 / RNF04 / RNF06 — Verilog, modularidade, entregas e relatório de síntese
 
O núcleo é descrito inteiramente em Verilog (RNF01) e organizado em módulos com responsabilidades separadas: interface e fila de comandos, decodificador, memórias, motores gráficos, compositor e VGA (RNF02). O RTL completo, o top-level (`ghrd_top.v`), o projeto Quartus (`soc_system.qpf`) e os relatórios de compilação (`output_files/`) estão no repositório (RNF04). Os números de recursos e timing estão na seção 8 (RNF06).
 
### RF03 — Banco de registradores
 
Não existe um banco de registradores central. **Decisão de projeto:** cada motor possui seu próprio conjunto de registradores — a OAM (64 entradas de atributos, selecionada por `SPR_ID`), os registradores de rascunho e de saída do retângulo e do triângulo, os de scroll e cor de fundo, e a paleta (RAM 256 × 24 bits). O campo `REG` da instrução endereça diretamente o registrador dentro de cada engine.
 
### RF03 — ULA
 
Não há módulo ULA dedicado. **Decisão de projeto:** as operações aritméticas são realizadas dentro dos módulos que precisam delas — adições/subtrações (soma de scroll e wrap, endereço do tilemap, deslocamentos e detecção de hit dos sprites, vetores de aresta) e multiplicações (funções de aresta do triângulo, mapeadas em 6 blocos DSP). A ISA não possui instruções aritméticas (apenas configuram as unidades), e a aritmética dos motores precisa ser avaliada a cada pixel; por isso uma ULA central compartilhada não foi adotada.
 
### RF03 — Registrador de status
 
O status (offset `0x04`) é formado diretamente pelas flags da FIFO: bit 0 = cheia, bit 1 = vazia. Não há registrador de status independente (por exemplo, instrução em execução ou erro de decodificação).
 
### RF07 — valid / busy / done
 
`valid` corresponde à escrita na FIFO (`wrreq`); `busy` ao bit "FIFO cheia"; `done` ao bit "FIFO vazia". O driver ARM faz o handshake por polling de `busy` com timeout antes de cada escrita; em hardware a escrita não é bloqueada com a FIFO cheia. Não há sinal de `done` por instrução.
 
### RF10 — Sintaxe da ISA
 
 A ISA gera as palavras de 32 bits por meio da macro `GPU_CMD(eng, reg, val)` e as envia pelo driver Assembly ARM para que o hardware execute. A "sintaxe" da ISA é a tabela de instruções da seção 5.3 (campos `ENGINE` / `REG` / `VALOR`) e as funções correspondentes (seção 5.5). Não existe montador textual dedicado.

## 3. Softwares Utilizados
 
- **IDE de Desenvolvimento:** Intel Quartus Prime Lite Edition (25.1std, build 1129)
- **Integração de sistema:** Platform Designer (Qsys) — HPS + `gpu_top` + PIO + JTAG UART
- **Linguagem HDL:** Verilog-2001
- **Software no HPS:** GCC (nativo na placa ou `arm-linux-gnueabihf-gcc` para cross-compilação), GNU `as` para o driver em Assembly ARMv7, `make`; Linux no HPS
- **VSCode:** para a programação dos módulos em C
---
 
## 4. Hardware Usado nos Testes
 
- Kit de Desenvolvimento Terasic DE1-SoC
- FPGA Intel Cyclone V 5CSEMA5F31C6
- Processador HPS ARM Cortex-A9 Dual-Core
- Monitor VGA — 640×480 @ ~60 Hz
---
## 5. Arquitetura do Sistema
 
### 5.1 Visão Geral

<img width="1600" height="382" alt="image" src="https://github.com/user-attachments/assets/c4fc41b7-6b46-4694-b300-a690e13b73c3" />

O decodificador opera no clock de 50 MHz (o mesmo do Qsys); os motores gráficos, o compositor, a paleta e o VGA operam em `clk_25m`.

**Mapeamento para os blocos:**
 
| Bloco exigido | Implementação |
| :--- | :--- |
| Unidade de busca | Leitura da FIFO (`fifo_32bcomand` + estados `IDLE` / `WAIT_FIFO` do `mvp_interface_bg`) |
| IR | `command_reg` (`mvp_interface_bg`) |
| Unidade de Controle | FSM do `mvp_interface_bg` |
| Datapath | Campos do IR, registradores de rascunho, normalização de scroll e registradores de saída |
| Banco de registradores | Distribuído por motor (OAM, registradores de rascunho e paleta) — ver seção 2 |
| ULA | Aritmética distribuída nos motores (adições e multiplicações em DSP) — ver seção 2 |
| Registrador de status | Flags da FIFO (cheia / vazia) no offset `0x04` — ver seção 2 |
| Unidades funcionais gráficas | `background_renderer`, `motor_sprite`, `rasterizador_poligonos` |
| Unidade de Controle de Quadro | Geração de `fim_de_quadro` no `ghrd_top` |
| Compositor | Bloco `final_pixel_index` + `paleta_ram` no `ghrd_top` |
| Controlador VGA | `vga_driver` |

### 5.2 Temporização VGA (640×480 @ ~60 Hz)

O módulo `vga_driver.v` opera com clock de pixel de 25 MHz e utiliza os seguintes parâmetros padrão de varredura:

| Parâmetro | Horizontal (pixels) | Vertical (linhas) |
| :--- | :---: | :---: |
| Região ativa (visível) | 640 | 480 |
| Front Porch | 16 | 10 |
| Pulso de Sincronismo (Sync) | 96 | 2 |
| Back Porch | 48 | 33 |
| **Total por quadro** | **800** | **525** |

### 5.3 ISA do Coprocessador
 
**Formato da instrução (32 bits):**
 
```text
 31 | 30        27 | 26        23 | 22                          0
----+--------------+--------------+------------------------------
  0 |    ENGINE    |     REG      |            VALOR
```
 
| Campo | Bits | Descrição |
| :--- | :---: | :--- |
| Reservado | 31 | Ignorado, seria usado em caso de necessidade |
| ENGINE | 30:27 | Motor de destino |
| REG | 26:23 | Operação/registrador dentro da engine |
| VALOR | 22:0 | Operando(s), conforme a instrução |
 
| ENGINE | REG | Mnemônico | Campos de VALOR | Efeito |
| :---: | :---: | :--- | :--- | :--- |
| `0x1` BG | `0x0` | `BG_SCROLL` | `[8:0]` X, `[16:9]` Y | Define o scroll (normalizado módulo 320×240) |
| `0x1` BG | `0x1` | `BG_COLOR` | `[7:0]` cor | Cor sólida de fundo (menor prioridade) |
| `0x2` SPR | `0x0` | `SPR_ID` | `[4:0]` id | Seleciona o sprite (0–31) a ser editado |
| `0x2` SPR | `0x1` | `SPR_POS` | `[8:0]` X, `[16:9]` Y | Posição do sprite selecionado |
| `0x2` SPR | `0x2` | `SPR_TILE` | `[7:0]` índice | Padrão gráfico (tile base) |
| `0x2` SPR | `0x3` | `SPR_FLAGS` | `[0]` enable, `[1]` hflip, `[2]` vflip | Habilitação e espelhamentos |
| `0x3` RECT | `0x0` | `RECT_P0` | `[8:0]` x0, `[16:9]` y0 | Rascunho: canto superior esquerdo |
| `0x3` RECT | `0x1` | `RECT_P1` | `[8:0]` x1, `[16:9]` y1 | Rascunho: canto inferior direito |
| `0x3` RECT | `0x2` | `RECT_STYLE` | `[7:0]` cor, `[8]` enable | Commit: aplica coordenadas, cor e habilitação |
| `0x4` TRI | `0x0` | `TRI_V0` | `[9:0]` x0, `[18:10]` y0 (com sinal) | Rascunho: vértice 0 |
| `0x4` TRI | `0x1` | `TRI_V1` | `[9:0]` x1, `[18:10]` y1 (com sinal) | Rascunho: vértice 1 |
| `0x4` TRI | `0x2` | `TRI_V2` | `[9:0]` x2, `[18:10]` y2 (com sinal) | Rascunho: vértice 2 |
| `0x4` TRI | `0x3` | `TRI_STYLE` | `[7:0]` cor, `[8]` enable | Commit: aplica vértices, cor e habilitação |
| `0x5` PAL | `0x0` | `PAL_RED_ADDR` | `[15:8]` índice, `[7:0]` R | Rascunho: endereço e vermelho |
| `0x5` PAL | `0x1` | `PAL_GB_WRITE` | `[15:8]` G, `[7:0]` B | Grava {R,G,B} na entrada selecionada |
 
 
**Mapa MMIO** (escravo `gpu_top_0` na ponte Lightweight HPS-to-FPGA, endereçamento por palavra):
 
| Offset | Acesso | Descrição |
| :---: | :---: | :--- |
| `0x00` | Escrita | Empilha uma instrução de 32 bits na FIFO (*valid*) |
| `0x04` | Leitura | Status: bit 0 = FIFO cheia (*busy*), bit 1 = FIFO vazia (*done*) |
 
### 5.4 Memórias Utilizadas
 
| Módulo | Arquivo MIF | Tamanho | Conteúdo |
| :--- | :--- | :--- | :--- |
| `fifo_32bcomand` | — | 256 × 32 bits | Fila de instruções vindas do ARM |
| `ram_tile` | `tile_back.mif` | 16.384 × 8 bits | Tileset de background (256 tiles × 64 px) |
| `ram_tilemap_2port` | `tilemap_back.mif` | 4.096 × 8 bits (1.200 usadas) | Mapa de tiles 40×30 |
| `rom_memoria2` | `espace_invasor.mif` | 16.384 × 8 bits | Tileset de sprites |
| `paleta_ram` | `paleta.mif` | 256 × 24 bits | Paleta RGB (programável por instrução) |
| `ram_framebuffer` | — | 76.800 × 8 bits | VRAM 320×240 (leitura habilitada; escrita reservada à etapa seguinte) |
| OAM (`motor_sprite`) | — | 64 × (9+8+8+1+1+1 bits) | Atributos dos sprites (registradores) |


### 5.5 Software (Aplicação em C e Driver Assembly ARM)
 
```text
main.c / menus (background.c, sprites.c, poligonos.c, entrada.c)   <- aplicação em C
        │  gpu_send(engine, reg, valor)
        ▼
gpu.c — GPU_CMD(eng, reg, val) monta a palavra de 32 bits
        │  gpu_write_cmd(cmd)
        ▼
gpu_driver.s — Assembly ARM: open/mmap2 de /dev/mem, polling de BUSY, str na FIFO
        │  MMIO (0xFF200000, ponte Lightweight HPS-to-FPGA)
        ▼
gpu_top (FIFO → decodificador → motores gráficos)
```
 
Correspondência entre as instruções da ISA e o software (os mnemônicos são nomes de documentação; no código as instruções são geradas por `GPU_CMD`):
 
| Instrução | Função C | Instruções enviadas |
| :--- | :--- | :--- |
| `BG_SCROLL` | `bg_scroll(x, y)` | `ENG_BG`, 0 |
| `SPR_ID`, `SPR_POS`, `SPR_TILE`, `SPR_FLAGS` | `spr_mover`, `spr_mudar_tile`, `spr_espelhar`, `spr_girar`, `spr_reset` | `ENG_SPR`, 0..3 |
| `RECT_P0`, `RECT_P1`, `RECT_STYLE` | `ret_mover`, `ret_cor`, `poligonos_reset` | `ENG_RECT`, 0..2 |
| `TRI_V0..V2`, `TRI_STYLE` | `tri_mover`, `tri_cor`, `poligonos_reset` | `ENG_TRI`, 0..3 |
| `BG_COLOR`, `PAL_RED_ADDR`, `PAL_GB_WRITE` | — (não usadas pela aplicação atual) | — |
 
---

## 6. Instalação e Configuração
 
1. Clone este repositório para a sua máquina local.
2. Abra o Intel Quartus Prime Lite Edition.
3. Vá em **File > Open Project** e selecione `soc_system.qpf` (entidade de topo: `ghrd_top`).
4. Se necessário, regenere o sistema no Platform Designer (`soc_system.qsys`) via **Generate HDL**.
5. Clique em **Start Compilation** e aguarde a finalização ("Successful").
6. Conecte a DE1-SoC via USB-Blaster, ligue a placa, abra o **Programmer** e grave `output_files/soc_system.sof`.
> **Nota:** os arquivos `.mif` e a atribuição de pinos já estão incluídos no projeto.
 
**Compilação e execução do software (no HPS):**
 
1. Copie os arquivos de software (`Makefile`, `*.c`, `*.h`, `gpu_driver.s`) para a placa, ou cross-compile no computador com `make CC=arm-linux-gnueabihf-gcc`.
2. Na placa (já com o `.sof` gravado e o Linux em execução), compile com `make` (o Makefile usa `-no-pie`, pois o driver em Assembly usa endereços absolutos).
3. Execute com privilégios de superusuário, pois o driver acessa `/dev/mem`: `sudo ./gpu_cli`.
4. Use o menu: **[1]** Polígonos, **[2]** Sprites, **[3]** Background, **[4]** Demonstração "tudo" (Enter para parar), **[5]** Reset da tela, **[0]** Sair.
O endereço físico utilizado é `0xFF200000` (ponte Lightweight HPS-to-FPGA) + offset `0x0` do `gpu_top_0`, configurado no início de `gpu_driver.s`.
 
<!-- Imagens do processo de compilação/gravação: inserir aqui -->
 
---

## 7. Testes e Funcionamento

### 7.1 Estratégia de Verificação

A verificação foi organizada em três níveis:

| Nível | Objetivo |
| :--- | :--- | 
| Módulo | Validar cada unidade isoladamente (decodificador, motores gráficos, VGA) | 
| Integração | Validar o fluxo completo: instrução na FIFO até o pixel de saída | 
| Hardware | Validar o sistema real na DE1-SoC, com o ARM enviando instruções ao coprocessador | 

### 7.2 Casos de Teste

Cada caso está associado ao requisito que valida (seção 1). O critério de aceitação define o que deve ser observado para o teste ser considerado aprovado.

| ID | Requisito | Procedimento | Critério de aceitação | Resultado |
| :--- | :--- | :--- | :--- | :--- |
| T01 | RF05, RF06 | Energizar a placa e não enviar instruções | Imagem estável, sem perda de sincronismo, com a FIFO vazia | Aprovado, imagem aparece na tela do monitor de forma estável |
| T02 | RF01, RF02, RF08 | Enviar `BG_SCROLL` pelo menu Background | O fundo se desloca conforme o valor enviado | Aprovado, Desloca para todos lados e diagonal |
| T03 | RF04 | Enviar scroll próximo de 320 (X) e 240 (Y) | O fundo reaparece do lado oposto (wrap-around) | Aprovado |
| T04 | RF04 | Selecionar um sprite por ID e alterar a posição | Apenas o sprite selecionado se move | Aprovado, Seleciona pelo menu e move o sprite selecionado |
| T05 | RF04 | Aplicar espelhamento horizontal e vertical | O sprite aparece espelhado nos eixos escolhidos | Aprovado |
| T06 | RF04 | Sobrepor dois sprites no mesmo pixel | Prevalece o sprite de menor ID | Aprovado, o sprite selecionado sobrepõe o não selecionado |
| T07 | RF04 | Enviar retângulo e triângulo pelo menu Polígonos | As duas primitivas aparecem preenchidas, com a cor definida | Aprovado, poligonos aparecem na tela |
| T08 | RF05 | Sobrepor sprite, polígono e fundo | Ordem de camadas: sprite, polígono, fundo | Aprovado |
| T09 | RF08 | Executar a demonstração "tudo" (opção 4) | 32 sprites, retângulo e triângulo animados, com o fundo em scroll, sem artefatos | Aprovado, aparecem todos os elementos dos motores |


### 7.3 Roteiro da Demonstração em Hardware

1. Gravar `soc_system.sof` pelo Programmer e aguardar o Linux iniciar no HPS.
2. Compilar o software (`make`) e executar `sudo ./gpu_cli`.
3. Com o menu aberto e sem enviar instruções, verificar a imagem estável (T01).
4. Executar os casos T02 a T09 pelos menus Background, Sprites e Polígonos.
5. Executar a demonstração "tudo" (opção 4) e observar o comportamento por alguns segundos (T09).
6. Usar o Reset da tela (opção 5) e verificar o retorno ao estado inicial.

### 7.4 Resultados Visuais da Demonstração em Hardware

Abaixo estão os registros visuais dos testes executados diretamente na placa DE1-SoC conectada ao monitor VGA:

#### 1. Interface de Controle no Terminal (HPS Linux) e Estado Inicial (T01)
<img width="292" height="207" alt="image" src="https://github.com/user-attachments/assets/6c7cd21a-d75c-4930-a0cc-51ad13a4f833" />

<img width="775" height="577" alt="Design sem nome (14)" src="https://github.com/user-attachments/assets/a38110cd-4356-4b5e-a99f-da21e4275a2a" />

#### 2. Teste de Polígonos e Cores da Paleta (T07)
<img width="775" height="577" alt="Design sem nome (15)" src="https://github.com/user-attachments/assets/c6d7d3d1-d9ad-4f21-9424-8c504279dcc0" />

#### 3. Teste de Sprites, Movimentação e Espelhamento (T04, T05, T06)
<img width="775" height="577" alt="Design sem nome (16)" src="https://github.com/user-attachments/assets/22f1cf38-a504-4226-af6f-8f042b53f1a2" />

---
 
## 8. Análise dos Resultados
 
### 8.1 Resultados Alcançados
 
- **Coprocessador programável:** os motores do Problema 1 passaram a ser unidades funcionais acionadas por uma ISA de 32 bits, recebida do ARM por FIFO.
- **Ciclo de busca/execução:** FSM com IR e datapath, consumindo instruções continuamente da fila.
- **Pilha completa ARM → FPGA:** aplicação em C, driver em Assembly ARM com `mmap` de `/dev/mem` e handshake por *busy*, FIFO e decodificador em hardware.
- **Operação contínua de vídeo:** VGA, controle de quadro e compositor independem da execução de instruções.
- **Composição e paleta:** 5 níveis de prioridade com transparência pelo índice 0 e paleta de 256 cores programável por instrução.
  
### 8.2 Utilização de Recursos (Cyclone V 5CSEMA5F31C6)
 
| Recurso | Utilizado | Disponível | Percentual |
| :--- | :--- | :--- | :--- |
| ALMs (Lógica) | 3.761 | 32.070 | 12% |
| Registradores | 4.998 | — | — |
| Blocos de RAM (M10K) | 180 | 397 | 45% |
| Bits de memória | 1.432.320 | 4.065.280 | 35% |
| Blocos DSP | 6 | 87 | 7% |
| Pinos | 382 | 457 | 84% |
| PLLs / DLLs | 0 / 1 | 6 / 4 | 0% / 25% |

### 8.3 Timing

A análise de timing foi realizada pelo Timing Analyzer do Quartus Prime (relatórios `output_files/soc_system.sta.rpt` e `.sta.summary`), com o clock de entrada de 50 MHz (`CLOCK_50`, período de 20 ns) restringido em `soc_system.sdc`. A tabela apresenta os resultados do modelo de pior caso (Slow 1100mV 85C).

| Clock | Fmax | Slack de setup | Slack de hold |
| :--- | :--- | :--- | :--- |
| `clock_50_1` (CLOCK_50) | 91,67 MHz | +9,091 ns | +0,256 ns |
| `altera_reserved_tck` (JTAG) | 76,38 MHz | +10,120 ns | +0,416 ns |
| `afi_clk_write_clk` (SDRAM do HPS) | — | +1,730 ns | +0,143 ns |

O slack de setup indica a folga entre o período do clock e o atraso do caminho mais lento; o slack de hold indica a folga contra mudanças prematuras do dado. Valores positivos significam que a restrição foi atendida.

No clock principal do projeto (`clock_50_1`), o caminho crítico leva cerca de 10,9 ns dos 20 ns disponíveis, o que resulta em Fmax de 91,67 MHz, aproximadamente 83% acima da frequência de operação de 50 MHz. O clock `afi_clk_write_clk` pertence ao controlador de memória DDR do HPS e não ao coprocessador, por isso a Fmax não é comparada com o projeto. O clock `altera_reserved_tck` é o clock JTAG usado pelo programador.

Todos os caminhos analisados de setup, hold, recovery e removal têm slack positivo e TNS = 0 no modelo de pior caso, ou seja, o projeto fecha timing a 50 MHz.

**Limitação:** o clock de 25 MHz (`clk_25m`), usado pelos motores gráficos, pelo compositor e pelo VGA, é gerado por um divisor de registrador e não é declarado como clock gerado no SDC. Por isso o Timing Analyzer não o reporta como domínio separado, e a Fmax de 91,67 MHz refere-se ao domínio de 50 MHz. Como `clk_25m` é derivado de `CLOCK_50` por um divisor por 2, a folga observada indica que os caminhos desse domínio também têm margem. Mesmo assim, o correto é declará-lo no SDC com `create_generated_clock` (ou usar uma PLL) para que possa ser exibido na analise.

### 8.4 Limitações e Melhorias Possíveis

#### Limitações Atuais:
- **Quantidade e dimensão de polígonos:** Ao contrário dos sprites (que possuem 32 instâncias independentes na OAM), o rasterizador atual instancia apenas 2 primitivas simultâneas (um retângulo e um triângulo), e a aplicação em C manipula formas de dimensões pré-definidas.
- **Exposição da Paleta e Cor de Fundo no Menu:** As instruções `BG_COLOR` (`0x1`) e de reprogramação da LUT da paleta (`PAL_RED_ADDR` e `PAL_GB_WRITE` na Engine `0x5`) estão implementadas e sintetizadas no decodificador em hardware (`mvp_interface_bg.v`), mas não foram expostas no menu interativo em C; na demonstração atual, a tabela da paleta é exercitada alternando dinamicamente os índices de cor dos polígonos (`RECT_STYLE` e `TRI_STYLE`).
- **Sincronização de Quadro em Software:** O sinal físico `fim_de_quadro` é gerado em hardware, porém não foi mapeado no bit 2 do registrador de status (`offset 0x04`), de modo que a cadência de 60 FPS na aplicação em C é controlada via temporização de sistema (`usleep`).

#### Melhorias Futuras:
- Conectar o sinal de V-Blank ao bit 2 do registrador de status no `gpu_top.v` para habilitar o *polling* via `gpu_wait_vblank()`, e ativar o *Ping-Pong Buffer* (`bank_read_reg`) para atualização estritamente durante o intervalo vertical.
- Expor no menu em C as chamadas para `BG_COLOR` e para a Engine `0x5` (edição dinâmica de RGB da paleta).
- Expandir o módulo de polígonos para suportar múltiplas instâncias parametrizáveis pelo usuário.
- Migrar a macro de empacotamento `GPU_CMD` do código C (`gpu.h`) para dentro do driver em Assembly (`gpu_driver.s`), encapsulando totalmente o formato binário da ISA na camada de baixo nível.

### 8.5 Funcionalidades Não Atendidas

Os itens abaixo diferem do que o enunciado do Problema #2 exige ou sugere:

| Item do enunciado | Situação | Justificativa |
| :--- | :---: | :--- |
| Banco de registradores (obrigatório, 4.1) | Não atendido | Registradores distribuídos por motor (OAM, rascunhos, scroll, paleta); o campo `REG` endereça diretamente o registrador dentro de cada engine. |
| ULA (3.1) | Não atendido | A aritmética é feita dentro dos motores que a utilizam; a ISA não possui instruções aritméticas. |
| Registrador de status (obrigatório, 4.1) | Parcial | O status é formado apenas pelas flags da FIFO (cheia/vazia); não há status de execução ou de erro. |
| Comunicação valid / busy / done | Parcial | `valid` = escrita na FIFO, `busy` = FIFO cheia, `done` = FIFO vazia; não há `done` por instrução. |
| Programa em Assembly da ISA e sintaxe (4.2) | Não atendido | A ISA é programada por uma aplicação em C sobre driver em Assembly ARM; não há montador textual. |
| Mecanismo de sincronização com o VGA (4.1) | Parcial | O pulso `fim_de_quadro` é gerado e exportado; a troca de bancos (ping-pong) está desativada e as instruções são aplicadas assim que decodificadas. [confirme se ainda é o caso] |
 
## 9. Referências
 
ADAMS, V. Hunter. **VGA Driver in Verilog.** [S. l.], [s. d.]. Disponível em: <https://vanhunteradams.com/DE1/VGA_Driver/Driver.html>. Acesso em: 24 ago. 2026.
 
PATTERSON, David A.; HENNESSY, John L. **Computer Organization and Design: The Hardware/Software Interface, ARM Edition.** [S. l.]: Morgan Kaufmann, 2016. (The Morgan Kaufmann Series in Computer Architecture and Design).
