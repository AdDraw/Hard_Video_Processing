//////////////////////////////////////////////////////////////////////////////////
// Company: 	Gdansk University of Technology
// Engineer: 	Adam Drawc 
// Create Date:   	11:23:35 01/11/2019 
// Design Name: 		Version_3
// Module Name:   	CPS_v3
// Project Name: 		Hardware video processing path in FPGA 
// Target Devices: 	ML509/XUPV5
// Tool versions: 	14.7
// Description: 		Module performing video processing ( uses erosion algorithm )
// Additional Comments: 
// 		Version_1: Properly reads and writes to BRAM memory, data is passed through without alterations
// 		Version_2: Added morphological processing (erosion), enabled switching from alteration to no alteration
// 		Version_3: Deleted the switching mechanism
//////////////////////////////////////////////////////////////////////////////////
// This module contains the algorithm for processing data. In Version 3 there is no BRAM actig as a RAM memory for temporary data.
// Incoming data is aquired from input BRAM on port BRAM-DUAL_INPUT. Processed data is sent to the output BRAM through port BRAM-DUAL_OUTPUT.
// Processing occurs on 128x128x3 bits. Algorithm used is erosion, a type of morphological processing. Erosion implemented works only with one
// constant externally sourced structural element with 3x3 dimension lenghts. Those are defined in this file under lenght_struct_element. 
//
// Control over reads and writes from memory are similar in structure to other modules in the project. For incoming data lines vld_i, rdy_o 
// need to be switched acordingly. In case of the data outputted control lines are empty_i and full_o. Those signals carry the information regarding
// the need to read or write and when it the correlated modules are allowed to do so.
// 
// Module works only when configuration has ended and video data is valid. Requires state on line 'video_ACK_i' to be high.
// Outputs one control signal vld_mem_o which activates (changes state to high) when data is sent to output memory.
//
// Processing is done when an internal shifting buffer has loaded a row of data onto the second position available. Then this row is passed to the
// algorithm that incorporates all the rows in the buffer. Erosion is done on every pixel in a row simultanously. Usage of the assign structure allows for
// the process to be combinational which would later be favorable for minimazing the critical path of the algorithm.
//
// Incorporates Global Reset. Can work with frequencies up to those allowed by the BRAM memories used.
//
//////////////////////////////////////////////////////////////////////////////////
`define lenght_struct_element 3
module CPS_v3
(	//GLOBAL
	input wire  			rst_i, clk_i,
	output reg  			vld_mem_o,
	
	//BRAM-DUAL_INPUT
	input wire [383:0] 	doutb_bram12_i,
	input wire 				vld_i,
	input wire 				en_read_i,
	output reg 				rdy_o,
	output reg [6:0] 		addrb_bram12_o,
	output wire 			clkb_bram12_o,

	//BRAM-DUAL_OUTPUT
	input 					empty_i,
	output reg 				full_o,
	output reg 				wea_bram3_o,
	output wire 			clka_bram3_o,
	output reg [6:0] 		addra_bram3_o,
	output wire [383:0] 	dina_bram3_o,
	//config
	input [26:0] 			element_struct,
	input 					video_ACK_i);
	
	//REGS
	reg [3:0] 				vld_counter;
	reg [3:0] 				full_counter;
	reg		  				start_counter,read;
	reg [389:0] 			row2PE [2:0]; // 3 rows for morphological processing
	reg  						write_counter;
	
	//Wires
	wire 						WRITE;
	wire [383:0] 			processed;
	
	//Assigns
	//Read from BRAM
	assign clkb_bram12_o	= clk_i;
	//Write to BRAM
	assign clka_bram3_o	= clk_i;
	assign WRITE			= write_counter;
	
	//Read
	//SINGLE BRAM INPUT, adress sweep and transmission control 
	always @(negedge clk_i or posedge rst_i)
	begin
		if(rst_i)
		begin
			addrb_bram12_o	<= 0;
			vld_counter		<= 0;
			rdy_o				<= 1'b1;
			read				<= 0;
		end
		else
		begin
			if( video_ACK_i )
			begin
				if( en_read_i == 1'b1 )
				begin
					if( vld_i )
					begin
						if( vld_counter != 4'd4 )
						begin
							rdy_o				<= 0;
							addrb_bram12_o	<= 0;
							vld_counter		<= 0;
							read				<= 1'b1;
						end
						else vld_counter	<= vld_counter + 1'b1;
					end
					else
					begin
						rdy_o	<= 1'b1;
						if( addrb_bram12_o != 7'd127 )
						begin
							addrb_bram12_o	<= addrb_bram12_o + 1'b1;
						end	
						else
						begin
							read	<= 0;
						end
					end
				end
				else
				begin
					addrb_bram12_o	<= 0;
					vld_counter		<= 0;
					rdy_o				<= 1'b1;
					read				<= 1'b0;
				end
			end	
		end
	end
	//Aquisition of video rows & inputing new rows to the processing shifting buffer
	always @(posedge clk_i or posedge rst_i)
	begin
		if(rst_i)
		begin
			row2PE[0]		<= 0;
			row2PE[1]		<= 0;
			row2PE[2]		<= 0;
			write_counter	<= 0;
		end
		else
		begin
			if( video_ACK_i )
			begin
				if( read  &&  addrb_bram12_o != 0  &&  addrb_bram12_o != 7'd127 )
				begin
					row2PE[0][386:3]	<= doutb_bram12_i;
					row2PE[1][386:3]	<= row2PE[0][386:3];
					row2PE[2][386:3]	<= row2PE[1][386:3];
					if( write_counter == 1 )
					begin
						write_counter	<= 2'd1;
					end
					else 
					begin
						write_counter	<= write_counter+1'b1;
					end
				end
				else
				begin
					write_counter	<= 0;
					row2PE[0]		<= 0;
					row2PE[1]		<= 0;
					row2PE[2]		<= 0;
				end
			end	
		end
	end
	
	//EROSION on row2PE[1]
	assign	processed[383:381]	= (element_struct=={row2PE[0][389:381],row2PE[1][389:381],row2PE[2][389:381]})? row2PE[1][386:384] : 3'b111;
	assign	processed[380:378]	= (element_struct=={row2PE[0][386:378],row2PE[1][386:378],row2PE[2][386:378]})? row2PE[1][383:381] : 3'b111;
	assign	processed[377:375]	= (element_struct=={row2PE[0][383:375],row2PE[1][383:375],row2PE[2][383:375]})? row2PE[1][380:378] : 3'b111;
	assign	processed[374:372]	= (element_struct=={row2PE[0][380:372],row2PE[1][380:372],row2PE[2][380:372]})? row2PE[1][377:375] : 3'b111;
	assign	processed[371:369]	= (element_struct=={row2PE[0][377:369],row2PE[1][377:369],row2PE[2][377:369]})? row2PE[1][374:372] : 3'b111;
	assign	processed[368:366]	= (element_struct=={row2PE[0][374:366],row2PE[1][374:366],row2PE[2][374:366]})? row2PE[1][371:369] : 3'b111;
	assign	processed[365:363]	= (element_struct=={row2PE[0][371:363],row2PE[1][371:363],row2PE[2][371:363]})? row2PE[1][368:366] : 3'b111;
	assign	processed[362:360]	= (element_struct=={row2PE[0][368:360],row2PE[1][368:360],row2PE[2][368:360]})? row2PE[1][365:363] : 3'b111;
	assign	processed[359:357]	= (element_struct=={row2PE[0][365:357],row2PE[1][365:357],row2PE[2][365:357]})? row2PE[1][362:360] : 3'b111;
	assign	processed[356:354]	= (element_struct=={row2PE[0][362:354],row2PE[1][362:354],row2PE[2][362:354]})? row2PE[1][359:357] : 3'b111;
	assign	processed[353:351]	= (element_struct=={row2PE[0][359:351],row2PE[1][359:351],row2PE[2][359:351]})? row2PE[1][356:354] : 3'b111;
	assign	processed[350:348]	= (element_struct=={row2PE[0][356:348],row2PE[1][356:348],row2PE[2][356:348]})? row2PE[1][353:351] : 3'b111;
	assign	processed[347:345]	= (element_struct=={row2PE[0][353:345],row2PE[1][353:345],row2PE[2][353:345]})? row2PE[1][350:348] : 3'b111;
	assign	processed[344:342]	= (element_struct=={row2PE[0][350:342],row2PE[1][350:342],row2PE[2][350:342]})? row2PE[1][347:345] : 3'b111;
	assign	processed[341:339]	= (element_struct=={row2PE[0][347:339],row2PE[1][347:339],row2PE[2][347:339]})? row2PE[1][344:342] : 3'b111;
	assign	processed[338:336]	= (element_struct=={row2PE[0][344:336],row2PE[1][344:336],row2PE[2][344:336]})? row2PE[1][341:339] : 3'b111;
	assign	processed[335:333]	= (element_struct=={row2PE[0][341:333],row2PE[1][341:333],row2PE[2][341:333]})? row2PE[1][338:336] : 3'b111;
	assign	processed[332:330]	= (element_struct=={row2PE[0][338:330],row2PE[1][338:330],row2PE[2][338:330]})? row2PE[1][335:333] : 3'b111;
	assign	processed[329:327]	= (element_struct=={row2PE[0][335:327],row2PE[1][335:327],row2PE[2][335:327]})? row2PE[1][332:330] : 3'b111;
	assign	processed[326:324]	= (element_struct=={row2PE[0][332:324],row2PE[1][332:324],row2PE[2][332:324]})? row2PE[1][329:327] : 3'b111;
	assign	processed[323:321]	= (element_struct=={row2PE[0][329:321],row2PE[1][329:321],row2PE[2][329:321]})? row2PE[1][326:324] : 3'b111;
	assign	processed[320:318]	= (element_struct=={row2PE[0][326:318],row2PE[1][326:318],row2PE[2][326:318]})? row2PE[1][323:321] : 3'b111;
	assign	processed[317:315]	= (element_struct=={row2PE[0][323:315],row2PE[1][323:315],row2PE[2][323:315]})? row2PE[1][320:318] : 3'b111;
	assign	processed[314:312]	= (element_struct=={row2PE[0][320:312],row2PE[1][320:312],row2PE[2][320:312]})? row2PE[1][317:315] : 3'b111;
	assign	processed[311:309]	= (element_struct=={row2PE[0][317:309],row2PE[1][317:309],row2PE[2][317:309]})? row2PE[1][314:312] : 3'b111;
	assign	processed[308:306]	= (element_struct=={row2PE[0][314:306],row2PE[1][314:306],row2PE[2][314:306]})? row2PE[1][311:309] : 3'b111;
	assign	processed[305:303]	= (element_struct=={row2PE[0][311:303],row2PE[1][311:303],row2PE[2][311:303]})? row2PE[1][308:306] : 3'b111;
	assign	processed[302:300]	= (element_struct=={row2PE[0][308:300],row2PE[1][308:300],row2PE[2][308:300]})? row2PE[1][305:303] : 3'b111;
	assign	processed[299:297]	= (element_struct=={row2PE[0][305:297],row2PE[1][305:297],row2PE[2][305:297]})? row2PE[1][302:300] : 3'b111;
	assign	processed[296:294]	= (element_struct=={row2PE[0][302:294],row2PE[1][302:294],row2PE[2][302:294]})? row2PE[1][299:297] : 3'b111;
	assign	processed[293:291]	= (element_struct=={row2PE[0][299:291],row2PE[1][299:291],row2PE[2][299:291]})? row2PE[1][296:294] : 3'b111;
	assign	processed[290:288]	= (element_struct=={row2PE[0][296:288],row2PE[1][296:288],row2PE[2][296:288]})? row2PE[1][293:291] : 3'b111;
	assign	processed[287:285]	= (element_struct=={row2PE[0][293:285],row2PE[1][293:285],row2PE[2][293:285]})? row2PE[1][290:288] : 3'b111;
	assign	processed[284:282]	= (element_struct=={row2PE[0][290:282],row2PE[1][290:282],row2PE[2][290:282]})? row2PE[1][287:285] : 3'b111;
	assign	processed[281:279]	= (element_struct=={row2PE[0][287:279],row2PE[1][287:279],row2PE[2][287:279]})? row2PE[1][284:282] : 3'b111;
	assign	processed[278:276]	= (element_struct=={row2PE[0][284:276],row2PE[1][284:276],row2PE[2][284:276]})? row2PE[1][281:279] : 3'b111;
	assign	processed[275:273]	= (element_struct=={row2PE[0][281:273],row2PE[1][281:273],row2PE[2][281:273]})? row2PE[1][278:276] : 3'b111;
	assign	processed[272:270]	= (element_struct=={row2PE[0][278:270],row2PE[1][278:270],row2PE[2][278:270]})? row2PE[1][275:273] : 3'b111;
	assign	processed[269:267]	= (element_struct=={row2PE[0][275:267],row2PE[1][275:267],row2PE[2][275:267]})? row2PE[1][272:270] : 3'b111;
	assign	processed[266:264]	= (element_struct=={row2PE[0][272:264],row2PE[1][272:264],row2PE[2][272:264]})? row2PE[1][269:267] : 3'b111;
	assign	processed[263:261]	= (element_struct=={row2PE[0][269:261],row2PE[1][269:261],row2PE[2][269:261]})? row2PE[1][266:264] : 3'b111;
	assign	processed[260:258]	= (element_struct=={row2PE[0][266:258],row2PE[1][266:258],row2PE[2][266:258]})? row2PE[1][263:261] : 3'b111;
	assign	processed[257:255]	= (element_struct=={row2PE[0][263:255],row2PE[1][263:255],row2PE[2][263:255]})? row2PE[1][260:258] : 3'b111;
	assign	processed[254:252]	= (element_struct=={row2PE[0][260:252],row2PE[1][260:252],row2PE[2][260:252]})? row2PE[1][257:255] : 3'b111;
	assign	processed[251:249]	= (element_struct=={row2PE[0][257:249],row2PE[1][257:249],row2PE[2][257:249]})? row2PE[1][254:252] : 3'b111;
	assign	processed[248:246]	= (element_struct=={row2PE[0][254:246],row2PE[1][254:246],row2PE[2][254:246]})? row2PE[1][251:249] : 3'b111;
	assign	processed[245:243]	= (element_struct=={row2PE[0][251:243],row2PE[1][251:243],row2PE[2][251:243]})? row2PE[1][248:246] : 3'b111;
	assign	processed[242:240]	= (element_struct=={row2PE[0][248:240],row2PE[1][248:240],row2PE[2][248:240]})? row2PE[1][245:243] : 3'b111;
	assign	processed[239:237]	= (element_struct=={row2PE[0][245:237],row2PE[1][245:237],row2PE[2][245:237]})? row2PE[1][242:240] : 3'b111;
	assign	processed[236:234]	= (element_struct=={row2PE[0][242:234],row2PE[1][242:234],row2PE[2][242:234]})? row2PE[1][239:237] : 3'b111;
	assign	processed[233:231]	= (element_struct=={row2PE[0][239:231],row2PE[1][239:231],row2PE[2][239:231]})? row2PE[1][236:234] : 3'b111;
	assign	processed[230:228]	= (element_struct=={row2PE[0][236:228],row2PE[1][236:228],row2PE[2][236:228]})? row2PE[1][233:231] : 3'b111;
	assign	processed[227:225]	= (element_struct=={row2PE[0][233:225],row2PE[1][233:225],row2PE[2][233:225]})? row2PE[1][230:228] : 3'b111;
	assign	processed[224:222]	= (element_struct=={row2PE[0][230:222],row2PE[1][230:222],row2PE[2][230:222]})? row2PE[1][227:225] : 3'b111;
	assign	processed[221:219]	= (element_struct=={row2PE[0][227:219],row2PE[1][227:219],row2PE[2][227:219]})? row2PE[1][224:222] : 3'b111;
	assign	processed[218:216]	= (element_struct=={row2PE[0][224:216],row2PE[1][224:216],row2PE[2][224:216]})? row2PE[1][221:219] : 3'b111;
	assign	processed[215:213]	= (element_struct=={row2PE[0][221:213],row2PE[1][221:213],row2PE[2][221:213]})? row2PE[1][218:216] : 3'b111;
	assign	processed[212:210]	= (element_struct=={row2PE[0][218:210],row2PE[1][218:210],row2PE[2][218:210]})? row2PE[1][215:213] : 3'b111;
	assign	processed[209:207]	= (element_struct=={row2PE[0][215:207],row2PE[1][215:207],row2PE[2][215:207]})? row2PE[1][212:210] : 3'b111;
	assign	processed[206:204]	= (element_struct=={row2PE[0][212:204],row2PE[1][212:204],row2PE[2][212:204]})? row2PE[1][209:207] : 3'b111;
	assign	processed[203:201]	= (element_struct=={row2PE[0][209:201],row2PE[1][209:201],row2PE[2][209:201]})? row2PE[1][206:204] : 3'b111;
	assign	processed[200:198]	= (element_struct=={row2PE[0][206:198],row2PE[1][206:198],row2PE[2][206:198]})? row2PE[1][203:201] : 3'b111;
	assign	processed[197:195]	= (element_struct=={row2PE[0][203:195],row2PE[1][203:195],row2PE[2][203:195]})? row2PE[1][200:198] : 3'b111;
	assign	processed[194:192]	= (element_struct=={row2PE[0][200:192],row2PE[1][200:192],row2PE[2][200:192]})? row2PE[1][197:195] : 3'b111;
	assign	processed[191:189]	= (element_struct=={row2PE[0][197:189],row2PE[1][197:189],row2PE[2][197:189]})? row2PE[1][194:192] : 3'b111;
	assign	processed[188:186]	= (element_struct=={row2PE[0][194:186],row2PE[1][194:186],row2PE[2][194:186]})? row2PE[1][191:189] : 3'b111;
	assign	processed[185:183]	= (element_struct=={row2PE[0][191:183],row2PE[1][191:183],row2PE[2][191:183]})? row2PE[1][188:186] : 3'b111;
	assign	processed[182:180]	= (element_struct=={row2PE[0][188:180],row2PE[1][188:180],row2PE[2][188:180]})? row2PE[1][185:183] : 3'b111;
	assign	processed[179:177]	= (element_struct=={row2PE[0][185:177],row2PE[1][185:177],row2PE[2][185:177]})? row2PE[1][182:180] : 3'b111;
	assign	processed[176:174]	= (element_struct=={row2PE[0][182:174],row2PE[1][182:174],row2PE[2][182:174]})? row2PE[1][179:177] : 3'b111;
	assign	processed[173:171]	= (element_struct=={row2PE[0][179:171],row2PE[1][179:171],row2PE[2][179:171]})? row2PE[1][176:174] : 3'b111;
	assign	processed[170:168]	= (element_struct=={row2PE[0][176:168],row2PE[1][176:168],row2PE[2][176:168]})? row2PE[1][173:171] : 3'b111;
	assign	processed[167:165]	= (element_struct=={row2PE[0][173:165],row2PE[1][173:165],row2PE[2][173:165]})? row2PE[1][170:168] : 3'b111;
	assign	processed[164:162]	= (element_struct=={row2PE[0][170:162],row2PE[1][170:162],row2PE[2][170:162]})? row2PE[1][167:165] : 3'b111;
	assign	processed[161:159]	= (element_struct=={row2PE[0][167:159],row2PE[1][167:159],row2PE[2][167:159]})? row2PE[1][164:162] : 3'b111;
	assign	processed[158:156]	= (element_struct=={row2PE[0][164:156],row2PE[1][164:156],row2PE[2][164:156]})? row2PE[1][161:159] : 3'b111;
	assign	processed[155:153]	= (element_struct=={row2PE[0][161:153],row2PE[1][161:153],row2PE[2][161:153]})? row2PE[1][158:156] : 3'b111;
	assign	processed[152:150]	= (element_struct=={row2PE[0][158:150],row2PE[1][158:150],row2PE[2][158:150]})? row2PE[1][155:153] : 3'b111;
	assign	processed[149:147]	= (element_struct=={row2PE[0][155:147],row2PE[1][155:147],row2PE[2][155:147]})? row2PE[1][152:150] : 3'b111;
	assign	processed[146:144]	= (element_struct=={row2PE[0][152:144],row2PE[1][152:144],row2PE[2][152:144]})? row2PE[1][149:147] : 3'b111;
	assign	processed[143:141]	= (element_struct=={row2PE[0][149:141],row2PE[1][149:141],row2PE[2][149:141]})? row2PE[1][146:144] : 3'b111;
	assign	processed[140:138]	= (element_struct=={row2PE[0][146:138],row2PE[1][146:138],row2PE[2][146:138]})? row2PE[1][143:141] : 3'b111;
	assign	processed[137:135]	= (element_struct=={row2PE[0][143:135],row2PE[1][143:135],row2PE[2][143:135]})? row2PE[1][140:138] : 3'b111;
	assign	processed[134:132]	= (element_struct=={row2PE[0][140:132],row2PE[1][140:132],row2PE[2][140:132]})? row2PE[1][137:135] : 3'b111;
	assign	processed[131:129]	= (element_struct=={row2PE[0][137:129],row2PE[1][137:129],row2PE[2][137:129]})? row2PE[1][134:132] : 3'b111;
	assign	processed[128:126]	= (element_struct=={row2PE[0][134:126],row2PE[1][134:126],row2PE[2][134:126]})? row2PE[1][131:129] : 3'b111;
	assign	processed[125:123]	= (element_struct=={row2PE[0][131:123],row2PE[1][131:123],row2PE[2][131:123]})? row2PE[1][128:126] : 3'b111;
	assign	processed[122:120]	= (element_struct=={row2PE[0][128:120],row2PE[1][128:120],row2PE[2][128:120]})? row2PE[1][125:123] : 3'b111;
	assign	processed[119:117]	= (element_struct=={row2PE[0][125:117],row2PE[1][125:117],row2PE[2][125:117]})? row2PE[1][122:120] : 3'b111;
	assign	processed[116:114]	= (element_struct=={row2PE[0][122:114],row2PE[1][122:114],row2PE[2][122:114]})? row2PE[1][119:117] : 3'b111;
	assign	processed[113:111]	= (element_struct=={row2PE[0][119:111],row2PE[1][119:111],row2PE[2][119:111]})? row2PE[1][116:114] : 3'b111;
	assign	processed[110:108]	= (element_struct=={row2PE[0][116:108],row2PE[1][116:108],row2PE[2][116:108]})? row2PE[1][113:111] : 3'b111;
	assign	processed[107:105]	= (element_struct=={row2PE[0][113:105],row2PE[1][113:105],row2PE[2][113:105]})? row2PE[1][110:108] : 3'b111;
	assign	processed[104:102]	= (element_struct=={row2PE[0][110:102],row2PE[1][110:102],row2PE[2][110:102]})? row2PE[1][107:105] : 3'b111;
	assign	processed[101:99]		= (element_struct=={row2PE[0][107:99], row2PE[1][107:99], row2PE[2][107:99]}) ? row2PE[1][104:102] : 3'b111;
	assign	processed[98:96]		= (element_struct=={row2PE[0][104:96], row2PE[1][104:96], row2PE[2][104:96]}) ? row2PE[1][101:99]  : 3'b111;
	assign	processed[95:93]		= (element_struct=={row2PE[0][101:93], row2PE[1][101:93], row2PE[2][101:93]}) ? row2PE[1][98:96]   : 3'b111;
	assign	processed[92:90]		= (element_struct=={row2PE[0][98:90],  row2PE[1][98:90],  row2PE[2][98:90]})  ? row2PE[1][95:93]   : 3'b111;
	assign	processed[89:87]		= (element_struct=={row2PE[0][95:87],  row2PE[1][95:87],  row2PE[2][95:87]})  ? row2PE[1][92:90]   : 3'b111;
	assign	processed[86:84]		= (element_struct=={row2PE[0][92:84],  row2PE[1][92:84],  row2PE[2][92:84]})  ? row2PE[1][89:87]   : 3'b111;
	assign	processed[83:81]		= (element_struct=={row2PE[0][89:81],  row2PE[1][89:81],  row2PE[2][89:81]})  ? row2PE[1][86:84]   : 3'b111;
	assign	processed[80:78]		= (element_struct=={row2PE[0][86:78],  row2PE[1][86:78],  row2PE[2][86:78]})  ? row2PE[1][83:81]   : 3'b111;
	assign	processed[77:75]		= (element_struct=={row2PE[0][83:75],  row2PE[1][83:75],  row2PE[2][83:75]})  ? row2PE[1][80:78]   : 3'b111;
	assign	processed[74:72]		= (element_struct=={row2PE[0][80:72],  row2PE[1][80:72],  row2PE[2][80:72]})  ? row2PE[1][77:75]   : 3'b111;
	assign	processed[71:69]		= (element_struct=={row2PE[0][77:69],  row2PE[1][77:69],  row2PE[2][77:69]})  ? row2PE[1][74:72]   : 3'b111;
	assign	processed[68:66]		= (element_struct=={row2PE[0][74:66],  row2PE[1][74:66],  row2PE[2][74:66]})  ? row2PE[1][71:69]   : 3'b111;
	assign	processed[65:63]		= (element_struct=={row2PE[0][71:63],  row2PE[1][71:63],  row2PE[2][71:63]})  ? row2PE[1][68:66]   : 3'b111;
	assign	processed[62:60]		= (element_struct=={row2PE[0][68:60],  row2PE[1][68:60],  row2PE[2][68:60]})  ? row2PE[1][65:63]   : 3'b111;
	assign	processed[59:57]		= (element_struct=={row2PE[0][65:57],  row2PE[1][65:57],  row2PE[2][65:57]})  ? row2PE[1][62:60]   : 3'b111;
	assign	processed[56:54]		= (element_struct=={row2PE[0][62:54],  row2PE[1][62:54],  row2PE[2][62:54]})  ? row2PE[1][59:57]   : 3'b111;
	assign	processed[53:51]		= (element_struct=={row2PE[0][59:51],  row2PE[1][59:51],  row2PE[2][59:51]})  ? row2PE[1][56:54]   : 3'b111;
	assign	processed[50:48]		= (element_struct=={row2PE[0][56:48],  row2PE[1][56:48],  row2PE[2][56:48]})  ? row2PE[1][53:51]   : 3'b111;
	assign	processed[47:45]		= (element_struct=={row2PE[0][53:45],  row2PE[1][53:45],  row2PE[2][53:45]})  ? row2PE[1][50:48]   : 3'b111;
	assign	processed[44:42]		= (element_struct=={row2PE[0][50:42],  row2PE[1][50:42],  row2PE[2][50:42]})  ? row2PE[1][47:45]   : 3'b111;
	assign	processed[41:39]		= (element_struct=={row2PE[0][47:39],  row2PE[1][47:39],  row2PE[2][47:39]})  ? row2PE[1][44:42]   : 3'b111;
	assign	processed[38:36]		= (element_struct=={row2PE[0][44:36],  row2PE[1][44:36],  row2PE[2][44:36]})  ? row2PE[1][41:39]   : 3'b111;
	assign	processed[35:33]		= (element_struct=={row2PE[0][41:33],  row2PE[1][41:33],  row2PE[2][41:33]})  ? row2PE[1][38:36]   : 3'b111;
	assign	processed[32:30]		= (element_struct=={row2PE[0][38:30],  row2PE[1][38:30],  row2PE[2][38:30]})  ? row2PE[1][35:33]   : 3'b111;
	assign	processed[29:27]		= (element_struct=={row2PE[0][35:27],  row2PE[1][35:27],  row2PE[2][35:27]})  ? row2PE[1][32:30]   : 3'b111;
	assign	processed[26:24]		= (element_struct=={row2PE[0][32:24],  row2PE[1][32:24],  row2PE[2][32:24]})  ? row2PE[1][29:27]   : 3'b111;
	assign	processed[23:21]		= (element_struct=={row2PE[0][29:21],  row2PE[1][29:21],  row2PE[2][29:21]})  ? row2PE[1][26:24]   : 3'b111;
	assign	processed[20:18]		= (element_struct=={row2PE[0][26:18],  row2PE[1][26:18],  row2PE[2][26:18]})  ? row2PE[1][23:21]   : 3'b111;
	assign	processed[17:15]		= (element_struct=={row2PE[0][23:15],  row2PE[1][23:15],  row2PE[2][23:15]})  ? row2PE[1][20:18]   : 3'b111;
	assign	processed[14:12]		= (element_struct=={row2PE[0][20:12],  row2PE[1][20:12],  row2PE[2][20:12]})  ? row2PE[1][17:15]   : 3'b111;
	assign	processed[11:9]		= (element_struct=={row2PE[0][17:9],   row2PE[1][17:9],   row2PE[2][17:9]})   ? row2PE[1][14:12]   : 3'b111;
	assign	processed[8:6]			= (element_struct=={row2PE[0][14:6],   row2PE[1][14:6],   row2PE[2][14:6]})   ? row2PE[1][11:9]    : 3'b111;
	assign	processed[5:3]	 		= (element_struct=={row2PE[0][11:3],   row2PE[1][11:3],   row2PE[2][11:3]})   ? row2PE[1][8:6]     : 3'b111;
	assign	processed[2:0]	 		= (element_struct=={row2PE[0][8:0],    row2PE[1][8:0],    row2PE[2][8:0]})    ? row2PE[1][5:3]     : 3'b111;
	
	
	assign 	dina_bram3_o	= processed;
	
	///WRITE 
	//BRAM-SINGLE_OUTPUT, adress sweep and transmission control 
	always @(negedge clk_i or posedge rst_i)
	begin
		if(rst_i)
		begin
			addra_bram3_o	<= 0;
			wea_bram3_o		<= 0;
			full_o			<= 0;
			full_counter	<= 0;
			start_counter	<= 0;
			vld_mem_o		<= 0;
		end
		else
		begin
			if( video_ACK_i )
			begin
				if( ~empty_i )
				begin
					full_o			<= 0;
					addra_bram3_o	<= 0;
					start_counter	<= 0;
					full_counter	<= 0;
				end
				else
				begin
					if( addra_bram3_o == 7'd125 ) start_counter<=1'b1;
					
					if( start_counter )
					begin
						if( full_counter > 4'h0 )
						begin
							full_o		<= 1'b1;
							vld_mem_o	<= 1'b1;
							wea_bram3_o	<= 1'b0;
						end
						else
						begin
							full_counter	<= full_counter + 1'b1;
						end
					end
					else
					begin
						full_o			<= 1'b0;
						full_counter	<= 0;
					end
				end
				
				if(WRITE) 
				begin
					if( addra_bram3_o[6] != 7'd126 )
					begin
						addra_bram3_o	<= addra_bram3_o + 1'b1;
						wea_bram3_o		<= 1'b1;
					end
					else
					begin
						wea_bram3_o		<= 1'b0;
					end
				end
				else
				begin
					wea_bram3_o			<= 1'b0;
				end	
			end		
		end
	end
endmodule
