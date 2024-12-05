
`timescale 1 ns / 1 ps


module fsmc_bridge(
	input sys_clk,
	input rst_n,
	
	input fsmc_nadv,
	input fsmc_wr,
	input fsmc_rd,
	input fsmc_cs,
	inout [15:0]fsmc_db ,


 	output  [15:0] BUS_ADDR,

 	output  [15:0] BUS_DATA_WR,
 	input [15:0] BUS_DATA_RD
); 



wire rdn ;
wire wrn ;

assign  rdn = fsmc_cs | fsmc_rd;
assign  wrn = fsmc_cs | fsmc_wr;


reg [15:0]address_reg;
always@(posedge sys_clk or negedge rst_n)
	begin
		if(!rst_n)
			begin
				address_reg <= 16'd0;
			end
		else if (~fsmc_nadv && wrn ) begin 
				address_reg <= fsmc_db;
			end
		else begin
			address_reg <= address_reg;
	end
	end
assign BUS_ADDR = address_reg;
assign BUS_DATA_WR = wrn ? fsmc_db : 16'hzzzz;
assign fsmc_db = rdn ?  BUS_DATA_RD : 16'hzzzz;


//ila_0 ila_0(
//.clk	(sys_clk),
//.probe0	(fsmc_nadv),
//.probe1	(fsmc_wr),
//.probe2	(fsmc_rd),
//.probe3	(fsmc_cs),
//.probe4	(fsmc_db),
//.probe5	(address_reg),
//.probe6	(BUS_DATA_WR),
//.probe7	(BUS_DATA_RD)
////.probe8	(),
////.probe9	(),
////.probe10()
//);
endmodule
