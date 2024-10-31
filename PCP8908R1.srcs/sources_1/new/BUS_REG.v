module BUS (
  input io_clk,
  // input io_rst,

  input  [1:0]  io_be,
  input  [15:0] io_addr,
  input  [15:0] io_data_i,
  output [15:0] io_data_o,
// INPUT DATA
  input  [15:0]     module_status0,
  input  [15:0]     module_status1,
  input  [15:0]     module_status2,
  input  [15:0]     module_status3,
  input  [15:0]     module_status4,
  //OUTPUT REG
  output [15:0]     module_control
 
);

  wire C = io_clk;
  // wire R = io_rst;
  wire [1:0]BE = io_be;
  wire [15:0] A = io_addr;
  wire [15:0] D = io_data_i;
  reg   [31:0] DATA_RD;

  //test regs
  wire [(16*16 -1):0] test_reg;

// reg read 
assign io_data_o = DATA_RD;
  always @(*) begin
    case ({io_addr[15:1],1'd0})
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
BUS_CATCH #('h0002,'d2) X0002 (C,BE,A,D, module_control);
BUS_CATCH #('h0100,'d2) X0100 (C,BE,A,D, test_reg[16*0 +:16]);
BUS_CATCH #('h0104,'d2) X0104 (C,BE,A,D, test_reg[16*1 +:16]);
BUS_CATCH #('h0108,'d2) X0108 (C,BE,A,D, test_reg[16*2 +:16]);
BUS_CATCH #('h010c,'d2) X010c (C,BE,A,D, test_reg[16*3 +:16]);
BUS_CATCH #('h0110,'d2) X0110 (C,BE,A,D, test_reg[16*4 +:16]);
BUS_CATCH #('h0114,'d2) X0114 (C,BE,A,D, test_reg[16*5 +:16]);
BUS_CATCH #('h0118,'d2) X0118 (C,BE,A,D, test_reg[16*6 +:16]);
BUS_CATCH #('h011c,'d2) X011c (C,BE,A,D, test_reg[16*7 +:16]);
BUS_CATCH #('h0120,'d2) X0120 (C,BE,A,D, test_reg[16*8 +:16]);
BUS_CATCH #('h0124,'d2) X0124 (C,BE,A,D, test_reg[16*9 +:16]);
BUS_CATCH #('h0128,'d2) X0128 (C,BE,A,D, test_reg[16*10+:16]);
BUS_CATCH #('h012c,'d2) X012c (C,BE,A,D, test_reg[16*11+:16]);
BUS_CATCH #('h0130,'d2) X0130 (C,BE,A,D, test_reg[16*12+:16]);
BUS_CATCH #('h0134,'d2) X0134 (C,BE,A,D, test_reg[16*13+:16]);
BUS_CATCH #('h0138,'d2) X0138 (C,BE,A,D, test_reg[16*14+:16]);
BUS_CATCH #('h013c,'d2) X013c (C,BE,A,D, test_reg[16*15+:16]);

endmodule