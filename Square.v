module Square (
    input wire clk, rstn,          // clk = clock principal, rstn = reset ativo em 0
    input wire refr_tick,          // pulso de atualização da tela
    input wire turn_r, turn_l,     // sinais de girar
    input wire [9:0] x, y,         // posição do pixel no VGA
    output wire [11:0] square_rgb, // cor final
    output wire square_on,        // desenhar pixel
	 output reg [3:0] score //pontuação filha da puta
	
);

    // Dimensões da tela VGA
    localparam MAX_X = 640;
    localparam MAX_Y = 480;

    // Tamanho da snake e da comida
    localparam SNAKE_SIZE = 20;
    localparam FOOD_SIZE  = 10;

    // Cores
    localparam COLOR_SNAKE = 12'hF00; // vermelho
    localparam COLOR_FOOD  = 12'h000; // preto
    localparam COLOR_WALL  = 12'h00F; // azul

    reg [3:0] step = 1;  // velocidade

    // ---------------------------------------------------------
    // DIREÇÃO
    // ---------------------------------------------------------
    reg [1:0] direction; 
    reg [9:0] snake_x, snake_y; 

    always @(posedge clk or negedge rstn) begin
        if(!rstn)
            direction <= 2'b00; 
        else begin
            if(turn_r)      direction <= direction + 1;
            else if(turn_l) direction <= direction - 1;
        end
    end

    // Flag de Reset por Vitória )
    wire game_reset = (step >= 5);

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            snake_x <= MAX_X/2 - SNAKE_SIZE/2;
            snake_y <= MAX_Y/2 - SNAKE_SIZE/2;   
        end
        else if(refr_tick) begin
            
            //Se atingir velocidade 5, reseta para o centro
            if(game_reset) begin
                snake_x <= MAX_X/2 - SNAKE_SIZE/2;
                snake_y <= MAX_Y/2 - SNAKE_SIZE/2;
            end else begin
                //Lógica de atravessar paredes
                case(direction)
                    2'b00: begin // Direita
                        // Se passar da borda direita -> vai para esquerda (0)
                        if (snake_x + SNAKE_SIZE + step >= MAX_X) 
                            snake_x <= 0;
                        else 
                            snake_x <= snake_x + step;
                    end
                    
                    2'b01: begin // Baixo
                        // Se passar da borda inferior -> vai para o topo (0)
                        if (snake_y + SNAKE_SIZE + step >= MAX_Y) 
                            snake_y <= 0;
                        else 
                            snake_y <= snake_y + step;
                    end
                    
                    2'b10: begin // Esquerda
                        // Se passar da borda esquerda (menor que o passo) -> vai para direita
                        if (snake_x < step) 
                            snake_x <= MAX_X - SNAKE_SIZE;
                        else 
                            snake_x <= snake_x - step;
                    end
                    
                    2'b11: begin // Cima
                        // Se passar da borda superior -> vai para baixo
                        if (snake_y < step) 
                            snake_y <= MAX_Y - SNAKE_SIZE;
                        else 
                            snake_y <= snake_y - step;
                    end
                endcase
            end
        end
    end

    
    // COMIDA E RESET DE VELOCIDADE E PONTUACAO
   
    reg [9:0] food_x, food_y;
    reg [15:0] lfsr;

    always @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            food_x <= 300;
            food_y <= 200;
            lfsr   <= 16'hACE1;
            step   <= 1; // Reseta velocidade no reset geral
				score <= 0; // <-- RESETA A PORRA DA PONTUAÇÂO
        end
        else if(refr_tick) begin
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[4] ^ lfsr[2] ^ lfsr[1]};

            // Reseta a comida e velocidade APENAS se velocidade >= 5
            if(game_reset) begin
                step   <= 1; // Volta velocidade para 1
                score  <= 0; // <--- NOVO: Zera pontuação quando o jogo reinicia
                food_x <= 300;
                food_y <= 200;
            end
            // Colisão com Comida
            else if(
                snake_x < food_x + FOOD_SIZE &&
                snake_x + SNAKE_SIZE > food_x &&
                snake_y < food_y + FOOD_SIZE &&
                snake_y + SNAKE_SIZE > food_y
            ) begin
                step <= step + 1; // Aumenta velocidade
					 score  <= score + 1; // <--- NOVO: Aumenta pontuação
                food_x <= (lfsr[9:0] % (MAX_X - 40)) + 20;
                food_y <= (lfsr[15:6] % (MAX_Y - 40)) + 20;
            end
        end
    end

    // DESENHO
    
    wire snake_on_pixels =
        x >= snake_x && x < snake_x + SNAKE_SIZE &&
        y >= snake_y && y < snake_y + SNAKE_SIZE;

    wire food_on_pixels =
        x >= food_x && x < food_x + FOOD_SIZE &&
        y >= food_y && y < food_y + FOOD_SIZE;

    wire wall_pixel =
        (x <= 1) || (x >= MAX_X-2) ||
        (y <= 1) || (y >= MAX_Y-2);

    assign square_on = snake_on_pixels | food_on_pixels | wall_pixel;

    assign square_rgb =
        snake_on_pixels ? COLOR_SNAKE : // Prioridade para snake (para ver ela passando pela borda)
        food_on_pixels  ? COLOR_FOOD  :
        wall_pixel      ? COLOR_WALL  :
                          12'h000;

endmodule
