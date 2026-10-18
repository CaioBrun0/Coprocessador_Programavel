# Na placa:           make
# Cross-compilando:   make CC=arm-linux-gnueabihf-gcc
# -no-pie: o driver em assembly usa enderecos absolutos (ldr r1, =simbolo)
CC     ?= gcc
CFLAGS ?= -Wall -Wextra -O2 -std=gnu11 -no-pie
SRC     = main.c gpu.c entrada.c poligonos.c sprites.c background.c

gpu_cli: $(SRC) gpu_driver.s
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f gpu_cli
