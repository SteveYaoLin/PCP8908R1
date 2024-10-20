`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/20 11:32:31
// Design Name: 
// Module Name: checkdata_tb
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
`define  ADCA   checkdata_tb.uut.u1
`define  ADCB   checkdata_tb.uut.u2
`define   SYS_CLOCK checkdata_tb.uut.clk_130m
`define   ADCA_CLK `ADCA.adc_clk
`define   ADCB_CLK `ADCB.adc_clk


`define  ADCA_FIFO_BEGIN        `ADCA.fifo_enbale
`define  ADCB_FIFO_BEGIN        `ADCB.fifo_enbale
`define  ADCB_FIFO_READ         `ADCB.rd_en
`define  ADCB_FIFO_READ_DATA    `ADCB.fifo_data
module checkdata_tb;

  // Inputs
  reg sys_clk;
  reg sys_rst_n;
  reg [13:0] ad_porta_data;
  reg [13:0] ad_portb_data;
  reg ad_ofa;
  reg ad_ofb;
  reg fmc_clk;
  reg fmc_nl;

  // Inouts
  wire [15:0] fmc_adda_data;

  // Outputs
  wire ad_shdna;
  wire ad_shdnb;
  wire ad_porta_clk;
  wire ad_portb_clk;
  wire fmc_nwait;
  wire fmc_nwe;
  wire fmc_ncs;
  wire fmc_noe;
  wire fmc_int;
  wire mcu_int;

  // Instantiate the sys_top module
  sys_top uut (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .ad_porta_data(ad_porta_data),
    .ad_portb_data(ad_portb_data),
    .ad_ofa(ad_ofa),
    .ad_ofb(ad_ofb),
    .ad_shdna(ad_shdna),
    .ad_shdnb(ad_shdnb),
    .ad_porta_clk(ad_porta_clk),
    .ad_portb_clk(ad_portb_clk),
    .fmc_adda_data(fmc_adda_data),
    .fmc_clk(fmc_clk),
    .fmc_nl(fmc_nl),
    .fmc_nwait(fmc_nwait),
    .fmc_nwe(fmc_nwe),
    .fmc_ncs(fmc_ncs),
    .fmc_noe(fmc_noe),
    .fmc_int(fmc_int),
    .mcu_int(mcu_int)
  );

  // Clock generation
    reg clk_50m;
    reg clk_65mA;
    reg clk_65mB;
    reg once;
    reg [2:0] delay_cnt_adcb ;
  // Generate 50M clock
  always #10 sys_clk = ~sys_clk;  // 50M clock -> period = 20ns (T/2 = 10ns)

  // genarate ad_portb_data increace data
    always @(posedge ad_portb_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
      ad_portb_data = 0;
      ad_ofb = 0;
      delay_cnt_adcb <= 0;
    end
    else if (`ADCB_FIFO_BEGIN == 1'b1) begin
      ad_portb_data = ad_portb_data + 1;  // Random 14-bit data for porta
      delay_cnt_adcb <= 3'h4;
      // $display("+");
    end
    else if  ((`ADCB_FIFO_BEGIN == 1'b0)&& |delay_cnt_adcb )begin
        ad_portb_data <= ad_portb_data + 1; 
        delay_cnt_adcb <= delay_cnt_adcb -1;
        
    end
    else if  ((`ADCB_FIFO_BEGIN == 1'b0)&& (|delay_cnt_adcb == 0) )begin
      // ad_ofa = ~ad_ofa;  // Toggle enable signal
      ad_portb_data <= 0 ;
    end

  end
  //checkout ADCB FIFO READ DATA
    // initial begin
      always @(posedge SYS_CLOCK ) begin
        
      if `ADCB_FIFO_READ == 1'b1 begin
      $display("Time is %0t,FIFO READ DATA is %0d",$realtime,`ADCB_FIFO_READ_DATA);
    end

        
   

    initial begin
    sys_clk = 0;
    clk_50m = 0;
    clk_65mA = 0;
    clk_65mB = 0;
    sys_rst_n = 1;
    ad_porta_data = 0;
    ad_portb_data = 0;
    ad_ofa = 0;
    ad_ofb = 0;
    // fmc_adda_data = 0;
    fmc_clk = 0;
    fmc_nl = 1;
    once = 0;
    #100;
    sys_rst_n = 0;  // De-assert reset after 100ns

    #100;
    sys_rst_n = 1;  // De-assert reset after 100ns
    #6000;
    @(posedge `ADCB_CLK )
     force `ADCB_FIFO_BEGIN = 1;
      $display("+");
    #10000;
    @(posedge `ADCB_CLK )
     force `ADCB_FIFO_BEGIN = 0;
     $display("end");

    
  end


endmodule
