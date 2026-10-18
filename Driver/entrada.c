#include <stdio.h>
#include <stdlib.h>
#include <sys/select.h>
#include <unistd.h>
#include "entrada.h"

int ler_int(const char *prompt, int min, int max)
{
    char buf[64];
    for (;;) {
        printf("%s", prompt);
        fflush(stdout);
        if (!fgets(buf, sizeof buf, stdin)) { putchar('\n'); exit(0); }
        char *fim;
        long v = strtol(buf, &fim, 10);
        if (fim == buf || (*fim != '\n' && *fim != '\0')) { puts("Entrada invalida."); continue; }
        if (v < min || v > max) { printf("Valor fora do intervalo (%d a %d).\n", min, max); continue; }
        return (int)v;
    }
}

int tecla_pressionada(void)
{
    fd_set fds;
    struct timeval tv = {0, 0};
    char b[64];
    FD_ZERO(&fds);
    FD_SET(STDIN_FILENO, &fds);
    if (select(STDIN_FILENO + 1, &fds, NULL, NULL, &tv) > 0) {
        if (fgets(b, sizeof b, stdin) == NULL) return 1;
        return 1;
    }
    return 0;
}
