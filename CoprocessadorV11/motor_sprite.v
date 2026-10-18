module motor_sprite (
    input  wire        clk,
    input  wire        reset,
    
    // Coordenadas lógicas da tela (320x240)
    input  wire [8:0]  logical_x,
    input  wire [7:0]  logical_y,

	 // Barramento Dinâmico da ISA (Vindo do Decodificador)
    input  wire [4:0]  spr_id,
    input  wire [8:0]  spr_x,
    input  wire [7:0]  spr_y,
    input  wire [7:0]  spr_tile,
    input  wire        spr_enable,
    input  wire        spr_hflip,
    input  wire        spr_vflip,
    
    // Pulsos de gravação seletivos
    input  wire        spr_wr_pos,
    input  wire        spr_wr_tile,
    input  wire        spr_wr_flags,
	 
	 //Seleciona o banco do Ping-Pong (0 ou 1)
	 input  wire		  bank_read, 			
    
	 // Interface com a ROM de Padrões (Tileset - Porta B)
    output wire [13:0] rom_addr,
    input  wire [7:0]  rom_data_in,

    // Saída para o Compositor de Camadas
    output reg  [7:0]  sprite_color_idx,
    output reg         sprite_active
);

    // =========================================================================
    // 1. OAM (Object Attribute Memory) - 32 Sprites
	 // OAM EXPANDIDA PARA 64 POSIÇÕES (DOUBLE BUFFERING)
    // Banco A = Índices [0 a 31] | Banco B = Índices [32 a 63]
    // =========================================================================
    reg [8:0] oam_x      [0:63]; // Posição X (0 a 319)
    reg [7:0] oam_y      [0:63]; // Posição Y (0 a 239)
    reg [7:0] oam_tile   [0:63]; // Índice do desenho base na ROM
    reg       oam_enable [0:63]; // Sprite ligado/desligado
    reg       oam_hflip  [0:63]; // Espelhamento horizontal
    reg       oam_vflip  [0:63]; // Espelhamento vertical
    
  integer i;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 64; i = i + 1) begin
                oam_x[i] <= 9'd0; oam_y[i] <= 8'd0; oam_tile[i] <= 8'd0;
                oam_enable[i] <= 1'b0; oam_hflip[i] <= 1'b0; oam_vflip[i] <= 1'b0;
            end
            // Mantém apenas o Sprite 0 ativo para debug inicial
            oam_tile[0] <= 8'd32; oam_enable[0] <= 1'b1;
            oam_tile[32] <= 8'd32; oam_enable[32] <= 1'b1;
        end else begin
            // Grava no banco oculto (~bank_read) apenas quando o decodificador mandar
 
            if (spr_wr_pos) begin
					 oam_x[{bank_read, spr_id}] <= spr_x;
					 oam_y[{bank_read, spr_id}] <= spr_y;
				end
				if (spr_wr_tile) begin
					oam_tile[{bank_read, spr_id}] <= spr_tile;
				end
				if (spr_wr_flags) begin
					oam_enable[{bank_read, spr_id}] <= spr_enable;
					oam_hflip[{bank_read, spr_id}]  <= spr_hflip;
					oam_vflip[{bank_read, spr_id}]  <= spr_vflip;
				end
        end
    end

    // =========================================================================
    // 2. HIT DETECTION E PRIORIDADE (Varredura Paralela)
    // =========================================================================
    reg       hit_found;
    reg [3:0] hit_dx;         // Deslocamento X dentro do sprite (0 a 15)
    reg [3:0] hit_dy;         // Deslocamento Y dentro do sprite (0 a 15)
    reg [7:0] hit_tile_base;  
    reg       hit_hflip;
    reg       hit_vflip;

    integer j;
    always @(*) begin
        hit_found = 1'b0; hit_dx = 4'd0; hit_dy = 4'd0;
        hit_tile_base = 8'd0; hit_hflip = 1'b0; hit_vflip = 1'b0;
        
        for (j = 31; j >= 0; j = j - 1) begin
            if (oam_enable[{bank_read, j[4:0]}] && 
               (logical_x >= oam_x[{bank_read, j[4:0]}]) && (logical_x < oam_x[{bank_read, j[4:0]}] + 9'd16) &&
               (logical_y >= oam_y[{bank_read, j[4:0]}]) && (logical_y < oam_y[{bank_read, j[4:0]}] + 8'd16)) begin
                
                hit_found     = 1'b1;
                hit_dx        = logical_x - oam_x[{bank_read, j[4:0]}]; 
                hit_dy        = logical_y - oam_y[{bank_read, j[4:0]}]; 
                hit_tile_base = oam_tile[{bank_read, j[4:0]}];
                hit_hflip     = oam_hflip[{bank_read, j[4:0]}];
                hit_vflip     = oam_vflip[{bank_read, j[4:0]}];
            end
        end
    end
	// =========================================================================
	//	MATEMATICA DO TILE
	// =========================================================================
    wire [3:0] eff_dx = hit_hflip ? (4'd15 - hit_dx) : hit_dx;
    wire [3:0] eff_dy = hit_vflip ? (4'd15 - hit_dy) : hit_dy;
    wire [7:0] actual_tile = hit_tile_base + (eff_dy[3] ? 8'd2 : 8'd0) + (eff_dx[3] ? 8'd1 : 8'd0);
    assign rom_addr = {actual_tile, eff_dy[2:0], eff_dx[2:0]};
	 // =========================================================================
    // Pipeline
	 // =========================================================================
    reg hit_found_delay;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            hit_found_delay <= 1'b0; sprite_active <= 1'b0; sprite_color_idx <= 8'd0;
        end else begin
            hit_found_delay <= hit_found;
            if (hit_found_delay && rom_data_in != 8'd0) begin
                sprite_active <= 1'b1; sprite_color_idx <= rom_data_in;
            end else begin
                sprite_active <= 1'b0; sprite_color_idx <= 8'd0;
            end
        end
    end
endmodule