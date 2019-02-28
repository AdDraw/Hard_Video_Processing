////////////////////////////////////////////////////////////////////////////////////////////
// Company: 			Gdansk University of Technology
// Engineer: 			Adam Drawc 
// Create Date:   	23:16:03 09/24/2018 
// Design Name:    	Version_3
// Module Name:    	clk_div_IIC 
// Project Name:   	Hardware video processing path in FPGA
// Target Devices: 	ML509/XUPV5
// Tool versions:  	14.7
// Description: 		Clk divider for IIC bus clock
// Additional Comments: 
//			:Version_1 - IIC_clk =50kHz, Freq divider= 2000 (works with an input clock 100MHz)
//       :Version_2 - Added an automatically computated divider constanst  
//			:Version_3 - Added NoDivide option (proper behaviour of the module when in/out freqs are to be the same) 
////////////////////////////////////////////////////////////////////////////////////////////
// Module clk_div_IIC acts as a clock divider for an input Clock. The same could be achieved 
// by using a PLL loop but if limited resources are available this clock divider should be sufficient.
// Error percentage is only low for a limited group of even numbers (2,4,6.. etc). Does work 
// with every Clock divider but then the error will have a greater value.
// Through the use of local parameters clk divider can be automatically computated without 
// the need for manual computation. Works through a simple case statement that will toggle
// the output clock onle when the conditions are met. There is only one condition. If the included 
// counter is at the half of the divider constant (const_div) then output will switch to '1' and if its 
// equal to divider constant it switches to '0' and zreoes the counter.
////////////////////////////////////////////////////////////////////////////////////////////
module clk_div_IIC(clk_i,rst_i,clk_o);

	localparam f_i = 100000000, 		//frequency of the input clk
				  f_o = 100000, 		 	//desired frequency of the output clk
				  const_div = f_i/f_o ; //automatically computated divider constanst  	 	

	input clk_i,rst_i;
	output wire clk_o;

	wire divide;
	reg clk_temp=1'b0;

	assign clk_o=(divide)? clk_temp:clk_i;
	assign divide =(const_div==1) ? 1'b0 : 1'b1 ;
	integer cnt=0;

	always @(posedge clk_i or posedge rst_i)
	begin 
		if(rst_i)
			begin
				cnt=0;
				clk_temp=1'b0;
			end 
		else
		begin
			if(divide)	
			begin
				cnt=cnt+1;
				case(cnt) 
				const_div/2: clk_temp=1'b1;
				const_div  : begin 
									clk_temp=1'b0;
									cnt=0;
								 end
				endcase
			end						
		end 	
	end 		
endmodule
