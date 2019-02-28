`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:23:31 01/15/2019 
// Design Name: 
// Module Name:    symulation_main 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module symulation_main(
		//CH7301C
		rst_Chrontel_o,
		dvi_d_o,
		x_clk_p_o,
		x_clk_n_o,
		dvi_de_o,
		dvi_hsync_o,
		dvi_vsync_o,
		//AD9980
		ad_dataclk_i,
		ad_hsync_i,
		ad_vsync_i,
		ad_red_i,
		ad_green_i,
		ad_blue_i,
		Bus2IP_Clk,
		Bus2IP_Reset,
		column_max,
		line_max
		);

	//CHRONTEL Ch7301C
	output  												rst_Chrontel_o;
	output  [0:11]										dvi_d_o;
	output  												x_clk_p_o;
	output  												x_clk_n_o;
	output  												dvi_de_o;
	output  												dvi_hsync_o;
	output  												dvi_vsync_o;
	//ANALOG DEVICES AD9980
	input 												ad_dataclk_i;
	input 												ad_hsync_i;
	input 												ad_vsync_i;
	input [0:7] 										ad_red_i;
	input [0:7] 										ad_green_i;
	input [0:7] 										ad_blue_i;
	input                                     Bus2IP_Clk;
	input                                     Bus2IP_Reset;		
	
	output wire [10:0] column_max;
	output wire [10:0] line_max;
	
//	REGS
	//CH7301C
	wire [ 9:0 ] H_FP;
	wire [ 9:0 ] H_BP;
	wire [ 9:0 ] H_sync;
	wire [ 9:0 ] H_VldDat;
	wire [ 9:0 ] COLUMNS;
	wire [ 9:0 ] V_FP;
	wire [ 9:0 ] V_BP;
	wire [ 9:0 ] V_sync;
	wire [ 9:0 ] V_VldDat;
	wire [ 9:0 ] LINES;
	wire H_active;
	wire V_active;
	wire [9:0] HighCol;
	wire [9:0] LowCol;
	wire [9:0] LowLine;
	wire [9:0] HighLine;
	wire [23:0] Color;

	//AD9980
	wire 												vld_video_i,vld_video_o;
	wire 												vld_mem_i,vld_mem_o;
	wire 												rdy,vld;
	
	//BRAMS 
	wire clka_bram12,clka_bram3;
	
	wire wea_bram3;
	wire [6:0] addra_bram3,addra_bram12;
	wire [383:0] dina_bram3,dina_bram12;
	
	wire [6:0] addrb_bram12_i;
	wire [6:0] addrb_bram12_o;
	wire [6:0] addrb_bram3_o;
	wire [6:0] addrb_bram3_i;

	wire clkb_bram12_i;
	wire clkb_bram12_o;
	wire clkb_bram3_o;
	wire clkb_bram3_i;
			  
	wire [383:0] doutb_bram12_i;
	wire [383:0] doutb_bram12_o;
	wire [383:0] doutb_bram3_i;
	wire [383:0] doutb_bram3_o;
	wire wea_bram12_i,wea_bram12_o;
	
	wire empty_i,empty_o;
	wire full_i,full_o;
	wire rdy_i,rdy_o;
	wire vld_i,vld_o;
	
	//PROCESSING
	wire [26:0] 									elem_struct;
	wire												enable_processing;
	wire  											video_ACK;
	wire 												ENABLE_INPUT;
	wire 												readBRAM1;
	
  //Assigns
  assign rst_Chrontel_o=1'b1; //RST dla ukladu Chrontel , '0' aktywne
  assign video_ACK=1'b1,elem_struct=27'b100100100100100100100100100,enable_processing=1'b1,
  ENABLE_INPUT=1'b1,readBRAM1=1'b0;
  
	assign 	H_FP=10'd16,
				H_BP=10'd120,
				H_sync=10'd64,
				H_VldDat=10'd640,
				COLUMNS=10'd840,
				V_FP=10'd1,
				V_BP=10'd16,
				V_sync=10'd3,
				V_VldDat=10'd480,
				LINES=10'd500,
				H_active=0,
				V_active=0,
				HighCol=10'd640,
				LowCol=0,
				LowLine=0,
				HighLine=10'd480,
				Color=24'hFFFFFF;
				
  assign	  addrb_bram12_i	= (enable_processing)? addrb_bram12_o : addrb_bram3_o,
			  addrb_bram3_i	= (enable_processing)? addrb_bram3_o  : 7'd0,
		
			  clkb_bram12_i	= (enable_processing)? clkb_bram12_o  : clkb_bram3_o,
			  clkb_bram3_i		= (enable_processing)? clkb_bram3_o	  : 1'd0,
			  
			  doutb_bram12_i	= (enable_processing)? doutb_bram12_o : 384'd0,
			  doutb_bram3_i	= (enable_processing)? doutb_bram3_o  : doutb_bram12_o,
			  
			  full_i				= (enable_processing)? full_o			  : 1'b0,
			  empty_i			= (enable_processing)? empty_o		  : 1'b0,
			  vld_i				= (enable_processing)? vld_o			  : 1'b1,
			  rdy_i				= (enable_processing)? rdy_o			  : 1'b1,
			  vld_mem_i			= (enable_processing)? vld_mem_o		  : 1'b1; 
			  
  assign	  wea_bram12_i		= (readBRAM1)			? 1'b0 			  : wea_bram12_o,
			  vld_video_i		= (readBRAM1)			? 1'b1			  : vld_video_o;		  
			  
	
				  
	video_in_v3 INPUT_VID (
			.pixel_clk_i(ad_dataclk_i), 
			.rst_i(Bus2IP_Reset), 
		//VIDEO_IN
			.hsync_i(ad_hsync_i), 
			.vsync_i(ad_vsync_i),
			.red_i(ad_red_i), 
			.green_i(ad_green_i), 
			.blue_i(ad_blue_i), 
		//BRAM12
			.clka_bram12_o(clka_bram12), 
			.wea_bram12_o(wea_bram12_o),
			.addra_bram12_o(addra_bram12), 
			.dina_bram12_o(dina_bram12), 
		//CPS
			.vld_o(vld_o),
			.rdy_i(rdy_i),
			.vld_video_o(vld_video_o), 
			.column_max_o(column_max), 
			.line_max_o(line_max),
		//CONFIG
			.video_ACK_i(video_ACK));	
		 
	blk_mem_gen5 input_buffer_BRAM( 
	 .clka(clka_bram12), 
	 .clkb(clkb_bram12_i), 
	 .wea(wea_bram12_i), 
	 .addra(addra_bram12), 
	 .addrb(addrb_bram12_i), 
	 .dina(dina_bram12), 
	 .doutb(doutb_bram12_o));
		 
	CPS_v3 processing_erosion (
		 .rst_i(Bus2IP_Reset), 
		 .clk_i(Bus2IP_Clk), 
		 .video_ACK_i(video_ACK),
		 .vld_mem_o(vld_mem_o),
	 //video_in
		 .vld_i(vld_i),
		 .en_read_i(vld_video_i),
		 .rdy_o(rdy_o),
	 //bram12
		 .clkb_bram12_o(clkb_bram12_o), 
		 .addrb_bram12_o(addrb_bram12_o), 
		 .doutb_bram12_i(doutb_bram12_i), 
	 //bram3
		 .wea_bram3_o(wea_bram3), 
		 .clka_bram3_o(clka_bram3), 
		 .addra_bram3_o(addra_bram3), 
		 .dina_bram3_o(dina_bram3),
	 //video_out
		 .empty_i(empty_i),
		 .full_o(full_o),
		 .element_struct(elem_struct));

	 	 	
	 blk_mem_gen5 output_buffer_BRAM (
		 .clka(clka_bram3), 
		 .clkb(clkb_bram3_i),
		 .wea(wea_bram3),  
		 .addra(addra_bram3), 
		 .addrb(addrb_bram3_i), 
		 .dina(dina_bram3), 
		 .doutb(doutb_bram3_o));	
	 
	 VIDEO_OUT3 OUTPUT_VID (
			.clk_i(Bus2IP_Clk),
			.rst_i(Bus2IP_Reset),
		//BRAM
			.clkb_bram3_o(clkb_bram3_o),
			.doutb_bram3_i(doutb_bram3_i),
			.addrb_bram3_o(addrb_bram3_o),
			.full_i(full_i), 
			.empty_o(empty_o),
		//VIDEO
			.video_ACK_i(video_ACK), 
			.VLD_VIDEO_i(vld_video_i), 
			.vld_mem_i(vld_mem_i),
			.vga_d_o(dvi_d_o), 
			.vga_de_o(dvi_de_o), 
			.vga_hsync_o(dvi_hsync_o), 
			.vga_vsync_o(dvi_vsync_o), 
			.x_clk_p_o(x_clk_p_o), 
			.x_clk_n_o(x_clk_n_o), 
		//CSR
			.H_FP(H_FP), 
			.H_BP(H_BP), 
			.H_sync(H_sync), 
			.H_VldDat(H_VldDat), 
			.COLUMNS(COLUMNS), 
			.V_FP(V_FP), 
			.V_BP(V_BP), 
			.V_sync(V_sync), 
			.V_VldDat(V_VldDat), 
			.LINES(LINES), 
			.H_active(H_active), 
			.V_active(V_active), 
			.Color(Color), 
			.HighLine(HighLine), 
			.LowLine(LowLine), 
			.HighCol(HighCol), 
			.LowCol(LowCol),
			.VideoInputActive(ENABLE_INPUT));
			
endmodule
