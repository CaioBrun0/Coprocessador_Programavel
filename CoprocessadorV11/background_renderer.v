module background_renderer (
    input  wire        clk,          // Clock de 25 MHz
    input  wire        reset,
    input  wire [8:0]  logic_x,      // 0 a 319
    input  wire [7:0]  logic_y,      // 0 a 239
    input  wire [8:0]  scroll_x,     // 0 a 319
    input  wire [7:0]  scroll_y,     // 0 a 239
	 input  wire 			bank_read, 	 //Seleciona o banco de Leitura
	 output wire [13:0] rom_addr,
    input  wire [7:0]  rom_data_in,
    output reg  [7:0]  color_out
);

    // =========================================================================
    // Aplicação do Scroll e Cálculo de Endereço
    // =========================================================================
    wire [9:0] soma_x = logic_x + scroll_x;
    wire [8:0] scrolled_x = (soma_x >= 320) ? (soma_x - 320) : soma_x[8:0];
    
    wire [8:0] soma_y = logic_y + scroll_y;
    wire [7:0] scrolled_y = (soma_y >= 240) ? (soma_y - 240) : soma_y[7:0];

    wire [5:0] tile_x      = scrolled_x[8:3];
    wire [4:0] tile_y      = scrolled_y[7:3];
    wire [2:0] row_in_tile = scrolled_y[2:0];
    wire [2:0] col_in_tile = scrolled_x[2:0];
	
	// Endereço base de 11 bits na malha (tile_y * 40 + tile_x)
    wire [10:0] tilemap_addr = {1'b0, tile_y, 5'b0} + {3'b0, tile_y, 3'b0} + {5'b0, tile_x};
	 
    
	 // =========================================================================
    // INTERLIGAÇÃO DAS MEMÓRIAS
    // =========================================================================
    wire [7:0] tile_id_bruto;
    reg [2:0] row_d1;
    reg [2:0] col_d1;

	 
	 //endereço de 12 bits: O MSB decide se lemos do Banco A (0) ou B (1)
	 wire [11:0] ping_pong_addr = {bank_read, tilemap_addr};
	 
	 // Concatenação para buscar o padrão do pixel na ROM gráfica (14 bits)
    assign rom_addr = {tile_id_bruto, row_d1, col_d1}; 
     
    ram_tilemap_2port tilemap_inst (
        .clock     (clk),
        .data      (8'd0),
        .wraddress (12'd0),
        .wren      (1'b0),
        .rdaddress (ping_pong_addr),  // Recebe o endereço roteado com o bit do Ping-Pong
        .q         (tile_id_bruto) 
    );
	 
    always @(posedge clk) begin
        row_d1 <= row_in_tile;
        col_d1 <= col_in_tile;
    end

    // =========================================================================
    // Saída da Cor Final
    // =========================================================================
    always @(posedge clk) begin
        if (reset) begin
            color_out <= 8'd0;
        end else begin
            color_out <= rom_data_in; 
        end
    end

endmodule