module mvp_interface_bg (
    input  wire        clk,
    input  wire        reset,
    input  wire        fim_de_quadro, // V-Blank

    // Interface de Leitura da FIFO
    input  wire [31:0] fifo_q,
    input  wire        fifo_empty,
    output reg         fifo_rdreq,

    // Saídas para o Motor de Background
    output reg  [8:0]  bg_scroll_x,
    output reg  [7:0]  bg_scroll_y,
    output reg  [7:0]  bg_color,
	 
	 // Saídas para o Motor de Background (ENGINE 0x1)
    output reg  [8:0]  bg_scroll_x,
    output reg  [7:0]  bg_scroll_y,
    output reg  [7:0]  bg_color,

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
    output reg              tri_enable
);

    localparam IDLE      = 2'd0;
    localparam READ_FIFO = 2'd1;
    localparam EXECUTE   = 2'd2;
    localparam SYNC      = 2'd3;

    reg [1:0]  state;
    reg [31:0] command_reg;

    wire [3:0]  cmd_engine = command_reg[30:27];
    wire [3:0]  cmd_reg    = command_reg[26:23];
    wire [22:0] cmd_value  = command_reg[22:0];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state       <= IDLE;
            fifo_rdreq  <= 1'b0;
            bg_scroll_x <= 9'd0;
            bg_scroll_y <= 8'd0;
            bg_color    <= 8'd0;
        end else begin
            fifo_rdreq <= 1'b0; // O pulso de leitura dura apenas 1 clock

            case (state)
                IDLE: begin
                    // Se a fila não está vazia, pede para ler a próxima instrução
                    if (!fifo_empty) begin
                        fifo_rdreq <= 1'b1;
                        state      <= READ_FIFO;
                    end
                end

                READ_FIFO: begin
                    // Guarda o valor que saiu da FIFO no registo de instrução (IR)
                    command_reg <= fifo_q;
                    state       <= EXECUTE;
                end

                EXECUTE: begin
                   // Roteamento baseado no identificador do motor (ENGINE)
                    case (cmd_engine)
							4'h1: begin // ENGINE 0x1: BACKGROUND
                        case (cmd_reg)
                            4'h0: begin // Atualiza Scroll X e Y
                                bg_scroll_x <= cmd_value[8:0];
                                bg_scroll_y <= cmd_value[16:9];
                            end
                            4'h1: bg_color <= cmd_value[7:0];
                        endcase
                    end
						  4'h3: begin // ENGINE 0x3: RETÂNGULO
                            case (cmd_reg)
                                4'h0: begin // SET_P0
                                    rect_x0 <= cmd_value[8:0];
                                    rect_y0 <= cmd_value[16:9];
                                end
                                4'h1: begin // SET_P1
                                    rect_x1 <= cmd_value[8:0];
                                    rect_y1 <= cmd_value[16:9];
                                end
                                4'h2: begin // SET_STYLE
                                    rect_color  <= cmd_value[7:0];
                                    rect_enable <= cmd_value[8];
                                end
                            endcase
                        end

                        4'h4: begin // ENGINE 0x4: TRIÂNGULO
                            case (cmd_reg)
                                4'h0: begin // SET_P0
                                    tri_x0 <= cmd_value[9:0];
                                    tri_y0 <= cmd_value[18:10];
                                end
                                4'h1: begin // SET_P1
                                    tri_x1 <= cmd_value[9:0];
                                    tri_y1 <= cmd_value[18:10];
                                end
                                4'h2: begin // SET_P2
                                    tri_x2 <= cmd_value[9:0];
                                    tri_y2 <= cmd_value[18:10];
                                end
                                4'h3: begin // SET_STYLE
                                    tri_color  <= cmd_value[7:0];
                                    tri_enable <= cmd_value[8];
                                end
                            endcase
                        end
                    endcase
                    // Vai para o SYNC para esperar o momento seguro de atualizar a ecrã
                    state <= SYNC;
                end

                SYNC: begin
                    // Só liberta a máquina para ler a próxima instrução no fim do quadro
                    if (fim_de_quadro) begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule