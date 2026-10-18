#ifndef GPU_H
#define GPU_H
#include <stdint.h>

/* ---- Motores (bits 30:27 do comando) ---- */
#define ENG_BG    0x1
#define ENG_SPR   0x2
#define ENG_RECT  0x3
#define ENG_TRI   0x4

#define TELA_W 320   /* tela logica */
#define TELA_H 240

/* Formato do comando: [30:27] motor | [26:23] registrador | [22:0] valor */
#define GPU_CMD(eng, reg, val) \
    ( ((uint32_t)((eng) & 0xF) << 27) | \
      ((uint32_t)((reg) & 0xF) << 23) | \
      ((uint32_t)(val) & 0x7FFFFFu) )

/* ---- Implementadas em assembly (gpu_driver.s): unico acesso ao hardware ---- */
int      gpu_init(void);                 /* abre e mapeia /dev/mem: 0 ok, -1 erro */
void     gpu_close(void);
int      gpu_write_cmd(uint32_t cmd);    /* 0 = ok, -1 = FIFO cheia (timeout) */
uint32_t gpu_read_status(void);          /* bit0 = cheia, bit1 = vazia */

/* ---- Implementada em C (gpu.c): so monta o comando e chama o driver ---- */
void gpu_send(unsigned eng, unsigned reg, uint32_t val);

#endif
