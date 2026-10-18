#include <stdio.h>
#include "gpu.h"
#include "entrada.h"
#include "background.h"

void bg_scroll(int x, int y)
{
    gpu_send(ENG_BG, 0, (uint32_t)x | ((uint32_t)y << 9));
}

void menu_background(void)
{
    for (;;) {
        puts("\n=== BACKGROUND ===\n[1] Scroll\n[2] Voltar");
        int op = ler_int("> ", 1, 2);
        if (op == 1) {
            int x = ler_int("Scroll X (0-319): ", 0, TELA_W - 1);
            int y = ler_int("Scroll Y (0-239): ", 0, TELA_H - 1);
            bg_scroll(x, y);
        } else {
            return;
        }
    }
}