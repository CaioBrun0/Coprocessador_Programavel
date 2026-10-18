#ifndef POLIGONOS_H
#define POLIGONOS_H
/* Retangulo (motor 0x3) e Triangulo (motor 0x4).
   Retornam 0 ok, -1 se a forma sairia da tela. */
int  ret_mover(int x, int y);   /* canto superior esquerdo -> (x,y) */
void ret_cor(int cor);          /* indice da paleta (1-255; 0 = transparente) */
int  tri_mover(int x, int y);   /* canto superior esquerdo da caixa -> (x,y) */
void tri_cor(int cor);
void menu_poligonos(void);
#endif
