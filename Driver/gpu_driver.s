@ ============================================================================
@ Driver da GPU - ARMv7 (Cortex-A9 do HPS), Linux EABI, sintaxe GNU as
@
@ Este arquivo e o UNICO codigo que toca o hardware:
@   gpu_init()        abre /dev/mem e mapeia a GPU (syscalls open + mmap2)
@   gpu_close()       desfaz o mapeamento (munmap + close)
@   gpu_write_cmd()   envia um comando de 32 bits para a FIFO
@   gpu_read_status() le o registrador de status
@ O ponteiro do periferico (gpu_base) e local a este arquivo: o C nao o enxerga.
@
@ Convencao AAPCS: argumentos em r0-r3, retorno em r0, preserva r4-r11.
@ ============================================================================
    .syntax unified
    .arm

@ ---- CONFIGURACAO: unico lugar onde fica o endereco fisico da GPU ----------
    .equ LW_BRIDGE_BASE, 0xFF200000      @ ponte lightweight HPS->FPGA
    .equ GPU_OFFSET,     0x00000000      @ TODO: offset do gpu_top_0 no Qsys
    .equ GPU_PHYS,       (LW_BRIDGE_BASE + GPU_OFFSET)
    .equ GPU_PAGE,       (GPU_PHYS >> 12)        @ mmap2 usa unidades de 4 KB
    .equ GPU_PAGE_OFF,   (GPU_PHYS & 0xFFF)

@ ---- Registradores da GPU (offset em bytes) --------------------------------
    .equ REG_CMD,        0x00            @ escrita: FIFO de comandos
    .equ REG_STATUS,     0x04            @ leitura: bit0 = cheia, bit1 = vazia

@ ---- Syscalls do Linux ARM EABI (numero vai em r7) -------------------------
    .equ SYS_CLOSE,      6
    .equ SYS_OPEN,       5
    .equ SYS_MUNMAP,     91
    .equ SYS_MMAP2,      192

    .equ OPEN_FLAGS,     0x101002        @ O_RDWR (2) | O_SYNC (0x101000)
    .equ MAP_SPAN,       4096

    .section .rodata
dev_mem:
    .asciz "/dev/mem"

    .data
    .align 2
gpu_base:  .word 0                        @ endereco virtual da GPU
gpu_map:   .word 0                        @ endereco virtual da pagina mapeada
gpu_fd:    .word 0                        @ descritor de /dev/mem

    .text
    .global gpu_init
    .global gpu_close
    .global gpu_write_cmd
    .global gpu_read_status
    .type   gpu_init, %function
    .type   gpu_close, %function
    .type   gpu_write_cmd, %function
    .type   gpu_read_status, %function

@ ----------------------------------------------------------------------------
@ int gpu_init(void)        retorna 0 = ok, -1 = erro
@ ----------------------------------------------------------------------------
gpu_init:
    push  {r4, r5, r7, lr}

    @ fd = open("/dev/mem", O_RDWR | O_SYNC)
    ldr   r0, =dev_mem
    ldr   r1, =OPEN_FLAGS
    mov   r2, #0
    mov   r7, #SYS_OPEN
    svc   #0
    cmp   r0, #0
    blt   .Linit_erro
    mov   r4, r0                         @ r4 = fd
    ldr   r1, =gpu_fd
    str   r4, [r1]

    @ map = mmap2(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, fd, pagina)
    mov   r0, #0
    mov   r1, #MAP_SPAN
    mov   r2, #3                         @ PROT_READ | PROT_WRITE
    mov   r3, #1                         @ MAP_SHARED
    ldr   r5, =GPU_PAGE                  @ offset em paginas de 4 KB
    mov   r7, #SYS_MMAP2
    svc   #0
    cmn   r0, #4096                      @ -4095..-1 = codigo de erro
    bcs   .Linit_fecha

    ldr   r1, =gpu_map
    str   r0, [r1]
    ldr   r2, =GPU_PAGE_OFF
    add   r0, r0, r2                     @ base virtual + deslocamento na pagina
    ldr   r1, =gpu_base
    str   r0, [r1]
    mov   r0, #0
    pop   {r4, r5, r7, pc}

.Linit_fecha:                            @ mmap falhou: fecha o fd
    mov   r0, r4
    mov   r7, #SYS_CLOSE
    svc   #0
    ldr   r1, =gpu_fd
    mov   r2, #0
    str   r2, [r1]
.Linit_erro:
    mvn   r0, #0                         @ -1
    pop   {r4, r5, r7, pc}
    .ltorg

@ ----------------------------------------------------------------------------
@ void gpu_close(void)
@ ----------------------------------------------------------------------------
gpu_close:
    push  {r7, lr}

    ldr   r1, =gpu_map
    ldr   r0, [r1]
    cmp   r0, #0
    beq   1f
    mov   r1, #MAP_SPAN
    mov   r7, #SYS_MUNMAP
    svc   #0
    ldr   r1, =gpu_map
    mov   r2, #0
    str   r2, [r1]
1:
    ldr   r1, =gpu_fd
    ldr   r0, [r1]
    cmp   r0, #0
    ble   2f
    mov   r7, #SYS_CLOSE
    svc   #0
    ldr   r1, =gpu_fd
    mov   r2, #0
    str   r2, [r1]
2:
    ldr   r1, =gpu_base
    mov   r2, #0
    str   r2, [r1]
    pop   {r7, pc}
    .ltorg

@ ----------------------------------------------------------------------------
@ int gpu_write_cmd(uint32_t cmd)     r0 = comando; retorna 0 ok / -1 erro
@ ----------------------------------------------------------------------------
gpu_write_cmd:
    ldr   r1, =gpu_base
    ldr   r1, [r1]                       @ r1 = base virtual da GPU
    cmp   r1, #0
    beq   3f                             @ gpu_init() nao foi chamado
    ldr   r3, =0x00FFFFFF                @ timeout do polling
1:  ldr   r2, [r1, #REG_STATUS]
    tst   r2, #1                         @ bit0 = FIFO cheia?
    beq   2f                             @ nao cheia -> pode escrever
    subs  r3, r3, #1
    bne   1b
    b     3f                             @ estourou o timeout
2:  str   r0, [r1, #REG_CMD]             @ empilha o comando na FIFO
    dmb                                  @ garante a ordem dos acessos
    mov   r0, #0
    bx    lr
3:  mvn   r0, #0                         @ r0 = -1
    bx    lr
    .ltorg

@ ----------------------------------------------------------------------------
@ uint32_t gpu_read_status(void)
@ ----------------------------------------------------------------------------
gpu_read_status:
    ldr   r1, =gpu_base
    ldr   r1, [r1]
    cmp   r1, #0
    moveq r0, #0
    bxeq  lr
    ldr   r0, [r1, #REG_STATUS]
    bx    lr
    .ltorg

    .section .note.GNU-stack,"",%progbits
