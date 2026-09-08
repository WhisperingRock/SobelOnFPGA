`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2026 07:34:11 PM
// Design Name: 
// Module Name: Convolution
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 						Input Mat LSB is element zero!!!!
//////////////////////////////////////////////////////////////////////////////////


module Convolution
#(
	parameter logic			FILTER = 0
)
(
	input logic						CLK_i, 
	input logic		[71:0]			MATRIX_i,				// 3x3 = 9 pixels, 8 bits each
	input logic						MATRIX_VALID_i, 		// input ready for import
	output logic	[7:0]			RESULT_o, 					
	output logic					RESULT_VALID_o			// result ready for export
);

	// ~~~~ local param/alloc/const ~~~~

	localparam signed	[8:0] 		pixelmin = 9'b0_0000_0000;
	localparam signed 	[8:0]		pixelmax = 9'b0_1111_1111;

	// box blurr
	logic signed 		[23:0] 		sum_comb;
	logic signed 		[23:0] 		temp_result;
	logic 				[15:0]		div;
	assign 							div = (FILTER == 0) ? 16'd9 : 16'd1; 
	
	localparam logic signed [7:0] 	K_BOX [0:8] = 
	'{
		8'd1, 8'd1, 8'd1,
		8'd1, 8'd1, 8'd1,
		8'd1, 8'd1, 8'd1		
	};
	
	// sobel
	logic signed 		[23:0] 		sum_x, sum_y;
	logic signed 		[23:0] 		tmp_x, tmp_y;
	localparam signed	[23:0]		sobel_thresh = 4000;
	localparam logic signed [7:0] 	K_SOBEL_X [0:8] = 
	'{
		1, 0, -1,
		2, 0, -2,
		1, 0, -1
	};
	localparam logic signed [7:0] 	K_SOBEL_Y [0:8] = 
	'{
		 1,  2,  1,
		 0,  0,  0,
		-1, -2, -1
	}; 


	
	// ~~~~ async logic ~~~~
	// Note : will perform only once til new data flows in
	always_comb begin
		
		// ~~ sanitize between kernel operations ~~
		sum_comb 	= '0;
		sum_x		= '0;
		sum_y		= '0;
		
		// ~~ box blurr filter ~~
		if(FILTER == 0) begin
			// ~~ compute kernel sum per CLK ~~
			for(int i = 0; i < 9; i++) begin
				sum_comb += K_BOX[i] * $signed({1'b0, MATRIX_i[i*8 +: 8]});																						
			end
		end
		
		// ~~ sobel filter ~~
		else begin
			// ~~ compute kernel sum per CLK ~~
			for(int i = 0; i < 9; i++) begin
				sum_x += K_SOBEL_X[i] * $signed({1'b0, MATRIX_i[i*8 +: 8]});
				sum_y += K_SOBEL_Y[i] * $signed({1'b0, MATRIX_i[i*8 +: 8]});																						
			end
		end
		
		
	end
	
	
	// ~~~~ sync logic ~~~~
	always_ff @(posedge CLK_i) begin
	
		RESULT_VALID_o <= MATRIX_VALID_i;										// result likely ready if input is 
		
		if(MATRIX_VALID_i) begin
		
			// box filter
			if(FILTER == 0) begin
				temp_result <= sum_comb / div;
				
				// pixel clipping
				if(temp_result < pixelmin) 			begin 	RESULT_o <= 8'd0; 			end	// floor clip 
				else if(temp_result > pixelmax) 	begin	RESULT_o <= pixelmax; 		end	// or ceil clip
				else 								begin	RESULT_o <= temp_result;	end	// or apply gain factor
			end
			
			// sobel filter
			else begin
						
				tmp_x <= $signed(sum_x) * $signed(sum_x); // Gx ^ 2
				tmp_y <= $signed(sum_y) * $signed(sum_y); // Gy ^ 2
				temp_result <= $signed(tmp_x) + $signed(tmp_y); // Gx^2 + Gy^2
				
				// Avoid square root and use threshold instead 
				if(temp_result < sobel_thresh)	begin 	RESULT_o <= pixelmin; 	end	 
				else  							begin	RESULT_o <= pixelmax;	end
				
			end
		end
	end


endmodule
