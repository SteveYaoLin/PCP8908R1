module BUS (
  input io_clk,
  input rst_n,
  input burst_clk,
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
  output  reg [15:0] cnt_limit_down           ,
  output  reg [15:0] store_cnt                ,
  output  reg [15:0] module_control
 
);
parameter _WR_DELAY = 4'd2;
parameter _RD_DELAY = 4'd1;
wire addr_0002_catch ;
wire rdn ;
wire wrn ;
  // wire C ;
  // wire R ;
  // wire W ; 
  // wire [1:0]BE ;
  // wire [15:0] A ;
  // wire [15:0] D ;
  reg  [15:0] DATA_RD;
  wire [15:0] ADDR_RD;
  wire [15:0] ADDR_WR;
  reg [15:0] address_reg;
  reg [15:0] module_test;


  //test regs
  wire [(16*16 -1):0] test_reg;
  wire [15:0] ADDR_RD_test ;
  wire [15:0] ADDR_WR_test ;
  reg [3:0] wr_delay_cnt;
  wire wr_delay_assecced;
  reg [3:0] rd_delay_cnt;
  wire rd_delay_assecced;

  // reg [15:0] cnt_limit_down ;
  // reg [15:0] store_cnt      ;
  
assign ADDR_RD = address_reg & {16{~rdn}} & {16{~io_cs}};
assign ADDR_WR = address_reg & {16{~wrn}} & {16{~io_cs}};
// reg read 
assign io_data = ~(rdn | io_cs) ? DATA_RD : 16'hzzzz;
assign  addrphase = io_nadv | io_cs;
assign  rdn = io_cs | rd_delay_assecced | io_rd;
assign  wrn = io_cs | wr_delay_assecced | io_wr;

  // assign BE = io_be;
  // assign A = address_reg;
  // assign D = io_data;
  // assign C = io_clk;
  // assign R = rst_n;
  // assign W = ~(wrn|io_cs); 

  assign ADDR_RD_test = address_reg & {16{~rdn}} & {16{~io_cs}};
  assign ADDR_WR_test = address_reg & {16{~wrn}} & {16{~io_cs}};
  assign addr_0002_catch = (address_reg == 16'h0002) ? 1'b1 : 1'b0;

// wr keeps counter
always@(posedge io_clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        wr_delay_cnt <= 4'd0;
      end
    else if (io_wr == 1'b0) begin
        if  (wr_delay_cnt == _WR_DELAY) begin
            wr_delay_cnt <= _WR_DELAY;
        end
        else  begin
            wr_delay_cnt <= wr_delay_cnt + 1'b1;
        end
      end
    else begin
        wr_delay_cnt <= 4'd0;
      end
  end
  assign  wr_delay_assecced = (wr_delay_cnt == _WR_DELAY) ? 1'b0 : 1'b1;

  // wr keeps counter
always@(posedge io_clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        rd_delay_cnt <= 4'd0;
      end
    else if (io_rd == 1'b0) begin
        if  (rd_delay_cnt == _RD_DELAY) begin
            rd_delay_cnt <= _RD_DELAY;
        end
        else  begin
            rd_delay_cnt <= rd_delay_cnt + 1'b1;
        end
      end
    else begin
        rd_delay_cnt <= 4'd0;
      end
  end
  assign  rd_delay_assecced = (rd_delay_cnt == _RD_DELAY) ? 1'b0 : 1'b1;

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
    'h000e : DATA_RD = module_test;
    'h0010 : DATA_RD = cnt_limit_down;
    'h0012 : DATA_RD = store_cnt;
    

    // 'h0100 : DATA_RD = test_reg[16*0 +:16];
    // 'h0104 : DATA_RD = test_reg[16*1 +:16];
    // 'h0108 : DATA_RD = test_reg[16*2 +:16];
    // 'h010c : DATA_RD = test_reg[16*3 +:16];
    // 'h0110 : DATA_RD = test_reg[16*4 +:16];
    // 'h0114 : DATA_RD = test_reg[16*5 +:16];
    // 'h0118 : DATA_RD = test_reg[16*6 +:16];
    // 'h011c : DATA_RD = test_reg[16*7 +:16];
    // 'h0120 : DATA_RD = test_reg[16*8 +:16];
    // 'h0124 : DATA_RD = test_reg[16*9 +:16];
    // 'h0128 : DATA_RD = test_reg[16*10+:16];
    // 'h012c : DATA_RD = test_reg[16*11+:16];
    // 'h0130 : DATA_RD = test_reg[16*12+:16];
    // 'h0134 : DATA_RD = test_reg[16*13+:16];
    // 'h0138 : DATA_RD = test_reg[16*14+:16];
    // 'h013c : DATA_RD = test_reg[16*15+:16];

    default : DATA_RD = 32'h0;
    endcase
  end

  always @(posedge io_clk or negedge rst_n) begin
    if (!rst_n) begin
      module_control <= 0;
    end
    // else if (io_wr == 1'b0 && address_reg == 'h0002 && io_cs == 1'b0) begin
    else if (addr_0002_catch&!wrn) begin
      module_control <= io_data;
    end
    else  begin
      module_control <= module_control;
    end
  end

  always @(posedge io_clk or negedge rst_n) begin
    if (!rst_n) begin
      module_test <= 0;
    end
    else if (wrn == 1'b0 && address_reg == 'h000e) begin
      module_test <= io_data;
    end
    else  begin
      module_test <= module_test;
    end
  end

  always @(posedge io_clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt_limit_down <= 'd2519;//10M point at 65MSPS 16384 
    end
    else if (wrn == 1'b0 && address_reg == 'h0010) begin
      cnt_limit_down <= io_data;
    end
    else  begin
      cnt_limit_down <= cnt_limit_down;
    end
  end

  always @(posedge io_clk or negedge rst_n) begin
    if (!rst_n) begin
      store_cnt <= 'd1262; // increase number 15M point at 65MSPS 16384 
    end
    else if (wrn == 1'b0 && address_reg == 'h0012) begin
      store_cnt <= io_data;
    end
    else  begin
      store_cnt <= store_cnt;
    end
  end


//reg write
// bus_write #('h0002,'d2) 
//   X0002 
//     (
//     .io_rst(R)        ,
//     .io_clk(C)        ,
//     .io_wr(W                ),
//     .addrCatch(addr_0002_catch  ),
//     .io_wen(BE),
//     .io_addr(ADDR_WR       ),
//     .io_data(D                ),
//     .io_dout(module_control)
//     );

// bus_write #(16'h000e) X000E (
//   .rst_n(rst_n),
//   .io_clk(io_clk),
//   .io_wr(wrn),
//   .io_addr(address_reg),
//   .io_data(io_data),
//   .io_dout(module_test)
//   );

// bus_write #('h0100) X0100 (R,C,wrn,ADDR_WR,D,test_reg[16*0 +:16]);
// bus_write #('h0104) X0104 (R,C,wrn,ADDR_WR,D,test_reg[16*1 +:16]);
// bus_write #('h0108) X0108 (R,C,wrn,ADDR_WR,D,test_reg[16*2 +:16]);
// bus_write #('h010c) X010c (R,C,wrn,ADDR_WR,D,test_reg[16*3 +:16]);
// bus_write #('h0110) X0110 (R,C,wrn,ADDR_WR,D,test_reg[16*4 +:16]);
// bus_write #('h0114) X0114 (R,C,wrn,ADDR_WR,D,test_reg[16*5 +:16]);
// bus_write #('h0118) X0118 (R,C,wrn,ADDR_WR,D,test_reg[16*6 +:16]);
// bus_write #('h011c) X011c (R,C,wrn,ADDR_WR,D,test_reg[16*7 +:16]);
// bus_write #('h0120) X0120 (R,C,wrn,ADDR_WR,D,test_reg[16*8 +:16]);
// bus_write #('h0124) X0124 (R,C,wrn,ADDR_WR,D,test_reg[16*9 +:16]);
// bus_write #('h0128) X0128 (R,C,wrn,ADDR_WR,D,test_reg[16*10+:16]);
// bus_write #('h012c) X012c (R,C,wrn,ADDR_WR,D,test_reg[16*11+:16]);
// bus_write #('h0130) X0130 (R,C,wrn,ADDR_WR,D,test_reg[16*12+:16]);
// bus_write #('h0134) X0134 (R,C,wrn,ADDR_WR,D,test_reg[16*13+:16]);
// bus_write #('h0138) X0138 (R,C,wrn,ADDR_WR,D,test_reg[16*14+:16]);
// bus_write #('h013c) X013c (R,C,wrn,ADDR_WR,D,test_reg[16*15+:16]);

//  ila_0 ila_0
//  (
// .clk	(io_clk),
// .probe0	(burst_clk),
// .probe1	({io_wr,io_rd,io_nadv,io_cs,rdn,wrn,addrphase}),
// .probe2	(DATA_RD),
// .probe3	(ADDR_WR_test),
// .probe4	(ADDR_RD_test),
// .probe5	(module_control),
// .probe6	(module_test)
// // .probe7	()
// );

// ila_0 ila_0(
// .clk	(io_clk),
// .probe0	(io_nadv),
// .probe1	(io_wr),
// .probe2	(io_rd),
// .probe3	(io_cs),
// .probe4	(burst_clk),
// .probe5	(ADDR_RD_test),
// .probe6	(module_control),
// .probe7	(ADDR_WR_test),
// .probe8	(addr_0002_catch)
// //.probe9	(),
// //.probe10(),
// //.probe11()
// );

endmodule