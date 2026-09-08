`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/04/2026 11:13:15 AM
// Design Name: 
// Module Name: ImageProcessTop
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


module ImageProcessTop(

	input logic				axi_clk, 
	input logic				axi_reset_n,		// active LOW
	output logic			o_intr,
	
	// sub interface (importing from DMA Controller, from DDR )
	input logic 			DATA_VALID_i, 
	input logic [7:0] 		DATA_i, 
	output 					DATA_RDY_o, 
	
	// main interface (exporting to DMA Controller, to DDR )
	input logic 			DATA_RDY_i, 
	output logic [7:0] 		DATA_o, 
	output logic 			DATA_VALID_o
    );
    
    
    // ~~~~ local param/alloc/const ~~~~
    logic [71:0] 			mat;
	logic					mat_valid;
	logic					axi_buff_full;
	logic [7:0]				result; 
	logic					result_valid;
	localparam logic 		filt_sel = 1; 	// {0:box, 1:sobel} 

	assign DATA_RDY_o 		= !axi_buff_full;
    


    
    // ~~~~ instances ~~~~
    ImageControlUnit
    #(.PIXELWIDTH(512), .PIXELHEIGHT(512))
	ICU
    (
    	.CLK_i				(axi_clk), 
    	.RST_i				(!axi_reset_n),
    	.PIXEL_i			(DATA_i),
    	.PIXEL_VALID_i		(DATA_VALID_i),
    	.MATRIX_VALID_o		(mat_valid), 
    	.MATRIX_o			(mat),
    	.INTRR_o			(o_intr) 
    );
    

    Convolution 
	#(
		.FILTER				(filt_sel)
	)
	CONV
	(
		.CLK_i				(axi_clk), 
		.MATRIX_i			(mat),				
		.MATRIX_VALID_i		(mat_valid), 
		.RESULT_o			(result), 
		.RESULT_VALID_o		(result_valid)
	);

    // timimg mismatch between conv output and what DMA is accepting
    //	therefore we use a FIFO 
	outputBuffer OBUFFER (
      .wr_rst_busy			(),        
      .rd_rst_busy			(),        
      .s_aclk				(axi_clk),		// input wire s_aclk
      .s_aresetn			(axi_reset_n),		// input wire s_aresetn
      .s_axis_tvalid		(result_valid),		// input wire s_axis_tvalid
      .s_axis_tready		(),    
      .s_axis_tdata			(result),			// input wire [7 : 0] s_axis_tdata
      .m_axis_tvalid		(DATA_VALID_o),    	// output wire m_axis_tvalid
      .m_axis_tready		(DATA_RDY_i),    	// input wire m_axis_tready
      .m_axis_tdata			(DATA_o),      		// output wire [7 : 0] m_axis_tdata
      .axis_prog_full		(axi_buff_full)		// output wire axis_prog_full
    );
    
endmodule
