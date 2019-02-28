//////////////////////////////////////////////////////////////////////////////////
// Company: 	Gdansk University of Technology
// Engineer: 	Adam Drawc 
// Create Date:    11:23:48 01/11/2019 
// Design Name: 	 Version_3
// Module Name:    video_in_v3 
// Project Name: 	 	Hardware video processing path in FPGA 
// Target Devices: 	ML509/XUPV5
// Tool versions:		ISE Design Suite 14.7
// Description: 		Module for aquiring video data from AD9980 input video codec
// Additional Comments: 
//	:	Version_3 : Valid with AD9980(One resolution [640x480],valid data 128x128, column&frame counter)
//////////////////////////////////////////////////////////////////////////////////
// This module was designed to detect a video format and select only valid
// (from the perspective of the project) chunk of the input video. It does so trough the addendum of 
// implemented counters and predefined limits. Whilst counting impulses on input lines  pixel_clk and 
// hsync_i. First one defines columns and the latter rows. Decides if the video has any format and
// accordindly sets an output vld_video_o to represent that what is visible at the input is a video 
// and not just irregular noise. After each frames counters are to be zeroed and when they pass the 
// limits are to input new sequentional data coming from the lines red_i,green_i and blue_i into a 
// shifting register (row2mem) that amounts to one whole row of data. If the limit conditions are 
// met each new row is to be send to the BRAM memory with the falling_edge of the hsync_i
// for further processing. Further processing only occurs when all rows were written to the memory.
// The comunnication with the processing module is maintainted through the lines rdy_i and vld_o.
//
// Ports in the group AD9980 relate to the lines coming out of the AD9980 input video Codec
//	Ports in the group BRAM are used to send rows to the Input BRAM and are BRAM compliant
// Port video_ACK_i is connected to the iic_master2 and signalises the end of the
// I2C Bus Configuration Stage
// Lastly column_max_o & line_max_o are used to send informations about the incoming video 
// format to the MicroBlaze as to enable testing 
//
//	Any shifting of the shift register only happens when all the conditions are met
// As of this version of the project what gets put into the Memory are rows of pixels 
// represented only by 3 bits which comes from the limitation put on the project by the OS 
// on which the development kit is operating. Windows XP only allows only 2GB of RAM to a single 
// program thus constraining the amount of components and their size that was to be put in the project.  
// 
// Counters are to count only when:
//		1) Configuration Stage has ended (video_ACK_i='1')
//		2) Vsync & Hsync has appeared at least once
//		3) Vsync & Hsync are not active
// Counters zero at the edges leading to an active state of the Vsync or Hsync
///////////////////////////////////////////////////////////////////////////////////
 module video_in_v3(
	//AD9980
	input  pixel_clk_i,rst_i,
	input  hsync_i,vsync_i,
	input  [7:0] red_i,
	input  [7:0] green_i,
	input  [7:0] blue_i,
	//BRAM
	output wire clka_bram12_o,
	output reg 	wea_bram12_o,
	output reg 	[6:0] addra_bram12_o,
	output reg [383:0] dina_bram12_o,
	output reg vld_o,
	output wire vld_video_o,
	input wire rdy_i,
	
	//CONFIG
	input video_ACK_i,
	
	//uB TEST
	output reg [10:0] column_max_o,
	output reg [10:0] line_max_o );
		
	//LocalParams
	localparam 	LowLineProc		=	11'd195,
					HighLineProc	=	11'd323,
					LowColProc		=	11'd415,
					HighColProc		=	11'd543;
	
	//Regs
	reg countV_en;
	reg countH_en;
	reg vld_line,vld_column;
	reg [1:0] temp_hsync;
	reg [1:0] temp_vsync;
	reg [12:0] line_counter;
	reg [12:0] column_counter;
	reg [383:0] row2mem; 
	
	//Wires
	wire vld_frame;

	//Assigns
	assign vld_video_o	= vld_frame; 
	assign vld_frame		= vld_column & vld_line;	
	assign clka_bram12_o = hsync_i;
	
	//SHIFT REG
	always @(posedge pixel_clk_i or posedge rst_i)
	begin
		if(rst_i)
		begin
			row2mem<=0;
		end
		else
		begin
			if(vld_frame && video_ACK_i)
			begin
				if( line_counter>LowLineProc && line_counter<HighLineProc) //185 314
				begin
					if( column_counter>LowColProc && column_counter<HighColProc)//355 484
					begin
						row2mem[2]		<=	red_i[7];	
						row2mem[1]		<=	green_i[7];	
						row2mem[0]		<=	blue_i[7];		
						row2mem[383:3]	<=	row2mem[380:0];
					end
				end
			end			
		end
	end
	
	//ADDRES SWEEP/MEMORY WRITE
	always @(negedge hsync_i or posedge rst_i) 
	begin
		if(rst_i)
		begin
			addra_bram12_o<=7'd0;
			wea_bram12_o<=0;
			dina_bram12_o<=0;
			vld_o<=0;
		end
		else
		begin
			if(vld_frame && video_ACK_i)
			begin
				if(~rdy_i) vld_o<=0;
				else
				begin
					if(addra_bram12_o==7'd126) vld_o<=1'b1;
				end	
				
				if( line_counter>LowLineProc && line_counter<HighLineProc )
				begin
					if(addra_bram12_o!=7'd127)
					begin
						addra_bram12_o<=addra_bram12_o+1'b1;
						dina_bram12_o<=row2mem;
						wea_bram12_o<=1'b1;
					end
					else
					begin
							wea_bram12_o<=1'b0;
					end
				end
				else
				begin
					wea_bram12_o<=1'b0;
					if(~vsync_i) addra_bram12_o<=0;
				end
			end
			else
			begin
				wea_bram12_o<=0;
			end
		end
	end
	
	//LINE COUNTER
	always @(posedge hsync_i or posedge rst_i) 
	begin
		if(rst_i)
		begin
			line_counter	<= 0;
			vld_line			<= 1'b0;
			line_max_o		<= 0;
			temp_vsync		<= 2'b00;
			countV_en		<= 1'b0;
		end
		else
		begin
			if( video_ACK_i)
			begin
				//Probing Vsync
				temp_vsync[0]	<= vsync_i;
				temp_vsync[1]	<= temp_vsync[0];
				
				if(temp_vsync==2'b10)
				begin
					countV_en	<= 1'b1;
					if(line_max_o == 0 && countV_en == 1'b1)
					begin
						line_max_o		<= line_counter;
						vld_line		<= 1'b1;
						line_counter	<= 0;
					end
					else line_counter<= 0;
				end
				else line_counter	<= line_counter + 1'b1; 
			end	
		end
	end
	
	//COLUMN COUNTER
	always @(posedge pixel_clk_i or posedge rst_i)
	begin
		if(rst_i)
		begin
			column_counter	<= 0;
			vld_column		<= 1'b0;
			column_max_o	<= 0;
			countH_en		<= 1'b0;
			temp_hsync		<= 2'b00;
		end
		else
		begin
			if(video_ACK_i)
			begin
				temp_hsync[0]<=hsync_i;
				temp_hsync[1]<=temp_hsync[0];
				if(vsync_i)
				begin
					if(temp_hsync == 2'b10 && countH_en == 0) countH_en	<= 1'b1; 
					else
					begin
						case(temp_hsync)
						2'b11  : begin

									column_counter	<= column_counter + 1'b1;

									end	
						2'b10  : begin
										if(column_max_o == 0)
										begin
											column_max_o	<= column_counter;
											vld_column		<= 1'b1;
											column_counter	<= 0;
										end
										else column_counter	<= 0;
									end	
						default: column_counter	<= 0;
						endcase
					end	
				end	
			end	
		end
	end
endmodule
