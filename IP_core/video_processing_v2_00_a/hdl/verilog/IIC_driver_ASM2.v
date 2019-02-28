//////////////////////////////////////////////////////////////////////////////////
// Company: Gdansk University of Technology
// Engineer: Adam Drawc 
// Create Date:    16:00:24 09/22/2018 
// Design Name: 	 Version_2
// Module Name:    iic_videobus_driver 
// Project Name:   Hardware video processing path in FPGA
// Target Devices: XUPV5/ML509
// Tool versions:  14.7
// Description: IIC bus driver for programming codecs(CH7301C, AD9980) 
// Additional Comments: 
//		: Version_2 : BusMASTER able to read, write and send errors [ASM]
//////////////////////////////////////////////////////////////////////////////////
// This module acts as a iic bus master only. Steers both of the bus lines.
// Line SDA is bidirectional, line SCL not because programming only happens in one way
// which elminates the need. Whole module works with maximal frequencies stated in 
// documentations of both codecs (CH7301C, AD9980). Using those components limits the speed
// to 100kbps. Both operations (read & write ) were added.
//
// Reactions on negative ACK from SLAVE devices was implemented. After module has recognised
// that there was an error on the line it will stop actual and further transmission 
// Proper data regarding the error will be sent to the MicroBlaze and displayed for the user.
// In this version (Version_2) error information contains the location of the negative ACK
// which allows to properly analise in what moment IIC transmissions doesn't work.
//
// This version of the IIC works only for devices that have no restriction on the 
// Hold time on the SDA line. In this project both devices have zero nanoseconds required 
// on the hold time thus state on the SDA changes instantaniously with the falling 
// edge of the SCL clock.

// Ports:
// rst_i 	- External Reset
//	clk_i 	- External Clock
//	DA_i 		- Device Adress 
//	RA_i 		- Register Adress
//	data_i	- Data to be written (used for write transmissions) 
// data_o	- Data read 
//	SDA_io_I - I2C data input
//	SDA_io_O	- I2C data output
//	SDA_io_T	- I2C data directional pin
//	SCL_o		- I2C data clock 
//	vld_i		- External Valid 
//	rdy_o		- Ready
//	ACK_o		- Vector containing location of the lack of ACK in case of an Error
//	TEST2		- General purpose test pin
//  
// ASM 
// When the request for transmission, in a form of high state on line vld_i, appears
// ASM starts changing states. It does so in an organised manner going from 
// one to the next in a straight line. However there are exceptions. As of this version 
// IIC transmission regardless of the operation will always have the same start. 
// To comply with codec documentations, first Device Adress sent will always have 
// the last bit (R/nW) equal '0'. Therefore to maintain this in the state machine 
// first DA has '0' as a last bit. Informations about the transmission are in the 
// Ch7301C documentation. 
// ASM has a redundant number of states which was designed intentionally and only for 
// the easier testing resulting in an easier to analise structure.
//////////////////////////////////////////////////////////////////////////////////

module IIC_driver_ASM2(
	rst_i,
	clk_i,
	DA_i,
	RA_i,
	data_i,
	SDA_io_I,
	SDA_io_O,
	SDA_io_T,
	SCL_o,
	vld_i,
	rdy_o,
	data_o,
	ACK_o,
	TEST2
	);

	//Params:
	localparam //VALID
				  VALID=2'b10,	
				  //Memory operations
				  READ=1'b1,
				  WRITE=1'b0,
				  //SDA_io Directions
				  IN=1'b1,
				  OUT=1'b0,
				  //ASM States
				  IDLE=4'b0000,
				  START=4'b0001,
				  DAB=4'b0010,
				  SACK=4'b0011,
				  RAB=4'b0100,
				  SACK2=4'b0101,
				  RESTART=4'b0110,
				  DATA_W=4'b0111,
				  SACK3=4'b1000,
				  DAB_R=4'b1001,
				  SACK4=4'b1010,
				  DATA_R=4'b1011,
				  MACK=4'b1100,
				  STOP=4'b1101,
				  SLACK=4'b1110;
				  
	//Ports:
	input wire rst_i,clk_i,vld_i;
	input wire [7:0] DA_i,data_i,RA_i;
	output wire [31:0] TEST2; //TEST

	output reg rdy_o				=	1'b1;
	output reg [31:0] data_o	=	32'd0;
	output reg [31:0] ACK_o		=	32'd0; 
	
	//I2C Ports
	output wire SCL_o;
	input SDA_io_I; 	
	output reg SDA_io_O;
	output wire SDA_io_T;
	
	//Regs
	reg dir=OUT;
	reg start_out=1'b0;
	reg [8:0] data_temp=9'h000;
	reg [3:0] state=IDLE;
	reg [2:0] index_w = 3'h7;
	reg [3:0] index_r = 4'h8;
	reg [2:0] index_ack =3'b000;
	reg SCL_o_en=1'b0;
	reg [1:0] vld_temp=2'b11;
	reg [31:0] ACK=32'd0;
	
	//Assigns
	assign SCL_o    = (SCL_o_en==1'b1) ? ~clk_i : (start_out==1'b0 && state==DAB)? 1'b0 :1'b1 ;
	assign SDA_io_T = dir;
	assign TEST2	 = index_r;

	//Read performed on the SDA line
	always @(negedge clk_i or posedge rst_i)
	begin
		if(rst_i)
		begin
			data_temp<=9'h000;
			ACK<=32'd0;
		end
		else
		begin
			if(state==DATA_R) data_temp[index_r]<=SDA_io_I;
			
			if((state==RAB && index_w==3'h7 ) || (state==DATA_W && index_w==3'h7)  || (state==DATA_R && index_r==4'h8 ) /*|| state==RESTART*/ ||state==SLACK)
			begin
				ACK[index_ack]<=SDA_io_I;
				index_ack<=index_ack+1'b1;
			end
			else
			begin
				if(state==IDLE || state==STOP)
				begin
					index_ack<=0;
				end
			end	
		end
	end
	
	//SDA, SCL Control
	always@( posedge clk_i or posedge rst_i)
	begin
		if(rst_i)
		begin
			index_r<=4'h8;
			index_w<=3'h7;
			state<=IDLE;
			SDA_io_O<=1'b1; 
			dir<=OUT;
			vld_temp<=2'b11;
			rdy_o<=1;
			data_o<=32'd0;
			SCL_o_en<=1'b0;
			ACK_o<=32'd0;
			start_out<=1'b0;
		end
		else
		begin
			vld_temp[0]<=vld_i;
			vld_temp[1]<=vld_temp[0];
			
			if(vld_temp==VALID)
			begin
				rdy_o<=1'b0;
			end
			case(state)
			IDLE:	begin
						dir<=OUT;
						SDA_io_O<=1'b1;
						start_out<=1'b0;
						if(~rdy_o) state<=START;
						else state<=IDLE;
					end
			START:begin
						SDA_io_O<=1'b0;
						index_w<=3'h7;
						if(start_out)
						begin
							state<=DAB;
							start_out<=1'b0;
						end
						else
						begin
							start_out<=1'b1;
						end
					end
			DAB:	begin
						SDA_io_O<=DA_i[index_w];
						if(index_w>3'h0) 
						begin
							state<=DAB;
							index_w<=index_w-1;
						end
						else
						begin
							SDA_io_O<=1'b0;
							state<=SACK;	
						end								
					end
			SACK:	begin
						dir<=IN;
						index_w<=3'h7;
						state<=RAB;
					end	
			RAB:	begin
						dir<=OUT;
						SDA_io_O<=RA_i[index_w];
						if(index_w>3'h0) 
						begin
							state<=RAB;
							index_w<=index_w-1;
						end
						else state<=SACK2;
					end
			SACK2:begin
						dir<=IN;
						if(DA_i[0]==WRITE) 
						begin
							state<=DATA_W;
							index_w<=3'h7;
						end
						else state<=SLACK;							
					end
			DATA_W:begin
						dir<=OUT;
						SDA_io_O<=data_i[index_w];
						if(index_w>3'h0)
						begin
							state<=DATA_W;
							index_w<=index_w-1;
						end
						else state<=SACK3;
					end
			SACK3:begin
						dir<=IN;
						state<=STOP;
					end
			
			SLACK:begin //przejsciowy
						dir<=OUT;
						SDA_io_O<=1'b1;
						state<=RESTART;
					end
			RESTART:begin
						dir<=OUT;
						SDA_io_O<=1'b1; 
						if(index_w==3'h1)
						begin
							SDA_io_O<=1'b0; 
							index_w<=3'h7;
							state<=DAB_R;
						end
						else
						begin
							index_w<=3'h1;
							state<=RESTART;
						end
					end
			DAB_R:begin
						SDA_io_O<=DA_i[index_w]; 
						if(index_w>3'h0)
						begin
							state<=DAB_R;
							index_w<=index_w-1;
						end
						else state<=SACK4;
					end
			SACK4:begin
						dir<=IN;
						index_r<=4'h8;
						state<=DATA_R;
					end
			DATA_R:begin
						if(index_r>4'h0)
						begin
							state<=DATA_R;
							index_r<=index_r-1;
						end
						else 
						begin
							state<=STOP;
							dir<=OUT;
							SDA_io_O<=1'b1; 
						end	
					end
			STOP:	begin
						dir<=OUT;
						data_o<=data_temp[7:0];
						ACK_o<=ACK;
						SDA_io_O<=1'b0; 
						rdy_o<=1'b1;
						state<=IDLE;
					end		
			default : begin
							rdy_o<=1'b1;
							state<=IDLE;
						 end
			endcase	
			
			//noACK Reaction
			if(ACK[index_ack-1]) 
			begin
				state<=STOP;
			end
			
			//SCL Control
			if((state==IDLE)||(state==START)||(state==RESTART))
			begin
				SCL_o_en<=1'b0;
			end
			else SCL_o_en<=1'b1;		
		end
	end
endmodule
