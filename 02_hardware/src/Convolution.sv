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
	parameter logic signed [7:0] 	KERNEL [0:8] = 
	'{
		8'd1, 8'd1, 8'd1,
		8'd1, 8'd1, 8'd1,
		8'd1, 8'd1, 8'd1		
	},
	
	parameter logic [15:0]		 	DIV = 16'd9
)
(
	input logic				CLK_i, 
	input logic		[71:0]	MATRIX_i,				// 3x3 = 9 pixels, 8 bits each
	input logic				MATRIX_VALID_i, 		// input ready for import
	output logic	[7:0]	RESULT_o, 					
	output logic			RESULT_VALID_o			// result ready for export
);

	// ~~~~ local param/alloc/const ~~~~
	logic signed 		[23:0] 	sum_comb;
	localparam signed	[8:0] 	PIXELMIN = 0;
	localparam signed 	[8:0]	PIXELMAX = 255; 

	
	// ~~~~ async logic ~~~~
	// Note : will perform only once til new data flows in
	always_comb begin
		
		// ~~ sanitize between kernel operations ~~
		sum_comb = '0;
		
		// ~~ compute an entire kernel sum per CLK ~~
		for(int i = 0; i < 9; i++) begin
			sum_comb += KERNEL[i] * $signed({1'b0, MATRIX_i[i*8 +: 8]});		// idx part-selection 
																				//     [start_index +: width]
																				// extending to signed
		end
	end
	
	
	// ~~~~ sync logic ~~~~
	always_ff @(posedge CLK_i) begin
	
		RESULT_VALID_o <= MATRIX_VALID_i;										// result likely ready if input is 
		
		if(MATRIX_VALID_i) begin
			if(sum_comb < PIXELMIN) 		begin 	RESULT_o <= 8'd0; 			end	// floor clip 
			else if(sum_comb > PIXELMAX) 	begin	RESULT_o <= PIXELMAX; 		end	// or ceil clip
			else 							begin	RESULT_o <= sum_comb / DIV;	end	// or apply gain factor
		end
	end


endmodule
