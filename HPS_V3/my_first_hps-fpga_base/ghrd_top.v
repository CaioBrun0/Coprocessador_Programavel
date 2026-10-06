`define ENABLE_HPS

module ghrd_top(

      ///////// ADC /////////
      output             ADC_CONVST,
      output             ADC_DIN,
      input              ADC_DOUT,
      output             ADC_SCLK,

      ///////// AUD /////////
      input              AUD_ADCDAT,
      inout              AUD_ADCLRCK,
      inout              AUD_BCLK,
      output             AUD_DACDAT,
      inout              AUD_DACLRCK,
      output             AUD_XCK,

      ///////// CLOCK2 /////////
      input              CLOCK2_50,

      ///////// CLOCK3 /////////
      input              CLOCK3_50,

      ///////// CLOCK4 /////////
      input              CLOCK4_50,

      ///////// CLOCK /////////
      input              CLOCK_50,

      ///////// DRAM /////////
      output      [12:0] DRAM_ADDR,
      output      [1:0]  DRAM_BA,
      output             DRAM_CAS_N,
      output             DRAM_CKE,
      output             DRAM_CLK,
      output             DRAM_CS_N,
      inout       [15:0] DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_RAS_N,
      output             DRAM_UDQM,
      output             DRAM_WE_N,

      ///////// FAN /////////
      output             FAN_CTRL,

      ///////// FPGA /////////
      output             FPGA_I2C_SCLK,
      inout              FPGA_I2C_SDAT,

      ///////// GPIO /////////
      inout     [35:0]   GPIO_0,
      inout     [35:0]   GPIO_1,
 
      ///////// HEX0 /////////
      output      [6:0]  HEX0,

      ///////// HEX1 /////////
      output      [6:0]  HEX1,

      ///////// HEX2 /////////
      output      [6:0]  HEX2,

      ///////// HEX3 /////////
      output      [6:0]  HEX3,

      ///////// HEX4 /////////
      output      [6:0]  HEX4,

      ///////// HEX5 /////////
      output      [6:0]  HEX5,

`ifdef ENABLE_HPS
      ///////// HPS /////////
      inout              HPS_CONV_USB_N,
      output      [14:0] HPS_DDR3_ADDR,
      output      [2:0]  HPS_DDR3_BA,
      output             HPS_DDR3_CAS_N,
      output             HPS_DDR3_CKE,
      output             HPS_DDR3_CK_N,
      output             HPS_DDR3_CK_P,
      output             HPS_DDR3_CS_N,
      output      [3:0]  HPS_DDR3_DM,
      inout       [31:0] HPS_DDR3_DQ,
      inout       [3:0]  HPS_DDR3_DQS_N,
      inout       [3:0]  HPS_DDR3_DQS_P,
      output             HPS_DDR3_ODT,
      output             HPS_DDR3_RAS_N,
      output             HPS_DDR3_RESET_N,
      input              HPS_DDR3_RZQ,
      output             HPS_DDR3_WE_N,
      output             HPS_ENET_GTX_CLK,
      inout              HPS_ENET_INT_N,
      output             HPS_ENET_MDC,
      inout              HPS_ENET_MDIO,
      input              HPS_ENET_RX_CLK,
      input       [3:0]  HPS_ENET_RX_DATA,
      input              HPS_ENET_RX_DV,
      output      [3:0]  HPS_ENET_TX_DATA,
      output             HPS_ENET_TX_EN,
      inout       [3:0]  HPS_FLASH_DATA,
      output             HPS_FLASH_DCLK,
      output             HPS_FLASH_NCSO,
      inout              HPS_GSENSOR_INT,
      inout              HPS_I2C1_SCLK,
      inout              HPS_I2C1_SDAT,
      inout              HPS_I2C2_SCLK,
      inout              HPS_I2C2_SDAT,
      inout              HPS_I2C_CONTROL,
      inout              HPS_KEY,
      inout              HPS_LED,
      inout              HPS_LTC_GPIO,
      output             HPS_SD_CLK,
      inout              HPS_SD_CMD,
      inout       [3:0]  HPS_SD_DATA,
      output             HPS_SPIM_CLK,
      input              HPS_SPIM_MISO,
      output             HPS_SPIM_MOSI,
      inout              HPS_SPIM_SS,
      input              HPS_UART_RX,
      output             HPS_UART_TX,
      input              HPS_USB_CLKOUT,
      inout       [7:0]  HPS_USB_DATA,
      input              HPS_USB_DIR,
      input              HPS_USB_NXT,
      output             HPS_USB_STP,
`endif /*ENABLE_HPS*/

      ///////// IRDA /////////
      input              IRDA_RXD,
      output             IRDA_TXD,

      ///////// KEY /////////
      input       [3:0]  KEY,

      ///////// LEDR /////////
      output      [9:0]  LEDR,

      ///////// PS2 /////////
      inout              PS2_CLK,
      inout              PS2_CLK2,
      inout              PS2_DAT,
      inout              PS2_DAT2,

      ///////// SW /////////
      input       [9:0]  SW,

      ///////// TD /////////
      input              TD_CLK27,
      input       [7:0]  TD_DATA,
      input              TD_HS,
      output             TD_RESET_N,
      input              TD_VS,

      ///////// VGA /////////
      output      [7:0]  VGA_B,
      output             VGA_BLANK_N,
      output             VGA_CLK,
      output      [7:0]  VGA_G,
      output             VGA_HS,
      output      [7:0]  VGA_R,
      output             VGA_SYNC_N,
      output             VGA_VS,

      ///////// UART /////////  
      output             UART_TX,
      input              UART_RX,
      output             UART_RTS,
      input              UART_CTS,

      ///////// QSPI /////////  
      output             QSPI_FLASH_SCLK,
      inout       [3:0]  QSPI_FLASH_DATA,
      output             QSPI_FLASH_CE_n,

      ///////// RISC-V JTAG /////////
      input              RISCV_JTAG_TCK,
      input              RISCV_JTAG_TDI,
      output             RISCV_JTAG_TDO,
      input              RISCV_JTAG_TMS 
);

// ============================================================================
// FIOS INTERNOS DO HPS (GHRD ORIGINAL)
// ============================================================================
wire [3:0]  fpga_debounced_buttons;
wire [9:0]  fpga_led_internal;
wire        hps_fpga_reset_n;
wire [2:0]  hps_reset_req;
wire        hps_cold_reset;
wire        hps_warm_reset;
wire        hps_debug_reset;
wire [27:0] stm_hw_events;

assign stm_hw_events = {{3{1'b0}}, SW, fpga_led_internal, fpga_debounced_buttons};

// ============================================================================
// DIVISOR DE CLOCK (25 MHz) E POWER-ON RESET (DO COPROCESSADOR GRÁFICO)
// ============================================================================
reg clk_25m = 1'b0;
always @(posedge CLOCK_50) begin
    clk_25m <= ~clk_25m;
end

reg [7:0] por_counter = 8'hFF; 
always @(posedge clk_25m) begin
    if (por_counter != 8'd0) begin
        por_counter <= por_counter - 1'b1;
    end
end

// KEY[0] é ativo baixo na DE1-SoC
wire global_reset = (~KEY[0]) | (por_counter != 8'd0);

// ============================================================================
// DECLARAÇÃO DOS FIOS GRÁFICOS E CONDUIT DA GPU
// ============================================================================
wire [9:0] vga_next_x; 
wire [9:0] vga_next_y; 
wire [8:0] logical_x = vga_next_x[9:1]; 
wire [7:0] logical_y = vga_next_y[8:1]; 

wire [13:0] bkg_rom_addr;
wire [7:0]  bkg_rom_data;
wire [7:0]  bkg_color;

wire [13:0] spr_rom_addr;
wire [7:0]  spr_rom_data;
wire [7:0]  spr_color;
wire        spr_active;

wire [7:0]  poly_color;
wire        poly_active;
wire [23:0] final_rgb;

// Fios que vêm do gpu_top_0 dentro do soc_system (Conduit video_out)
wire [8:0]  bg_scroll_x;
wire [7:0]  bg_scroll_y;
wire [7:0]  bg_color_solid;
wire        fim_de_quadro = (logical_x == 9'd319) && (logical_y == 8'd239);

// Valores fixos temporários para o Sprite 0
wire [8:0]  boneco_x = 9'd160;
wire [7:0]  boneco_y = 8'd120;

// Fios dinâmicos do Retângulo (Vindos do Qsys)
wire [8:0]  rect_x0_ctrl, rect_x1_ctrl;
wire [7:0]  rect_y0_ctrl, rect_y1_ctrl, rect_color_ctrl;
wire        rect_visible;

// Fios dinâmicos do Triângulo (Vindos do Qsys)
wire signed [9:0] tri_x0_ctrl, tri_x1_ctrl, tri_x2_ctrl;
wire signed [8:0] tri_y0_ctrl, tri_y1_ctrl, tri_y2_ctrl;
wire [7:0]        tri_color_ctrl;
wire              tri_visible;

// ============================================================================
// FRAME BUFFER (VRAM PARA A FASE 3)
// ============================================================================
wire [16:0] vram_rd_addr;
wire [7:0]  vram_color;

// Cálculo otimizado do endereço sem multiplicar: (Y * 256) + (Y * 64) + X
assign vram_rd_addr = ({logical_y, 8'd0} + {logical_y, 6'd0}) + logical_x;

ram_framebuffer u_vram (
    .clock     (clk_25m),
    .data      (8'd0),         
    .wraddress (17'd0),
    .wren      (1'b0), 
    .rdaddress (vram_rd_addr), 
    .q         (vram_color)
);

// ============================================================================
// COMPOSITOR DE CAMADAS
// ============================================================================
wire poligonos_visiveis = poly_active && (poly_color != 8'd0);
 
wire [7:0] final_pixel_index = (spr_active && spr_color != 8'd0) ? spr_color :
                                poligonos_visiveis               ? poly_color : 
                               (bkg_color != 8'd0)               ? bkg_color  : 
                               (vram_color != 8'd0)              ? vram_color :
                                                                   bg_color_solid;

// ============================================================================
// INSTÂNCIA DO SISTEMA SOC (HPS + GPU_TOP)
// ============================================================================
soc_system u0 (
    .clk_clk                               ( CLOCK_50             ),
    .reset_reset_n                         ( hps_fpga_reset_n     ),

    .memory_mem_a                          ( HPS_DDR3_ADDR        ),
    .memory_mem_ba                         ( HPS_DDR3_BA          ),
    .memory_mem_ck                         ( HPS_DDR3_CK_P        ),
    .memory_mem_ck_n                       ( HPS_DDR3_CK_N        ),
    .memory_mem_cke                        ( HPS_DDR3_CKE         ),
    .memory_mem_cs_n                       ( HPS_DDR3_CS_N        ),
    .memory_mem_ras_n                      ( HPS_DDR3_RAS_N       ),
    .memory_mem_cas_n                      ( HPS_DDR3_CAS_N       ),
    .memory_mem_we_n                       ( HPS_DDR3_WE_N        ),
    .memory_mem_reset_n                    ( HPS_DDR3_RESET_N     ),
    .memory_mem_dq                         ( HPS_DDR3_DQ          ),
    .memory_mem_dqs                        ( HPS_DDR3_DQS_P       ),
    .memory_mem_dqs_n                      ( HPS_DDR3_DQS_N       ),
    .memory_mem_odt                        ( HPS_DDR3_ODT         ),
    .memory_mem_dm                         ( HPS_DDR3_DM          ),
    .memory_oct_rzqin                      ( HPS_DDR3_RZQ         ),
        
    .hps_0_hps_io_hps_io_emac1_inst_TX_CLK ( HPS_ENET_GTX_CLK     ),
    .hps_0_hps_io_hps_io_emac1_inst_TXD0   ( HPS_ENET_TX_DATA[0]  ),
    .hps_0_hps_io_hps_io_emac1_inst_TXD1   ( HPS_ENET_TX_DATA[1]  ),
    .hps_0_hps_io_hps_io_emac1_inst_TXD2   ( HPS_ENET_TX_DATA[2]  ),
    .hps_0_hps_io_hps_io_emac1_inst_TXD3   ( HPS_ENET_TX_DATA[3]  ),
    .hps_0_hps_io_hps_io_emac1_inst_RXD0   ( HPS_ENET_RX_DATA[0]  ),
    .hps_0_hps_io_hps_io_emac1_inst_MDIO   ( HPS_ENET_MDIO        ),
    .hps_0_hps_io_hps_io_emac1_inst_MDC    ( HPS_ENET_MDC         ),
    .hps_0_hps_io_hps_io_emac1_inst_RX_CTL ( HPS_ENET_RX_DV       ),
    .hps_0_hps_io_hps_io_emac1_inst_TX_CTL ( HPS_ENET_TX_EN       ),
    .hps_0_hps_io_hps_io_emac1_inst_RX_CLK ( HPS_ENET_RX_CLK      ),
    .hps_0_hps_io_hps_io_emac1_inst_RXD1   ( HPS_ENET_RX_DATA[1]  ),
    .hps_0_hps_io_hps_io_emac1_inst_RXD2   ( HPS_ENET_RX_DATA[2]  ),
    .hps_0_hps_io_hps_io_emac1_inst_RXD3   ( HPS_ENET_RX_DATA[3]  ),
      
    .hps_0_hps_io_hps_io_qspi_inst_IO0     ( HPS_FLASH_DATA[0]    ),
    .hps_0_hps_io_hps_io_qspi_inst_IO1     ( HPS_FLASH_DATA[1]    ),
    .hps_0_hps_io_hps_io_qspi_inst_IO2     ( HPS_FLASH_DATA[2]    ),
    .hps_0_hps_io_hps_io_qspi_inst_IO3     ( HPS_FLASH_DATA[3]    ),
    .hps_0_hps_io_hps_io_qspi_inst_SS0     ( HPS_FLASH_NCSO       ),
    .hps_0_hps_io_hps_io_qspi_inst_CLK     ( HPS_FLASH_DCLK       ),
    
    .hps_0_hps_io_hps_io_sdio_inst_CMD     ( HPS_SD_CMD           ),
    .hps_0_hps_io_hps_io_sdio_inst_D0      ( HPS_SD_DATA[0]       ),
    .hps_0_hps_io_hps_io_sdio_inst_D1      ( HPS_SD_DATA[1]       ),
    .hps_0_hps_io_hps_io_sdio_inst_CLK     ( HPS_SD_CLK           ),
    .hps_0_hps_io_hps_io_sdio_inst_D2      ( HPS_SD_DATA[2]       ),
    .hps_0_hps_io_hps_io_sdio_inst_D3      ( HPS_SD_DATA[3]       ),
            
    .hps_0_hps_io_hps_io_usb1_inst_D0      ( HPS_USB_DATA[0]      ),
    .hps_0_hps_io_hps_io_usb1_inst_D1      ( HPS_USB_DATA[1]      ),
    .hps_0_hps_io_hps_io_usb1_inst_D2      ( HPS_USB_DATA[2]      ),
    .hps_0_hps_io_hps_io_usb1_inst_D3      ( HPS_USB_DATA[3]      ),
    .hps_0_hps_io_hps_io_usb1_inst_D4      ( HPS_USB_DATA[4]      ),
    .hps_0_hps_io_hps_io_usb1_inst_D5      ( HPS_USB_DATA[5]      ),
    .hps_0_hps_io_hps_io_usb1_inst_D6      ( HPS_USB_DATA[6]      ),
    .hps_0_hps_io_hps_io_usb1_inst_D7      ( HPS_USB_DATA[7]      ),
    .hps_0_hps_io_hps_io_usb1_inst_CLK     ( HPS_USB_CLKOUT       ),
    .hps_0_hps_io_hps_io_usb1_inst_STP     ( HPS_USB_STP          ),
    .hps_0_hps_io_hps_io_usb1_inst_DIR     ( HPS_USB_DIR          ),
    .hps_0_hps_io_hps_io_usb1_inst_NXT     ( HPS_USB_NXT          ),
            
    .hps_0_hps_io_hps_io_spim1_inst_CLK    ( HPS_SPIM_CLK         ),
    .hps_0_hps_io_hps_io_spim1_inst_MOSI   ( HPS_SPIM_MOSI        ),
    .hps_0_hps_io_hps_io_spim1_inst_MISO   ( HPS_SPIM_MISO        ),
    .hps_0_hps_io_hps_io_spim1_inst_SS0    ( HPS_SPIM_SS          ),
        
    .hps_0_hps_io_hps_io_uart0_inst_RX     ( HPS_UART_RX          ),
    .hps_0_hps_io_hps_io_uart0_inst_TX     ( HPS_UART_TX          ),
    
    .hps_0_hps_io_hps_io_i2c0_inst_SDA     ( HPS_I2C1_SDAT        ),
    .hps_0_hps_io_hps_io_i2c0_inst_SCL     ( HPS_I2C1_SCLK        ),
    
    .hps_0_hps_io_hps_io_i2c1_inst_SDA     ( HPS_I2C2_SDAT        ),
    .hps_0_hps_io_hps_io_i2c1_inst_SCL     ( HPS_I2C2_SCLK        ),
    
    .hps_0_hps_io_hps_io_gpio_inst_GPIO09  ( HPS_CONV_USB_N       ),
    .hps_0_hps_io_hps_io_gpio_inst_GPIO35  ( HPS_ENET_INT_N       ),
    .hps_0_hps_io_hps_io_gpio_inst_GPIO40  ( HPS_LTC_GPIO         ),
    .hps_0_hps_io_hps_io_gpio_inst_GPIO48  ( HPS_I2C_CONTROL      ),
    .hps_0_hps_io_hps_io_gpio_inst_GPIO53  ( HPS_LED              ),
    .hps_0_hps_io_hps_io_gpio_inst_GPIO54  ( HPS_KEY              ),
    .hps_0_hps_io_hps_io_gpio_inst_GPIO61  ( HPS_GSENSOR_INT      ),

    .hps_0_f2h_stm_hw_events_stm_hwevents  ( stm_hw_events        ),
    .hps_0_h2f_reset_reset_n               ( hps_fpga_reset_n     ),
    .hps_0_f2h_warm_reset_req_reset_n      ( ~hps_warm_reset      ),
    .hps_0_f2h_debug_reset_req_reset_n     ( ~hps_debug_reset     ),
    .hps_0_f2h_cold_reset_req_reset_n      ( ~hps_cold_reset      ),

    // Sinais exportados do gpu_top_0 (Conduit video_out)
    .gpu_top_0_video_out_color             ( bg_color_solid       ),
    .gpu_top_0_video_out_scroll_x          ( bg_scroll_x          ),
    .gpu_top_0_video_out_scroll_y          ( bg_scroll_y          ),
    .gpu_top_0_video_out_vblank            ( fim_de_quadro        ),
	 
	 // Sinais exportados do gpu_top_0 (Conduit video_out)
    .gpu_top_0_video_out_color             ( bg_color_solid       ),
    .gpu_top_0_video_out_scroll_x          ( bg_scroll_x          ),
    .gpu_top_0_video_out_scroll_y          ( bg_scroll_y          ),
    .gpu_top_0_video_out_vblank            ( fim_de_quadro        ),

    // SINAIS DOS POLÍGONOS 
    .gpu_top_0_video_out_rect_enable       ( rect_enable_ctrl ),
    .gpu_top_0_video_out_rect_x0           ( rect_x0_ctrl ),
    .gpu_top_0_video_out_rect_y0           ( rect_y0_ctrl ),
    .gpu_top_0_video_out_rect_x1           ( rect_x1_ctrl ),
    .gpu_top_0_video_out_rect_y1           ( rect_y1_ctrl ),
    .gpu_top_0_video_out_rect_color        ( rect_color_ctrl ),

    .gpu_top_0_video_out_tri_enable        ( tri_enable_ctrl ),
    .gpu_top_0_video_out_tri_x0            ( tri_x0_ctrl ),
    .gpu_top_0_video_out_tri_y0            ( tri_y0_ctrl ),
    .gpu_top_0_video_out_tri_x1            ( tri_x1_ctrl ),
    .gpu_top_0_video_out_tri_y1            ( tri_y1_ctrl ),
    .gpu_top_0_video_out_tri_x2            ( tri_x2_ctrl ),
    .gpu_top_0_video_out_tri_y2            ( tri_y2_ctrl ),
    .gpu_top_0_video_out_tri_color         ( tri_color_ctrl )
);

// ============================================================================
// INSTÂNCIAS DAS MEMÓRIAS GRÁFICAS (ROM / RAM / PALETA)
// ============================================================================
ram_tile u_bkg_tiles_rom (
    .clock     (clk_25m),
    .data      (8'd0),
    .rdaddress (bkg_rom_addr),
    .wraddress (14'd0),
    .wren      (1'b0),
    .q         (bkg_rom_data)
);

rom_memoria2 u_sprites_rom (
    .address_a (14'd0),
    .q_a       (),
    .address_b (spr_rom_addr),
    .q_b       (spr_rom_data),
    .clock     (clk_25m)
);

paleta_rom u_paleta (
    .clock   (clk_25m),
    .address (final_pixel_index),
    .q       (final_rgb)
);

// ============================================================================
// MOTORES GRÁFICOS E CONTROLADOR VGA
// ============================================================================
vga_driver u_driver (
    .clock    (clk_25m),
    .reset    (global_reset),
    .color_in (final_rgb),
    .next_x   (vga_next_x),        
    .next_y   (vga_next_y),        
    .hsync    (VGA_HS), 
    .vsync    (VGA_VS), 
    .red      (VGA_R),   
    .green    (VGA_G), 
    .blue     (VGA_B),  
    .sync     (VGA_SYNC_N),  
    .clk      (VGA_CLK),   
    .blank    (VGA_BLANK_N)
);

// ============================================================================
// CONTROLE DO PING-PONG BUFFER (DOUBLE BUFFERING)
// ============================================================================
reg bank_read_reg;
always @(posedge clk_25m) begin
    if (global_reset) begin
        bank_read_reg <= 1'b0;
    end else if (fim_de_quadro) begin
        // Inverte o banco de leitura de forma perfeitamente síncrona
        bank_read_reg <= ~bank_read_reg; 
    end
end

background_renderer u_bkg_renderer (
    .clk         (clk_25m),
    .reset       (global_reset),
    .logic_x     (logical_x),
    .logic_y     (logical_y),
    .scroll_x    (bg_scroll_x), 
    .scroll_y    (bg_scroll_y),
    .bank_read   (bank_read_reg),  //Conexão do sinal do Ping-Pong
    .rom_addr    (bkg_rom_addr),   
    .rom_data_in (bkg_rom_data),
    .color_out   (bkg_color)
);

motor_sprite u_sprites ( 
    .clk              (clk_25m),
    .reset            (global_reset),
    .logical_x        (logical_x),
    .logical_y        (logical_y),
    .sprite_x_in      (boneco_x), 
    .sprite_y_in      (boneco_y), 
    .sprite_hflip_in  (SW[8]),   
    .sprite_vflip_in  (SW[9]),   
    .rom_addr         (spr_rom_addr),
    .rom_data_in      (spr_rom_data),
    .sprite_color_idx (spr_color),
    .sprite_active    (spr_active)
);

rasterizador_poligonos u_poly_raster (
    .clk              (clk_25m),
    .reset            (global_reset),
    .logical_x        (logical_x),
    .logical_y        (logical_y),
    
    // Retângulo dinâmico
    .rect_enable      (rect_enable_ctrl), 
    .rect_x0          (rect_x0_ctrl),   .rect_y0 (rect_y0_ctrl),
    .rect_x1          (rect_x1_ctrl),   .rect_y1 (rect_y1_ctrl),
    .rect_color       (rect_color_ctrl),
    
    // Triângulo dinâmico
    .tri_enable       (tri_enable_ctrl), 
    .tri_x0           (tri_x0_ctrl),    .tri_y0 (tri_y0_ctrl),
    .tri_x1           (tri_x1_ctrl),    .tri_y1 (tri_y1_ctrl),
    .tri_x2           (tri_x2_ctrl),    .tri_y2 (tri_y2_ctrl),
    .tri_color        (tri_color_ctrl),
    
    .poly_color_index (poly_color),
    .poly_active      (poly_active)
);

// ============================================================================
// DETECTORES DE BORDA DE RESET DO HPS (GHRD ORIGINAL)
// ============================================================================
hps_reset hps_reset_inst (
    .source_clk (CLOCK_50),
    .source     (hps_reset_req)
);

altera_edge_detector pulse_cold_reset (
    .clk       (CLOCK_50),
    .rst_n     (hps_fpga_reset_n),
    .signal_in (hps_reset_req[0]),
    .pulse_out (hps_cold_reset)
);
defparam pulse_cold_reset.PULSE_EXT = 6;
defparam pulse_cold_reset.EDGE_TYPE = 1;
defparam pulse_cold_reset.IGNORE_RST_WHILE_BUSY = 1;

altera_edge_detector pulse_warm_reset (
    .clk       (CLOCK_50),
    .rst_n     (hps_fpga_reset_n),
    .signal_in (hps_reset_req[1]),
    .pulse_out (hps_warm_reset)
);
defparam pulse_warm_reset.PULSE_EXT = 2;
defparam pulse_warm_reset.EDGE_TYPE = 1;
defparam pulse_warm_reset.IGNORE_RST_WHILE_BUSY = 1;
  
altera_edge_detector pulse_debug_reset (
    .clk       (CLOCK_50),
    .rst_n     (hps_fpga_reset_n),
    .signal_in (hps_reset_req[2]),
    .pulse_out (hps_debug_reset)
);
defparam pulse_debug_reset.PULSE_EXT = 32;
defparam pulse_debug_reset.EDGE_TYPE = 1;
defparam pulse_debug_reset.IGNORE_RST_WHILE_BUSY = 1;

endmodule