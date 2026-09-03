`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2026 09:16:29 AM
// Design Name: 
// Module Name: LineBuffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 	Gathers a single row (512) of pixel data, one pixel at a time, 
//					and outputs a single row (3) for a 3x3 kernel. The input_avail
//					signal indicates the next pixel is ready to be read and the 
//					output_avail indicates the downstream module is ready for a 
//					kernel window slide. 
//
//					How to use : 
//						- Fill the row largely unrestricted but prevent rollover until ready for new row
//						- Only slide kernel row when sobel operation has finished that that position
//						- reset can also be used rather than rollover to start a new row/window 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module LineBuffer
#(parameter	int unsigned PWIDTH 	= 512,
			int unsigned PHEIGHT 	= 512
)
( 
	input logic				CLK_i, 
	input logic				RST_i, 
	input logic		[7:0]	DIN_i,
	input logic				DIN_AVAIL_i,	// input data ready to be read/sent to this mod
	input logic				DOUT_AVAIL_i,	// output data ready to be read/recieved from this mod
	output logic	[23:0]	DOUT_o 			// packing 3 byte/pixels into a single word. Not using packed array to reduce dimension
);

	// ~~~~ local params/alloc ~~~~
	logic [7:0] line [0:PWIDTH-1];			// line contains 512 (bytes) pixels
	logic [8:0]	writePtr; 					// 9 bits covers 512 pixel width (2^9)
	logic [8:0] readPtr;
	
	
	// ~~~~ sync logic ~~~~
	always_ff @(posedge CLK_i)
	begin
	
		// ~~ priority 0 : reset r/w ptrs to zero place ~~
		if(RST_i) begin 
			writePtr 	<= 0;
			readPtr		<= 0; 
		end
		
		// ~~  priority 1 : read/write ~~
		else begin
		
			// ~ Store pixel i in row/line when available ~
			if(DIN_AVAIL_i == 1'b1) begin
				line[writePtr]	<= DIN_i;
				writePtr		<= writePtr + 1'b1;
			end
			
			// ~ Slide the kernel window (this row in particular) right 1 when prompted ~
			if(DOUT_AVAIL_i == 1'b1) begin 
				readPtr 		<= readPtr + 1'b1; 
			end
		end
					
	end
	
	// ~~~~ comb logic ~~~~
	assign DOUT_o = {line[readPtr], line[readPtr+1'd1], line[readPtr+1'd2]};	// pack 3 pixels for kernel row
	
endmodule
