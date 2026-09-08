`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/01/2026 08:47:08 AM
// Design Name: 
// Module Name: Convolution_tb
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


module Convolution_tb();

	// ~~~~ imports ~~~~
	import tb_utils_pkg::*;


	// ~~~~ local param/allocs ~~~~
	// ~~ ports ~~
	logic					clk;
	logic [71:0]			mat;
	logic					mat_valid;
	logic [7:0]				result1, 		result2; 
	logic					result_valid1,	result_valid2;
	// ~~ consts ~~
	// ~~ testing ~~
	testcase tc;
	logic	[31:0]			tnum;
	
	
	// ~~~~ module instances ~~~~
	// ~~ box blur ~~
	Convolution 
	#(
		.FILTER(1'b0)
	)
	UUT_BOX
	(
		.CLK_i(clk), 
		.MATRIX_i(mat),				
		.MATRIX_VALID_i(mat_valid), 
		.RESULT_o(result1), 
		.RESULT_VALID_o(result_valid1)
	);
	// ~~ sobel ~~
	Convolution 
	#(
		.FILTER(1'b1)
	)
	UUT_SOBEL_X
	(
		.CLK_i(clk), 
		.MATRIX_i(mat),				
		.MATRIX_VALID_i(mat_valid), 
		.RESULT_o(result2), 
		.RESULT_VALID_o(result_valid2)
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
		mat					= 72'h00_00_00___00_00_00___00_00_00;
		mat_valid			= 1'b1;
		#100; 
		
		
		// ~~ TC1 ~~
		tc.new_test("1's Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'h01_01_01___01_01_01___01_01_01;
			#11;
			assert(result1 			=== {8'h01})		else tc.err("BoxBlur result error");
			assert(result_valid1 	=== {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 			=== {8'h00})		else tc.err("Sobel result error");
			assert(result_valid1 	=== {1'b1})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
				
		// ~~ TC2 ~~
		tc.new_test("Floor Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'h00_00_00___00_00_00___00_00_00;
			#11;
			assert(result1 === {8'h00})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("Sobel result error");
			assert(result_valid2 === {1'b1})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
		// ~~ TC3 ~~
		tc.new_test("5's Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'h05_05_05___05_05_05___05_05_05;
			#11;
			assert(result1 === {8'h05})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("Sobel result error");
			assert(result_valid2 === {1'b1})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
		// ~~ TC4 ~~
		tc.new_test("Ceiling Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'hFF_FF_FF___FF_FF_FF___FF_FF_FF;
			#11;
			assert(result1 === {8'hFF})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("Sobel result error");
			assert(result_valid2 === {1'b1})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
		// ~~ TC5 ~~
		tc.new_test("Identity Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'h01_00_00___00_01_00___00_00_01;
			#11;
			assert(result1 === {8'h00})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("Sobel result error");
			assert(result_valid2 === {1'b1})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
		// ~~ TC6 ~~
		tc.new_test("3x Identity Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'h03_00_00___00_03_00___00_00_03;
			#11;
			assert(result1 === {8'h01})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("Sobel result error");
			assert(result_valid2 === {1'b1})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
		// ~~ TC7 ~~
		tc.new_test("Increasing Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'h01_02_03___04_05_06___07_08_09; // mat[0] = 09 
			#11;
			assert(result1 === {8'h05})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("Sobel result error");				
			assert(result_valid2 === {1'b1})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
		// ~~ TC8 ~~
		tc.new_test("Increasing Mat Reversed"); 
		tnum					= tc.get_testnum();
			mat					= 72'h09_08_07___06_05_04___03_02_01;	// mat[0] = 01
			#11;
			assert(result1 === {8'h05})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("Sobel result error");				// should be -8 but floor clip
			assert(result_valid2 === {1'b1})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
		// ~~ TC9 ~~
		tc.new_test("Single-Centered 9"); 
		tnum					= tc.get_testnum();
			mat					= 72'h00_00_00___00_00_09___00_00_00;
			#11;
			assert(result1 === {8'h01})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'd00})					else tc.err("Sobel result error");
			assert(result_valid2 === {1'b1})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
		// ~~ TC10 ~~
		tc.new_test("New data not ready"); 
		tnum					= tc.get_testnum();
			mat					= 72'h00_00_00___00_09_00___00_00_00;
			mat_valid	= 1'b0;
			#11;
			assert(result1 === {8'h01})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b0})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'd00})					else tc.err("Sobel result error");
			assert(result_valid2 === {1'b0})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
		// ~~ TC11 ~~
		tc.new_test("Medium Range Numbers"); 
		tnum					= tc.get_testnum();
			mat					= 72'h81_81_81___81_81_81___81_81_81;
			mat_valid	= 1'b1;
			#11;
			assert(result1 === {8'h81})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'd00})					else tc.err("Sobel result error");
			assert(result_valid2 === {1'b1})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
		// ~~ TC12 ~~
		tc.new_test("Sobel Numbers"); 
		tnum					= tc.get_testnum();
			mat					= 72'h00_00_81___00_00_81___81_81_81;
			mat_valid	= 1'b1;
			#11;
			assert(result1 === {8'd71})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === 8'hFF)					else tc.err("Sobel result error");
			assert(result_valid2 === {1'b1})			else tc.err("Sobel result_valid error");
			#9;
		tc.test_done();
		
	end
endmodule
