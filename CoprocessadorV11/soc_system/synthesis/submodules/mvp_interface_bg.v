module mvp_interface_bg (
    input  wire        clk,
    input  wire        reset,
    input  wire        fim_de_quadro, // V-Blank

    // Interface de Leitura da FIFO
    input  wire [31:0] fifo_q,
    input  wire        fifo_empty,
    output reg         fifo_rdreq,
    
    // Saídas para o Motor de Background (ENGINE 0x1)
    output reg  [8:0]  bg_scroll_x,
    output reg  [7:0]  bg_scroll_y,
    output reg  [7:0]  bg_color,
    
    // Saídas OAM (Sprites)
    output reg [4:0]  spr_id,
    output reg [8:0]  spr_x,
    output reg [7:0]  spr_y,
    output reg [7:0]  spr_tile,
    output reg        spr_enable,
    output reg        spr_hflip,
    output reg        spr_vflip,
    output reg        spr_wr_pos,
    output reg        spr_wr_tile,
    output reg        spr_wr_flags,

    // Saídas para o Motor de Retângulos (ENGINE 0x3)
    output reg [8:0]        rect_x0,
    output reg [7:0]        rect_y0,
    output reg [8:0]        rect_x1,
    output reg [7:0]        rect_y1,
    output reg [7:0]        rect_color,
    output reg              rect_enable,

    // Saídas para o Motor de Triângulos (ENGINE 0x4)
    output reg signed [9:0] tri_x0,
    output reg signed [8:0] tri_y0,
    output reg signed [9:0] tri_x1,
    output reg signed [8:0] tri_y1,
    output reg signed [9:0] tri_x2,
    output reg signed [8:0] tri_y2,
    output reg [7:0]        tri_color,
    output reg              tri_enable,
	 
	 //Saídas para Paleta Programavel (Engine 0x5)
	 output reg paleta_wren,
	 output reg[7:0] paleta_wr_addr,
	 output reg[23:0] paleta_wr_data
);

    localparam IDLE      = 3'd0;
    localparam WAIT_FIFO = 3'd1;
    localparam READ_FIFO = 3'd2;
    localparam EXECUTE   = 3'd3;
    localparam HOLD      = 3'd4;

    reg [3:0]  state;
    reg [31:0] command_reg;

    reg [8:0]        rect_x0_s, rect_x1_s;
    reg [7:0]        rect_y0_s, rect_y1_s;
    reg signed [9:0] tri_x0_s, tri_x1_s, tri_x2_s;
    reg signed [8:0] tri_y0_s, tri_y1_s, tri_y2_s;
	 
	 reg [7:0] paleta_addr_s;
    reg [7:0] paleta_red_s;

    wire [3:0]  cmd_engine = command_reg[30:27];
    wire [3:0]  cmd_reg    = command_reg[26:23];
    wire [22:0] cmd_value  = command_reg[22:0];

    wire [8:0] scroll_x_in = cmd_value[8:0];
    wire [7:0] scroll_y_in = cmd_value[16:9];
    wire [8:0] scroll_x_ok = (scroll_x_in >= 9'd320) ? (scroll_x_in - 9'd320) : scroll_x_in;
    wire [7:0] scroll_y_ok = (scroll_y_in >= 8'd240) ? (scroll_y_in - 8'd240) : scroll_y_in;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE; 
            fifo_rdreq <= 1'b0;
            rect_enable <= 1'b0; 
            tri_enable <= 1'b0;
            spr_wr_pos <= 1'b0; 
            spr_wr_tile <= 1'b0; 
            spr_wr_flags <= 1'b0;
        end else begin
            fifo_rdreq <= 1'b0;

            case (state)
               IDLE: begin
                    spr_wr_pos <= 1'b0; 
                    spr_wr_tile <= 1'b0; 
                    spr_wr_flags <= 1'b0;
                    paleta_wren <= 1'b0;
                    
                    if (!fifo_empty) begin 
                        fifo_rdreq <= 1'b1; 
                        state <= WAIT_FIFO; 
                    end
                end
                
                WAIT_FIFO: begin
                    state <= READ_FIFO; 
                end
                
                READ_FIFO: begin 
                    command_reg <= fifo_q; 
                    state <= EXECUTE; 
                end
                
                EXECUTE: begin
                    case (cmd_engine)
                        4'h1: begin 
                            case (cmd_reg) // BACKGROUND
                                4'h0: begin bg_scroll_x <= scroll_x_ok; bg_scroll_y <= scroll_y_ok; end
                                4'h1: bg_color <= cmd_value[7:0];
                            endcase
                        end
                              
                        4'h2: begin
                            case (cmd_reg) // SPRITES
                                4'h0: spr_id <= cmd_value[4:0];
                                4'h1: begin spr_x <= cmd_value[8:0]; spr_y <= cmd_value[16:9]; spr_wr_pos <= 1'b1; end
                                4'h2: begin spr_tile <= cmd_value[7:0]; spr_wr_tile <= 1'b1; end
                                4'h3: begin spr_enable <= cmd_value[0]; spr_hflip <= cmd_value[1]; spr_vflip <= cmd_value[2]; spr_wr_flags <= 1'b1; end
                            endcase
                        end

                        4'h3: begin
                            case (cmd_reg) // RETÂNGULO
                                4'h0: begin rect_x0_s <= cmd_value[8:0]; rect_y0_s <= cmd_value[16:9]; end
                                4'h1: begin rect_x1_s <= cmd_value[8:0]; rect_y1_s <= cmd_value[16:9]; end
                                4'h2: begin 
                                    rect_color  <= cmd_value[7:0]; 
                                    rect_enable <= cmd_value[8];
                                    rect_x0 <= rect_x0_s; rect_y0 <= rect_y0_s;
                                    rect_x1 <= rect_x1_s; rect_y1 <= rect_y1_s;
                                end
                            endcase
                        end

                        4'h4: begin
                            case (cmd_reg) // TRIÂNGULO
                                4'h0: begin tri_x0_s <= cmd_value[9:0]; tri_y0_s <= cmd_value[18:10]; end
                                4'h1: begin tri_x1_s <= cmd_value[9:0]; tri_y1_s <= cmd_value[18:10]; end
                                4'h2: begin tri_x2_s <= cmd_value[9:0]; tri_y2_s <= cmd_value[18:10]; end
                                4'h3: begin 
                                    tri_color  <= cmd_value[7:0]; 
                                    tri_enable <= cmd_value[8];
                                    tri_x0 <= tri_x0_s; tri_y0 <= tri_y0_s;
                                    tri_x1 <= tri_x1_s; tri_y1 <= tri_y1_s;
                                    tri_x2 <= tri_x2_s; tri_y2 <= tri_y2_s;
                                end
                            endcase
                        end
								// ENGINE 0x5: PALETA PROGRAMÁVEL (LUT)
                        4'h5: begin
                            case (cmd_reg) 
                                // Comando 0: Guarda Endereço e Red
                                4'h0: begin 
                                    paleta_addr_s <= cmd_value[15:8]; 
                                    paleta_red_s  <= cmd_value[7:0]; 
                                end
                                // Comando 1: Recebe Green/Blue, junta e grava
                                4'h1: begin 
                                    paleta_wr_addr <= paleta_addr_s;
                                    paleta_wr_data <= {paleta_red_s, cmd_value[15:8], cmd_value[7:0]};
                                    paleta_wren    <= 1'b1;
                                end
                            endcase
                        end
                    endcase
                    
                    state <= HOLD;
                end
                
                HOLD: begin 
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule