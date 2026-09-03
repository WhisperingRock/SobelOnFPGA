`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/02/2026 01:38:35 PM
// Design Name: 
// Module Name: ImageControlUnit_tb
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


module ImageControlUnit_tb();

	// ~~~~ imports ~~~~
	import tb_utils_pkg::*;


	// ~~~~ local param/allocs ~~~~
	// ~~ port ~~
	// ~ I ~
	logic 					clk; 
	logic 					reset; 
	logic 					pvalid;
	logic	[7:0] 			pixel;
	// ~ O ~
	logic 					mvalid;
	logic	[71:0] 			mat; 
	
	// ~~ const ~~
	localparam int unsigned PIXELWIDTH = 512;
	
	// ~~ test ~~
	testcase tc;
	logic	[31:0]			tnum;
	logic	[71:0]			mat_ans;
	int j; 
	int k;

	// ~~~~ instances ~~~~
	ImageControlUnit 
	#(
		.PIXELWIDTH			(512), 
		.PIXELHEIGHT		(512)
	) 
	UUT
	(
		.CLK_i				(clk), 
		.RST_i				(reset),
		.PIXEL_VALID_i		(pvalid),
		.PIXEL_i			(pixel),
		.MATRIX_VALID_o		(mvalid), 
		.MATRIX_o			(mat) 
	);
	
	// ~~~~ heartbeat (10ns) ~~~~
	always begin
		#5;
		clk	<= !clk;  
	end

	
	// ~~~~ testing ~~~~
	initial begin
	
		// ~~ class instances ~~
		tc					= new();
		
		// ~~ defaults ~~
		clk					= 1'b1;
		reset				= 1'b1;
		pvalid				= 1'b0;
		pixel				= 8'h00;
		#100;
		reset				= 1'b0;
		#10; 
		
		// ~~ TC1 ~~
		tc.new_test("3 uniform rows only"); 
		tnum				= tc.get_testnum();
			uniform_fill_LineBuffer(255, 512, pixel, pvalid); 	// row 0
			uniform_fill_LineBuffer(126, 512, pixel, pvalid); 	// row 1
			uniform_fill_LineBuffer(7, 512, pixel, pvalid);		// row 2
																
			mat_ans = 72'h07_07_07___7E_7E_7E___FF_FF_FF;
			wait(mvalid);
			
			for(int i = 0; i < PIXELWIDTH; i++) begin
				$display("|-%d", i);
				#5;
				assert(mvalid === 1'b1)					else tc.err("mvalid HIGH error");
				assert(mat === mat_ans)					else tc.err("mat error");
				#5;
			end
			
			// ~ run out of data ~ 
			#5;
			mat_ans = 72'hXX_XX_XX___07_07_07___7E_7E_7E;
			assert(mvalid === 1'b0)						else tc.err("mvalid ending error");
			assert(mat === mat_ans)						else tc.err("mat ending error");
			#5;
		tc.test_done();
		
		// ~~ TC2 ~~
		tc.new_test("3 increasing rows only"); 
		tnum				= tc.get_testnum();
		
			increment_fill_LineBuffer(0, 512, pixel, pvalid); 		// row 0
			
			for(int i = 0; i < 64; i++) begin
				increment_fill_LineBuffer(0, 8, pixel, pvalid); 	// row 1
			end
			
			increment_fill_LineBuffer(0, 256, pixel, pvalid);		// row 2
			increment_fill_LineBuffer(0, 256, pixel, pvalid);
																
			
			wait(mvalid);
			
			for(int i = 0; i < PIXELWIDTH; i++) begin
				$display("|-%d", i);
				j = i % 256; 
				k = i % 8;
				mat_ans = 72'hXX_XX_XX___07_07_07___7E_7E_7E; todo
				#5;
				assert(mvalid === 1'b1)					else tc.err("mvalid HIGH error");
				assert(mat === mat_ans)					else tc.err("mat error");
				#5;
			end
			
			// ~ run out of data ~ 
			#5;
			mat_ans = 72'hXX_XX_XX___07_07_07___7E_7E_7E;
			assert(mvalid === 1'b0)						else tc.err("mvalid ending error");
			assert(mat === mat_ans)						else tc.err("mat ending error");
			#5;
		tc.test_done();
	end
	
	
	
	
	
	// ~~~~ tasks ~~~~
	task automatic increment_fill_LineBuffer
	(
		input int unsigned 	startNum, 
		input int unsigned 	buffSize,
		ref logic [7:0] 	pxl,
		ref logic 			writeEn
	);
	
		writeEn = 1'b1; 
		for(int i = 0; i < buffSize; i++) begin
			pxl = startNum + i;
			#10;  
		end
		writeEn = 1'b0;
		pxl 	= 8'h00; 
	endtask
	
	task automatic uniform_fill_LineBuffer
	(
		input int unsigned 	num, 
		input int unsigned 	buffSize,
		ref logic [7:0] 	pxl,
		ref logic 			writeEn
	);
	
		writeEn = 1'b1; 
		for(int i = 0; i < buffSize; i++) begin
			pxl = num;
			#10;  
		end
		writeEn = 1'b0;
		pxl 	= 8'h00; 
	endtask
	
endmodule
