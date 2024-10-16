/* 
 * --------------------
 * Project Name			: gkds_sys 
 * Module Name				: fsmc_driver 
 * Description				: The codes of "fsmc_driver"
 * --------------------
 * Tool Versions			: Quartus II 13.1
 * Target Device			: Cyclone IV E  EP4CE10F17C8
 * --------------------
 * Engineer					: weicguodong
 * Revision					: V0.0
 * Created Date			: 2019-11-28
 * --------------------
 * Engineer					:
 * Revision					:
 * Modified Date			:
 * --------------------
 * Additional Comments	: 
 * 
 * --------------------
 */
 /****************************************************************/
 //timescale
`timescale 1 ns / 1 ps

/****************************************************************/
module fsmc_bridge(
	input sys_clk,
	input rst_n,
	
	//fsmc总线相关信号

	input fsmc_nadv,
	input fsmc_wr,
	input fsmc_rd,
	input fsmc_cs,
	inout [15:0]fsmc_db ,

	//外部接口
	// output  [0:0]  BUS_CLK,
 	output  [31:0] BUS_ADDR,
 	// output  [3:0]  BUS_BE,
 	output  [31:0] BUS_DATA_WR,
 	input [31:0] BUS_DATA_RD
); 

/****************************************************************/
//wr和rd信号提取
wire rdn = fsmc_cs | fsmc_rd;
wire wrn = fsmc_cs | fsmc_wr;

/****************************************************************/
//接收地址
reg [15:0]address_reg;
always@(posedge fsmc_nadv or negedge rst_n)
	begin
		if(!rst_n)
			begin
				address_reg <= 24'd0;
			end
		else
			begin
				address_reg <= fsmc_db;
			end
	end

//接收数据
reg [15:0]ad_parameter;
always@(posedge wrn or negedge rst_n)
	begin
		if(!rst_n)
			begin
				ad_parameter <= 16'd0;
			end
		else	
			begin
				ad_parameter <= fsmc_db;
			end
		
	end
assign BUS_ADDR = address_reg;
assign BUS_DATA_WR = wrn ? fsmc_db : 16'hzzzz;
assign fsmc_db = rdn ?  BUS_DATA_RD : 16'hzzzz;
/****************************************************************/
endmodule
