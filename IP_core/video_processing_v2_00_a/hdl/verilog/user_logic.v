//----------------------------------------------------------------------------
// user_logic.vhd - module
//----------------------------------------------------------------------------
`include "iic_master2.v"
`include "video_in_v3.v"
`include "video_out_v3.v"
`include "blk_mem_gen5.v"
`include "CPS_v3.v"
`include "clk_div.v"
`include "dviPLL4.v"
`include "IIC_driver_ASM2.v"

module user_logic
(
  // -- ADD USER PORTS BELOW THIS LINE ---------------
	  //I2C
      SDA_io_I,
		SDA_io_O,
		SDA_io_T,
		SCL_o,
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
  // -- ADD USER PORTS ABOVE THIS LINE ---------------
  
  // -- DO NOT EDIT BELOW THIS LINE ------------------
  // -- Bus protocol ports, do not add to or delete 
  Bus2IP_Clk,                     // Bus to IP clock
  Bus2IP_Reset,                   // Bus to IP reset
  Bus2IP_Data,                    // Bus to IP data bus
  Bus2IP_BE,                      // Bus to IP byte enables
  Bus2IP_RdCE,                    // Bus to IP read chip enable
  Bus2IP_WrCE,                    // Bus to IP write chip enable
  IP2Bus_Data,                    // IP to Bus data bus
  IP2Bus_RdAck,                   // IP to Bus read transfer acknowledgement
  IP2Bus_WrAck,                   // IP to Bus write transfer acknowledgement
  IP2Bus_Error                    // IP to Bus error response
  // -- DO NOT EDIT ABOVE THIS LINE ------------------
); // user_logic

// -- ADD USER PARAMETERS BELOW THIS LINE ------------
// --USER parameters added here 
// -- ADD USER PARAMETERS ABOVE THIS LINE ------------

// -- DO NOT EDIT BELOW THIS LINE --------------------
// -- Bus protocol parameters, do not add to or delete
parameter C_SLV_DWIDTH                   = 32;
parameter C_NUM_REG                      = 83;
// -- DO NOT EDIT ABOVE THIS LINE --------------------

// -- ADD USER PORTS BELOW THIS LINE -----------------
	//I2C
	input   SDA_io_I;
	output  SDA_io_O;
	output  SDA_io_T;
	output  SCL_o;
	//CHRONTEL Ch7301C
	output  rst_Chrontel_o;
	output  [0:11] dvi_d_o;
	output  x_clk_p_o;
	output  x_clk_n_o;
	output  dvi_de_o;
	output  dvi_hsync_o;
	output  dvi_vsync_o;
	//ANALOG DEVICES AD9980
	input ad_dataclk_i;
	input ad_hsync_i;
	input ad_vsync_i;
	input [0:7] ad_red_i;
	input [0:7] ad_green_i;
	input [0:7] ad_blue_i;
// -- ADD USER PORTS ABOVE THIS LINE -----------------

// -- DO NOT EDIT BELOW THIS LINE --------------------
// -- Bus protocol ports, do not add to or delete
input                                     Bus2IP_Clk;
input                                     Bus2IP_Reset;
input      [0 : C_SLV_DWIDTH-1]           Bus2IP_Data;
input      [0 : C_SLV_DWIDTH/8-1]         Bus2IP_BE;
input      [0 : C_NUM_REG-1]              Bus2IP_RdCE;
input      [0 : C_NUM_REG-1]              Bus2IP_WrCE;
output     [0 : C_SLV_DWIDTH-1]           IP2Bus_Data;
output                                    IP2Bus_RdAck;
output                                    IP2Bus_WrAck;
output                                    IP2Bus_Error;
// -- DO NOT EDIT ABOVE THIS LINE --------------------

//----------------------------------------------------------------------------
// Implementation
//----------------------------------------------------------------------------

  // --USER nets declarations added here, as needed for user logic
  	reg [18:0]	i2c_reg0,i2c_reg1,i2c_reg2,i2c_reg3, i2c_reg4,
					i2c_reg5,i2c_reg6,i2c_reg7,i2c_reg8,i2c_reg9,i2c_reg10,
					i2c_reg11,i2c_reg12,i2c_reg13,i2c_reg14,i2c_reg15,i2c_reg16,
					i2c_reg17,i2c_reg18,i2c_reg19,i2c_reg20,i2c_reg21,i2c_reg22,i2c_reg23,
					i2c_reg24,i2c_reg25,i2c_reg26,i2c_reg27,i2c_reg28,i2c_reg29,i2c_reg30,
					i2c_reg31,i2c_reg32,i2c_reg33,i2c_reg34,i2c_reg35, i2c_reg36,i2c_reg37,
					i2c_reg38,i2c_reg39,i2c_reg40,i2c_reg41, i2c_reg42,i2c_reg43,i2c_reg44,
					i2c_reg45,i2c_reg46,i2c_reg47,i2c_reg48,i2c_reg49,i2c_reg50,i2c_reg51,
					i2c_reg52,i2c_reg53,i2c_reg54,i2c_reg55,i2c_reg56,i2c_reg57,i2c_reg58,i2c_reg59;
	//I2C tests
	wire [0:C_SLV_DWIDTH-1]						TEST1;
	wire [0:C_SLV_DWIDTH-1]						TEST2;
	wire [0:C_SLV_DWIDTH-1]						TEST3;
	wire [0 : C_SLV_DWIDTH-1] 					DataRead_I2C;
	wire [0 : C_SLV_DWIDTH-1] 					i2creg_return;
	wire [0 : C_SLV_DWIDTH-1] 					ACK;
	
	//CH7301C
	reg [ 9:0 ] H_FP,H_BP,H_sync,H_VldDat,COLUMNS;
	reg [ 9:0 ] V_FP,V_BP,V_sync,V_VldDat,LINES;
	reg H_active,V_active;
	reg [9:0] HighCol,LowCol,LowLine,HighLine;
	reg [23:0] Color;
	
	//AD9980
	//wire 												vld_video;
	wire 												vld_mem_o,vld_mem_i;
	wire [0:10]										column_max;
	wire [0:10]										line_max;
	
	//BRAMS 
	reg 												readBRAM1;
	wire 												clka_bram3;
	
	wire 												wea_bram3;
	wire [6:0] 										addra_bram3;
	wire [383:0] 									dina_bram3;
	
	wire [6:0]										addrb_bram12_i;
	wire [6:0]										addrb_bram12_o;
	wire [6:0] 										addrb_bram3_o;
	wire [6:0] 										addrb_bram3_i;

	wire 												clkb_bram12_i;
	wire 												clkb_bram12_o;
	wire 												clkb_bram3_o;
	wire 												clkb_bram3_i;
	
	wire [383:0] 									doutb_bram12_i;
	wire [383:0] 									doutb_bram12_o;
	wire [383:0] 									doutb_bram3_i;
	wire [383:0] 									doutb_bram3_o;
	
	wire 												empty_i,empty_o;
	wire 												full_i,full_o;
	wire 												rdy_i,rdy_o;
	wire 												vld_i,vld_o;
	
	wire 												vld_video_o,vld_video_i;
	wire												wea_bram12_i,wea_bram12_o;
	wire												clka_bram12_i,clka_bram12_o;
	wire												addra_bram12_i,addra_bram12_o;
	wire												dina_bram12_i,dina_bram12_o;

	//PROCESSING
	reg [26:0] 										elem_struct;
	reg 												enable_processing;
	//CTRLs
	reg 												CSR_START;
	reg 												CSR_DONE;
	wire 												video_ACK;
	
  // Nets for user logic slave model s/w accessible register example
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg0;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg1;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg2;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg3;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg4;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg5;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg6;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg7;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg8;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg9;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg10;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg11;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg12;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg13;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg14;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg15;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg16;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg17;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg18;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg19;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg20;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg21;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg22;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg23;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg24;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg25;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg26;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg27;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg28;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg29;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg30;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg31;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg32;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg33;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg34;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg35;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg36;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg37;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg38;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg39;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg40;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg41;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg42;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg43;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg44;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg45;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg46;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg47;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg48;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg49;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg50;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg51;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg52;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg53;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg54;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg55;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg56;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg57;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg58;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg59;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg60;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg61;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg62;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg63;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg64;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg65;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg66;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg67;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg68;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg69;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg70;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg71;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg72;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg73;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg74;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg75;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg76;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg77;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg78;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg79;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg80;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg81;
  reg        [0 : C_SLV_DWIDTH-1]           slv_reg82;
  wire       [0 : 82]                       slv_reg_write_sel;
  wire       [0 : 82]                       slv_reg_read_sel;
  reg        [0 : C_SLV_DWIDTH-1]           slv_ip2bus_data;
  wire                                      slv_read_ack;
  wire                                      slv_write_ack;
  integer                                   byte_index, bit_index;

  // --USER logic implementation added here
  /*****************************************************************************************/
  /*****************************************************************************************/
  //Instantations
    iic_master2 IIC (
	 //GLOBAL
    .rst_i( Bus2IP_Reset), 
    .clk_i( Bus2IP_Clk), 
    .SDA_io_I(SDA_io_I), 	
	 .SDA_io_O(SDA_io_O), 
	 .SDA_io_T(SDA_io_T),		
    .SCL_o(SCL_o), 
    .vid_ACK_o(video_ACK), 
    .data_o(DataRead_I2C), 
	 //CSR
    .i2c_reg0(i2c_reg0), 
    .i2c_reg1(i2c_reg1), 
    .i2c_reg2(i2c_reg2), 
    .i2c_reg3(i2c_reg3), 
    .i2c_reg4(i2c_reg4), 
    .i2c_reg5(i2c_reg5), 
    .i2c_reg6(i2c_reg6), 
    .i2c_reg7(i2c_reg7), 
    .i2c_reg8(i2c_reg8), 
    .i2c_reg9(i2c_reg9), 
    .i2c_reg10(i2c_reg10), 
    .i2c_reg11(i2c_reg11), 
    .i2c_reg12(i2c_reg12), 
    .i2c_reg13(i2c_reg13), 
    .i2c_reg14(i2c_reg14), 
    .i2c_reg15(i2c_reg15), 
    .i2c_reg16(i2c_reg16), 
    .i2c_reg17(i2c_reg17), 
    .i2c_reg18(i2c_reg18), 
    .i2c_reg19(i2c_reg19), 
    .i2c_reg20(i2c_reg20), 
    .i2c_reg21(i2c_reg21), 
    .i2c_reg22(i2c_reg22), 
    .i2c_reg23(i2c_reg23), 
    .i2c_reg24(i2c_reg24), 
    .i2c_reg25(i2c_reg25), 
    .i2c_reg26(i2c_reg26), 
    .i2c_reg27(i2c_reg27), 
    .i2c_reg28(i2c_reg28), 
    .i2c_reg29(i2c_reg29), 
    .i2c_reg30(i2c_reg30), 
    .i2c_reg31(i2c_reg31), 
    .i2c_reg32(i2c_reg32), 
    .i2c_reg33(i2c_reg33), 
    .i2c_reg34(i2c_reg34), 
    .i2c_reg35(i2c_reg35), 
    .i2c_reg36(i2c_reg36), 
    .i2c_reg37(i2c_reg37), 
    .i2c_reg38(i2c_reg38), 
    .i2c_reg39(i2c_reg39), 
    .i2c_reg40(i2c_reg40), 
    .i2c_reg41(i2c_reg41), 
    .i2c_reg42(i2c_reg42), 
    .i2c_reg43(i2c_reg43), 
    .i2c_reg44(i2c_reg44), 
    .i2c_reg45(i2c_reg45), 
    .i2c_reg46(i2c_reg46), 
    .i2c_reg47(i2c_reg47), 
    .i2c_reg48(i2c_reg48), 
    .i2c_reg49(i2c_reg49), 
    .i2c_reg50(i2c_reg50), 
    .i2c_reg51(i2c_reg51), 
    .i2c_reg52(i2c_reg52), 
    .i2c_reg53(i2c_reg53), 
    .i2c_reg54(i2c_reg54), 
    .i2c_reg55(i2c_reg55), 
    .i2c_reg56(i2c_reg56), 
    .i2c_reg57(i2c_reg57), 
    .i2c_reg58(i2c_reg58), 
    .i2c_reg59(i2c_reg59), 
	 .CSR_DONE(CSR_DONE),
	 .ACK_o(ACK),
	 .TEST1(TEST1),
	 .TEST2(TEST2),
	 .TEST3(TEST3));
	 
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
			.clka_bram12_o(clka_bram12_o), 
			.wea_bram12_o(wea_bram12_o),
			.addra_bram12_o(addra_bram12_o), 
			.dina_bram12_o(dina_bram12_o), 
		//CPS
			.vld_o(vld_o),
			.rdy_i(rdy_i),
			.vld_video_o(vld_video_o), 
			.column_max_o(column_max), 
			.line_max_o(line_max),
		//CONFIG
			.video_ACK_i(video_ACK));	
		 
	blk_mem_gen5 input_buffer_BRAM( 
	 .clka(clka_bram12_i), 
	 .clkb(clkb_bram12_i), 
	 .wea(wea_bram12_i), 
	 .addra(addra_bram12_i), 
	 .addrb(addrb_bram12_i), 
	 .dina(dina_bram12_i), 
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
			.VideoInputActive(~slv_reg82[30]));
		 
  //Assigns
  assign 	rst_Chrontel_o=1'b1; //RST dla ukladu Chrontel , '0' aktywne
  
//PROCESSING ENABLE 
  assign		addrb_bram12_i	= (enable_processing)? addrb_bram12_o : addrb_bram3_o,
				addrb_bram3_i	= (enable_processing)? addrb_bram3_o  : 7'd0,

				clkb_bram12_i	= (enable_processing)? clkb_bram12_o  : clkb_bram3_o,
				clkb_bram3_i	= (enable_processing)? clkb_bram3_o	  : 1'd0,
		  
				doutb_bram12_i	= (enable_processing)? doutb_bram12_o : 384'd0,
				doutb_bram3_i	= (enable_processing)? doutb_bram3_o  : doutb_bram12_o,
			
				full_i			= (enable_processing)? full_o			  : 1'b0,
				empty_i			= (enable_processing)? empty_o		  : 1'b0,
				vld_i				= (enable_processing)? vld_o			  : 1'b1,
				rdy_i				= (enable_processing)? rdy_o			  : 1'b1,
				vld_mem_i		= (enable_processing)? vld_mem_o		  : 1'b1;
	
//READ BRAM1	
  assign 	wea_bram12_i	= (readBRAM1)			? 1'b0 			  : wea_bram12_o,
				clka_bram12_i	= (readBRAM1)			? 1'b0 			  : clka_bram12_o,
				addra_bram12_i	= (readBRAM1)			? 7'd0 			  : addra_bram12_o,
				dina_bram12_i	= (readBRAM1)			? 384'd0 		  : dina_bram12_o,
				vld_video_i		= (readBRAM1)			? 1'b1			  : vld_video_o;
	
  //Sequential
   always @*//TYLKO ODCZYT i zmiana z perspektywy uB
	begin
	  if (Bus2IP_Reset)
	  begin
			i2c_reg0		<=0; 	i2c_reg1		<=0; 	i2c_reg2		<=0; 	i2c_reg3		<=0; 	i2c_reg4		<=0;
			i2c_reg5		<=0; 	i2c_reg6		<=0; 	i2c_reg7		<=0; 	i2c_reg8		<=0; 	i2c_reg9		<=0;
			i2c_reg10	<=0; 	i2c_reg11	<=0; 	i2c_reg12	<=0; 	i2c_reg13	<=0; 	i2c_reg14	<=0;
			i2c_reg15	<=0; 	i2c_reg16	<=0; 	i2c_reg17	<=0; 	i2c_reg18 	<=0; 	i2c_reg19	<=0;
			i2c_reg20	<=0; 	i2c_reg21	<=0; 	i2c_reg22	<=0; 	i2c_reg23	<=0; 	i2c_reg24	<=0;
			i2c_reg25	<=0; 	i2c_reg26	<=0; 	i2c_reg27	<=0; 	i2c_reg28	<=0; 	i2c_reg29	<=0;
			i2c_reg30	<=0; 	i2c_reg31	<=0; 	i2c_reg32	<=0; 	i2c_reg33	<=0; 	i2c_reg34	<=0;
			i2c_reg35	<=0; 	i2c_reg36	<=0; 	i2c_reg37	<=0; 	i2c_reg38	<=0; 	i2c_reg39	<=0;
			i2c_reg30	<=0; 	i2c_reg31	<=0;	i2c_reg32	<=0; 	i2c_reg33	<=0; 	i2c_reg34	<=0;
			i2c_reg35	<=0; 	i2c_reg36	<=0;	i2c_reg37	<=0; 	i2c_reg38	<=0; 	i2c_reg39	<=0;
			i2c_reg40	<=0; 	i2c_reg41	<=0;	i2c_reg42	<=0; 	i2c_reg43	<=0; 	i2c_reg44	<=0;
			i2c_reg45	<=0;	i2c_reg46	<=0; 	i2c_reg47	<=0; 	i2c_reg48	<=0; 	i2c_reg49	<=0;
	   	i2c_reg50	<=0; 	i2c_reg51	<=0; 	i2c_reg52	<=0; 	i2c_reg53	<=0; 	i2c_reg54	<=0;
			i2c_reg55	<=0; 	i2c_reg56	<=0; 	i2c_reg57	<=0; 	i2c_reg58	<=0; 	i2c_reg59	<=0;
		
			H_FP			<= 0; H_BP			<= 0;	H_sync		<= 0;
			H_VldDat		<= 0; COLUMNS		<= 0;	H_active		<= 0;
			
			V_FP			<= 0;	V_BP			<= 0;	V_sync		<= 0;
			V_VldDat		<= 0;	LINES			<= 0;	V_active		<= 0;
			
			Color			<= 0;	HighLine		<= 0;
			HighCol		<= 0;	LowLine		<= 0;	LowCol		<= 0;
			
			CSR_DONE			<= 1'b0; 
			CSR_START	 	<= 1'b0; 
	  end
	  else
	  begin
			if(CSR_START==1'b0 && slv_reg25[31]==1'b1)
			begin
				CSR_START<=1'b1;
			end
			
			if(CSR_START && slv_reg25[31]==1'b1)
			begin
			//I2C
				//CHRONTEL 
				i2c_reg0		<= slv_reg0[13:31]; 
				i2c_reg1		<= slv_reg1[13:31];
				i2c_reg2		<= slv_reg2[13:31];
				i2c_reg3		<= slv_reg3[13:31];
				i2c_reg4		<= slv_reg4[13:31];
				i2c_reg5		<= slv_reg5[13:31];
				i2c_reg6		<= slv_reg6[13:31];
				i2c_reg7		<= slv_reg7[13:31];
				i2c_reg8		<= slv_reg8[13:31];
				i2c_reg9		<= slv_reg9[13:31];
				i2c_reg10	<= slv_reg10[13:31];
				i2c_reg11	<= slv_reg11[13:31];
				i2c_reg12	<= slv_reg12[13:31];
				//AD9980
				i2c_reg13	<= slv_reg32[13:31]; 
				i2c_reg14	<= slv_reg33[13:31];
				i2c_reg15	<= slv_reg34[13:31];
				i2c_reg16	<= slv_reg35[13:31];
				i2c_reg17	<= slv_reg36[13:31];
				i2c_reg18	<= slv_reg37[13:31];
				i2c_reg19	<= slv_reg38[13:31];
				i2c_reg20	<= slv_reg39[13:31];
				i2c_reg21	<= slv_reg40[13:31];
				i2c_reg22	<= slv_reg41[13:31];
				i2c_reg23	<= slv_reg42[13:31];
				i2c_reg24	<= slv_reg43[13:31];
				i2c_reg25	<= slv_reg44[13:31];
				i2c_reg26	<= slv_reg45[13:31]; 
				i2c_reg27	<= slv_reg46[13:31];
				i2c_reg28	<= slv_reg47[13:31];
				i2c_reg29	<= slv_reg48[13:31];
				i2c_reg30	<= slv_reg49[13:31];
				i2c_reg31	<= slv_reg50[13:31];
				i2c_reg32	<= slv_reg51[13:31];
				i2c_reg33	<= slv_reg52[13:31];
				i2c_reg34	<= slv_reg53[13:31];
				i2c_reg35	<= slv_reg54[13:31];
				i2c_reg36	<= slv_reg55[13:31];
				i2c_reg37	<= slv_reg56[13:31];
				i2c_reg38	<= slv_reg57[13:31];
				i2c_reg39	<= slv_reg58[13:31]; 
				i2c_reg40	<= slv_reg59[13:31];
				i2c_reg41	<= slv_reg60[13:31];
				i2c_reg42	<= slv_reg61[13:31];
				i2c_reg43	<= slv_reg62[13:31];
				i2c_reg44	<= slv_reg63[13:31];
				i2c_reg45	<= slv_reg64[13:31];
				i2c_reg46	<= slv_reg65[13:31];
				i2c_reg47	<= slv_reg66[13:31];
				i2c_reg48	<= slv_reg67[13:31];
				i2c_reg49	<= slv_reg68[13:31];
				i2c_reg50	<= slv_reg69[13:31];
				i2c_reg51	<= slv_reg70[13:31];
				i2c_reg52	<= slv_reg71[13:31];
				i2c_reg53	<= slv_reg72[13:31];
				i2c_reg54	<= slv_reg73[13:31];
				i2c_reg55	<= slv_reg74[13:31];
				i2c_reg56	<= slv_reg75[13:31];
				i2c_reg57	<= slv_reg76[13:31];
				i2c_reg58	<= slv_reg77[13:31];
				i2c_reg59	<= slv_reg78[13:31];
				
			   if(slv_reg82[29])//RODZIELCZOSC z uB
				begin
					H_FP				<= slv_reg13[31-9:31];
					H_BP				<= slv_reg14[31-9:31];
					H_sync			<= slv_reg15[31-9:31];
					H_VldDat		<= slv_reg16[31-9:31];
					COLUMNS		<= slv_reg17[31-9:31];
					H_active		<= slv_reg18[31];
					V_FP				<= slv_reg19[31-9:31];
					V_BP				<= slv_reg20[31-9:31];
					V_sync			<= slv_reg21[31-9:31];
					V_VldDat		<= slv_reg22[31-9:31];
					LINES				<= slv_reg23[31-9:31];
					V_active		<= slv_reg18[30];
				end
				else
				begin
					H_FP			<= 16;
					H_BP			<= 120;
					H_sync		<= 32;
					H_VldDat		<= 640;
					COLUMNS		<= 808;
					H_active		<= 0;
					V_FP			<= 1;
					V_BP			<= 20;
					V_sync		<= 3;
					V_VldDat		<= 480;
					LINES			<= 504;
					V_active		<= 0;
				end
				
				if(slv_reg82[30]) //Kolor z uB
				begin 
					Color[6:4]	<= slv_reg27[8:10]; 	//G7-G5
					Color[23:21]<= slv_reg27[11:13]; //G4-G2
					Color[0]		<= slv_reg27[14]; 	//G1
					Color[15]	<= slv_reg27[15]; 	//G0
					Color[11:7]	<= slv_reg27[16:20]; //R7-R3
					Color[3:1]	<= slv_reg27[21:23]; //R2-R0
					Color[20:16]<= slv_reg27[24:28]; //B7-B3
					Color[14:12]<= slv_reg27[29:31]; //B2-B0
				end
				else
				begin
					Color<=24'hFFFFFF;
				end	
				
				if(slv_reg82[31])//WYMIARY z uB
				begin
					HighCol[9:1]<= slv_reg27[0:8];
					HighCol[0]	<= 1'b0;
					HighLine		<= slv_reg30[12:21];
					LowLine		<= slv_reg30[2:11];
					LowCol		<= slv_reg30[22:31];
				end
				else
				begin
					HighCol		<= 10'hFFF;
					HighLine		<= 10'hFFF;
					LowLine		<= 0;
					LowCol		<= 0;
				end
				
				if(slv_reg82[28]) //Przetwarzanie Y/N
				begin
					elem_struct<={9{slv_reg24[29:31]}};
					enable_processing<=1'b1;
				end
				else
				begin
					enable_processing<=1'b0;
					elem_struct<=0;
				end
				
				if(slv_reg82[27]) //ZRODLO z BRAM1 // COEFILE
				begin
					readBRAM1<=1'b1;
				end
				else
				begin
					readBRAM1<=1'b0;
				end
				CSR_DONE<=1'b1;
			end
	  end
	end
  /*****************************************************************************************/
  /*****************************************************************************************/
  // --END of user logic implementation
  
  
  assign
    slv_reg_write_sel = Bus2IP_WrCE[0:82],
    slv_reg_read_sel  = Bus2IP_RdCE[0:82],
    slv_write_ack     = Bus2IP_WrCE[0] || Bus2IP_WrCE[1] || Bus2IP_WrCE[2] || Bus2IP_WrCE[3] || Bus2IP_WrCE[4] || Bus2IP_WrCE[5] || Bus2IP_WrCE[6] || Bus2IP_WrCE[7] || Bus2IP_WrCE[8] || Bus2IP_WrCE[9] || Bus2IP_WrCE[10] || Bus2IP_WrCE[11] || Bus2IP_WrCE[12] || Bus2IP_WrCE[13] || Bus2IP_WrCE[14] || Bus2IP_WrCE[15] || Bus2IP_WrCE[16] || Bus2IP_WrCE[17] || Bus2IP_WrCE[18] || Bus2IP_WrCE[19] || Bus2IP_WrCE[20] || Bus2IP_WrCE[21] || Bus2IP_WrCE[22] || Bus2IP_WrCE[23] || Bus2IP_WrCE[24] || Bus2IP_WrCE[25] || Bus2IP_WrCE[26] || Bus2IP_WrCE[27] || Bus2IP_WrCE[28] || Bus2IP_WrCE[29] || Bus2IP_WrCE[30] || Bus2IP_WrCE[31] || Bus2IP_WrCE[32] || Bus2IP_WrCE[33] || Bus2IP_WrCE[34] || Bus2IP_WrCE[35] || Bus2IP_WrCE[36] || Bus2IP_WrCE[37] || Bus2IP_WrCE[38] || Bus2IP_WrCE[39] || Bus2IP_WrCE[40] || Bus2IP_WrCE[41] || Bus2IP_WrCE[42] || Bus2IP_WrCE[43] || Bus2IP_WrCE[44] || Bus2IP_WrCE[45] || Bus2IP_WrCE[46] || Bus2IP_WrCE[47] || Bus2IP_WrCE[48] || Bus2IP_WrCE[49] || Bus2IP_WrCE[50] || Bus2IP_WrCE[51] || Bus2IP_WrCE[52] || Bus2IP_WrCE[53] || Bus2IP_WrCE[54] || Bus2IP_WrCE[55] || Bus2IP_WrCE[56] || Bus2IP_WrCE[57] || Bus2IP_WrCE[58] || Bus2IP_WrCE[59] || Bus2IP_WrCE[60] || Bus2IP_WrCE[61] || Bus2IP_WrCE[62] || Bus2IP_WrCE[63] || Bus2IP_WrCE[64] || Bus2IP_WrCE[65] || Bus2IP_WrCE[66] || Bus2IP_WrCE[67] || Bus2IP_WrCE[68] || Bus2IP_WrCE[69] || Bus2IP_WrCE[70] || Bus2IP_WrCE[71] || Bus2IP_WrCE[72] || Bus2IP_WrCE[73] || Bus2IP_WrCE[74] || Bus2IP_WrCE[75] || Bus2IP_WrCE[76] || Bus2IP_WrCE[77] || Bus2IP_WrCE[78] || Bus2IP_WrCE[79] || Bus2IP_WrCE[80] || Bus2IP_WrCE[81] || Bus2IP_WrCE[82],
    slv_read_ack      = Bus2IP_RdCE[0] || Bus2IP_RdCE[1] || Bus2IP_RdCE[2] || Bus2IP_RdCE[3] || Bus2IP_RdCE[4] || Bus2IP_RdCE[5] || Bus2IP_RdCE[6] || Bus2IP_RdCE[7] || Bus2IP_RdCE[8] || Bus2IP_RdCE[9] || Bus2IP_RdCE[10] || Bus2IP_RdCE[11] || Bus2IP_RdCE[12] || Bus2IP_RdCE[13] || Bus2IP_RdCE[14] || Bus2IP_RdCE[15] || Bus2IP_RdCE[16] || Bus2IP_RdCE[17] || Bus2IP_RdCE[18] || Bus2IP_RdCE[19] || Bus2IP_RdCE[20] || Bus2IP_RdCE[21] || Bus2IP_RdCE[22] || Bus2IP_RdCE[23] || Bus2IP_RdCE[24] || Bus2IP_RdCE[25] || Bus2IP_RdCE[26] || Bus2IP_RdCE[27] || Bus2IP_RdCE[28] || Bus2IP_RdCE[29] || Bus2IP_RdCE[30] || Bus2IP_RdCE[31] || Bus2IP_RdCE[32] || Bus2IP_RdCE[33] || Bus2IP_RdCE[34] || Bus2IP_RdCE[35] || Bus2IP_RdCE[36] || Bus2IP_RdCE[37] || Bus2IP_RdCE[38] || Bus2IP_RdCE[39] || Bus2IP_RdCE[40] || Bus2IP_RdCE[41] || Bus2IP_RdCE[42] || Bus2IP_RdCE[43] || Bus2IP_RdCE[44] || Bus2IP_RdCE[45] || Bus2IP_RdCE[46] || Bus2IP_RdCE[47] || Bus2IP_RdCE[48] || Bus2IP_RdCE[49] || Bus2IP_RdCE[50] || Bus2IP_RdCE[51] || Bus2IP_RdCE[52] || Bus2IP_RdCE[53] || Bus2IP_RdCE[54] || Bus2IP_RdCE[55] || Bus2IP_RdCE[56] || Bus2IP_RdCE[57] || Bus2IP_RdCE[58] || Bus2IP_RdCE[59] || Bus2IP_RdCE[60] || Bus2IP_RdCE[61] || Bus2IP_RdCE[62] || Bus2IP_RdCE[63] || Bus2IP_RdCE[64] || Bus2IP_RdCE[65] || Bus2IP_RdCE[66] || Bus2IP_RdCE[67] || Bus2IP_RdCE[68] || Bus2IP_RdCE[69] || Bus2IP_RdCE[70] || Bus2IP_RdCE[71] || Bus2IP_RdCE[72] || Bus2IP_RdCE[73] || Bus2IP_RdCE[74] || Bus2IP_RdCE[75] || Bus2IP_RdCE[76] || Bus2IP_RdCE[77] || Bus2IP_RdCE[78] || Bus2IP_RdCE[79] || Bus2IP_RdCE[80] || Bus2IP_RdCE[81] || Bus2IP_RdCE[82];

  // implement slave model register(s)
  always @( posedge Bus2IP_Clk )
    begin: SLAVE_REG_WRITE_PROC

      if ( Bus2IP_Reset == 1 )
        begin
          slv_reg0  <= 0; slv_reg1  <= 0; slv_reg2  <= 0;
          slv_reg3  <= 0; slv_reg4  <= 0; slv_reg5  <= 0;
          slv_reg6  <= 0; slv_reg7  <= 0; slv_reg8  <= 0;
			 slv_reg9  <= 0; slv_reg10 <= 0; slv_reg11 <= 0;
          slv_reg12 <= 0; slv_reg13 <= 0; slv_reg14 <= 0;
          slv_reg15 <= 0; slv_reg16 <= 0; slv_reg17 <= 0; slv_reg18 <= 0;
          slv_reg19 <= 0; slv_reg20 <= 0; slv_reg21 <= 0; slv_reg22 <= 0;
          slv_reg23 <= 0; slv_reg24 <= 0; slv_reg25 <= 0; slv_reg26 <= 0;
          slv_reg27 <= 0; slv_reg28 <= 0; slv_reg29 <= 0; slv_reg30 <= 0; 
			 slv_reg31 <= 0; slv_reg32 <= 0; slv_reg33 <= 0; slv_reg34 <= 0;
			 slv_reg35 <= 0; slv_reg36 <= 0; slv_reg37 <= 0; slv_reg38 <= 0; 
			 slv_reg39 <= 0; slv_reg40 <= 0; slv_reg41 <= 0; slv_reg42 <= 0; 
			 slv_reg43 <= 0; slv_reg44 <= 0; slv_reg45 <= 0;
          slv_reg46 <= 0; slv_reg47 <= 0; slv_reg48 <= 0;
          slv_reg49 <= 0; slv_reg50 <= 0; slv_reg51 <= 0;
          slv_reg52 <= 0; slv_reg53 <= 0; slv_reg54 <= 0; slv_reg55 <= 0;
          slv_reg56 <= 0; slv_reg57 <= 0; slv_reg58 <= 0;
          slv_reg59 <= 0; slv_reg60 <= 0; slv_reg61 <= 0; slv_reg62 <= 0; 
			 slv_reg63 <= 0; slv_reg64 <= 0; slv_reg65 <= 0; slv_reg66 <= 0; 
			 slv_reg67 <= 0; slv_reg68 <= 0; slv_reg69 <= 0; slv_reg70 <= 0;
			 slv_reg71 <= 0; slv_reg72 <= 0; slv_reg73 <= 0; slv_reg74 <= 0;
          slv_reg75 <= 0; slv_reg76 <= 0; slv_reg77 <= 0; slv_reg78 <= 0;
          slv_reg79 <= 0; slv_reg80 <= 0; slv_reg81 <= 0; slv_reg82 <= 0;
        end
      else
        case ( slv_reg_write_sel )
          83'b10000000000000000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg0[bit_index] <= Bus2IP_Data[bit_index];
          83'b01000000000000000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg1[bit_index] <= Bus2IP_Data[bit_index];
          83'b00100000000000000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg2[bit_index] <= Bus2IP_Data[bit_index];
          83'b00010000000000000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg3[bit_index] <= Bus2IP_Data[bit_index];
          83'b00001000000000000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg4[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000100000000000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg5[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000010000000000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg6[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000001000000000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg7[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000100000000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg8[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000010000000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg9[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000001000000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg10[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000100000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg11[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000010000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg12[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000001000000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg13[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000100000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg14[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000010000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg15[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000001000000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg16[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000100000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg17[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000010000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg18[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000001000000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg19[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000100000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg20[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000010000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg21[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000001000000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg22[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000100000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg23[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000010000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg24[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000001000000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg25[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000100000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg26[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000010000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg27[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000001000000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg28[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000100000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg29[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000010000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg30[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000001000000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg31[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000100000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg32[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000010000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg33[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000001000000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg34[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000100000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg35[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000010000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg36[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000001000000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg37[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000100000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg38[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000010000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg39[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000001000000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg40[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000100000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg41[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000010000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg42[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000001000000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg43[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000100000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg44[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000010000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg45[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000001000000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg46[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000100000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg47[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000010000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg48[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000001000000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg49[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000100000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg50[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000010000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg51[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000001000000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg52[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000100000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg53[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000010000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg54[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000001000000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg55[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000100000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg56[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000010000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg57[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000001000000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg58[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000100000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg59[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000010000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg60[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000001000000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg61[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000100000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg62[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000010000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg63[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000001000000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg64[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000100000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg65[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000010000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg66[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000001000000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg67[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000100000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg68[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000010000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg69[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000001000000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg70[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000100000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg71[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000010000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg72[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000001000000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg73[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000000100000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg74[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000000010000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg75[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000000001000000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg76[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000000000100000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg77[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000000000010000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg78[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000000000001000 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg79[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000000000000100 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg80[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000000000000010 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg81[bit_index] <= Bus2IP_Data[bit_index];
          83'b00000000000000000000000000000000000000000000000000000000000000000000000000000000001 :
            for ( byte_index = 0; byte_index <= (C_SLV_DWIDTH/8)-1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                for ( bit_index = byte_index*8; bit_index <= byte_index*8+7; bit_index = bit_index+1 )
                  slv_reg82[bit_index] <= Bus2IP_Data[bit_index];
          default : ;
        endcase
    end // SLAVE_REG_WRITE_PROC

  // implement slave model register read mux
  always @( slv_reg_read_sel or slv_reg0 or slv_reg1 or slv_reg2 or slv_reg3 or slv_reg4 or slv_reg5 or slv_reg6 or slv_reg7 or slv_reg8 or slv_reg9 or slv_reg10 or slv_reg11 or slv_reg12 or slv_reg13 or slv_reg14 or slv_reg15 or slv_reg16 or slv_reg17 or slv_reg18 or slv_reg19 or slv_reg20 or slv_reg21 or slv_reg22 or slv_reg23 or slv_reg24 or slv_reg25 or TEST1 or slv_reg27 or TEST3 or ACK or slv_reg30 or DataRead_I2C or slv_reg32 or slv_reg33 or slv_reg34 or slv_reg35 or slv_reg36 or slv_reg37 or slv_reg38 or slv_reg39 or slv_reg40 or slv_reg41 or slv_reg42 or slv_reg43 or slv_reg44 or slv_reg45 or slv_reg46 or slv_reg47 or slv_reg48 or slv_reg49 or slv_reg50 or slv_reg51 or slv_reg52 or slv_reg53 or slv_reg54 or slv_reg55 or slv_reg56 or slv_reg57 or slv_reg58 or slv_reg59 or slv_reg60 or slv_reg61 or slv_reg62 or slv_reg63 or slv_reg64 or slv_reg65 or slv_reg66 or slv_reg67 or slv_reg68 or slv_reg69 or slv_reg70 or slv_reg71 or slv_reg72 or slv_reg73 or slv_reg74 or slv_reg75 or slv_reg76 or slv_reg77 or slv_reg78 or slv_reg79 or column_max or line_max or slv_reg82 )
    begin: SLAVE_REG_READ_PROC

      case ( slv_reg_read_sel )
        83'b10000000000000000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg0;
        83'b01000000000000000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg1;
        83'b00100000000000000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg2;
        83'b00010000000000000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg3;
        83'b00001000000000000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg4;
        83'b00000100000000000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg5;
        83'b00000010000000000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg6;
        83'b00000001000000000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg7;
        83'b00000000100000000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg8;
        83'b00000000010000000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg9;
        83'b00000000001000000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg10;
        83'b00000000000100000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg11;
        83'b00000000000010000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg12;
        83'b00000000000001000000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg13;
        83'b00000000000000100000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg14;
        83'b00000000000000010000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg15;
        83'b00000000000000001000000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg16;
        83'b00000000000000000100000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg17;
        83'b00000000000000000010000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg18;
        83'b00000000000000000001000000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg19;
        83'b00000000000000000000100000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg20;
        83'b00000000000000000000010000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg21;
        83'b00000000000000000000001000000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg22;
        83'b00000000000000000000000100000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg23;
        83'b00000000000000000000000010000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg24;
        83'b00000000000000000000000001000000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg25;
        83'b00000000000000000000000000100000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= TEST1;
        83'b00000000000000000000000000010000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg27;
        83'b00000000000000000000000000001000000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= TEST3;
        83'b00000000000000000000000000000100000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= ACK;
        83'b00000000000000000000000000000010000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg30;
        83'b00000000000000000000000000000001000000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= DataRead_I2C;
        83'b00000000000000000000000000000000100000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg32;
        83'b00000000000000000000000000000000010000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg33;
        83'b00000000000000000000000000000000001000000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg34;
        83'b00000000000000000000000000000000000100000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg35;
        83'b00000000000000000000000000000000000010000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg36;
        83'b00000000000000000000000000000000000001000000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg37;
        83'b00000000000000000000000000000000000000100000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg38;
        83'b00000000000000000000000000000000000000010000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg39;
        83'b00000000000000000000000000000000000000001000000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg40;
        83'b00000000000000000000000000000000000000000100000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg41;
        83'b00000000000000000000000000000000000000000010000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg42;
        83'b00000000000000000000000000000000000000000001000000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg43;
        83'b00000000000000000000000000000000000000000000100000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg44;
        83'b00000000000000000000000000000000000000000000010000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg45;
        83'b00000000000000000000000000000000000000000000001000000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg46;
        83'b00000000000000000000000000000000000000000000000100000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg47;
        83'b00000000000000000000000000000000000000000000000010000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg48;
        83'b00000000000000000000000000000000000000000000000001000000000000000000000000000000000 : slv_ip2bus_data <= slv_reg49;
        83'b00000000000000000000000000000000000000000000000000100000000000000000000000000000000 : slv_ip2bus_data <= slv_reg50;
        83'b00000000000000000000000000000000000000000000000000010000000000000000000000000000000 : slv_ip2bus_data <= slv_reg51;
        83'b00000000000000000000000000000000000000000000000000001000000000000000000000000000000 : slv_ip2bus_data <= slv_reg52;
        83'b00000000000000000000000000000000000000000000000000000100000000000000000000000000000 : slv_ip2bus_data <= slv_reg53;
        83'b00000000000000000000000000000000000000000000000000000010000000000000000000000000000 : slv_ip2bus_data <= slv_reg54;
        83'b00000000000000000000000000000000000000000000000000000001000000000000000000000000000 : slv_ip2bus_data <= slv_reg55;
        83'b00000000000000000000000000000000000000000000000000000000100000000000000000000000000 : slv_ip2bus_data <= slv_reg56;
        83'b00000000000000000000000000000000000000000000000000000000010000000000000000000000000 : slv_ip2bus_data <= slv_reg57;
        83'b00000000000000000000000000000000000000000000000000000000001000000000000000000000000 : slv_ip2bus_data <= slv_reg58;
        83'b00000000000000000000000000000000000000000000000000000000000100000000000000000000000 : slv_ip2bus_data <= slv_reg59;
        83'b00000000000000000000000000000000000000000000000000000000000010000000000000000000000 : slv_ip2bus_data <= slv_reg60;
        83'b00000000000000000000000000000000000000000000000000000000000001000000000000000000000 : slv_ip2bus_data <= slv_reg61;
        83'b00000000000000000000000000000000000000000000000000000000000000100000000000000000000 : slv_ip2bus_data <= slv_reg62;
        83'b00000000000000000000000000000000000000000000000000000000000000010000000000000000000 : slv_ip2bus_data <= slv_reg63;
        83'b00000000000000000000000000000000000000000000000000000000000000001000000000000000000 : slv_ip2bus_data <= slv_reg64;
        83'b00000000000000000000000000000000000000000000000000000000000000000100000000000000000 : slv_ip2bus_data <= slv_reg65;
        83'b00000000000000000000000000000000000000000000000000000000000000000010000000000000000 : slv_ip2bus_data <= slv_reg66;
        83'b00000000000000000000000000000000000000000000000000000000000000000001000000000000000 : slv_ip2bus_data <= slv_reg67;
        83'b00000000000000000000000000000000000000000000000000000000000000000000100000000000000 : slv_ip2bus_data <= slv_reg68;
        83'b00000000000000000000000000000000000000000000000000000000000000000000010000000000000 : slv_ip2bus_data <= slv_reg69;
        83'b00000000000000000000000000000000000000000000000000000000000000000000001000000000000 : slv_ip2bus_data <= slv_reg70;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000100000000000 : slv_ip2bus_data <= slv_reg71;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000010000000000 : slv_ip2bus_data <= slv_reg72;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000001000000000 : slv_ip2bus_data <= slv_reg73;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000000100000000 : slv_ip2bus_data <= slv_reg74;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000000010000000 : slv_ip2bus_data <= slv_reg75;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000000001000000 : slv_ip2bus_data <= slv_reg76;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000000000100000 : slv_ip2bus_data <= slv_reg77;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000000000010000 : slv_ip2bus_data <= slv_reg78;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000000000001000 : slv_ip2bus_data <= slv_reg79;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000000000000100 : slv_ip2bus_data <= column_max;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000000000000010 : slv_ip2bus_data <= line_max;
        83'b00000000000000000000000000000000000000000000000000000000000000000000000000000000001 : slv_ip2bus_data <= slv_reg82;
        default : slv_ip2bus_data <= 0;
      endcase

    end // SLAVE_REG_READ_PROC

  // ------------------------------------------------------------
  // Example code to drive IP to Bus signals
  // ------------------------------------------------------------

  assign IP2Bus_Data    = slv_ip2bus_data;
  assign IP2Bus_WrAck   = slv_write_ack;
  assign IP2Bus_RdAck   = slv_read_ack;
  assign IP2Bus_Error   = 0;

endmodule
