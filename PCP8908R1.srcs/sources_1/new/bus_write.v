module bus_write #(
  parameter _ADD = 32'h0,
  parameter _BYTE = 'd2
)(
  input io_rst,
  input io_clk,
  input io_wr,
  input [_BYTE - 1:0]  io_wen,
  input [15:0] io_addr,
  inout [15:0] io_data,

  output [(_BYTE * 8) - 1 :0] io_dout
);

//   reg [7:0] ram8 [0:(_BYTE-1)];
reg [15:0] wr_reg ;
//   integer j;
//   initial begin : forSim
//     for (j = 0; j<_BYTE; j=j+1) begin
//       ram8[j] = 'd0;
//     end
//   end

  wire addrCatch = (io_addr[15:1]) == _ADD[15:1];

//   genvar i;
//   generate
//     for(i=0; i<_BYTE; i=i+1) begin : ram
//       always @ (posedge io_clk or negedge io_rst) begin
//         if (!io_rst) begin
//             ram8[i] = 'd0;
//         end
//         else if (io_wr & addrCatch & io_wen[i]) begin
//             ram8[i] <= io_data[ (i*8) +: 8];
//         end
//         // ram8[i] <= io_wen[i] & addrCatch ? io_data[ (i*8) +: 8] : ram8[i];
//       end
//       assign io_dout[i*8 +: 8] = ram8[i];
//     end
//   endgenerate
always @ (posedge io_clk or negedge io_rst) begin
    if (!io_rst) begin
        wr_reg <= 'd0;
    end
    else if (io_wr & addrCatch) begin
        wr_reg <= io_data;
    end
    else begin
        wr_reg <= wr_reg;
    end
end
 assign io_dout = wr_reg;
endmodule