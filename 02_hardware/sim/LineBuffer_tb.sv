`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2026 10:33:22 AM
// Design Name: 
// Module Name: LineBuffer_tb
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


module LineBuffer_tb();

	// ~~~~ imports ~~~~
	import tb_utils_pkg::*;

	// ~~~~ local param/allocs ~~~~
	// ~~ ports ~~
	logic					clk;
	logic					reset;
	logic	[7:0]			din;
	logic 					din_avail;
	logic					dout_avail; 
	logic	[23:0]			dout;
	// ~~ consts ~~
	localparam int unsigned PWIDTH 	= 12;	// smaller for ease of testing
	localparam int unsigned	PHEIGHT = 12;
	// ~~ testing ~~
	testcase tc;
	logic	[31:0]			tnum;
	bit [11:0][7:0]			arr; 
	
	
	// ~~~~ module instances ~~~~
	LineBuffer #(.PIXELWIDTH(PWIDTH), .PIXELHEIGHT(PHEIGHT)) UUT
	( 
		.CLK_i(clk), 				// 1'b	
		.RST_i(reset), 				// 1'b
		.DIN_i(din),				// 8'b
		.DIN_AVAIL_i(din_avail),	// 1'b
		.DOUT_AVAIL_i(dout_avail),	// 1'b
		.DOUT_o(dout) 				// 24'b
	);
	
	// ~~~~ heartbeat (10ns) ~~~~
	always begin
		#5;
		clk	<= !clk;  
	end
	
	// ~~~~ testing ~~~~
	initial begin
	
		// ~~ class instances ~~
		tc				= new();
		
		// ~~ defaults ~~
		clk				= 1'b0;
		reset			= 1'b1;	
		din				= 8'h00; 
		din_avail		= 1'b0;
		dout_avail		= 1'b0;
		#100; 
		reset			= 1'b0;
		#5;
		
		
		// ~~ TC1 ~~
		tc.new_test("Filling Line"); 
		tnum			= tc.get_testnum();
		
			arr			= 96'h12_11_10_09_08_07_06_05_04_03_02_01;
			din_avail	= 1'b1; 
			
			tc.print_subtest("2/3 of writes");
			din 		= arr[0];
			#5;
			assert(dout === {arr[0], 16'hXX_XX})			else tc.err("DOUT error");
			#5;
			
			din 		= arr[1];
			#5;
			assert(dout === {arr[0], arr[1], 8'hXX})		else tc.err("DOUT error");
			#5;
			
			tc.print_subtest("Disable write");
			din_avail	= 1'b0;
			din 		= arr[2];
			#5;
			assert(dout === {arr[0], arr[1], 8'hXX})		else tc.err("DOUT error");
			#5;
				
			tc.print_subtest("Re-enable write for 3/3 writes");
			din_avail	= 1'b1;		
			#5;
			assert(dout === {arr[0], arr[1], arr[2]})		else tc.err("DOUT error");
			#5;
			
			tc.print_subtest("Full buffer prevents new data");
			din 		= arr[3];
			#5;
			assert(dout === {arr[0], arr[1], arr[2]})		else tc.err("DOUT error");
			#5;
		tc.test_done();
		
			
		// ~~ TC2 ~~
		tc.new_test("Reset ptrs"); 
		tnum			= tc.get_testnum();
			reset			= 1'b1;
			din_avail		= 1'b0;
			dout_avail		= 1'b0;
			#10;
			
			// overwrite first 3 spots with zeros
			reset			= 1'b0;
			din_avail		= 1'b1;
			din				= 8'h00;
			#30;
			assert(dout === {24'h00_00_00})					else tc.err("DOUT error");
		tc.test_done();	
		
		// ~~ TC3 ~~
		tc.new_test("Fill to top, then empty"); 
		tnum			= tc.get_testnum();
			// place writePtr back to zero
			reset			= 1'b1; 
			#10;
			reset			= 1'b0;
			din_avail		= 1'b1;
			dout_avail		= 1'b0;
			
			// fill
			din			= arr[0];
			#10;
			din			= arr[1];
			#10;
			din			= arr[2];
			#10;

			// fill
			for(int i = 3; i < 12; i++) begin
				din			= arr[i];
				#5;
				assert(dout === {arr[0], arr[1], arr[2]})	else tc.err("DOUT error");
				#5;
			end
			
			// empty
			din_avail		= 1'b0;
			dout_avail		= 1'b1;
			for(int i = 3; i < 12; i++) begin
				#5;
				assert(dout === {arr[i-2], arr[i-1], arr[i]})	else tc.err("DOUT error");
				#5;
			end
			
			#5;
			assert(dout === {arr[10], arr[11], 8'hXX})			else tc.err("DOUT error");
			#10;
			assert(dout === {arr[11], 16'hXX_XX})				else tc.err("DOUT error");
			#10;
			assert(dout === {24'hXX_XX_XX})						else tc.err("DOUT error");
			#5;
			
		tc.test_done();	
		
		
		// ~~ TC4 ~~
		tc.new_test("R/W synch'd rollover"); 
		tnum			= tc.get_testnum();
		
			//todo
			
			
		tc.test_done();	

	
	
	end
	
	
endmodule
