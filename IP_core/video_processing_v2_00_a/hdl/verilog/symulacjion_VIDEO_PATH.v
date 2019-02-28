`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:06:00 01/15/2019
// Design Name:   symulation_main
// Module Name:   C:/Designs/Inzynierka_Adam_15_01/Inzynierka_Adam_15_01/Inzynierka_Adamv3/pcores/video_processing_v2_00_a/devl/projnav/symulacjion_VIDEO_PATH.v
// Project Name:  video_processing
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: symulation_main
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
`include "video_in_v3.v"
`include "video_out_v3.v"
`include "blk_mem_gen5.v"
`include "CPS_v3.v"
`include "dviPLL4.v"

module symulacjion_VIDEO_PATH;

	// Inputs
	reg ad_dataclk_i;
	reg ad_hsync_i;
	reg ad_vsync_i;
	reg [0:7] ad_red_i;
	reg [0:7] ad_green_i;
	reg [0:7] ad_blue_i;
	reg Bus2IP_Clk;
	reg Bus2IP_Reset;

	// Outputs
	wire rst_Chrontel_o;
	wire [0:11] dvi_d_o;
	wire x_clk_p_o;
	wire x_clk_n_o;
	wire dvi_de_o;
	wire dvi_hsync_o;
	wire dvi_vsync_o;
	wire [10:0] column_max;
	wire [10:0] line_max;
	
	reg [9:0] H_FP;
	reg [9:0] H_BP;
	reg [9:0] H_sync;
	reg [9:0] H_VldDat;
	reg [9:0] COLUMNS;
	reg [9:0] V_FP;
	reg [9:0] V_BP;
	reg [9:0] V_sync;
	reg [9:0] V_VldDat;
	reg [9:0] LINES;
	reg H_active;
	reg V_active;
	
	//Regs
	reg [10:0] column;
	reg [10:0] line;
	reg DataEnable;
	reg [4:0] add_op;
	reg [23:0] pixs;
	reg temp_col;
	reg video_ACK;
	
	// Instantiate the Unit Under Test (UUT)
	symulation_main uut (
		.rst_Chrontel_o(rst_Chrontel_o), 
		.dvi_d_o(dvi_d_o), 
		.x_clk_p_o(x_clk_p_o), 
		.x_clk_n_o(x_clk_n_o), 
		.dvi_de_o(dvi_de_o), 
		.dvi_hsync_o(dvi_hsync_o), 
		.dvi_vsync_o(dvi_vsync_o), 
		.ad_dataclk_i(ad_dataclk_i), 
		.ad_hsync_i(ad_hsync_i), 
		.ad_vsync_i(ad_vsync_i), 
		.ad_red_i(ad_red_i), 
		.ad_green_i(ad_green_i), 
		.ad_blue_i(ad_blue_i), 
		.Bus2IP_Clk(Bus2IP_Clk), 
		.Bus2IP_Reset(Bus2IP_Reset), 
		.column_max(column_max), 
		.line_max(line_max)
	);

	initial begin
		// Initialize Inputs
		ad_dataclk_i = 0;
		ad_hsync_i = 0;
		ad_vsync_i = 0;
		ad_red_i = 0;
		ad_green_i = 0;
		ad_blue_i = 0;
		Bus2IP_Clk = 0;
		Bus2IP_Reset = 1;
		H_FP = 16;
		H_BP = 120;
		H_sync = 64;
		H_VldDat = 640;
		COLUMNS = H_FP+H_BP+H_sync+H_VldDat;
		V_FP = 1;
		V_BP = 16;
		V_sync = 3;
		V_VldDat = 480;
		LINES = V_FP+V_BP+V_sync+V_VldDat;
		H_active = 0;
		V_active = 0;
		DataEnable=0;
		video_ACK=0;
		
		#100;
      Bus2IP_Reset = 0;
		#1000 video_ACK=1;
		
	end
	
	always #1   Bus2IP_Clk=~Bus2IP_Clk;		 //100MHz
	always #2	ad_dataclk_i=~ad_dataclk_i; //31.5 MHz
	
	always @(posedge ad_dataclk_i or posedge Bus2IP_Reset)
	begin
		if(Bus2IP_Reset)
		begin
			column<=0;
			line<=0;
			temp_col<=0;
		end
		else
		begin
			if(video_ACK)
			begin
				if(line<LINES)
				begin
					if(column<COLUMNS)
					begin
						column<=column+1'b1;
					end
					else
					begin
						line<=line+1'b1;
						column<=0;
					end	
				end
				else 
				begin
					line<=0;
					column<=0;	
				end	
			end		
		end
	end

	always @(negedge ad_dataclk_i or posedge Bus2IP_Reset)
	begin
		if(Bus2IP_Reset)
		begin
			ad_hsync_i<=1'b1;
			ad_vsync_i<=1'b1;
			DataEnable<=1'b0;
			ad_red_i<=0;
			ad_green_i<=0;
			ad_blue_i<=0;
			add_op<=1;
			pixs=0;
		end
		else
		begin
			if(video_ACK)
			begin
				if(DataEnable)
				begin
					pixs=24'hCF4F4F;
					ad_red_i<=pixs[23:16];
					ad_green_i<=pixs[15:8];
					ad_blue_i<=pixs[7:0];
				end
				else
				begin
					ad_red_i<=0;
					ad_green_i<=0;
					ad_blue_i<=0;
					pixs=0;
				end	
				
				if(line >(V_FP-1+ V_sync+V_BP))
				begin
					if(column>(H_FP+H_BP+H_sync))	DataEnable<=1'b1; //sterowanie Data_enable
					else DataEnable<=1'b0;	
				end
				else DataEnable<=1'b0;
				
				if(column>(H_FP-1) && column<(H_FP+H_sync) ) 
				begin
					ad_hsync_i<=1'b0; //sterowanie Hsync
					
				end
				else ad_hsync_i<=1'b1;	
				
				if(line>(V_FP-1) && line<(V_FP+V_sync)) 
				begin
					ad_vsync_i<=1'b0; 
					add_op<=add_op+1'b1;
				end	
				else ad_vsync_i<=1'b1;
			end	
		end
	end
endmodule

