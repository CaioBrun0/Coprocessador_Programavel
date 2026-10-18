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
 
**Demonstração:** [PREENCHER: instruções executadas na apresentação e o efeito observado na tela.]
 
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
 
**Demonstração:** [PREENCHER: fluxo ARM → FIFO → decodificador → motor gráfico mostrado na apresentação.]
 
### RF03 — Datapath
 
**Módulos:** `mvp_interface_bg.v`, `gpu_top.v`, `ghrd_top.v`.
 
**Como foi cumprido:** O datapath é formado pelos campos decodificados do IR (`cmd_engine`, `cmd_reg`, `cmd_value`), por registradores de rascunho (*staging*) de retângulo, triângulo e paleta, pelo bloco de normalização do scroll (comparação e subtração) e pelos registradores de saída que alimentam os motores gráficos. Esses sinais saem do `gpu_top` por um conduit (`video_out`) exportado do Qsys para o `ghrd_top`. Retângulos e triângulos são atualizados em duas etapas (rascunho/commit): as instruções de vértices gravam em registradores internos e a instrução `*_STYLE` aplica todos os valores de uma vez, evitando que a primitiva pisque ou "teleporte".
 
### RF04 — Motores gráficos como unidades funcionais
 
#### Motor de Background
 
**Módulos:** `background_renderer.v`, `ram_tilemap_2port` (`tilemap_back.mif`), `ram_tile` (`tile_back.mif`).
 
**Como foi cumprido:** O motor renderiza um tilemap de 40×30 posições com tiles 8×8 (256 padrões) e é acionado pelas instruções `BG_SCROLL` (deslocamento horizontal/vertical com repetição *wrap-around*) e `BG_COLOR` (cor sólida de fundo). O endereço do tilemap é `tile_y × 40 + tile_x`, calculado sem multiplicador.
 
**Demonstração:** [PREENCHER: `BG_SCROLL` em ação na placa.]
 
#### Motor de Sprites
 
**Módulos:** `motor_sprite.v`, `rom_memoria2` (`espace_invasor.mif`).
 
**Como foi cumprido:** O motor mantém uma OAM com atributos de 32 sprites 16×16 (X, Y, padrão, habilitação, espelhamento H e V), editada por instrução: `SPR_ID` seleciona o sprite e `SPR_POS`, `SPR_TILE` e `SPR_FLAGS` gravam seus atributos por pulsos de escrita seletivos. Cada sprite usa 4 subtiles 8×8, o espelhamento inverte as coordenadas dentro do sprite, e a detecção de hit é feita por varredura paralela dos 32 slots. Em sobreposição, vence o sprite de menor ID.
 
**Demonstração:** [PREENCHER: sprites movidos pelo ID e espelhados na placa.]
 
#### Rasterizador de Polígonos
 
**Módulo:** `rasterizador_poligonos.v`.
 
**Como foi cumprido:** Retângulos (comparação de limites) e triângulos (funções de aresta com aritmética inteira, independente da ordem dos vértices, usando 6 blocos DSP) são configurados pelas instruções `RECT_*` e `TRI_*`.
 
**Demonstração:** [PREENCHER: retângulo e triângulo na tela, cores e posições alteradas por instrução.]
 
### RF05 / RF06 — Unidade de Controle de Quadro, operação contínua e sincronização com o VGA
 
**Módulos:** `ghrd_top.v`, `vga_driver.v`.
 
**Como foi cumprido:** O `vga_driver` (máquinas de estados horizontal e vertical, 640×480 @ 60 Hz com pixel clock de 25 MHz) gera continuamente as coordenadas `next_x` / `next_y`, que são convertidas em coordenadas lógicas 320×240 (deslocamento de 1 bit, ampliação 2×2) e distribuídas aos motores gráficos. A lógica de controle de quadro, em `ghrd_top`, gera o pulso `fim_de_quadro` quando o último pixel visível (639, 479) é varrido e o exporta ao Qsys (conduit `vblank`) e ao `gpu_top`, servindo de referência de sincronização com o vídeo. VGA, controle de quadro e compositor não dependem da execução de instruções: continuam operando mesmo com a FIFO vazia.
 
Um contador de power-on reset (255 ciclos) mantém o sistema em reset após a energização, garantindo saída estável na inicialização.
 
**Demonstração:** [PREENCHER: imagem estável no monitor, mesmo sem instruções em execução.]
 
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
 
**Demonstração:** [PREENCHER: sobreposição de camadas e alteração de paleta por instrução.]
 
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
 
**Demonstração:** [PREENCHER: execução do `gpu_cli` na placa (menu, demo "tudo") e a imagem resultante.]
 
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

(COLOCAR IMAGEM DO DRAW.IO)

O decodificador opera no clock de 50 MHz (o mesmo do Qsys); os motores gráficos, o compositor, a paleta e o VGA operam em `clk_25m`.

**Mapeamento para os blocos exigidos no Problema #2:**
 
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


### 5.2 ISA do Coprocessador
 
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
(DESENVOLVER SOBRE TESTES)
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
| ALMs (Lógica) | 3.755 | 32.070 | 12% |
| Registradores | 5.002 | — | — |
| Blocos de RAM (M10K) | 180 | 397 | 45% |
| Bits de memória | 1.432.320 | 4.065.280 | 35% |
| Blocos DSP | 6 | 87 | 7% |
| Pinos | 382 | 457 | 84% |
| PLLs / DLLs | 0 / 1 | 6 / 4 | 0% / 25% |
 
### 8.3 Limitações e Melhorias Possíveis

- Software: corrigir `gpu_wait_vblank()` (bit 2 de status inexistente) e usar `BG_COLOR` e as instruções de paleta na aplicação, para demonstrar a paleta programável.
- Controle de quadro com troca de bancos ativa (`bank_read` sincronizado com `fim_de_quadro`) para evitar artefatos, já que hoje as instruções são aplicadas assim que decodificadas.
- Adicionar mais poligonos na tela, visto que só é possivel adicionar 1 poligono de cada.
- Desenvolver uma aplicação para desenhar poligonos do tamanho que o usuário desejar.
- Ajustar Driver Assembly, deixar ele 100% responsável pela montagem de instruções, remover o codigo C que auxilia na montagem.
 
### 8.4 Funcionalidades Não Atendidas
 
- Banco de registradores central, ULA dedicada e registrador de status independente: substituídos por registradores e aritmética distribuídos nos motores e pelas flags da FIFO (decisões de projeto descritas na seção 2).
- Sinais *valid* / *busy* / *done* por instrução: apenas *busy* e *done* globais, derivados das flags da FIFO.
---
 
## 9. Referências
 
ADAMS, V. Hunter. **VGA Driver in Verilog.** [S. l.], [s. d.]. Disponível em: <https://vanhunteradams.com/DE1/VGA_Driver/Driver.html>. Acesso em: 24 ago. 2026.
 
PATTERSON, David A.; HENNESSY, John L. **Computer Organization and Design: The Hardware/Software Interface, ARM Edition.** [S. l.]: Morgan Kaufmann, 2016. (The Morgan Kaufmann Series in Computer Architecture and Design).
