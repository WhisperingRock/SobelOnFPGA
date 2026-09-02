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
	logic [7:0]				result1, result2; 
	logic					result_valid1, result_valid2;
	// ~~ consts ~~
	localparam logic signed [7:0] K_BOX [0:8] = 
	'{
		1, 1, 1,
		1, 1, 1,
		1, 1, 1
	};
	
	localparam logic signed [7:0] K_SOBEL_X [0:8] = 
	'{
		1, 0, -1,
		2, 0, -2,
		1, 0, -1
	};
	
	
	// ~~ testing ~~
	testcase tc;
	logic	[31:0]			tnum;
	
	
	// ~~~~ module instances ~~~~
	Convolution 
	#(
		.KERNEL(K_BOX), 
		.DIV(9)
	)
	UUT_BOX
	(
		.CLK_i(clk), 
		.MATRIX_i(mat),				
		.MATRIX_VALID_i(mat_valid), 
		.RESULT_o(result1), 
		.RESULT_VALID_o(result_valid1)
	);
	
	Convolution 
	#(
		.KERNEL(K_SOBEL_X), 
		.DIV(1)
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
			#5;
			assert(result1 === {8'h01})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("SobelX result error");
			assert(result_valid1 === {1'b1})			else tc.err("SobelX result_valid error");
			#5;
		tc.test_done();
		
				
		// ~~ TC2 ~~
		tc.new_test("Floor Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'h00_00_00___00_00_00___00_00_00;
			#5;
			assert(result1 === {8'h00})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("SobelX result error");
			assert(result_valid2 === {1'b1})			else tc.err("SobelX result_valid error");
			#5;
		tc.test_done();
		
		// ~~ TC3 ~~
		tc.new_test("5's Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'h05_05_05___05_05_05___05_05_05;
			#5;
			assert(result1 === {8'h05})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("SobelX result error");
			assert(result_valid2 === {1'b1})			else tc.err("SobelX result_valid error");
			#5;
		tc.test_done();
		
		// ~~ TC4 ~~
		tc.new_test("Ceiling Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'hFF_FF_FF___FF_FF_FF___FF_FF_FF;
			#5;
			assert(result1 === {8'hFF})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("SobelX result error");
			assert(result_valid2 === {1'b1})			else tc.err("SobelX result_valid error");
			#5;
		tc.test_done();
		
		// ~~ TC5 ~~
		tc.new_test("Identity Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'h01_00_00___00_01_00___00_00_01;
			#5;
			assert(result1 === {8'h00})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("SobelX result error");
			assert(result_valid2 === {1'b1})			else tc.err("SobelX result_valid error");
			#5;
		tc.test_done();
		
		// ~~ TC6 ~~
		tc.new_test("3x Identity Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'h03_00_00___00_03_00___00_00_03;
			#5;
			assert(result1 === {8'h01})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("SobelX result error");
			assert(result_valid2 === {1'b1})			else tc.err("SobelX result_valid error");
			#5;
		tc.test_done();
		
		// ~~ TC7 ~~
		tc.new_test("Increasing Mat"); 
		tnum					= tc.get_testnum();
			mat					= 72'h01_02_03___04_05_06___07_08_09; // mat[0] = 09 
			#5;
			assert(result1 === {8'h05})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h08})					else tc.err("SobelX result error");				
			assert(result_valid2 === {1'b1})			else tc.err("SobelX result_valid error");
			#5;
		tc.test_done();
		
		// ~~ TC8 ~~
		tc.new_test("Increasing Mat Reversed"); 
		tnum					= tc.get_testnum();
			mat					= 72'h09_08_07___06_05_04___03_02_01;	// mat[0] = 01
			#5;
			assert(result1 === {8'h05})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'h00})					else tc.err("SobelX result error");				// should be -8 but floor clip
			assert(result_valid2 === {1'b1})			else tc.err("SobelX result_valid error");
			#5;
		tc.test_done();
		
		// ~~ TC9 ~~
		tc.new_test("Single-Centered 9"); 
		tnum					= tc.get_testnum();
			mat					= 72'h00_00_00___00_00_09___00_00_00;
			#5;
			assert(result1 === {8'h01})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b1})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'd18})					else tc.err("SobelX result error");
			assert(result_valid2 === {1'b1})			else tc.err("SobelX result_valid error");
			#5;
		tc.test_done();
		
		// ~~ TC10 ~~
		tc.new_test("New data not ready"); 
		tnum					= tc.get_testnum();
			mat					= 72'h00_00_00___00_09_00___00_00_00;
			mat_valid	= 1'b0;
			#5;
			assert(result1 === {8'h01})					else tc.err("BoxBlur result error");
			assert(result_valid1 === {1'b0})			else tc.err("BoxBlur result_valid error");
			assert(result2 === {8'd18})					else tc.err("SobelX result error");
			assert(result_valid2 === {1'b0})			else tc.err("SobelX result_valid error");
			#5;
		tc.test_done();
	end
endmodule
