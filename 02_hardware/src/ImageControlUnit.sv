`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/01/2026 09:44:53 AM
// Design Name: 
// Module Name: ImageControlUnit
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


module ImageControlUnit
#(parameter	int unsigned PIXELWIDTH = 512,
			int unsigned PIXELHEIGHT = 512)
(
	input logic 			CLK_i, 
	input logic 			RST_i,
	input logic 			PIXEL_VALID_i,
	input logic 	[7:0] 	PIXEL_i,
	output logic 			MATRIX_VALID_o, 
	output logic	[71:0] 	MATRIX_o,
	output logic			INTRR_o 
);


	// ~~~~ local wires/param/alloc/const ~~~~
	typedef enum logic {IDLE, RD_BUFFER}	read_state;
	read_state rdState;
	
	localparam logic [11:0]	pixelsInThreeRows = PIXELWIDTH * 3;
	
	// ~~ input pixel vars ~~
	logic			[8:0]	pixelCounter; 		// index for pixel in row (designed to rollover)
	logic			[1:0]	currWrLineBuff; 	// indicates how many rows(0-3) we've filled w/ pixels (designed to rollover)
	logic			[3:0]	validInput;			// dictates which LB gets to read

	
	// ~~ output pixel vars ~~
	logic			[8:0]	windowCounter;		// kernel position on the width-axis
	logic			[1:0]	currRdLineBuff;		// kernel row grouping selector
	logic			[3:0]	validOutput; 		// pairs w/ above to enable specific LBs to output their 3 pixels 		
	logic			[11:0]	currBufferedPixels;	// number of pixels currently in LBs
	
	
	logic			[23:0]	lb0_o;
	logic			[23:0]	lb1_o;
	logic			[23:0]	lb2_o;	
	logic			[23:0]	lb3_o;	
	
	 
	// ~~~~ instances ~~~~
	LineBuffer #(PIXELWIDTH,PIXELHEIGHT) lb00
	( 
		.CLK_i			(CLK_i), 
		.RST_i			(RST_i), 
		.DIN_i			(PIXEL_i),
		.DIN_AVAIL_i	(validInput[0]),	
		.DOUT_AVAIL_i	(validOutput[0]),	
		.DOUT_o			(lb0_o)
	);
	
	LineBuffer #(PIXELWIDTH,PIXELHEIGHT) lb01
	( 
		.CLK_i			(CLK_i), 
		.RST_i			(RST_i), 
		.DIN_i			(PIXEL_i),
		.DIN_AVAIL_i	(validInput[1]),	
		.DOUT_AVAIL_i	(validOutput[1]),	
		.DOUT_o			(lb1_o)
	);
    
   	LineBuffer #(PIXELWIDTH,PIXELHEIGHT) lb02
	( 
		.CLK_i			(CLK_i), 
		.RST_i			(RST_i), 
		.DIN_i			(PIXEL_i),
		.DIN_AVAIL_i	(validInput[2]),	
		.DOUT_AVAIL_i	(validOutput[2]),	
		.DOUT_o			(lb2_o)
	);
    
    LineBuffer #(PIXELWIDTH,PIXELHEIGHT) lb03
	( 
		.CLK_i			(CLK_i), 
		.RST_i			(RST_i), 
		.DIN_i			(PIXEL_i),
		.DIN_AVAIL_i	(validInput[3]),	
		.DOUT_AVAIL_i	(validOutput[3]),	
		.DOUT_o			(lb3_o)
	);
	
	
	// ~~~~ async logic ~~~~
	assign validInput 		= {3'b000, PIXEL_VALID_i} << currWrLineBuff;
	
	always_comb begin
		case(currRdLineBuff) 
			2'b00 : begin 
				MATRIX_o 	= {lb2_o, lb1_o, lb0_o};
				validOutput = {1'b0, {3{MATRIX_VALID_o}}};
			end
				
			2'b01 : begin 
				MATRIX_o 	= {lb3_o, lb2_o, lb1_o};
				validOutput = {{3{MATRIX_VALID_o}}, 1'b0};
			end
			
			2'b10 : begin 
				MATRIX_o 	= {lb0_o, lb3_o, lb2_o};
				validOutput = {{2{MATRIX_VALID_o}}, 1'b0, MATRIX_VALID_o};
			end
			
			2'b11 : begin 
				MATRIX_o 	= {lb1_o, lb0_o, lb3_o};
				validOutput = {MATRIX_VALID_o, 1'b0, {2{MATRIX_VALID_o}}};
			end
			
			default : begin
				MATRIX_o	= 24'd0;
				validOutput = 4'd0;
			end
		endcase
	end

	
	
	// ~~~~ sync logic ~~~~
	always_ff @(posedge CLK_i) begin
	
		// ~~ priority 0 : reset clear ptrs and counters ~~
		if(RST_i == 1'b1) begin 
			pixelCounter 		<= 9'd0;
			windowCounter		<= 9'd0;
			currWrLineBuff		<= 2'd0;
			currRdLineBuff		<= 2'd0;
			currBufferedPixels	<= 12'd0;
			
			rdState				<= IDLE;
			MATRIX_VALID_o 		<= 1'b0;
			INTRR_o				<= 1'b0;
		end
		
		// ~~ priority 1 : read or write data ~~
		else begin
		
			// ~ process incoming pixel data ~
			if(PIXEL_VALID_i == 1'b1) begin 
				
				// move input pixel ptr to fill next spot
				pixelCounter 			<= pixelCounter + 1;		
				
				// max'd pixel counter rolls over and starts new row
				if(pixelCounter == (PIXELWIDTH-1)) begin
					currWrLineBuff 		<= currWrLineBuff + 2'b01; 
				end
				
				// buffer gains a pixel if only "deposit" occurs
				if(!MATRIX_VALID_o) begin currBufferedPixels	<= currBufferedPixels + 1; end
			end
			
			
			// ~ process outgoing window data ~
			//if(writeOutEn) begin
			if(MATRIX_VALID_o) begin
				
				// move output window ptr to next spot
				windowCounter 			<= windowCounter + 1;
				
				// max'd window counter rolls over and starts new row
				if(windowCounter == (PIXELWIDTH-1)) begin
					currRdLineBuff 		<= currRdLineBuff + 2'b01; 
				end
				
				// buffer loses a pixel if only "withdraw" occurs
				if(PIXEL_VALID_i == 1'b0) begin currBufferedPixels	<= currBufferedPixels - 1; end
			end
			
		end
	
		// ~~ FSM logic ~~
		case(rdState)
		
			// ~ IDLE : dont output til buffer enough rows for a full kernel pass ~
			IDLE : begin	
				if(currBufferedPixels >= pixelsInThreeRows) begin 
					rdState 		<= RD_BUFFER;
					MATRIX_VALID_o 	<= 1'b1;
					INTRR_o			<= 1'b0;
				end
			end
			
			// ~ RD_BUFFER : output windows til the row end is reached ~
			RD_BUFFER : begin
				if(windowCounter == PIXELWIDTH-1) begin 
					rdState 		<= IDLE;
					MATRIX_VALID_o 	<= 1'b0;
					INTRR_o			<= 1'b1;
				end
			end
		endcase
	end 
	
endmodule
