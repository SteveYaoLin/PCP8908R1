`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/22 10:53:24
// Design Name: 
// Module Name: adc_fifo_ctrl
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


module adc_fifo_ctrl#(
    parameter _COUNTER_WIDTH = 14,
    parameter _DATA_WIDTH = 14,
    parameter _FIFO_DEPTH = 16384
)    (
    input adc_clk,
    input sys_clk,
    input rst,
    input [13:0] sync_data,
    output [13:0] fifo_data,
    input fifo_enbale,
    output reg fifo_data_last_d1,
    output cycle_valid
    );

    wire  wr_en;                          
    wire  rd_en;                          
                  
    wire  full;                            
    wire  almost_full;              
    wire  wr_ack;                        
    wire  overflow;                    
    wire  empty;                          
    wire  almost_empty;            
    wire  valid;                          
    wire  underflow;                  
    wire  [_COUNTER_WIDTH -1 :0] rd_data_count;          
    wire  [_COUNTER_WIDTH -1 :0] wr_data_count;          
    wire  wr_rst_busy;              
    wire  rd_rst_busy;

  //reg define
    reg        empty_d0;
    reg        empty_d1;
    reg        almost_full_d0;
//
    reg fifo_enbale_d0;
    reg fifo_enbale_d1;

    reg [14:0] fifo_wr_cnt;
    reg [14:0] fifo_rd_cnt;
    wire rd_ready ;
    reg rd_ready_d1 ;
    reg rd_begin ;



fifo_generator_0 u_fifo_generator_0 (
  /*input  */.rst(~rst),                              
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

//create wr and counter signal
always @(posedge adc_clk or negedge rst) begin
    if(rst == 1'b0) begin
        fifo_enbale_d0 <= 1'b0;
        fifo_enbale_d1 <= 1'b0;
    end
    else begin
        fifo_enbale_d0 <= fifo_enbale;
        fifo_enbale_d1 <= fifo_enbale_d0;
    end
end
always @(posedge adc_clk or negedge rst) begin
    if(rst == 1'b0) begin
        fifo_wr_cnt <= 15'd0;
    end
    else if (fifo_enbale_d0 & ~fifo_enbale_d1) begin
        fifo_wr_cnt <= fifo_wr_cnt + 1'b1;
    end
    else if((|fifo_wr_cnt) & (fifo_wr_cnt < _FIFO_DEPTH))begin
        fifo_wr_cnt <= fifo_wr_cnt + 1'b1;
    end
    else  begin 
        fifo_wr_cnt <= 15'd0;
    end
    
end
assign wr_en = (|fifo_wr_cnt)? 1'b1 : 1'b0; //wr_en is H during 1-_FIFO_DEPTH

//create rd and counter signal
assign rd_ready = (fifo_wr_cnt == 15'h2cc0) ? 1'b1 : 1'b0;
// assign rd_begin = (fifo_wr_cnt == 15'h00d7) ? 1'b1 : 1'b0;

//rd_ready  clock sync
always @(posedge sys_clk or negedge rst) begin
if (rst == 1'b0) begin
    rd_begin <= 1'b0;
    rd_ready_d1 <= 1'b0;
end
else begin
    rd_begin <= rd_ready_d1;
    rd_ready_d1 <= rd_ready;
end
end

always @(posedge sys_clk or negedge rst) begin
    if(rst == 1'b0) begin
        fifo_rd_cnt <= 15'd0;
    end
    else if (rd_begin) begin
        fifo_rd_cnt <= fifo_rd_cnt + 1'b1;
    end
    else if ((|fifo_rd_cnt) & (fifo_rd_cnt < _FIFO_DEPTH))begin
        fifo_rd_cnt <= fifo_rd_cnt + 1'b1;
    end
    else  begin 
        fifo_rd_cnt <= 15'd0;
    end
    
end
assign rd_en = (|fifo_rd_cnt) ? 1'b1 : 1'b0; //rd_en is H during 1-_FIFO_DEPTH

assign cycle_valid = valid;
//create last data for fft
always @(posedge sys_clk or negedge rst) begin
    if (rst == 1'b0) begin
        fifo_data_last_d1 <= 1'b0;
    end
    else if (fifo_rd_cnt == _FIFO_DEPTH) begin
        fifo_data_last_d1 <= 1'b1;
    end
    else begin
        fifo_data_last_d1 <= 1'b0;
    end
end

endmodule
