module BUS (
  input io_clk,
  input rst_n,
  input io_wr,
  input io_rd,
  input io_nadv,
  input io_cs,
  input  [1:0]  io_be,
  // input  [15:0] io_addr,
  inout  [15:0] io_data,
  // output [15:0] io_data_o,
// INPUT DATA
  input  [15:0]     module_status0,
  input  [15:0]     module_status1,
  input  [15:0]     module_status2,
  input  [15:0]     module_status3,
  input  [15:0]     module_status4,
  //OUTPUT REG
  output [15:0]     module_control
 
);

  wire C ;
  wire R ;
  wire W ; 
  wire [1:0]BE;
  wire [15:0] A ;
  wire [15:0] D ;
  reg  [15:0] DATA_RD;
  wire [15:0] ADDR_RD;
  reg [15:0]address_reg;
  //test regs
  wire [(16*16 -1):0] test_reg;
assign ADDR_RD = address_reg & {16{~io_rd}} & {16{~io_cs}};
// reg read 
assign io_data = ~(io_rd | io_cs) ? DATA_RD : 16'hzzzz;
assign  addrphase = io_nadv | io_cs;

  assign BE = io_be;
  assign A = address_reg;
  assign D = io_data;
  assign C = io_clk;
  assign R = rst_n;
  assign W = ~(io_wr|io_cs); 
//create addrreg
always@(posedge io_clk or negedge rst_n)
	begin
		if(!rst_n)
			begin
				address_reg <= 16'd0;
			end
		else if ((addrphase== 1'b0) & io_data[15] == 1'b0 )begin 
				address_reg <= {io_data[14:0],1'b0};
			end
		else begin
			address_reg <= address_reg;
	end
end
// READ
  always @(*) begin
    case (ADDR_RD)
    'h0002 : DATA_RD = module_control;   
    'h0004 : DATA_RD = module_status0;  
    'h0006 : DATA_RD = module_status1;
    'h0008 : DATA_RD = module_status2;
    'h000a : DATA_RD = module_status3;
    'h000c : DATA_RD = module_status4;

    'h0100 : DATA_RD = test_reg[16*0 +:16];
    'h0104 : DATA_RD = test_reg[16*1 +:16];
    'h0108 : DATA_RD = test_reg[16*2 +:16];
    'h010c : DATA_RD = test_reg[16*3 +:16];
    'h0110 : DATA_RD = test_reg[16*4 +:16];
    'h0114 : DATA_RD = test_reg[16*5 +:16];
    'h0118 : DATA_RD = test_reg[16*6 +:16];
    'h011c : DATA_RD = test_reg[16*7 +:16];
    'h0120 : DATA_RD = test_reg[16*8 +:16];
    'h0124 : DATA_RD = test_reg[16*9 +:16];
    'h0128 : DATA_RD = test_reg[16*10+:16];
    'h012c : DATA_RD = test_reg[16*11+:16];
    'h0130 : DATA_RD = test_reg[16*12+:16];
    'h0134 : DATA_RD = test_reg[16*13+:16];
    'h0138 : DATA_RD = test_reg[16*14+:16];
    'h013c : DATA_RD = test_reg[16*15+:16];

    default : DATA_RD = 32'h0;
    endcase
  end
//reg write
bus_write #('h0002,'d2) X0002 (R,C,W,BE,A,D,module_control);
bus_write #('h0100,'d2) X0100 (R,C,W,BE,A,D,test_reg[16*0 +:16]);
bus_write #('h0104,'d2) X0104 (R,C,W,BE,A,D,test_reg[16*1 +:16]);
bus_write #('h0108,'d2) X0108 (R,C,W,BE,A,D,test_reg[16*2 +:16]);
bus_write #('h010c,'d2) X010c (R,C,W,BE,A,D,test_reg[16*3 +:16]);
bus_write #('h0110,'d2) X0110 (R,C,W,BE,A,D,test_reg[16*4 +:16]);
bus_write #('h0114,'d2) X0114 (R,C,W,BE,A,D,test_reg[16*5 +:16]);
bus_write #('h0118,'d2) X0118 (R,C,W,BE,A,D,test_reg[16*6 +:16]);
bus_write #('h011c,'d2) X011c (R,C,W,BE,A,D,test_reg[16*7 +:16]);
bus_write #('h0120,'d2) X0120 (R,C,W,BE,A,D,test_reg[16*8 +:16]);
bus_write #('h0124,'d2) X0124 (R,C,W,BE,A,D,test_reg[16*9 +:16]);
bus_write #('h0128,'d2) X0128 (R,C,W,BE,A,D,test_reg[16*10+:16]);
bus_write #('h012c,'d2) X012c (R,C,W,BE,A,D,test_reg[16*11+:16]);
bus_write #('h0130,'d2) X0130 (R,C,W,BE,A,D,test_reg[16*12+:16]);
bus_write #('h0134,'d2) X0134 (R,C,W,BE,A,D,test_reg[16*13+:16]);
bus_write #('h0138,'d2) X0138 (R,C,W,BE,A,D,test_reg[16*14+:16]);
bus_write #('h013c,'d2) X013c (R,C,W,BE,A,D,test_reg[16*15+:16]);

//ila_0 ila_0(
//.clk	(io_clk),
//.probe0	(io_nadv),
//.probe1	(io_wr),
//.probe2	(io_rd),
//.probe3	(io_cs),
//.probe4	(module_control),
//.probe5	(address_reg),
//.probe6	(ADDR_RD),
//.probe7	(DATA_RD),
//.probe8	(addrphase)
////.probe9	(),
////.probe10(),
////.probe11()
//);

endmodule