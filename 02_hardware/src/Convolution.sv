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
// 
//////////////////////////////////////////////////////////////////////////////////


module Convolution(
	input logic				CLK_i, 
	input logic		[71:0]	PIXEL_DATA_i,				// 3x3 = 9 pixels, 8 bits each
	input logic				PIXEL_DATA_VALID_i, 		// indicates incoming data is ready to be read
	output logic	[7:0]	CONVOLVED_DATA_o, 			// result
	output logic			CONVOLVED_DATA_VALID_o		// indicates convolution has finished
);

	// ~~~~ local param/alloc/const ~~~~
	localparam logic signed [7:0] 	KERNEL [0:8] = 
	'{
		8'd1, 8'd1, 8'd1,
		8'd1, 8'd1, 8'd1,
		8'd1, 8'd1, 8'd1		
	};
	
	localparam logic [15:0]		 	div = 16'd9;		// 9 for a DC bias/gain on a 3x3 kernel
	logic [19:0] 					sum_comb; 

	
	// ~~~~ async logic ~~~~
	// Note : will perform only once til new data flows in
	always_comb begin
		
		// ~~ sanitize between kernel operations ~~
		sum_comb = 16'd0;
		
		// ~~ compute an entire kernel sum per CLK ~~
		for(int i = 0; i < 9; i++) begin
			sum_comb += KERNEL[i] * PIXEL_DATA_i[i*8 +: 8];		// Using indexed part-selection [start_index +: width]
		end
	end
	
	
	// ~~~~ sync logic ~~~~
	always_ff @(posedge CLK_i) begin
	
		CONVOLVED_DATA_VALID_o <= PIXEL_DATA_VALID_i;			// if input data is valid on this cycle, then output data is
																// likely also ready
		
		if(PIXEL_DATA_VALID_i) begin
			CONVOLVED_DATA_o <= sum_comb / div; 				// integer rounding into average value
		end
	end


endmodule
