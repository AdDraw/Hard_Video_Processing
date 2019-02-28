/*
 * main.c
 *
 *  	Created on: 18-12-2018
 *      Author: Adam Drawc 160549
 *
 *      Wpisywanie do i2creg:
 *      Rejestr po stronie sprzêtowej ma 18 aktywnych bitów [17:0]
 *      i2creg={[18]   - 1=Use 0=DontUse
 *      		[17]   - 1 = CH7301C , 0 =AD9980
 *      		[16]   - Read=1 ,Write=0
 *      		[15:8] - 8bit na adres rejestru
 *      		[7:0]  - 8bit na dane wysylane do tego rejestru}
 *
 *      Adresy rejestrow ukladu :
 *        //Chrontel CH7301C
 *					_1Cc = 8'h1C+8'h80, d_1Cc = 8'b00000001, rw_1Cc = W, //RW // 2xPixelRate
 *					_1Dc = 8'h1D+8'h80, d_1Dc = 8'b01001000, rw_1Dc = R, //RW //
 *					_1Ec = 8'h1E+8'h80, d_1Ec = 8'b11000000, rw_1Ec = R, //RW
 *					_1Fc = 8'h1F+8'h80, d_1Fc = 8'b10000001, rw_1Fc = W, //RW // IDF=1 ,24bit 2xpixel Rate
 *					_20c = 8'h20+8'h80, d_20c = 8'b00000000, rw_20c = R, //RW
 *					_21c = 8'h21+8'h80, d_21c = 8'b00000000, rw_21c = R, //RW
 *					_23c = 8'h23+8'h80, d_23c = 8'b00000000, rw_23c = R, //RW
 *					_31c = 8'h31+8'h80, d_31c = 8'b10000000, rw_31c = R, //DEF VAL
 *					_33c = 8'h33+8'h80, d_33c = 8'b00001000, rw_33c = W, //RW
 *					_34c = 8'h34+8'h80, d_34c = 8'b00010110, rw_34c = W, //DEF VAL
 *					_35c = 8'h35+8'h80, d_35c = 8'b00110000, rw_35c = R, //DEF VAL
 *					_36c = 8'h36+8'h80, d_36c = 8'b01100000, rw_36c = W, //DEF VAL
 *					_37c = 8'h37+8'h80, d_37c = 8'b00000000, rw_37c = R, //DEF VAL
 *					_48c = 8'b11001000, d_48c = 8'b00011001, rw_48c = W, //RW //zmiana  8'h48+8'h80
 *					_49c = 8'h49+8'h80, d_49c = 8'b11000000, rw_49c = W, //RW //zmiana
 *					_4Ac = 8'h4A+8'h80, d_4Ac = 8'b10010101, rw_4Ac = R, //RW
 *					_4Bc = 8'h4B+8'h80, d_4Bc = 8'b00010111, rw_4Bc = R, //RW
 *					_56c = 8'h56+8'h80, d_56c = 8'b00000000, rw_56c = R, //RW
 *		  //AD9980
 *					_00a = 8'h00, 		d_00a = 8'b00000000, rw_00a = R,  //RO
 *					_01a = 8'h01, 		d_01a = 8'b01101000, rw_01a = R,  //RW
 *					_02a = 8'h02, 		d_02a = 8'b11010000, rw_02a = R,  //RW
 *					_03a = 8'h03, 		d_03a = 8'b01001000, rw_03a = R,  //RW
 *					_04a = 8'h04, 		d_04a = 8'b10000000, rw_04a = R,  //RW
 *					_05a = 8'h05, 		d_05a = 8'b01000000, rw_05a = R,  //RW
 *					_06a = 8'h06, 		d_06a = 8'b00000000, rw_06a = R,  //RW
 *					_07a = 8'h07, 		d_07a = 8'b01000000, rw_07a = R,  //RW
 *					_08a = 8'h08, 		d_08a = 8'b00000000, rw_08a = R,  //RW
 *					_09a = 8'h09, 		d_09a = 8'b01000000, rw_09a = R,  //RW
 *					_0Aa = 8'h0A, 		d_0Aa = 8'b00000000, rw_0Aa = R,  //RW
 *					_0Ba = 8'h0B, 		d_0Ba = 8'b01000000, rw_0Ba = R,  //RW
 *					_0Ca = 8'h0C, 		d_0Ca = 8'b00000000, rw_0Ca = R,  //RW
 *					_0Da = 8'h0D, 		d_0Da = 8'b01000000, rw_0Da = R,  //RW
 *					_0Ea = 8'h0E, 		d_0Ea = 8'b00000000, rw_0Ea = R,  //RW
 *					_0Fa = 8'h0F, 		d_0Fa = 8'b01000000, rw_0Fa = R,  //RW
 *					_10a = 8'h10, 		d_10a = 8'b00000000, rw_10a = R,  //RW
 *					_11a = 8'h11, 		d_11a = 8'b00100000, rw_11a = R,  //RW
 *					_12a = 8'h12, 		d_12a = 8'b00011000, rw_12a = R,  //RW
 *					_13a = 8'h13, 		d_13a = 8'b00100000, rw_13a = R,  //RW
 *					_14a = 8'h14, 		d_14a = 8'b00011000, rw_14a = R,  //RW
 *					_15a = 8'h15, 		d_15a = 8'b00001010, rw_15a = R,  //RW
 * 					_16a = 8'h16,		d_16a = 8'b00000000, rw_16a = R,  //RW
 *					_17a = 8'h17, 		d_17a = 8'b00000000, rw_17a = R,  //RW
 *					_18a = 8'h18, 		d_18a = 8'b00100000, rw_18a = R,  //RW
 *					_19a = 8'h19, 		d_19a = 8'b00010000, rw_19a = R,  //RW
 *					_1Aa = 8'h1A, 		d_1Aa = 8'b00100000, rw_1Aa = R,  //RW
 *					_1Ba = 8'h1B, 		d_1Ba = 8'b01011011, rw_1Ba = R,  //RW
 *					_1Ca = 8'h1C, 		d_1Ca = 8'b11111111, rw_1Ca = R,  //RW
 *					_1Da = 8'h1D, 		d_1Da = 8'b01111000, rw_1Da = R,  //RW
 *					_1Ea = 8'h1E, 		d_1Ea = 8'b00110000, rw_1Ea = R,  //RW
 *					_1Fa = 8'h1F, 		d_1Fa = 8'b00010100, rw_1Fa = R,  //RW
 *					_20a = 8'h20, 		d_20a = 8'b00001011, rw_20a = R,  //RW
 *					_21a = 8'h21, 		d_21a = 8'b00100000, rw_21a = R,  //RW
 *					_22a = 8'h22, 		d_22a = 8'b00110000, rw_22a = R,  //RW
 *					_23a = 8'h23, 		d_23a = 8'b00001010, rw_23a = R,  //RW
 *					_24a = 8'h24, 		d_24a = 8'b00000000, rw_24a = R,  //RO
 *					_25a = 8'h25, 		d_25a = 8'b00000000, rw_25a = R,  //RO
 *					_26a = 8'h26, 		d_26a = 8'b00000000, rw_26a = R,  //RO
 *					_27a = 8'h27, 		d_27a = 8'b00000000, rw_27a = R,  //RO
 *					_28a = 8'h28, 		d_28a = 8'b10111111, rw_28a = R,  //RW
 *					_29a = 8'h29, 		d_29a = 8'b00000010, rw_29a = R,  //RW
 *					_2Aa = 8'h2A, 		d_2Aa = 8'b00000000, rw_2Aa = R,  //RO
 *					_2Ba = 8'h2B, 		d_2Ba = 8'b00000000, rw_2Ba = R,  //RO
 *					_2Ca = 8'h2C, 		d_2Ca = 8'b00000000, rw_2Ca = R,  //RW
 *					_2Da = 8'h2D, 		d_2Da = 8'b11110000, rw_2Da = R,  //RW
 *					_2Ea = 8'h2E, 		d_2Ea = 8'b11110000, rw_2Ea = R;  //RW
 */
#include "xparameters.h"
#include "xbasic_types.h"
#include "xil_printf.h"

int main(){
	//ZMIENNE
	Xuint32 vals_read[98];
	Xuint32 vals_read_ACK[98];
	Xuint32 vals_ra[98];
	Xuint32 index=0;
	Xuint32 i=0;
	Xuint32 j=0;
	Xuint32 KONFIG=1;
	Xuint32 Read=0;
	Xuint32 display=1;
	Xuint32 vid_ACK=0;
	Xuint32 new_ra=0;
	Xuint32 last_ra=0;
	Xuint32 VIDEO_FORMAT=1; //0 for DVI , 1 for VGA setting on CHRONTEL

	for(i=0;i<98;i++)
	{
		vals_read_ACK[i]=0;
		vals_read[i]=0;
		vals_ra[i]=0;
	}

	//PARAMETRY
	////VIDEO OUT:CSR
	//FOR 640x480 @ 72Hz 63 MHz
	Xuint32 H_ValData	= 640;//640
	Xuint32 H_SyncWidth = 64;//64
	Xuint32 H_BP 		= 120;//120
	Xuint32 H_FP 		= 16;//16
	Xuint32 H_Columns	= H_ValData+H_SyncWidth+H_BP+H_FP;


	Xuint32 V_ValData	= 480;//480
	Xuint32 V_SyncWidth	= 3;//3
	Xuint32 V_BP		= 16;//16
	Xuint32 V_FP		= 1;//1
	Xuint32 V_Lines		= V_ValData+V_SyncWidth+V_BP+V_FP;

	//11(3) - both are active high
	//00(0) - both are active low
	//01(1) - V-active low  H-active high
	//10(2) - V-active high H-active low
	Xuint32 Active_HV   = 0;

	////I2C:CSR
	//output DVI - CH7301C
	Xuint32 dvi_i2c_reg0	= 0b1101001110000000001; //Use 	Chrontel Read 1Ch 01h
	Xuint32 dvi_i2c_reg1	= 0b1101001111110000001; //Use 	Chrontel Write 1Fh 81h
	Xuint32 dvi_i2c_reg2	= 0b1101011001100001000; //Use 	Chrontel Write 33h 08h
	Xuint32 dvi_i2c_reg3	= 0b1101011010000010110; //Use 	Chrontel Write 34h 16h
	Xuint32 dvi_i2c_reg4	= 0b1101011011001100000; //Use 	Chrontel Write 36h 60h
	Xuint32 dvi_i2c_reg5	= 0b1101100100000011010; //Use	Chrontel Write 48h 19h
	Xuint32 dvi_i2c_reg6	= 0b1101100100111000000; //Use 	Chrontel Write 49h C0h
	Xuint32 dvi_i2c_reg7	= 0b1101010000100001001; //Use  Chrontel Write 21h 00h
	Xuint32 dvi_i2c_reg8	= 0;//0b0111101011000000000; //NoUse Chrontel Write 56h 00h
	Xuint32 dvi_i2c_reg9	= 0b1101001110101000000;//Use Chrontel Write 1Dh 4Fh
	Xuint32 dvi_i2c_reg10	= 0;//NoUse
	Xuint32 dvi_i2c_reg11	= 0;//NoUse
	Xuint32 dvi_i2c_reg12	= 0;//NoUse
	//output VGA - CH7301C
	Xuint32 vga_i2c_reg0	= 0b1101001110000000001; //Use 	Chrontel Read 1Ch 01h
	Xuint32 vga_i2c_reg1	= 0b1101001111110000001; //Use 	Chrontel Write 1Fh 81h
	Xuint32 vga_i2c_reg2	= 0b1101011001100001000; //Use 	Chrontel Write 33h 08h
	Xuint32 vga_i2c_reg3	= 0b1101011010000010110; //Use 	Chrontel Write 34h 16h
	Xuint32 vga_i2c_reg4	= 0b1101011011001100000; //Use 	Chrontel Write 36h 60h
	Xuint32 vga_i2c_reg5	= 0b0101100100000011010; //Use	Chrontel Write 48h 19h
	Xuint32 vga_i2c_reg6	= 0b1101100100111000000; //Use 	Chrontel Write 49h C0h
	Xuint32 vga_i2c_reg7	= 0b1101010000100001001; //NoUse Chrontel Write 21h 09h
	Xuint32 vga_i2c_reg8	= 0;//0b0111101011000000000; //NoUse Chrontel Write 56h 00h
	Xuint32 vga_i2c_reg9	= 0;//NoUse
	Xuint32 vga_i2c_reg10	= 0;//NoUse
	Xuint32 vga_i2c_reg11	= 0;//NoUse
	Xuint32 vga_i2c_reg12	= 0;//NoUse
	//input VGA - AD9980
	Xuint32 i2c_reg13		= 0b1000000000100110100;//0x01 PLL DIV MSB
	Xuint32 i2c_reg14		= 0b1000000001010000000;//0x02 PLL DIV LSB
	Xuint32 i2c_reg15		= 0b1000000001101100000;//0x03 VCORange + PumpCurrent + ExtClock
	Xuint32 i2c_reg16		= 0b1000000010011000000;//0x04 Phase ADJUST STEP=11.25 DEF=16
	Xuint32 i2c_reg17		= 0b1000000010101000000;//0x05 RED GAIN DEF=0x80
	Xuint32 i2c_reg18		= 0b1000000011000000000;//0x06 must be written after a write to 0x05
	Xuint32 i2c_reg19		= 0b1000000011101000000;//0x07 GREEN GAIN DEF=0x80
	Xuint32 i2c_reg20		= 0b1000000100000000000;//0x08 must be written after a write to 0x07
	Xuint32 i2c_reg21		= 0b1000000100101000000;//0x09 BLUE GAIN DEF=0x80
	Xuint32 i2c_reg22		= 0b1000000101000000000;//0x0A must be written after a write to 0x09
	Xuint32 i2c_reg23		= 0b1000000101101000000;//0x0B Input offset Red MSB
	Xuint32 i2c_reg24		= 0b1000000110000000000;//0x0C Input offset Red LSB
	Xuint32 i2c_reg25		= 0b1000000110101000000;//0x0D Input offset Green MSB
	Xuint32 i2c_reg26		= 0b1000000111000000000;//0x0E Input offset Green LSB
	Xuint32 i2c_reg27		= 0b1000000111101000000;//0x0F Input offset Blue MSB
	Xuint32 i2c_reg28		= 0b1000001000000000000;//0x10 Input offset Blue LSB
	Xuint32 i2c_reg29		= 0b1000001000110000000;//0x11 Sync Separator Threshold DEF=32DDR
	Xuint32 i2c_reg30		= 0b1000001001000010000;//0x12 Hsync SRC_OVR+SRC_SEL+In_POL+Out_POL
	Xuint32 i2c_reg31		= 0b1000001001100100000;//0x13 Hsync Duration DEF=x20
	Xuint32 i2c_reg32		= 0b1000001010000000100;//0x14 Vsync OVR+SRC+POL_OVR+In_POL+Out_POL+FLTR_EN+DURATION
	Xuint32 i2c_reg33		= 0b1000001010100001110;//0x15 Vsync Duration if 0x14 bit 1==1 VLD DEF=0x0A
	Xuint32 i2c_reg34		= 0b1000001011000000000;//0x16 Precoast DEF=x00 Usually 2 i good
	Xuint32 i2c_reg35		= 0b1000001011100000000;//0x17 Postcoast DEF=x00 Usually 10 i good
	Xuint32 i2c_reg36		= 0b1000001100000100000;//0x18 Coast SRC+Pol_OVR+In_Pol Clamp SRC+R_Sel+G_Sel+B_Sel
	Xuint32 i2c_reg37		= 0b1000001100100001000;//0x19 Clamp Placement DEF=8
	Xuint32 i2c_reg38		= 0b1000001101000010100;//0x1A Clamp Duration  DEF=20
	Xuint32 i2c_reg39		= 0b1000001101101111011;//0x1B Clamp POL_OVR+In_POL+AUTOOFF_EN+AO_updtfreq+PROP_OP(110)
	Xuint32 i2c_reg40		= 0b1000001110011111111;//0x1C TestReg0 Prop_op
	Xuint32 i2c_reg41		= 0b1000001110101111000;//0x1D SOG Comp Threshold+Out_Pol+Out_Sel DEF
	Xuint32 i2c_reg42		= 0b1000001111000110100;//0x1E CH Sel_OVR+SEL+Prog_BW+PWRDWN SEL+EN+POL+PWR+FST_SW+SOG HiZ
	Xuint32 i2c_reg43		= 0b1000001111100010100;//0x1F Output MODE+ PrimaryOUTEN+SecondaryOUTEN+OUTPUT_DRV_STR+CLK_INV
	Xuint32 i2c_reg44		= 0b1000010000000001111;//0x20 OutClk_Sel+Out_HiZ+SOG_HiZ+Field_OutPol+PLL_SyncFLTR+SyncProcIn_SRC+propOP
	Xuint32 i2c_reg45		= 0b1000010000100100000;//0x21 PROP_OP
	Xuint32 i2c_reg46		= 0b1000010001000110010;//0x22 PROP_OP
	Xuint32 i2c_reg47		= 0b1000010001100001110;//0x23 Sync Filter Window Width DEF=10
	Xuint32 i2c_reg48		= 0b0010010010000000000;//0x24 ReadOnly HsyncDetection
	Xuint32 i2c_reg49		= 0b0010010010100000000;//0x25 ReadOnly HsyncPol
	Xuint32 i2c_reg50		= 0b0010010011000000000;//0x26 ReadOnly Hsyncs per Vsync MSB
	Xuint32 i2c_reg51		= 0b0010010011100000000;//0x27 ReadOnly Hsyncs per Vsync LSB
	Xuint32 i2c_reg52		= 0b1000010100010111111;//0x28 Prop_op
	Xuint32 i2c_reg53		= 0b1000010100100000010;//0x29 Prop_op
	Xuint32 i2c_reg54		= 0b0010010101000000000;//0x2A Read Only, Dont Use
	Xuint32 i2c_reg55		= 0b0010010101100000000;//0x2B Read Only, Dont Use
	Xuint32 i2c_reg56		= 0b1000010110000000000;//0x2C Offset Hold, continous update
	Xuint32 i2c_reg57		= 0b1000010110111110000;//0x2D prop_op
	Xuint32 i2c_reg58		= 0b1000010111011110000;//0x2E prop_op
	Xuint32 i2c_reg59		= 0;//dodatkowe

	//ACTIVE VIDEO
	Xuint32 HC=96;
	Xuint32 LC=256;
	Xuint32 HL=304;
	Xuint32 LL=176;
	Xuint8  RED=0x80;
	Xuint8  GREEN=0x80;
	Xuint8  BLUE=0x00;
	//COLOUR
	Xuint32 HCColor			=(HC<<24)|(GREEN<<16)|(RED<<8)|BLUE;
	Xuint32 HLLLLC			=(LL<<20)|(HL<<10)|LC;

	//defines the element_struct used for processing
	//[2]	- RED
	//[1]	- GREEN
	//[0]	- BLUE
	Xuint32 elem_struct 	= 0b001;

	//[0]- 1: Wymiary pochodz¹ z uB; 		0: Wymiary maksymalne
	//[1]- 1: Kolory pochodz¹ z uB; 		0: Kolory pochodz¹ z VIDEO IN
	//[2]- 1: Rozdzielczosc pochodzi z uB; 	0: Rozdzielczosc 640x480 @75Hz
	//[3]- 1: Przetwarzanie siê nie odbywa	0: Przetwarzanie siê odbywa
	Xuint32 program			= 0b01101;

	//ADRESY
	Xuint32 *I2CREG0	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR;
	Xuint32 *I2CREG1	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+1;
	Xuint32 *I2CREG2	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+2;
	Xuint32 *I2CREG3	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+3;
	Xuint32 *I2CREG4	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+4;
	Xuint32 *I2CREG5	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+5;
	Xuint32 *I2CREG6	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+6;
	Xuint32 *I2CREG7	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+7;
	Xuint32 *I2CREG8	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+8;
	Xuint32 *I2CREG9	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+9;
	Xuint32 *I2CREG10	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+10;
	Xuint32 *I2CREG11	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+11;
	Xuint32 *I2CREG12	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+12;
	Xuint32 *H_FPREG	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+13;
	Xuint32 *H_BPREG	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+14;
	Xuint32 *H_SYNCREG	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+15;
	Xuint32 *H_VldDatREG= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+16;
	Xuint32 *COLUMNSREG	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+17;
	Xuint32 *HV_activeREG= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+18;
	Xuint32 *V_FPREG	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+19;
	Xuint32 *V_BPREG	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+20;
	Xuint32 *V_SYNCREG	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+21;
	Xuint32 *V_VldDatREG= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+22;
	Xuint32 *LINESREG	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+23;
	Xuint32 *ELEM_REG= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+24;
	Xuint32 *CSR_DONE   = (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+25;
	Xuint32 *VID_ACKREG	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+26;
	Xuint32 *RegAdrI2C	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+28;
	Xuint32 *ColorHC_p	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+27;
	Xuint32 *HLLLLLC_p	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+30;
	Xuint32 *ReadACKI2C	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+29;
	Xuint32 *ReadI2C 	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+31;
	Xuint32 *I2CREG13	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+32;
	Xuint32 *I2CREG14	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+33;
	Xuint32 *I2CREG15	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+34;
	Xuint32 *I2CREG16	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+35;
	Xuint32 *I2CREG17	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+36;
	Xuint32 *I2CREG18	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+37;
	Xuint32 *I2CREG19	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+38;
	Xuint32 *I2CREG20	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+39;
	Xuint32 *I2CREG21	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+40;
	Xuint32 *I2CREG22	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+41;
	Xuint32 *I2CREG23	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+42;
	Xuint32 *I2CREG24	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+43;
	Xuint32 *I2CREG25	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+44;
	Xuint32 *I2CREG26	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+45;
	Xuint32 *I2CREG27	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+46;
	Xuint32 *I2CREG28	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+47;
	Xuint32 *I2CREG29	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+48;
	Xuint32 *I2CREG30	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+49;
	Xuint32 *I2CREG31	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+50;
	Xuint32 *I2CREG32	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+51;
	Xuint32 *I2CREG33	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+52;
	Xuint32 *I2CREG34	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+53;
	Xuint32 *I2CREG35	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+54;
	Xuint32 *I2CREG36	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+55;
	Xuint32 *I2CREG37	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+56;
	Xuint32 *I2CREG38	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+57;
	Xuint32 *I2CREG39	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+58;
	Xuint32 *I2CREG40	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+59;
	Xuint32 *I2CREG41	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+60;
	Xuint32 *I2CREG42	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+61;
	Xuint32 *I2CREG43	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+62;
	Xuint32 *I2CREG44	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+63;
	Xuint32 *I2CREG45	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+64;
	Xuint32 *I2CREG46	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+65;
	Xuint32 *I2CREG47	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+66;
	Xuint32 *I2CREG48	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+67;
	Xuint32 *I2CREG49	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+68;
	Xuint32 *I2CREG50	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+69;
	Xuint32 *I2CREG51	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+70;
	Xuint32 *I2CREG52	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+71;
	Xuint32 *I2CREG53	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+72;
	Xuint32 *I2CREG54	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+73;
	Xuint32 *I2CREG55	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+74;
	Xuint32 *I2CREG56	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+75;
	Xuint32 *I2CREG57	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+76;
	Xuint32 *I2CREG58	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+77;
	Xuint32 *I2CREG59	= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+78;

	Xuint32 *COLUMNS_MAX = (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+80;
	Xuint32 *LINES_MAX = (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+81;

	Xuint32 *PROGRAM_MODE= (Xuint32*) XPAR_VIDEO_PROCESSING_0_BASEADDR+82;

	while(1){
		if(KONFIG==1){
			xil_printf("KONFIGURACJA: Niewykonana\n...\n");
			//I2C
			//VIDEO OUT
			if(VIDEO_FORMAT==0){
				 *(I2CREG0)=dvi_i2c_reg0;
				 *(I2CREG1)=dvi_i2c_reg1;
				 *(I2CREG2)=dvi_i2c_reg2;
				 *(I2CREG3)=dvi_i2c_reg3;
				 *(I2CREG4)=dvi_i2c_reg4;
				 *(I2CREG5)=dvi_i2c_reg5;
				 *(I2CREG6)=dvi_i2c_reg6;
				 *(I2CREG7)=dvi_i2c_reg7;
				 *(I2CREG8)=dvi_i2c_reg8;
				 *(I2CREG9)=dvi_i2c_reg9;
				 *(I2CREG10)=dvi_i2c_reg10;
				 *(I2CREG11)=dvi_i2c_reg11;
				 *(I2CREG12)=dvi_i2c_reg12;}
			else{*(I2CREG0)=vga_i2c_reg0;
				 *(I2CREG1)=vga_i2c_reg1;
				 *(I2CREG2)=vga_i2c_reg2;
				 *(I2CREG3)=vga_i2c_reg3;
				 *(I2CREG4)=vga_i2c_reg4;
				 *(I2CREG5)=vga_i2c_reg5;
				 *(I2CREG6)=vga_i2c_reg6;
				 *(I2CREG7)=vga_i2c_reg7;
				 *(I2CREG8)=vga_i2c_reg8;
				 *(I2CREG9)=vga_i2c_reg9;
				 *(I2CREG10)=vga_i2c_reg10;
				 *(I2CREG11)=vga_i2c_reg11;
				 *(I2CREG12)=vga_i2c_reg12;}
			//VIDEO_IN
			 *(I2CREG13)=i2c_reg13;
			 *(I2CREG14)=i2c_reg14;
			 *(I2CREG15)=i2c_reg15;
			 *(I2CREG16)=i2c_reg16;
			 *(I2CREG17)=i2c_reg17;
			 *(I2CREG18)=i2c_reg18;
			 *(I2CREG19)=i2c_reg19;
			 *(I2CREG20)=i2c_reg20;
			 *(I2CREG21)=i2c_reg21;
			 *(I2CREG22)=i2c_reg22;
			 *(I2CREG23)=i2c_reg23;
			 *(I2CREG24)=i2c_reg24;
			 *(I2CREG25)=i2c_reg25;
			 *(I2CREG26)=i2c_reg26;
			 *(I2CREG27)=i2c_reg27;
			 *(I2CREG28)=i2c_reg28;
			 *(I2CREG29)=i2c_reg29;
			 *(I2CREG30)=i2c_reg30;
			 *(I2CREG31)=i2c_reg31;
			 *(I2CREG32)=i2c_reg32;
			 *(I2CREG33)=i2c_reg33;
			 *(I2CREG34)=i2c_reg34;
			 *(I2CREG35)=i2c_reg35;
			 *(I2CREG36)=i2c_reg36;
			 *(I2CREG37)=i2c_reg37;
			 *(I2CREG38)=i2c_reg38;
			 *(I2CREG39)=i2c_reg39;
			 *(I2CREG40)=i2c_reg40;
			 *(I2CREG41)=i2c_reg41;
			 *(I2CREG42)=i2c_reg42;
			 *(I2CREG43)=i2c_reg43;
			 *(I2CREG44)=i2c_reg44;
			 *(I2CREG45)=i2c_reg45;
			 *(I2CREG46)=i2c_reg46;
			 *(I2CREG47)=i2c_reg47;
			 *(I2CREG48)=i2c_reg48;
			 *(I2CREG49)=i2c_reg49;
			 *(I2CREG50)=i2c_reg50;
			 *(I2CREG51)=i2c_reg51;
			 *(I2CREG52)=i2c_reg52;
			 *(I2CREG53)=i2c_reg53;
			 *(I2CREG54)=i2c_reg54;
			 *(I2CREG55)=i2c_reg55;
			 *(I2CREG56)=i2c_reg56;
			 *(I2CREG57)=i2c_reg57;
			 *(I2CREG58)=i2c_reg58;
			 *(I2CREG59)=i2c_reg59;

			//DVI
			*(H_FPREG)=H_FP;
			*(H_BPREG)=H_BP;
			*(H_SYNCREG)=H_SyncWidth;
			*(H_VldDatREG)=H_ValData;
			*(COLUMNSREG)=H_Columns;
			*(HV_activeREG)=Active_HV;
			*(V_FPREG)=V_FP;
			*(V_BPREG)=V_BP;
			*(V_SYNCREG)=V_SyncWidth;
			*(V_VldDatREG)=V_ValData;
			*(LINESREG)=V_Lines;
			*(ColorHC_p)=HCColor;
			*(HLLLLLC_p)=HLLLLC;
			//PROCESSING
			*(ELEM_REG)=elem_struct;

			//Send an INFORMATION THAT THE uB Part has ended
			*(PROGRAM_MODE)=program;
			*(CSR_DONE)=1;
			KONFIG=0;
			xil_printf("KONFIGURACJA: Wykonana \n");}

		new_ra=*(RegAdrI2C);
		vid_ACK=*(VID_ACKREG);
		if(new_ra!=last_ra){
			if(new_ra==0){
			vals_read[index]=*(ReadI2C);
			vals_read_ACK[index]=*(ReadACKI2C);
			vals_ra[index]=last_ra;
			index++;}
			last_ra=new_ra;
		}

		//WYŒWIETLANIE
		//ZAWARTOSCI REJESTROW I2C
		if(index>88 && Read==0){
			xil_printf("\nEtap: I2C\n");
			for(i=42;i<index;i++){
				if(j==0){xil_printf("*****CH7301C*********************************\n");}
				if(j==7){xil_printf("*****AD9980**********************************\n");}
				xil_printf("R ");
				xil_printf("REG %d   ",j);
				xil_printf("ADR 0x%x   ",vals_ra[i]);
				xil_printf("ACK %d   ",vals_read_ACK[i]);
				xil_printf("VAL_READ 0x%x\n",vals_read[i]);
				j++;}
			Read=1;}

	    //ZAWARTOSCI REJESTROW VID_OUT
		if(Read==1 && display==1 && vid_ACK==1){
			xil_printf("\nEtap: VIDEO_OUT\n");
			xil_printf("H_Col %d\n",*(COLUMNSREG));
			xil_printf("H_VldData %d\n",*(H_VldDatREG));
			xil_printf("H_SyncWidth %d\n",*(H_SYNCREG));
			xil_printf("H_FP %d\n",*(H_FPREG));
			xil_printf("H_BP %d\n",*(H_BPREG));
			xil_printf("V_Lines %d\n",*(LINESREG));
			xil_printf("V_VldData %d\n",*(V_VldDatREG));
			xil_printf("V_SyncWidth %d\n",*(V_SYNCREG));
			xil_printf("V_FP %d\n",*(V_FPREG));
			xil_printf("V_BP %d\n",*(V_BPREG));
			xil_printf("HV_Active %b\n",*(HV_activeREG));

			xil_printf("\nEtap: PROCESSING\n");
			xil_printf("Element strukturalny \n ");
			xil_printf("  %x  %x  %x\n",elem_struct,elem_struct,elem_struct);
			xil_printf("   %x  %x  %x\n",elem_struct,elem_struct,elem_struct);
			xil_printf("   %x  %x  %x\n",elem_struct,elem_struct,elem_struct);

			xil_printf("\nEtap: VIDEO_IN\n");
			xil_printf("COLUMNS READ=%d\n",*(COLUMNS_MAX));
			xil_printf("LINES READ=%d\n",*(LINES_MAX));
			xil_printf("\nKoniec testów\n");

			xil_printf("\nEtap: VIDEO_OUT\n");
			xil_printf("KOLORY   ");
			xil_printf("RGB = 0x%x %x %x\n",RED,GREEN,BLUE);
			xil_printf("WYMIARY  ");
			xil_printf("HC = %d,LC = %d,HL = %d,LL = %d,\n",HC,LC,HL,LL);
			display=0;}
	}
return 0;
}

