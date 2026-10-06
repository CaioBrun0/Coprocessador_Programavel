module gpu_top (
    input  wire        clk,
    input  wire        reset,
    input  wire        fim_de_quadro,

    // Interface Avalon-MM Slave (Lado do Processador ARM)
    input  wire [1:0]  avs_address,
    input  wire        avs_write,
    input  wire [31:0] avs_writedata,
    input  wire        avs_read,
    output wire [31:0] avs_readdata,

    // Saídas para o Motor Gráfico (Conduit para fora do Qsys)
    output wire [8:0]  bg_scroll_x,
    output wire [7:0]  bg_scroll_y,
    output wire [7:0]  bg_color,
	 
	 //Saídas para Poligonos (Conduit)
	 output wire [8:0]        rect_x0,
    output wire [7:0]        rect_y0,
    output wire [8:0]        rect_x1,
    output wire [7:0]        rect_y1,
    output wire [7:0]        rect_color,
    output wire              rect_enable,

    output wire signed [9:0] tri_x0,
    output wire signed [8:0] tri_y0,
    output wire signed [9:0] tri_x1,
    output wire signed [8:0] tri_y1,
    output wire signed [9:0] tri_x2,
    output wire signed [8:0] tri_y2,
    output wire [7:0]        tri_color,
    output wire              tri_enable
);

    wire [31:0] fifo_q;
    wire        fifo_rdreq;
    wire        fifo_empty;
    wire        fifo_full;

    // Escreve na FIFO quando o ARM escreve no offset 0x00 (address == 00)
    wire fifo_wrreq = avs_write && (avs_address == 2'b00);

    // Leitura de Status no offset 0x04 (address == 01): Bit 1 = DONE (empty), Bit 0 = BUSY (full)
    assign avs_readdata = (avs_read && (avs_address == 2'b01)) ? {30'd0, fifo_empty, fifo_full} : 32'd0;

    // Instância com os nomes exatos do IP fifo_32bits da Altera (sem sclr)
    fifo_32bcomand u_fifo (
        .clock (clk),
        .data  (avs_writedata),
        .wrreq (fifo_wrreq),
        .rdreq (fifo_rdreq),
        .empty (fifo_empty),
        .full  (fifo_full),
        .q     (fifo_q),
        .usedw ()
    );

    // Instância com os nomes exatos do seu mvp_interface_bg.v (fifo_q e fifo_rdreq)
    // Instância do Decodificador com as novas portas de polígonos
    mvp_interface_bg u_decodificador (
        .clk           (clk),
        .reset         (reset),
        .fim_de_quadro (fim_de_quadro),
        
        .fifo_q        (fifo_q),
        .fifo_empty    (fifo_empty),
        .fifo_rdreq    (fifo_rdreq),
        
        .bg_scroll_x   (bg_scroll_x),
        .bg_scroll_y   (bg_scroll_y),
        .bg_color      (bg_color),
        
        // Roteamento dos fios dinâmicos do Retângulo
        .rect_x0       (rect_x0),
        .rect_y0       (rect_y0),
        .rect_x1       (rect_x1),
        .rect_y1       (rect_y1),
        .rect_color    (rect_color),
        .rect_enable   (rect_enable),
        
        // Roteamento dos fios dinâmicos do Triângulo
        .tri_x0        (tri_x0),
        .tri_y0        (tri_y0),
        .tri_x1        (tri_x1),
        .tri_y1        (tri_y1),
        .tri_x2        (tri_x2),
        .tri_y2        (tri_y2),
        .tri_color     (tri_color),
        .tri_enable    (tri_enable)
    );
endmodule