`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/05/2026 06:27:03 PM
// Design Name: 
// Module Name: ImageProcessTop_tb
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
`define imgFileHeaderSize 	1080 
`define imgTotalPixels		512*512

module ImageProcessTop_tb();
	
	// ~~~~ imports ~~~~
	import tb_utils_pkg::*;
	
	// ~~~~ local param/allocs ~~~~
	// ~~ port ~~
	// ~ I ~
	logic					clk;
	logic					axi_reset;
	logic					intrr;  
	// ~ O ~
	
	// ~ internal ~
	integer 				infile, outfile;
	logic	[31:0]			pixelsSent;
	logic	[31:0]			pixelsRecieved;
	
	logic					imgDataValid;
	logic	[7:0]			imgData;
	logic					outDataValid;
	logic	[7:0]			outData; 
	

	
	
	// ~~ const ~~
	localparam int unsigned PIXELWIDTH 		= 512;
	localparam int unsigned PREFILL_ROWS 	= 4;
	
	// ~~ test ~~
	testcase tc;
	logic	[31:0]			tnum;

	// ~~~~ instances ~~~~
	ImageProcessTop UUT(
	
		.axi_clk			(clk), 
		.axi_reset_n		(axi_reset),		
		.o_intr				(intrr),
		
		// sub interface (importing from DMA Controller)
		.DATA_VALID_i		(imgDataValid), 
		.DATA_i				(imgData), 
		.DATA_RDY_o			(), 						
		
		// main interface (exporting to DMA Controller)
		.DATA_RDY_i			(1'b1), 					// always ready for sim
		.DATA_o				(outData), 
		.DATA_VALID_o		(outDataValid)
	);
	
	
	// ~~~~ heartbeat (10ns) ~~~~
	always begin
		#5;
		clk	<= !clk;  
	end
	
	// ~~~~ transfer data between files ~~~~
	always @(posedge clk) begin
		
		// write output data to outfile 
		if(outDataValid) begin
			$fwrite(outfile, "%c", outData);				
			pixelsRecieved++;
		end
		
		// stop sim if we've recieved all pixels
		if(pixelsRecieved == `imgTotalPixels) begin
			$fclose(outfile);
			$stop;
		end
	end

	
	// ~~~~ testing ~~~~
	initial begin
	
		// ~~ class instances ~~
		tc = new();
		
		// ~~ defaults ~~
		clk						= 1'b0;
		axi_reset				= 1'b1;
		imgDataValid 			= 1'b0;
		pixelsSent				= 0;
		pixelsRecieved			= 0;
		#100;
		axi_reset				= 1'b0; 
		#100; 
		axi_reset				= 1'b1; 
		
		// ~~ TC1 ~~
		tc.new_test(""); 
		tnum = tc.get_testnum();
		
			// ~ file ptrs from system ~
			infile 	= $fopen("testimg1.bmp", "rb");
			outfile = $fopen("blurred_testimg1.bmp", "wb");
			
			// ~ transfer file metadata ~
			for(int i = 0; i < `imgFileHeaderSize; i++) begin
				$fscanf(infile, "%c", imgData);
				$fwrite(outfile, "%c", imgData);
			end 
			
			// ~ fill buffer enough to start exporting data ~
			// Note : Fill 4 LB s.t. we don't have to wait an entire row-cycle
			//			til we can output
			for(int i = 0; i < PREFILL_ROWS * PIXELWIDTH; i++) begin
				@(posedge clk) begin
					imgDataValid <= 1'b1;
					$fscanf(infile, "%c", imgData);
				end
			end
			
			// track pixels sent
			pixelsSent += PIXELWIDTH * PREFILL_ROWS;
			
			// disable import data temporarily
			@(posedge clk) begin imgDataValid <= 0; end
			
			// ~ Send remainin data when ready ~
			while(pixelsSent < `imgTotalPixels) begin
			
				// wait for "more data" request (which is intrr)
				@(posedge intrr) begin
				
					// send a rows of pixels
					for(int i = 0; i < PIXELWIDTH; i++) begin
						@(posedge clk) begin
							$fscanf(infile, "%c", imgData);
							imgDataValid <= 1'b1;
						end
					end
				end
					
				// disable import data temporarily
				@(posedge clk) begin
					imgDataValid <= 1'b0;
				end
				
				// track pixels sent
				pixelsSent += PIXELWIDTH;
			end
				
			// ~ send "blackout" pixel rows (b/c no matrix padding)	
			for(int j = 0; j < 2; j++) begin
				
				@(posedge intrr) begin
					for(int i = 0; i < PIXELWIDTH; i++) begin
						@(posedge clk) begin
							imgDataValid 	<= 1'b1;
							imgData			<= 8'h00; 
						end
					end
				end
				
				// disable import data
				@(posedge clk) begin
					imgDataValid <= 1'b0;
				end
			end
			
			// ~ no more reads : close read fptr
			$fclose(infile);
			
		tc.test_done();
	end
	
endmodule
