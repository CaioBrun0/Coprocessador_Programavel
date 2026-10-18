#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "gpu.h"
#include "entrada.h"
#include "poligonos.h"
#include "sprites.h"
#include "background.h"

static void demo_tudo(void)
{
    puts("\nDemonstracao: todos os elementos ao mesmo tempo. [Enter] para parar.");
    ret_cor(2);
    tri_cor(3);
    spr_mover(1, 0, 100);
    spr_mover(2, 200, 0);
    spr_mover(3, 150, 150);

    for (unsigned t = 0; !tecla_pressionada(); t++) {
        bg_scroll(t % TELA_W, (t / 2) % TELA_H);
        ret_mover(t % 240, 10);
        tri_mover(259 - t % 260, 150);
        spr_mover(1, t % 304, 100);
        spr_mover(2, 200, (t * 2) % 224);
        if (t % 30 == 0) spr_espelhar(3, 1);
        usleep(16667);                     /* ~60 quadros por segundo */
    }
}

int main(void)
{
    if (gpu_init() < 0) {
        fprintf(stderr, "Falha ao abrir a GPU (/dev/mem). Rode com sudo.\n");
        return 1;
    }
    atexit(gpu_close);

    for (;;) {
        puts("\n===== MENU =====\n[1] Poligonos\n[2] Sprites\n[3] Background\n"
             "[4] Mostrar \"Tudo\"\n[0] Sair");
        switch (ler_int("> ", 0, 4)) {
            case 1: menu_poligonos();  break;
            case 2: menu_sprites();    break;
            case 3: menu_background(); break;
            case 4: demo_tudo();       break;
            case 0: return 0;
        }
    }
}
