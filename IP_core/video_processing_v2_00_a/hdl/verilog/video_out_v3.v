/////////////////////////////////////////////////////////////////////////////////////////
// Company: Gdansk University of Technology
// Engineer: Adam Drawc 
// Create Date:    22:33:12 10/12/2018 
// Design Name: 	 Version_4
// Module Name:    VIDEO_OUT3
// Project Name:   Hardware video processing path in FPGA
// Target Devices: XUPV5/ML509
// Tool versions:  14.7
// Description: 	 Module for outputing video data in format acceptable by Ch7301C
// Additional Comments: 
//	: Version_1 : DVI compliant with CH7301C.
//   Version_2 : Changed DVI to VGA.
//   Version_3 : Added data coming from internal memory.
//	  Version_4 : Improved control over memory transmission. 	 	
/////////////////////////////////////////////////////////////////////////////////////////
// This module was designed to transmit data to codec CH7301C in an externally sourced VGA resolution.
// Data's source can be anything as long as it is complinant with dimensions of 128x128x3.
// Originally and for the purpose of this project actual resolution is 640x480@75Hz. Incoming data
// is smaller in volume than 640x480 so everything except a central square containing valid data is 
// in white colour.
//
// This module is highly configurable. Resolution can be programmed.
// Work modes are as stated below:
//		1) Transmitted is only one colour chosen beforehand. Configurable position of this colour
// 	2) Source of data is memory. Processed data is in the center. Rest is white.
//
// Functions only when the lines video_ACK_i, VLD_VIDEO_i and vld_mem_i are in high state.
// These signals describe accordingly the state of configuration, validity of input video and 
// data in the output memory.
//
// Since CH7301C requires a differential clock with frequency equal to double pixel clock PLL
// was added into the module as a submodule. It generates three clocks, two for the diffclock
// (clk2_ph0_i, clk2_ph2_i) and one which upholds setup and hold time specifications between
// data and clock lines (clk2_ph1_i). The difference in phase between clocks is 45 degrees.
//
// Though resolution can be changed through the MicroBlaze it is not really an ideal change.
// PLL is set to always convert an input clock of 100MHz to 63MHz. It is advised to use it only
// for resolution 640x480@75Hz if no changes to the PLL settings are done.
//
// Memory control is done as in every other module. This version is a counterpart of the write
// process in the CPS_v3 module.
//
/////////////////////////////////////////////////////////////////////////////////////////
module VIDEO_OUT3
(	
	input	wire clk_i,
	input wire rst_i,
	//BRAM3
	input wire [383:0] doutb_bram3_i,
	output reg [6:0] addrb_bram3_o,
	output wire clkb_bram3_o,
	//CTRL
	input wire full_i,
	input wire video_ACK_i,
	input wire VLD_VIDEO_i,
	input wire vld_mem_i,
	output reg empty_o,
	//VIDEO_Codec
	output reg [11:0] vga_d_o,
	output reg vga_de_o,
	output reg vga_hsync_o,
	output reg vga_vsync_o,
	output wire x_clk_p_o,
	output wire x_clk_n_o,
	//CONFIG
	input wire [9 :0] H_FP,H_BP,H_sync,H_VldDat,COLUMNS,
	input wire [9 :0] V_FP,V_BP,V_sync,V_VldDat,LINES,
	input wire H_active,V_active,
	input wire [23:0] Color,
	input wire [9:0] HighLine,LowLine,HighCol,LowCol,
	input wire VideoInputActive);
	
	//PARAMS
	localparam 	color_background	= 12'hFFF;
	localparam 	LowLineProc			= 11'd195,
					HighLineProc		= 11'd323,
					LowColProc			= 11'd455,
					HighColProc			= 11'd583;
	
	//Regs
	reg 			temp_col;
	reg [10:0] 	column, line;
	reg [383:0] row2display, shift_reg;
	reg 			readLineProc, readColProc; 
	
	//Wires
	wire 			ALL_VLD, LOCKED_OUT;
	wire 			clk2_ph0_i, clk2_ph2_i, data_clk;
	
	//Instances
	dviPLL4 PLL(clk_i, 		//100MHz->63MHz
					rst_i, 
					clk2_ph0_i, //phase 0  
					data_clk, 	//phase pi/2
					clk2_ph2_i, //phase pi
					LOCKED_OUT);
	
	//Combinational
	//Assigns
	assign x_clk_p_o			= clk2_ph0_i;		
	assign x_clk_n_o 			= clk2_ph2_i;
	assign ALL_VLD 			= (VideoInputActive)?LOCKED_OUT & VLD_VIDEO_i & video_ACK_i & vld_mem_i : LOCKED_OUT & video_ACK_i;
	assign clkb_bram3_o 		= ~vga_hsync_o; 

	//Sequential
	//ADDRES SWEEP
	always @(negedge clkb_bram3_o or posedge rst_i) 
	begin
		if(rst_i)
		begin
			addrb_bram3_o	<= 0;
			empty_o			<= 1;
		end
		else
		begin
			if( ALL_VLD )
			begin
				if( full_i )
				begin
					empty_o	<= 0;
				end
				else
				begin
					if( readLineProc )
					begin
						if( addrb_bram3_o != 7'd126 )
						begin
							empty_o			<= 1'b0;
							addrb_bram3_o	<= addrb_bram3_o+1'b1;
						end
						else
						begin
							empty_o	<= 1'b1;
						end
					end
					else
					begin
						if( ~vga_vsync_o && addrb_bram3_o == 7'd126)
						begin
							empty_o			<= 1'b1;
							addrb_bram3_o	<= 0;
						end
					end
				end
			end
		end
	end
	
	//DATA READ
	always @(negedge clkb_bram3_o or posedge rst_i)
	begin
		if(rst_i)
		begin
			row2display	<= 0;
		end
		else
		begin
			if( ALL_VLD )
			begin
				if( empty_o == 1'b0 && readLineProc )
				begin
					row2display	<= doutb_bram3_i;
				end			
				else row2display	<= 0;			
			end	
		end
	end

	//Column,Line Sweep
	always @(posedge x_clk_p_o or posedge rst_i)
	begin
		if(rst_i)
		begin
			temp_col			<= 1'b0;
			column			<= 0;
			line				<= 0;
			readLineProc	<= 1'b0;
			readColProc		<= 1'b0;
		end
		else
		begin
			if( ALL_VLD )
			begin
				if( line != LINES )
				begin
					if( column != COLUMNS )
					begin
						temp_col	<= temp_col + 1;
						if( temp_col == 1'b1 )
						begin
							column	<= column + 1'b1;
							temp_col	<= 1'b0;
						end
					end
					else
					begin
						line		<= line + 1'b1;
						column	<= 0;
					end	
				end
				else 
				begin
					line		<= 0;
					column	<= 0;	
				end

				if( line == LowLineProc ) readLineProc	<= 1'b1;
				else if( line == HighLineProc ) readLineProc	<= 1'b0;
				
				if( column == LowColProc ) readColProc	<= 1'b1;
				else if( column == HighColProc ) readColProc	<= 1'b0;
				
			end		
		end
	end
	
	//Data,SyncSignals Control
	always @(negedge data_clk or posedge rst_i)
	begin
		if(rst_i)
		begin
			vga_hsync_o		<= ~H_active;
			vga_vsync_o		<= ~V_active;
			vga_de_o			<= 1'b0;
			vga_d_o			<= 12'h000;
			shift_reg		=  0;
		end
		else
		begin
			if(ALL_VLD)
			begin
				//STEROWANIE KOLOREM
				if( vga_de_o )
				begin
					if( VideoInputActive )
					begin
						if( readLineProc ) 
						begin
							if( readColProc ) 
								begin
								if( temp_col ) 
								begin
									vga_d_o[11:7]		<= { shift_reg[383],4'b1001 };	// R7-R3 [11:7]	
									vga_d_o[6:4]		<= { shift_reg[382],2'b10 };		// G7-G5 [6:4]
									vga_d_o[3:1]		<= 3'b111; 								// R2-R0
									vga_d_o[0]			<= 1'b1; 								// G1
								end
								else
								begin
									vga_d_o[11:9]		<= 3'b011; 							// G4-G2
									vga_d_o[8:4]		<= {shift_reg[381],4'b1001};	// B7-B3 
									vga_d_o[3]			<= 1'b1;								// G0
									vga_d_o[2:0]		<= 3'b111;							// B2-B0
									
									shift_reg[383:3]	 =  shift_reg[380:0];
									shift_reg[2:0]		 =  3'b000;	
								end
							end
							else vga_d_o<=color_background;
						end
						else vga_d_o<=color_background;
					end
					else
					begin
						if( line>(V_FP+V_BP+V_sync+LowLine-1) && line <= (V_FP+V_BP+V_sync+HighLine) )
						begin
							if( column>(H_FP+H_BP+H_sync+LowCol) && column<= (H_FP+H_BP+H_sync+HighCol) )
							begin
								if( temp_col ) vga_d_o<=Color[11:0]; 
								else  vga_d_o<=Color[23:12];
							end
							else vga_d_o<=color_background;
						end
						else
						begin
							vga_d_o<=color_background;
						end
					end	
				end
				else
				begin
					vga_d_o<=12'h000;
				end
			
				//zatrzasniecie danych
				if(~vga_hsync_o) //active
				begin
					shift_reg=row2display;
				end
				
				//sterowanie Data_enable
				if(line >(V_FP-1+ V_sync+V_BP))
				begin
					if(column>(H_FP+H_BP+H_sync))	vga_de_o<=1'b1; 					
					else vga_de_o<=1'b0;	
				end
				else vga_de_o<=1'b0;
				
				//sterowanie Hsync
				if(column>(H_FP-1) && column<(H_FP+H_sync) ) vga_hsync_o<=H_active; 
				else vga_hsync_o<=~H_active;	
				
				//Sterowanie Vsync
				if(line>(V_FP-1) && line<(V_FP+V_sync))
				begin 
					vga_vsync_o<=V_active; 
				end
				else vga_vsync_o<=~V_active;
			end
			else
			begin
				vga_hsync_o<=~H_active;
				vga_vsync_o<=~V_active;
				vga_de_o<=1'b0;
				vga_d_o<=12'h000;
				shift_reg=0;
			end
		end
	end
endmodule
