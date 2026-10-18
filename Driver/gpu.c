#include <stdio.h>
#include "gpu.h"

/* Camada fina entre os motores e o driver: empacota (motor, reg, valor) em
   32 bits e entrega ao assembly. Nao acessa o hardware. */
void gpu_send(unsigned eng, unsigned reg, uint32_t val)
{
    if (gpu_write_cmd(GPU_CMD(eng, reg, val)) < 0)
        fprintf(stderr, "GPU: FIFO cheia/sem resposta (comando perdido)\n");
}
