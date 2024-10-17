`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/17 13:18:28
// Design Name: 
// Module Name: adc_dram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adc_dram(
    input adc_clk,
    input sys_clk,
    input rst,
    input [13:0] sync_data,
    output [13:0] fifo_data,
    input fifo_enbale,
    output cycle_valid
    );


                    
  reg  wr_en;                          
  reg  rd_en;                          
                  
  wire  full;                            
  wire  almost_full;              
  wire  wr_ack;                        
  wire  overflow;                    
  wire  empty;                          
  wire  almost_empty;            
  wire  valid;                          
  wire  underflow;                  
  wire  [31:0] rd_data_count;          
  wire  [31:0] wr_data_count;          
  wire  wr_rst_busy;              
  wire  rd_rst_busy;

fifo_generator_0 u_fifo_generator_0 (
  /*input  */.rst(rst),                              
  /*input  */.wr_clk(adc_clk),                       
  /*input  */.rd_clk(sys_clk),                       
  /*input  */.din(sync_data),                       
  /*input  */.wr_en(wr_en),                          
  /*input  */.rd_en(rd_en),                          
  /*output */.dout(fifo_data),                       
  /*output */.full(full),                            
  /*output */.almost_full(almost_full),              
  /*output */.wr_ack(wr_ack),                        
  /*output */.overflow(overflow),                    
  /*output */.empty(empty),                          
  /*output */.almost_empty(almost_empty),            
  /*output */.valid(valid),                          
  /*output */.underflow(underflow),                  
  /*output */.rd_data_count(rd_data_count),          
  /*output */.wr_data_count(wr_data_count),          
  /*output */.wr_rst_busy(wr_rst_busy),              
  /*output */.rd_rst_busy(rd_rst_busy)               
);

//create wr_end rd_en signal
always @(posedge adc_clk or negedge rst) begin
    if (rst == 1'b0) begin
        wr_en <= 1'b0;
        // rd_en <= 1'b0;
    end
    else begin
        wr_en <= fifo_enbale;
        // rd_en <= ~fifo_enbale;
    end
end

//create rd_en signal
always @(posedge sys_clk or negedge rst) begin
    if (rst == 1'b0) begin
        rd_en <= 1'b0;
    end
    // else if (!empty) begin
    //     rd_en <= 1'b1;
    // end
    else if (rd_en) begin
        rd_en <= 1'b1;
    end
    else if (empty)   begin
        rd_en <= 1'b0;
    end
end
assign cycle_valid = valid;

endmodule
