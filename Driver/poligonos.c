#include <stdio.h>
#include "gpu.h"
#include "entrada.h"
#include "poligonos.h"

typedef struct { int x0, y0, x1, y1, cor, ativo; } Retangulo;
typedef struct { int x[3], y[3], cor, ativo; }       Triangulo;

/* Estado em software: o hardware recebe sempre a forma completa */
static Retangulo ret = { 20, 20, 100, 80, 1, 0 };
static Triangulo tri = { {0, 60, 30}, {0, 0, 50}, 1, 0 };

static void ret_enviar(void)
{
    gpu_send(ENG_RECT, 0, (uint32_t)ret.x0 | ((uint32_t)ret.y0 << 9));
    gpu_send(ENG_RECT, 1, (uint32_t)ret.x1 | ((uint32_t)ret.y1 << 9));
    gpu_send(ENG_RECT, 2, (uint32_t)ret.cor | ((uint32_t)ret.ativo << 8)); /* confirma */
}

static void tri_enviar(void)
{
    for (int i = 0; i < 3; i++)   /* x: 10 bits com sinal, y: 9 bits com sinal */
        gpu_send(ENG_TRI, i, ((uint32_t)tri.x[i] & 0x3FF) | (((uint32_t)tri.y[i] & 0x1FF) << 10));
    gpu_send(ENG_TRI, 3, (uint32_t)tri.cor | ((uint32_t)tri.ativo << 8)); /* confirma */
}

int ret_mover(int x, int y)
{
    int w = ret.x1 - ret.x0, h = ret.y1 - ret.y0;
    if (x < 0 || y < 0 || x + w >= TELA_W || y + h >= TELA_H) return -1;
    ret.x0 = x; ret.y0 = y; ret.x1 = x + w; ret.y1 = y + h;
    ret.ativo = 1;
    ret_enviar();
    return 0;
}

void ret_cor(int cor) { ret.cor = cor; ret.ativo = 1; ret_enviar(); }

int tri_mover(int x, int y)
{
    int minx = tri.x[0], miny = tri.y[0];
    for (int i = 1; i < 3; i++) {
        if (tri.x[i] < minx) minx = tri.x[i];
        if (tri.y[i] < miny) miny = tri.y[i];
    }
    int dx = x - minx, dy = y - miny;
    for (int i = 0; i < 3; i++) {
        int nx = tri.x[i] + dx, ny = tri.y[i] + dy;
        if (nx < 0 || nx >= TELA_W || ny < 0 || ny >= TELA_H) return -1;
    }
    for (int i = 0; i < 3; i++) { tri.x[i] += dx; tri.y[i] += dy; }
    tri.ativo = 1;
    tri_enviar();
    return 0;
}

void tri_cor(int cor) { tri.cor = cor; tri.ativo = 1; tri_enviar(); }

static void submenu_forma(const char *nome, int is_tri)
{
    for (;;) {
        printf("\n--- %s ---\n[1] Mover\n[2] Alterar cor\n[3] Voltar\n", nome);
        int op = ler_int("> ", 1, 3);
        if (op == 1) {
            int x = ler_int("X: ", 0, TELA_W - 1);
            int y = ler_int("Y: ", 0, TELA_H - 1);
            if ((is_tri ? tri_mover(x, y) : ret_mover(x, y)) < 0)
                puts("A forma sairia da tela nessa posicao.");
        } else if (op == 2) {
            int cor = ler_int("Cor (indice da paleta, 1-255): ", 1, 255);
            if (is_tri) tri_cor(cor); else ret_cor(cor);
        } else return;
    }
}

void menu_poligonos(void)
{
    for (;;) {
        puts("\n=== POLIGONOS ===\n[1] Triangulo\n[2] Retangulo\n[3] Voltar");
        int op = ler_int("> ", 1, 3);
        if (op == 1) submenu_forma("Triangulo", 1);
        else if (op == 2) submenu_forma("Retangulo", 0);
        else return;
    }
}
