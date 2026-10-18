#include <stdio.h>
#include "gpu.h"
#include "entrada.h"
#include "sprites.h"

#define N_SPRITES   32
#define TILE_PADRAO 32   /* mesmo tile do sprite 0 no reset do Verilog */

typedef struct { int x, y, tile, ativo, hflip, vflip; } Sprite;
static Sprite spr[N_SPRITES];

/* O hardware NAO tem rotacao, so hflip/vflip. "Girar" troca o tile por um
   desenho ja pronto para cada lado. TODO: ajustar aos tiles da sua ROM
   (cada sprite 16x16 usa 4 tiles consecutivos: base+0..+3). */
static const int TILE_LADO[5] = { 0, 32, 36, 40, 44 };  /* [1]..[4] */

enum { P_POS = 1, P_TILE = 2, P_FLAGS = 4 };

static void spr_enviar(int id, unsigned partes)
{
    Sprite *s = &spr[id];
    gpu_send(ENG_SPR, 0, (uint32_t)id);               /* seleciona o sprite */
    if (partes & P_POS)
        gpu_send(ENG_SPR, 1, (uint32_t)s->x | ((uint32_t)s->y << 9));
    if (partes & P_TILE)
        gpu_send(ENG_SPR, 2, (uint32_t)s->tile);
    if (partes & P_FLAGS)                              /* enable | hflip | vflip */
        gpu_send(ENG_SPR, 3, (uint32_t)s->ativo | ((uint32_t)s->hflip << 1) | ((uint32_t)s->vflip << 2));
}

/* Primeiro uso: liga o sprite e manda tile + flags junto */
static unsigned ativar(int id)
{
    if (spr[id].ativo) return 0;
    spr[id].ativo = 1;
    if (spr[id].tile == 0) spr[id].tile = TILE_PADRAO;
    return P_TILE | P_FLAGS;
}

void spr_mover(int id, int x, int y)
{
    unsigned extra = ativar(id);
    spr[id].x = x; spr[id].y = y;
    spr_enviar(id, P_POS | extra);
}

void spr_girar(int id, int lado)
{
    unsigned extra = ativar(id);
    spr[id].tile = TILE_LADO[lado];
    spr_enviar(id, P_TILE | extra);
}

void spr_espelhar(int id, int eixo)
{
    unsigned extra = ativar(id);
    if (eixo == 1) spr[id].hflip = !spr[id].hflip;
    else           spr[id].vflip = !spr[id].vflip;
    spr_enviar(id, P_FLAGS | extra);
}

static void submenu_sprite(int id)
{
    for (;;) {
        printf("\n--- Sprite %d ---\n[1] Mover\n[2] Girar\n[3] Espelhar\n[4] Voltar\n", id);
        int op = ler_int("> ", 1, 4);
        if (op == 1) {
            int x = ler_int("X: ", 0, TELA_W - 16);
            int y = ler_int("Y: ", 0, TELA_H - 16);
            spr_mover(id, x, y);
        } else if (op == 2) {
            int lado = ler_int("Lado ([1] Cima, [2] Baixo, [3] Esquerda, [4] Direita, [5] Voltar): ", 1, 5);
            if (lado != 5) spr_girar(id, lado);
        } else if (op == 3) {
            int eixo = ler_int("[1] Horizontal, [2] Vertical, [3] Voltar: ", 1, 3);
            if (eixo != 3) spr_espelhar(id, eixo);
        } else return;
    }
}

void menu_sprites(void)
{
    for (;;) {
        puts("\n=== SPRITES ===");
        int id = ler_int("Escolha o sprite [0-31] ou [32] Voltar: ", 0, 32);
        if (id == 32) return;
        submenu_sprite(id);
    }
}
