//O PROBLEMA ESTA AQUI
module PixelGen(
	input wire clk, rstn,
	input wire video_on, p_tick,
	input wire right_k, left_k,
	input wire [9:0] pixel_x, pixel_y,
	output reg [3:0] r, g, b,
	output [3:0] score
);

	localparam BACKGROUND_COLOR = 12'hFFF;

	reg [3:0] r_reg, g_reg, b_reg;
	wire [3:0] square_control;
	wire [11:0] square_rgb;
	wire square_on;
	wire refr_tick;

	// refr_tick: 1-clock tick asserted at start of v-sync
	//            i.e., when the screen is refreshed (60 Hz)
	assign refr_tick = (pixel_y == 481) && (pixel_x == 0);
	
	Square sq (.clk(clk), 
				  .rstn(rstn), 
				  .refr_tick(refr_tick),
				  .turn_r(right_k), 
				  .turn_l(left_k),
				  .y(pixel_y), 
				  .x(pixel_x), 
				  .square_rgb(square_rgb),
				  .square_on(square_on),
				  .score(score)
				  );
	
	// output
	always@*
		if(~video_on)
			{r, g, b} = 12'h000;
		else if(square_on)
			{r, g, b} = square_rgb;
		else
			{r, g, b} = BACKGROUND_COLOR;

endmodule 
