#ifndef SPRITES_H
#define SPRITES_H
/* OAM: 32 sprites (motor 0x2), 16x16 pixels */
void spr_mover(int id, int x, int y);
void spr_girar(int id, int lado);      /* 1 cima, 2 baixo, 3 esquerda, 4 direita */
void spr_espelhar(int id, int eixo);   /* 1 horizontal, 2 vertical (alterna) */
void menu_sprites(void);
#endif
