module BUS (
  input io_clk,
  // input io_rst,

  input  [1:0]  io_be,
  input  [15:0] io_addr,
  input  [15:0] io_data_i,
  output [15:0] io_data_o,
// INPUT DATA
  input  [15:0]     module_status,
  //OUTPUT REG
  output [15:0]     module_control
 
);

  wire C = io_clk;
  // wire R = io_rst;
  wire [1:0]BE = io_be;
  wire [15:0] A = io_addr;
  wire [15:0] D = io_data_i;
  reg   [31:0] DATA_RD;

// reg read 
assign io_data_o = DATA_RD;
  always @(*) begin
    case ({io_addr[15:1],1'd0})
    'h0002 : DATA_RD = module_control;   
    'h0004 : DATA_RD = module_status;  
    default : DATA_RD = 32'h0;
    endcase
  end
//reg write
BUS_CATCH #('h0002,'d2) X0000 (C,BE,A,D, module_control);

endmodule