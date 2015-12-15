`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:11:20 10/02/2015
// Design Name:   BFSH_Core
// Module Name:   C:/Users/Imprint/Downloads/MP_BFSH_4/MP_BFSH_3/BFSH_TB.v
// Project Name:  MP_BFSH_0
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: BFSH_Core
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module BFSH_TB;

	// Inputs
	reg clk;
	reg rst;
	reg en_pt;
	reg [63:0] pt;
	reg [63:0] key;
	reg en_key;
   reg en_enc_dec;
	// Outputs
	wire core_initializing;
	wire core_busy;
	wire [63:0] ct;
	
	// Instantiate the Unit Under Test (UUT)
	BFSH_Core uut (
		.clk(clk), 
		.rst(rst), 
		.en_pt(en_pt),
		.en_enc_dec(en_enc_dec),
		.pt(pt), 
		.key(key), 
		.en_key(en_key), 
		.core_initializing(core_initializing), 
		.core_busy(core_busy), 
		.ct(ct)
		
	);
	initial begin
		clk = 0;
		forever begin
			#6 clk = ~clk;
		end
	end

	initial begin
		// Initialize Inputs
		
		rst = 0;
		en_pt = 0;
		pt = 0;
		key = 0;
		en_key = 0;
      en_enc_dec = 1'b0;
		// Wait 100 ns for global reset to finish
		#13 rst = 1'b1;
		#50 rst = 1'b0;
		#10 en_key = 1'b1; 
		#10 key = 64'h64_65_73_61_39_33_34_31;//64'h4b_52_55_54_41_52_54_48;
		#10 en_key = 1'b0;
		
		// Add stimulus here
		//#70 $stop;
		#700000 pt = {32'd75,32'd54};
		#10 en_pt = 1'b1;en_enc_dec = 1'b1;
		#10 en_pt = 1'b0;en_enc_dec = 1'b0;
		#1500 pt = {32'h74_A7_54_E7,32'hEA_BB_93_34};
		#10 en_pt = 1'b1;en_enc_dec = 1'b0;
		#17 en_pt = 1'b0;en_enc_dec = 1'b1;
		#1500 $stop;
		
	end
      
endmodule

