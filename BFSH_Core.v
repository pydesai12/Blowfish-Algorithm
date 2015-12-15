`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: San Jose State University
// Engineer: Krutarth Rami
// 			 Parth Desai
// Create Date:    11:47:56 09/18/2015 
// Design Name: 	 Blowfish_IOT_Encryption
// Module Name:    BFSH_Core 
// Project Name: 	 Master's Project-Encryption using Blowfish for Low Power IOT Devices.
// Target Devices:	Artix-7(Nexys-4) 
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
module BFSH_Core(clk,rst,en_pt,en_enc_dec,pt,key,en_key,core_initializing,core_busy,ct);
	input clk,rst,en_key,en_pt;
	input [63:0] pt,key;  //pt-Plaintext
	input en_enc_dec;
	output core_initializing,core_busy;
	output [63:0] ct;		 //ct-Ciphertext
	
	
	parameter IDLE=3'b000,INIT_P_ARR=3'b001,INIT_PROC=3'b010,INIT_PROC_MEM_RD=3'b011,
	INIT_PROC_WR=4'b110,CORE_IDLE=4'b100,CORE_PROC_MEM_RD=3'b101,CORE_PROC=3'b111;	//States
	
	
	parameter ofx0 = 10'd0,ofx1 = 10'd256,ofx2 = 10'd512,ofx3 = 10'd768;	
	
	wire [9:0] a;
	wire [7:0] b,c,d;
	wire [9:0] addra;
	wire [31:0] dina,douta;
	wire wea;
	
	reg en_key_d,en_pt_d;
	reg en_enc_dec_reg, upd_en_enc_dec_reg; //1:enable ecryption 0:enable Decryption
	reg en_mem,upd_en_mem;
	reg wr_en,upd_wr_en;
	reg first_read,upd_first_read;
	reg LH,upd_LH;
	reg check_wr;
	reg initializing,upd_initializing;
	reg [1:0] init_wr_count,upd_init_wr_count;
	reg [2:0] init_rd_count,upd_init_rd_count;
	reg [2:0] core_rd_count, upd_core_rd_count;
	reg [2:0] st,nx_st;
	reg [31:0] Round,upd_Round;
	reg [31:0] p_count,upd_p_count;
	reg [31:0] init_round_count,upd_init_round_count;
	reg [31:0] assign_p_arr,upd_assign_p_arr;
	reg [31:0] init_mem_wr_count,upd_init_mem_wr_count;
	reg [9:0] addroutreg,upd_addroutreg;
	reg [31:0] XL,upd_XL,XR,upd_XR;
	reg [31:0] P [0:17];  //P-Array
	reg [31:0] addr_XL,upd_addr_XL;
	reg [31:0] upd_p_arr;
	reg [31:0] S0,S1,S2,S3,upd_S0,upd_S1,upd_S2,upd_S3;
	reg [31:0] dina_reg,upd_dina_reg;
			 //Feistel Function Input	
	reg [63:0] str_key,upd_str_key,str_pt,upd_str_pt;
	
	reg [63:0] CT_out,upd_CT_out;
	
	
	
	assign a=addr_XL[31:24];
	assign b=addr_XL[23:16];
	assign c=addr_XL[15:8];
	assign d=addr_XL[7:0];
	
	assign ena = en_mem;
	assign clka = clk;
	assign rsta = rst;
	assign addra = upd_addroutreg;
	assign dina = upd_dina_reg;
	assign wea = upd_wr_en;
	
	assign core_initializing =((st==INIT_PROC)||(st==INIT_PROC_WR)||(INIT_PROC_MEM_RD))?1'b1:1'b0;
	assign core_busy = ((st==CORE_PROC)||(st==CORE_PROC_MEM_RD))?1'b1:1'b0;
	assign ct = CT_out;
	//Feistel Function
	function[31:0] FX;
	input [31:0] s0a,s1b,s2c,s3d;
	reg [31:0] s1,s2;
		begin
			s1 = s0a + s1b;
			s2 = s1 ^ s2c;
			FX = s2 + s3d;
		end
	endfunction
	
//	function [35:0] MEM_RD;
//	
//	input [7:0] addr;
//	input [1:0] count;
//	parameter ofx0 = 10'd0,ofx1 = 10'd256,ofx2 = 10'd512,ofx3 = 10'd768;
//	begin
//	
//	MEM_RD = douta;
//		
//			case(count)
//				2'b00: upd_addroutreg = {2'b00,addr} + ofx0;
//				2'b01: upd_addroutreg = {2'b00,addr} + ofx1;
//				2'b10: upd_addroutreg = {2'b00,addr} + ofx2;
//				2'b11: upd_addroutreg = {2'b00,addr} + ofx3;				
//			endcase
//	end	
//	endfunction
	
//function MEM_WR;
//input [9:0] addr;
//input [35:0] data;
//
//
//	begin
//	upd_addroutreg = addr;
//	upd_dina_reg = data;
//	upd_wr_en = 1'b1;
//	MEM_WR = 1'b1;
//	end
//endfunction
//	
//	function CORE_PROCESS;
//	endfunction
//Memory 32x1024 Initialized by fractional value of pi
	blk_mem_gen_v7_3 BRAM (
  .clka(clka), // input clka
  .rsta(rsta), // input rsta
  .ena(ena), // input ena
  .wea(wea), // input [0 : 0] wea
  .addra(addra), // input [9 : 0] addra
  .dina(dina), // input [31 : 0] dina
  .douta(douta) // output [31 : 0] douta
);

	always @(posedge clk or posedge rst)
	begin
		if(rst)
		begin
			en_key_d <= #1 1'b0;
			en_pt_d <= #1 1'b0;
			en_mem <= 1'b0;
			wr_en <= 1'b0;
			first_read <= #1 1'b1;								
			st <= #1 3'b000;
			str_key <= #1 64'b0;
			str_pt <= #1 64'b0;
			init_rd_count <= #1 3'b0;
			p_count <= #1 0;
			init_wr_count <= #1 2'b0;
			init_mem_wr_count <= #1 0;
			core_rd_count <= #1 3'b0;
			addroutreg <= #1 10'd0;
			dina_reg <= #1 36'b0;
			LH <= #1 1'b0;
			initializing <= #1 1'b0;
			en_enc_dec_reg <= #1 1'b0;
			
			CT_out <= 1'b0;
			
			Round <= #1 0;
			XL <= #1 0;
			XR <= #1 0;
			S0 <= #1 32'b0;
			S1 <= #1 32'b0;
			S2 <= #1 32'b0;
			S3 <= #1 32'b0;
			assign_p_arr <= #1 0;
			init_round_count <= #1 0;
			addr_XL <= #1 0;
			
			P[0] <= #1 32'h243F6A88;
			P[1] <= #1 32'h085A308D3;
			P[2] <= #1 32'h13198A2E;			//Initialize P-Array on Reset
			P[3] <= #1 32'h03707344;
			P[4] <= #1 32'hA4093822;
			P[5] <= #1 32'h299F31D0;
			P[6] <= #1 32'h082EFA98;
			P[7] <= #1 32'hEC4E6C89;
			P[8] <= #1 32'h452821E6;
			P[9] <= #1 32'h38D01377;
			P[10] <= #1 32'hBE5466CF;
			P[11] <= #1 32'h34E90C6C;
			P[12] <= #1 32'hC0AC29B7;
			P[13] <= #1 32'hC97C50DD;
			P[14] <= #1 32'h3F84D5B5;
			P[15] <= #1 32'hB5470917;
			P[16] <= #1 32'h9216D5D9;
			P[17] <= #1 32'h8979FB1B;
			
			
		end
		else
		begin
			if ((st==IDLE||st==CORE_IDLE) && en_key)
				str_key <= #1 key;
			else
				str_key <= #1 upd_str_key;
			
			if (st==CORE_IDLE && en_pt)
				begin
					str_pt <= #1 pt;
					en_enc_dec_reg <= #1 en_enc_dec;
					XL <= #1 pt[63:32];
					XR <= #1 pt[31:0];
				end
			else
				begin
					en_enc_dec_reg <= #1 upd_en_enc_dec_reg;
					str_pt <= #1 upd_str_pt;
					XL <= #1 upd_XL;
					XR <= #1 upd_XR;
					
				end
			if(st==INIT_P_ARR)
				P[p_count] <= #1 upd_p_arr;
			else if ((st==INIT_PROC_WR) && (assign_p_arr < 18) && (!assign_p_arr[0]) )
				begin
					P[assign_p_arr] <= #1 XL;
					P[assign_p_arr+1] <= #1 XR;
				end
			else
				begin
				
				end
			if(st==CORE_PROC && nx_st==CORE_IDLE)
			CT_out <= #1 {upd_XL,upd_XR};
			else
			CT_out <= #1 upd_CT_out;
			
			addr_XL <= #1 upd_addr_XL;
			st <= #1 nx_st;
			en_key_d <= #1 en_key;
			en_pt_d <= #1 en_pt;
			addroutreg <= #1 upd_addroutreg;
			dina_reg <= #1 upd_dina_reg;
			
			init_round_count <= #1 upd_init_round_count;
			assign_p_arr <= #1 upd_assign_p_arr;
			
			initializing <= #1 upd_initializing;
			LH <= #1 upd_LH;
			S0 <= #1 upd_S0;
			S1 <= #1 upd_S1;
			S2 <= #1 upd_S2;
			S3 <= #1 upd_S3;
			wr_en <= #1 upd_wr_en;
			init_rd_count <= #1 upd_init_rd_count;
			p_count <= #1 upd_p_count;
			init_wr_count <= #1 upd_init_wr_count;
			init_mem_wr_count <= #1 upd_init_mem_wr_count;
			Round <= #1 upd_Round;
			core_rd_count <= #1 upd_core_rd_count;
			first_read <= #1 upd_first_read;
			en_mem <= #1 upd_en_mem;
		end

	end 
always @(*)
begin
	nx_st = 3'b000;
	upd_init_rd_count = 3'b0;
	upd_p_count = p_count;
	upd_init_wr_count = 2'b0;
	upd_init_mem_wr_count = init_mem_wr_count;
	upd_Round = Round;
	upd_core_rd_count = 3'b0;
	upd_first_read = first_read;
	upd_en_mem = 1'b1;
	upd_addroutreg = 10'd0;
	upd_wr_en = 1'b0;
	upd_dina_reg = dina_reg;
	upd_str_key = str_key;
	upd_str_pt = str_pt;
	upd_en_enc_dec_reg = en_enc_dec_reg;
	upd_S0 = S0;
	upd_S1 = S1;
	upd_S2 = S2;
	upd_S3 = S3;
	upd_XL = XL;
	upd_XR = XR;
	upd_addr_XL = addr_XL;
	upd_LH = 0;
	upd_init_round_count = init_round_count;
	upd_assign_p_arr = assign_p_arr;
	
	upd_CT_out = CT_out;
	//check_wr = 0;
	//upd_initializing = initializing;
	upd_p_arr = P [p_count];
	case(st)
		IDLE:begin
					upd_p_count = 0;
					upd_first_read = 1'b1;
					if((en_key_d == 1'b1)&&(en_key == 1'b0))
					nx_st = INIT_P_ARR;
					else
					begin
						upd_en_mem = 1'b0;
						nx_st = IDLE;
					end
			  end
		INIT_PROC_MEM_RD:begin
									case(init_rd_count)
										3'b000: upd_addroutreg = {a} + ofx0;
										3'b001: upd_addroutreg = {2'b00,b} + ofx1;
										3'b010: upd_addroutreg = {2'b00,c} + ofx2;
										3'b011: upd_addroutreg = {2'b00,d} + ofx3;
										3'b100: upd_addroutreg = 10'd0;
									endcase
									case(init_rd_count)
										3'b000:upd_S0 = S0;
										3'b001:upd_S0 = douta;
										3'b010:upd_S1 = douta;
										3'b011:upd_S2 = douta;
										3'b100:upd_S3 = douta;
									endcase
									if(init_rd_count == 3'b100)
									begin
									   upd_init_rd_count = 3'b0;
										nx_st = INIT_PROC;			
									end
									else
									begin
										upd_init_rd_count = init_rd_count +3'b001;
										nx_st = INIT_PROC_MEM_RD;
									end
							  end
		INIT_P_ARR:begin
						if(p_count <= 17)
						begin	
							upd_LH = ~LH;
							upd_p_arr = (LH)?(P[p_count] ^ {str_key[31:0]}):(P[p_count] ^ {str_key[63:32]});
							upd_p_count = p_count + 1;
							upd_first_read = 1'b1;							
							nx_st = INIT_P_ARR;
						end
						else
						begin
							upd_LH = 1'b0;
							upd_addr_XL = XL ^ P[0];
							nx_st = INIT_PROC_MEM_RD;
						end
					 end
		INIT_PROC:begin
						if(init_round_count < 16)
							begin
								
								
								upd_XR = XL ^ P[init_round_count];
								upd_XL = FX(S0,S1,S2,S3) ^ XR;
								upd_addr_XL = upd_XL ^ P[init_round_count+1];
								
								
								upd_init_round_count = init_round_count + 1;
								nx_st = INIT_PROC_MEM_RD;
							end
						else
							begin
								
								upd_XR = XL ^ P[upd_init_round_count];
								upd_XL = XR ^ P[upd_init_round_count+1];
								upd_init_round_count = 0;
								
								nx_st = INIT_PROC_WR;
							end
					 end
		INIT_PROC_WR:begin
									upd_init_wr_count = init_wr_count +2'b01;
									upd_init_mem_wr_count = init_mem_wr_count + 1;
									if((init_mem_wr_count < 18)&&(assign_p_arr < 18))
									begin
										upd_assign_p_arr = assign_p_arr + 1;
										upd_init_wr_count = 2'b0;
										if(!assign_p_arr[0])
										nx_st = INIT_PROC_WR;
										else
										begin
										upd_addr_XL = XL ^ P[0];
										nx_st = INIT_PROC_MEM_RD;
										end
									end
									else if ((init_wr_count > 2'b01) && (init_mem_wr_count < 1042) && (init_mem_wr_count > 8))
									begin
										upd_init_mem_wr_count = init_mem_wr_count;
										upd_init_wr_count = 2'b0;
										upd_addr_XL = XL ^ P[0];
										upd_assign_p_arr = assign_p_arr;
										nx_st = INIT_PROC_MEM_RD;
										
									end
									else if(init_mem_wr_count >= 1042)
									begin
										upd_assign_p_arr = assign_p_arr;
										upd_init_mem_wr_count = 0;
										upd_init_wr_count = 2'b00;
										upd_XL = 0;
										upd_XR = 0;
										nx_st = CORE_IDLE;
									end
									else
									begin
										upd_assign_p_arr = assign_p_arr;
										upd_addroutreg = init_mem_wr_count - 18;
										upd_dina_reg = (init_wr_count)?(XR):(XL);
										upd_wr_en = 1'b1; 
										nx_st = INIT_PROC_WR;
									end
									
							  end
		CORE_IDLE:begin
						if((en_pt_d == 1'b1)&&(en_pt == 1'b0)&&(!en_key))
						begin
							if(~en_enc_dec_reg)
								begin
								upd_Round = 32'd17;
								upd_addr_XL = XL ^ P[17];
								end
							else
								begin
								upd_Round = 32'd0;
								upd_addr_XL = XL ^ P[0];
								end
							nx_st = CORE_PROC_MEM_RD;
						end
						else if (en_key)
						begin
							upd_en_mem = 1'b0;
							nx_st = IDLE;
						end
						else
						begin
							upd_en_mem = 1'b0;
							nx_st = CORE_IDLE;
						end
					 end
		CORE_PROC:begin
							if(en_enc_dec_reg)
								begin
									if(Round < 16)
									begin
										upd_XR = XL ^ P[Round];
										upd_XL = FX(S0,S1,S2,S3) ^ XR;
										upd_Round = Round + 1;
										upd_addr_XL = upd_XL ^ P[Round+1];
										nx_st = CORE_PROC_MEM_RD;
									end
									else
									begin
										upd_XR = XL ^ P[upd_Round];
										upd_XL = XR ^ P[upd_Round+1];
										upd_init_round_count = 0;
										
										upd_XR = XL ^ P[upd_Round];
										upd_XL = XR ^ P[upd_Round+1];
										upd_Round = 0;
										nx_st = CORE_IDLE;
									end
								end
							else
								begin
									if(Round > 1)
									begin
										upd_XR = XL ^ P[Round];
										upd_XL = FX(S0,S1,S2,S3) ^ XR;
										upd_Round = Round - 1;
										upd_addr_XL = upd_XL ^ P[Round-1];
										nx_st = CORE_PROC_MEM_RD;
									end
									else
									begin
										upd_XR = XL ^ P[upd_Round];
										upd_XL = XR ^ P[upd_Round-1];
											
											
										upd_XR = XL ^ P[upd_Round];
										upd_XL = XR ^ P[upd_Round-1];
										upd_Round = 0;
										nx_st = CORE_IDLE;
									end

								end
					 end
		CORE_PROC_MEM_RD:begin
									case(core_rd_count)
										3'b000: upd_addroutreg = {a} + ofx0;
										3'b001: upd_addroutreg = {2'b00,b} + ofx1;
										3'b010: upd_addroutreg = {2'b00,c} + ofx2;
										3'b011: upd_addroutreg = {2'b00,d} + ofx3;
										3'b100: upd_addroutreg = 10'd0;
									endcase
									case(core_rd_count)
										3'b000:upd_S0 = S0;
										3'b001:upd_S0 = douta;
										3'b010:upd_S1 = douta;
										3'b011:upd_S2 = douta;
										3'b100:upd_S3 = douta;
									endcase
									
									if(core_rd_count==3'b100)
									begin
										upd_core_rd_count = 3'b0;
										nx_st = CORE_PROC;
									end
									else
									begin
										upd_core_rd_count = core_rd_count + 3'b001;
										nx_st = CORE_PROC_MEM_RD;
									end
							  end
	endcase


end
endmodule


		/*
P-Array initial values
243F6A88,
85A308D3,
13198A2E,
03707344,
A4093822,
299F31D0,
082EFA98,
EC4E6C89,
452821E6,
38D01377,
BE5466CF,
34E90C6C,
C0AC29B7,
C97C50DD,
3F84D5B5,
B5470917,
9216D5D9,
8979FB1B,*/

