/////////////////////////////////////////////////////////////////////////////////////////
// Company: Gdansk University of Technology
// Engineer: Adam Drawc 
// Create Date:    22:33:12 10/05/2018 
// Design Name: 	 Version_4
// Module Name:    iic_master2 
// Project Name:   Hardware video processing path in FPGA
// Target Devices: XUPV5/ML509
// Tool versions:  14.7
// Description: 	 Master for iic_driver_ASM 
// Additional Comments: 
//	: Version_1 : CHRONTEL 7301C & AD9980  (Simple Config with tests)
//   Version_2 : CHRONTEL 7301C & AD9980  (Enhanced Config with tests)
//   Version_3 : CHRONTEL 7301C & AD9980  (Enhanced without tests + end of config signal)
//	  Version_4 : CHRONTEL 7301C & AD9980  (CSR inputted from uB, added the USE bit)
/////////////////////////////////////////////////////////////////////////////////////////
//This part (iic_master2) acts as a central component for aquirring and distriubuting valid adresses and 
//data over the I2C bus,in itself it does not steer the bus. Its only function is the sequentional transmit
// of incoming data from the Microblaze to the I2C bus master named IIC_driver_ASM2 IIC_BUS.
//It has two sub-modules, instance IIC_driver_ASM2 IIC_BUS and clk_div.
//Every command or a valid instruction to be transmitted shows up in the multitude of registers each with i2c_reg(n)
//n is a corresponding number. Group of those registers acts as a command buffer and the depth of the buffer is 120.
//Each command consists of 19 bits.  
//Bit 	[18] 		states the use of the command ,'0' means that the command won't be used;
//Bit 	[17] 		states which Slave is this command dedicated for, '0'=CH7301C ; '1'= AD9980;
//Bit 	[16] 		states the nature of the command, '0'=WRITE ; '1'=READ;
//Bits 	[15:8] 	define the adress of the register
//Bits	[7:0] 	define the data that will be trasmitted to the slave if the operation is of write nature
//
//For the transmitt as the number of operations is known after module parses through all of them the stage of I2C 
//Configurations will be done. iic_master2 will then send the vid_ACK_o signal (Logical '1') to the remaining hardware statng that
//both video codecs (CH7301C,Ad9980) were succesfully programmed. In other case it will stay as '0' and will hinder
//work of the hardware video processing path thus preventing any bugs or bad performance.
//////////////////////////////////////////////////////////////////////////////////////////
module iic_master2
	(     //GLOBAL
			input rst_i,
			input clk_i,
			//I2C
			input  SDA_io_I,
			output SDA_io_O,
			output SDA_io_T,
			output SCL_o,
			//CSR
			input CSR_DONE,
			input [18:0] i2c_reg0, 
			input [18:0] i2c_reg1,
			input [18:0] i2c_reg2,
			input [18:0] i2c_reg3, 
			input [18:0] i2c_reg4,
			input [18:0] i2c_reg5,
			input [18:0] i2c_reg6, 
			input [18:0] i2c_reg7,
			input [18:0] i2c_reg8,
			input [18:0] i2c_reg9, 
			input [18:0] i2c_reg10,
			input [18:0] i2c_reg11,
			input [18:0] i2c_reg12,
			input [18:0] i2c_reg13, 
			input [18:0] i2c_reg14,
			input [18:0] i2c_reg15,
			input [18:0] i2c_reg16, 
			input [18:0] i2c_reg17,
			input [18:0] i2c_reg18,
			input [18:0] i2c_reg19, 
			input [18:0] i2c_reg20,
			input [18:0] i2c_reg21,
			input [18:0] i2c_reg22, 
			input [18:0] i2c_reg23,
			input [18:0] i2c_reg24,
			input [18:0] i2c_reg25,
			input [18:0] i2c_reg26, 
			input [18:0] i2c_reg27,
			input [18:0] i2c_reg28,
			input [18:0] i2c_reg29, 
			input [18:0] i2c_reg30,
			input [18:0] i2c_reg31,
			input [18:0] i2c_reg32, 
			input [18:0] i2c_reg33,
			input [18:0] i2c_reg34,
			input [18:0] i2c_reg35, 
			input [18:0] i2c_reg36,
			input [18:0] i2c_reg37,
			input [18:0] i2c_reg38,
			input [18:0] i2c_reg39,
			input [18:0] i2c_reg40,
			input [18:0] i2c_reg41, 
			input [18:0] i2c_reg42,
			input [18:0] i2c_reg43,
			input [18:0] i2c_reg44, 
			input [18:0] i2c_reg45,
			input [18:0] i2c_reg46,
			input [18:0] i2c_reg47,
			input [18:0] i2c_reg48,
			input [18:0] i2c_reg49,
			input [18:0] i2c_reg50, 
			input [18:0] i2c_reg51,
			input [18:0] i2c_reg52,
			input [18:0] i2c_reg53,
			input [18:0] i2c_reg54, 
			input [18:0] i2c_reg55,
			input [18:0] i2c_reg56,
			input [18:0] i2c_reg57,
			input [18:0] i2c_reg58,
			input [18:0] i2c_reg59,
			//TEST
			output reg vid_ACK_o,
			output wire [31:0] data_o,
			output wire [31:0] ACK_o,
			output wire [31:0] TEST1,TEST2,TEST3 // ports made for general test purposes with elastic source
			);
			
	//Params
	localparam //Device Adresses
					DAB_DVI = 7'b1110110 , //0x76 CHRONTEL 7301C
					DAB_VGA = 7'b1001100 , //0x4C AD9980
				  //Control of Transmission
					Valid = 1'b1,
					NotValid = 1'b0,
				  //Operation on Reg
					R = 1'b1,
					W = 1'b0,	
					CH = 1'b1,
					AD = 1'b0,
					USE = 1'b1;
	//Registers
	reg vld_o;
	reg Enable_I2C;
	reg [1:0] temp_rdy;
	reg [1:0] temp_div;
	reg [1:0] temp_csrdone;
	reg [6:0] index;
	reg [9:0] counter;
	reg [7:0] DeviceAdress;
	reg [7:0] RegAdress;
	reg [7:0] DataOUT;
	reg [31:0] i;
	
	//Command Buffer
	localparam num_op=7'd119; //number of commands/operations
	reg [18:0] d_rw_reg_data [num_op:0];
	reg [18:0] temp [num_op-60:0];
	
	//Wires
	wire rdy_i;
	
	//Instances
	IIC_driver_ASM2 IIC_BUS(.rst_i   (rst_i),		   // input	
									.clk_i   (clk_div),		// input
									.DA_i    (DeviceAdress),// input [7:0]
									.RA_i    (RegAdress),	// input [7:0]
									.data_i  (DataOUT),     // input [7:0]
									.data_o  (data_o),		// output[7:0]			
									.SDA_io_I(SDA_io_I), 	// inout
									.SDA_io_O(SDA_io_O), 	// (bideractional pin SDA was designed this way
									.SDA_io_T(SDA_io_T),	   //  as to comply with the Xilinx's XPS)
									.SCL_o 	(SCL_o),		   // output 
									.vld_i 	(vld_o),		   // input
									.rdy_o 	(rdy_i),			// output
									.ACK_o	(ACK_o),			// output
									.TEST2	(TEST2)			// output(test pin)
									); 	 
									
	clk_div_IIC 	CLK_DIV (.clk_i (clk_i),       	// input
								   .rst_i (rst_i),		 	// input
								   .clk_o (clk_div));	 	// output	
	
	//Combinational
	assign TEST1=vid_ACK_o;
	assign TEST3=RegAdress;
	
	//Behavioral
	
	//Transform all the independent input ports into an Array
	always @(i2c_reg0 or i2c_reg1 or i2c_reg2 or i2c_reg3 or i2c_reg4 or 
				i2c_reg5 or i2c_reg6 or i2c_reg7 or i2c_reg8 or i2c_reg9 or i2c_reg10 or i2c_reg11 or
				i2c_reg12 or i2c_reg13 or i2c_reg14 or i2c_reg15 or i2c_reg16 or i2c_reg17 or i2c_reg18 or i2c_reg19 or
				i2c_reg20 or i2c_reg21 or i2c_reg22 or i2c_reg23 or i2c_reg24 or i2c_reg25 or i2c_reg26 or i2c_reg27 or
				i2c_reg28 or i2c_reg29 or i2c_reg30 or i2c_reg31 or i2c_reg32 or i2c_reg33 or i2c_reg34 or i2c_reg35 or
				i2c_reg36 or i2c_reg37 or i2c_reg38 or i2c_reg39 or i2c_reg40 or i2c_reg41 or i2c_reg42 or i2c_reg43 or
				i2c_reg44 or i2c_reg45 or i2c_reg46 or i2c_reg47 or i2c_reg48 or i2c_reg49 or i2c_reg50 or i2c_reg51 or
				i2c_reg52 or i2c_reg53 or i2c_reg54 or i2c_reg55 or i2c_reg56 or i2c_reg57 or i2c_reg58 or i2c_reg59)
	begin
		temp[0]=i2c_reg0; 
		temp[1]=i2c_reg1;
		temp[2]=i2c_reg2;
		temp[3]=i2c_reg3;
		temp[4]=i2c_reg4;
		temp[5]=i2c_reg5;
		temp[6]=i2c_reg6;
		temp[7]=i2c_reg7;
		temp[8]=i2c_reg8;
		temp[9]=i2c_reg9;
		temp[10]=i2c_reg10;
		temp[11]=i2c_reg11;
		temp[12]=i2c_reg12;
		temp[13]=i2c_reg13;
		temp[14]=i2c_reg14;
		temp[15]=i2c_reg15;
		temp[16]=i2c_reg16;
		temp[17]=i2c_reg17;
		temp[18]=i2c_reg18;
		temp[19]=i2c_reg19;
		temp[20]=i2c_reg20;
		temp[21]=i2c_reg21;
		temp[22]=i2c_reg22;
		temp[23]=i2c_reg23;
		temp[24]=i2c_reg24;
		temp[25]=i2c_reg25;
		temp[26]=i2c_reg26;
		temp[27]=i2c_reg27;
		temp[28]=i2c_reg28;
		temp[29]=i2c_reg29;
		temp[30]=i2c_reg30;
		temp[31]=i2c_reg31;
		temp[32]=i2c_reg32;
		temp[33]=i2c_reg33;
		temp[34]=i2c_reg34;
		temp[35]=i2c_reg35;
		temp[36]=i2c_reg36;
		temp[37]=i2c_reg37;
		temp[38]=i2c_reg38;
		temp[39]=i2c_reg39;
		temp[40]=i2c_reg40;
		temp[41]=i2c_reg41;
		temp[42]=i2c_reg42;
		temp[43]=i2c_reg43;
		temp[44]=i2c_reg44;
		temp[45]=i2c_reg45;
		temp[46]=i2c_reg46;
		temp[47]=i2c_reg47;
		temp[48]=i2c_reg48;
		temp[49]=i2c_reg49;
		temp[50]=i2c_reg50;
		temp[51]=i2c_reg51;
		temp[52]=i2c_reg52;
		temp[53]=i2c_reg53;
		temp[54]=i2c_reg54;
		temp[55]=i2c_reg55;
		temp[56]=i2c_reg56;
		temp[57]=i2c_reg57;
		temp[58]=i2c_reg58;
		temp[59]=i2c_reg59;
	end	

	//Adress and Data Transmitt to the I2C bus master
	always @(posedge clk_i or posedge rst_i)
	begin
		if(rst_i)
		begin
			Enable_I2C	 <= 1'b0;
			vid_ACK_o	 <= 1'b0;
			index			 <= 6'h00;
			counter		 <= 10'h000;
			vld_o			 <= Valid;
			temp_rdy		 <= 2'b11;
			temp_div		 <= 2'b00;
			temp_csrdone <= 2'b00;
			DeviceAdress <= 8'h00;
			RegAdress	 <= 8'h00;
			DataOUT		 <= 8'h00;
			//Ch7301C & AD9980 zeroing
			for(i=0;i<(num_op+1);i=i+1) 
			begin
				d_rw_reg_data[i]<=0;
			end
		end	
		else
		begin
			//Probing for the end of the initial stage
			temp_csrdone[0]<=CSR_DONE;
			temp_csrdone[1]<=temp_csrdone[0];
			
			if(temp_csrdone==2'b01 && Enable_I2C==1'b0)
			begin
				for(i=0;i<(num_op+1);i=i+1) 
				begin
					if(i<=59)
						d_rw_reg_data[i]<=temp[i];
						//i equal to 59 marks the end of the write commands
					else
					begin
						d_rw_reg_data[i]<={temp[i-60][18:17],1'b1,temp[i-60][15:0]}; 
						//for the test purpose each write command is read after the write stage
					end
				end
				//Index Zeroying 
				index<=0;
				Enable_I2C<=1'b1;
			end
			//probing of the rdy_i signal
			temp_rdy[0] <= rdy_i;
			temp_rdy[1] <= temp_rdy[0];
			
			//division of the clk by 2
			temp_div[0] <= clk_div;
			temp_div[1] <= temp_div[0];
			
			//Transmitter
			if(Enable_I2C)
			begin
				if(temp_div==2'b01)
				begin
					if(counter>10'd4)
					begin
						if( temp_rdy == 2'b11 && vld_o==Valid && index <(num_op+1) && temp_div==2'b01 ) 
						begin
							if(d_rw_reg_data[index][18]==USE)
							begin
								vld_o <= NotValid;
								index <= index + 1'b1;
								RegAdress<= d_rw_reg_data[index][15:8];
								
								if(d_rw_reg_data[index][17]==CH) DeviceAdress[7:1]<=DAB_DVI;
								else DeviceAdress[7:1]<=DAB_VGA;
								
								if( d_rw_reg_data[index][16]==R)
								begin
									DeviceAdress[0]<=R;
									DataOUT <= 8'h00;
								end				
								else
								begin	
									DeviceAdress[0] <= W;
									DataOUT <= d_rw_reg_data[index][7:0];
								end
							end
							else
							begin
								index <= index + 1'b1;
							end
						end
						else
						begin
							if( temp_rdy == 2'b01 )
							begin
								vld_o <= Valid;
								DeviceAdress <= 8'h00;
								RegAdress <= 8'h00;
								DataOUT <= 8'h00;	
								counter<=10'h000;
							end
							if(index==(num_op+1))
							begin
								if(counter>10'd100 ) vid_ACK_o<=1'b1;
								else counter<=counter+1'b1;
							end
						end
					end
					else counter<=counter+1'b1;
				end
			end		
		end
	end
endmodule

