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
	wire 												vld_video,vld_mem;
	wire 												rdy,vld;
	
	//BRAMS 
	wire clkb_bram12,clka_bram3,clka_bram12,clkb_bram3;
	wire empty,full; //from CPS to Video Out 
	wire wea_bram3,wea_bram12;
	wire [6:0] addra_bram3,addrb_bram12,addra_bram12,addrb_bram3;
	wire [383:0] dina_bram3,doutb_bram12,dina_bram12,doutb_bram3;
	
	//PROCESSING
	wire [26:0] 									elem_struct;
	wire												enable_processing;
	wire  											video_ACK;
	wire 												ENABLE_INPUT;
	
  //Assigns
  assign rst_Chrontel_o=1'b1; //RST dla ukladu Chrontel , '0' aktywne
  assign video_ACK=1'b1,elem_struct=27'b001001001001001001001001001,enable_processing=1'b0,
  ENABLE_INPUT=1'b1;
  
	assign 	H_FP=10'd16,
				H_BP=10'd120,
				H_sync=10'd64,
				H_VldDat=10'd640,
				COLUMNS=10'd800,
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
				
//Instantations	 
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
		.wea_bram12_o(wea_bram12),
		.addra_bram12_o(addra_bram12), 
		.dina_bram12_o(dina_bram12), 
		//CPS
		.vld_o(vld),
		.rdy_i(rdy),
		.vld_video_o(vld_video), 
		.column_max_o(column_max), 
		.line_max_o(line_max));
		 
	blk_mem_gen4 input_buffer_BRAM( 
	 .clka(clka_bram12), 
	 .clkb(clkb_bram12), 
	 .wea(wea_bram12), 
	 .addra(addra_bram12), 
	 .addrb(addrb_bram12), 
	 .dina(dina_bram12), 
	 .doutb(doutb_bram12));
		 
	CPS_v3 processing_erosion (
	 .rst_i(Bus2IP_Reset), 
	 .clk_i(Bus2IP_Clk), 
	 .vld_mem_o(vld_mem),
	 //video_in
	 .vld_i(vld), 
	 .en_read_i(vld_video), 
	 .rdy_o(rdy), 
	 //bram12
	 .clkb_bram12_o(clkb_bram12), 
	 .addrb_bram12_o(addrb_bram12), 
	 .doutb_bram12_i(doutb_bram12), 
	 //bram3
	 .wea_bram3_o(wea_bram3), 
	 .clka_bram3_o(clka_bram3), 
	 .addra_bram3_o(addra_bram3), 
	 .dina_bram3_o(dina_bram3),
	 //video_out
	 .empty_i(empty), 
	 .full_o(full),
	 .element_struct(elem_struct), 
    .enable_processing(enable_processing) );
	 	 	
	 blk_mem_gen4 output_buffer_BRAM (
	 .clka(clka_bram3), 
	 .clkb(clkb_bram3), 
	 .wea(wea_bram3),  
	 .addra(addra_bram3), 
	 .addrb(addrb_bram3), 
	 .dina(dina_bram3), 
	 .doutb(doutb_bram3));	
	 
	 VIDEO_OUT3 OUTPUT_VID (
		.clk_i(Bus2IP_Clk), 
		.rst_i(Bus2IP_Reset), 
		//BRAM
		.clkb_bram3_o(clkb_bram3),
		.doutb_bram3_i(doutb_bram3),
		.addrb_bram3_o(addrb_bram3), 
		.full_i(full), 
		.empty_o(empty),
		//VIDEO
		.video_ACK_i(video_ACK), 
		.VLD_VIDEO_i(vld_video), 
		.vld_mem_i(vld_mem),
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
		.VideoInputActive(ENABLE_INPUT)
		);

endmodule
