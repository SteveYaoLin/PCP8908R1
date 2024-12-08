`timescale 1ns / 1ps
module sys_top # (
    
    parameter _DATA_WIDTH = 14,
    parameter _FIFO_DEPTH = 32768,
    parameter _DUAL_WIDTH = 12
)
(
    input                 sys_clk     	,  
    input                 sys_rst_n   	,  
    output                 led   		,  
    
    inout     [15:0]       fmc_adda_data     ,  
    input     fmc_clk     ,  
    input     fmc_nl        , 
    output    fmc_nwait     , 
    input    fmc_nwe       ,  
    input    fmc_ncs       ,  
    input    fmc_noe       ,  
    output    fmc_int       , 
    output    mcu_int       , 
   
    input     [_DATA_WIDTH - 1:0]       ad_porta_data    	,  
    input     [_DATA_WIDTH - 1:0]       ad_portb_data    	,  
   
    input                 ad_ofa      	,  
    output                ad_shdna      	,
    output                ad_porta_oen      	,
    output                ad_porta_clk      	,  

    
    input                 ad_ofb      	, 
    output                ad_shdnb      	,
    output                ad_portb_oen      	,
    output                ad_portb_clk      	  

    );
    parameter _COUNTER_WIDTH = $clog2(_FIFO_DEPTH);
    
    wire        clk_65m;            
    wire        clk_130m;           
    wire        clkA_65m;           
    wire        clkB_65m;           
    wire        locked;             
    wire        rst_n;              
    wire  [15:0] BUS_ADDR;
//   wire  [3:0]  BUS_BE；
    wire  [15:0] BUS_DATA_WR;
    wire  [15:0] BUS_DATA_RD;

    //
    reg adc_porta_en  = 1'b0;
    reg adc_portb_en  = 1'b0;
    
    //
    wire  [_DATA_WIDTH - 1:0]       sync_porta_data    	;  
    wire  [_DATA_WIDTH - 1:0]       sync_portb_data    	;  
    wire  [_DATA_WIDTH - 1:0]       fifo_data_porta    	;  
    wire  [_DATA_WIDTH - 1:0]       fifo_data_portb    	;  

    wire  [15:0]       module_status;
    wire  [15:0]       module_control;

    wire fifo_adc_porta_sync;
    wire fifo_adc_portb_sync;
    wire fifo_adc_porta_last;
    wire fifo_adc_portb_last;

    wire [31:0]m_axis_data_tdata_porta;
    wire [23:0]m_axis_data_tuser_porta;
    wire [31:0]m_axis_data_tdata_portb;
    wire [23:0]m_axis_data_tuser_portb;
    wire m_axis_data_tvalid_porta;
    wire m_axis_data_tlast_porta;
    wire s_axis_data_tready_porta;


    wire m_axis_data_tvalid_portb;
    wire m_axis_data_tlast_portab;
    wire s_axis_data_tready_portb;

    wire  [15:0]    data_modulus_porta  ;  
    wire            data_eop_porta      ;      
    wire            data_valid_porta    ;    
    wire  [_DATA_WIDTH:0]    data_phase_porta    ;    
    wire            phase_valid_porta   ;    

    wire  [15:0]    data_modulus_portb  ;  
    wire            data_eop_portb      ;  
    wire            data_valid_portb    ;  
    wire  [_DATA_WIDTH:0]    data_phase_portb    ;    
    wire            phase_valid_portb   ;    

    wire [_COUNTER_WIDTH - 1 :0] modulus_porta_cnt;
    wire [_COUNTER_WIDTH - 1 :0] phase_porta_cnt;
    wire [_COUNTER_WIDTH - 1 :0] modulus_portb_cnt;
    wire [_COUNTER_WIDTH - 1 :0] phase_portb_cnt;

    wire [_DATA_WIDTH:0]          phase_diff;
    wire                            polarity;

    wire [15:0] cnt_limit_down           ;
    wire [15:0] store_cnt                ;

    wire [_DUAL_WIDTH - 1 :0] dual_ram_addr;

    wire  phase_porta_busy;
    wire  phase_porta_en;


    wire  phase_portb_busy;
    wire  phase_portb_en;


    wire  modulus_porta_busy;
    wire  modulus_porta_en;

    wire  modulus_portb_busy;
    wire  modulus_portb_en;

    // wire [_DATA_WIDTH:0] phase_porta_data;
    // wire [_DATA_WIDTH:0] phase_portb_data;

    // wire [_DATA_WIDTH:0] modulus_porta_data;
    // wire [_DATA_WIDTH:0] modulus_portb_data;

    reg temp_valid;
    wire test_ila;
    wire [4:0] FFT_NFFT;
    wire FWD_INV;
    wire CP_LEN;



    assign FFT_NFFT = 5'h0F;
    assign rst_n =  sys_rst_n && locked; 
    assign ad_shdna =1'b0;// module_control[0];
    assign ad_shdnb =1'b0;// module_control[1];
    assign ad_porta_oen = 1'b0;
    assign ad_portb_oen = 1'b0;

    //PLL模块
    clk_wiz_0 u_pll
    (
    .clk_out1(clk_130m),
    .clk_out2(clk_65m),
    .clk_out3(clkA_65m),
    .clk_out4(clkB_65m),
    .resetn(sys_rst_n), 
    .locked(locked),
    
    .clk_in1(sys_clk)
    );
  

BUS u_bus(
    .io_clk(clk_65m),
    .rst_n(rst_n),
    .io_be(2'b11),
    .io_wr(fmc_nwe),
    .io_rd(fmc_noe),
    .io_nadv(fmc_nl),
    .io_cs(fmc_ncs),
    // .io_addr(BUS_ADDR),
    // .io_data_i(BUS_DATA_WR),
    // .io_data_o(BUS_DATA_RD),
    .io_data(fmc_adda_data),
    // .module_status(module_status),
    .module_status0(16'h5a5a),
    // .module_status1(m_axis_data_tdata_porta[15:0]   ),
    // .module_status2(m_axis_data_tdata_porta[31:16]  ),
    // .module_status3(m_axis_data_tdata_portb[15:0]   ),
    // .module_status4(m_axis_data_tdata_portb[31:16]  ),

    .module_status1( data_modulus_porta ),
    .module_status2( data_phase_porta ),
    .module_status3( {test_ila,phase_diff} ),
    .module_status4( data_phase_portb ),
    .cnt_limit_down(cnt_limit_down),
    .store_cnt(store_cnt),
    .module_control(module_control),
    .dual_ram_addr(dual_ram_addr),
    .phase_porta_busy(phase_porta_busy),
    .phase_porta_en(phase_porta_en),
    .phase_portb_busy(phase_portb_busy),
    .phase_portb_en(phase_portb_en),
    .modulus_porta_busy(modulus_porta_busy),
    .modulus_porta_en(modulus_porta_en),
    .modulus_portb_busy(modulus_portb_busy),
    .modulus_portb_en(modulus_portb_en),
    // .phase_porta_data   (fmc_adda_data),
    // .phase_portb_data   (fmc_adda_data),
    // .modulus_porta_data (fmc_adda_data),
    // .modulus_portb_data (fmc_adda_data),


    .bus_wait(fmc_nwait)
);

phase_difference # (
    ._DATA_WIDTH(_DATA_WIDTH),
    ._COUNTER_WIDTH(_COUNTER_WIDTH)
) u_phase_difference (
    .clk(clk_130m),
    .rst_n(rst_n),
    .cnt_limit_up(store_cnt + cnt_limit_down),
    .cnt_limit_down(cnt_limit_down),

    .data_phase_porta(data_phase_porta),
    .phase_porta_cnt(phase_porta_cnt),
    .data_phase_portb(data_phase_portb),
    .phase_portb_cnt(phase_portb_cnt),
    .phase_diff(phase_diff),
    .polarity(polarity)
);

dual_ram_data # (
    ._DATA_WIDTH(_DATA_WIDTH),
    ._COUNTER_WIDTH(_COUNTER_WIDTH),
    ._DUAL_WIDTH(_DUAL_WIDTH)
)  u_phase_porta (
    .clk(clk_130m),
    .rst_n(rst_n),
    .data_in        (data_phase_porta),
    .data_cnt       (phase_porta_cnt),
    .cnt_limit_up   (store_cnt + cnt_limit_down),          
    .cnt_limit_down (cnt_limit_down),                      
    .porta_en       (phase_porta_en),
    .data_o_addr    (phase_porta_addr),
    .data_o         (),
    .data_ram_busy  (phase_porta_busy)
);

dual_ram_data # (
    ._DATA_WIDTH(_DATA_WIDTH),
    ._COUNTER_WIDTH(_COUNTER_WIDTH),
    ._DUAL_WIDTH(_DUAL_WIDTH)
)  u_phase_portb (
    .clk(clk_130m),
    .rst_n(rst_n),
    .data_in        (data_phase_portb),
    .data_cnt       (phase_portb_cnt),
    .cnt_limit_up   (store_cnt + cnt_limit_down),          
    .cnt_limit_down (cnt_limit_down),                      
    .porta_en       (phase_portb_en),
    .data_o_addr    (phase_portb_addr),
    .data_o         (),
    .data_ram_busy  (phase_portb_busy)
);

dual_ram_data # (
    ._DATA_WIDTH(_DATA_WIDTH),
    ._COUNTER_WIDTH(_COUNTER_WIDTH),
    ._DUAL_WIDTH(_DUAL_WIDTH)
)  u_modulus_porta (
    .clk(clk_130m),
    .rst_n(rst_n),
    .data_in        (data_modulus_porta),
    .data_cnt       (modulus_porta_cnt),
    .cnt_limit_up   (store_cnt + cnt_limit_down),          
    .cnt_limit_down (cnt_limit_down),                      
    .porta_en       (modulus_porta_en),
    .data_o_addr    (modulus_porta_addr),
    .data_o         (),
    .data_ram_busy  (modulus_porta_busy)
);

dual_ram_data # (
    ._DATA_WIDTH(_DATA_WIDTH),
    ._COUNTER_WIDTH(_COUNTER_WIDTH),
    ._DUAL_WIDTH(_DUAL_WIDTH)
)  u_modulus_portb (
    .clk(clk_130m),
    .rst_n(rst_n),
    .data_in        (data_modulus_portb),
    .data_cnt       (modulus_portb_cnt),
    .cnt_limit_up   (store_cnt + cnt_limit_down),          
    .cnt_limit_down (cnt_limit_down),                      
    .porta_en       (modulus_portb_en),
    .data_o_addr    (modulus_portb_addr),
    .data_o         (),
    .data_ram_busy  (modulus_portb_busy)
);

 //时钟信号缓冲
    BUFG bufa (.I(clkA_65m),.O(ad_porta_clk));
    BUFG bufb (.I(clkB_65m),.O(ad_portb_clk));

//
adc_data_sync #(
    ._DATA_WIDTH(_DATA_WIDTH)
) u_adc_sync_a(
    .clk_sync(clkA_65m),
    .sys_rst(rst_n),
    .adc_data(ad_porta_data),
    .sync_data(sync_porta_data)
);

adc_data_sync #(
    ._DATA_WIDTH(_DATA_WIDTH)
) u_adc_sync_b(
    .clk_sync(clkB_65m),
    .sys_rst(rst_n),
    .adc_data(ad_portb_data),
    .sync_data(sync_portb_data)
);
ila_0 ila_0(
.clk	(clk_130m),
.probe0	(fifo_data_porta),
.probe1	(fifo_data_portb),
.probe2	(m_axis_data_tdata_portb[15: 0]),
.probe3	(m_axis_data_tdata_portb[31:16]),
.probe4	(data_phase_portb),
.probe5	(data_modulus_porta),
.probe6	(data_phase_porta),
.probe7	(modulus_porta_cnt),
.probe8	({test_ila,phase_diff}),
.probe9	(phase_porta_cnt),
.probe10(data_modulus_portb),
.probe11({temp_valid,fifo_adc_porta_last,fifo_adc_porta_sync,s_axis_data_tready_porta,m_axis_data_tlast_porta,m_axis_data_tvalid_porta,ad_ofa,data_valid_porta,fifo_adc_portb_last,fifo_adc_portb_sync,s_axis_data_tready_portb,m_axis_data_tlast_portb,m_axis_data_tvalid_portb,ad_ofb,data_valid_portb,phase_valid_porta})
);

adc_fifo_ctrl  # (
    ._COUNTER_WIDTH(_COUNTER_WIDTH),
    ._DATA_WIDTH(_DATA_WIDTH),
    ._FIFO_DEPTH(_FIFO_DEPTH)
)   u1  (
    .adc_clk            (clkA_65m),
    .sys_clk            (clk_130m),
    .rst                (rst_n),
    .sync_data          (sync_porta_data),
    .fifo_data          (fifo_data_porta),
    .fifo_enbale        (temp_valid),
    .fifo_rd_ready      (s_axis_data_tready_porta),
    .fifo_data_last_d1  (fifo_adc_porta_last),
    .cycle_valid        (fifo_adc_porta_sync)
    );

adc_fifo_ctrl  # (
    ._COUNTER_WIDTH(_COUNTER_WIDTH),
    ._DATA_WIDTH(_DATA_WIDTH),
    ._FIFO_DEPTH(_FIFO_DEPTH)
)   u2  (

    .adc_clk            (clkB_65m),
    .sys_clk            (clk_130m),
    .rst                (rst_n),
    .sync_data          (sync_portb_data),
    .fifo_data          (fifo_data_portb),
    .fifo_enbale        (temp_valid),
    .fifo_rd_ready      (s_axis_data_tready_portb),
    .fifo_data_last_d1  (fifo_adc_portb_last),
    .cycle_valid        (fifo_adc_portb_sync)
    );
// instance fft module
 fft_ctrl  # (
    ._COUNTER_WIDTH(_COUNTER_WIDTH),
    ._DATA_WIDTH(_DATA_WIDTH),
    ._FIFO_DEPTH(_FIFO_DEPTH)
) u0_fft_ctrl
 (
     .aclk(clk_130m),                                            
     .aresetn(rst_n),                               
     .s_axis_config_tdata({3'b0,FFT_NFFT}),      
     .s_axis_config_tvalid(1'b1),    
     .s_axis_config_tready(),    

     .s_axis_data_tdata({18'h0,fifo_data_porta}),         
     .s_axis_data_tvalid(fifo_adc_porta_sync),            
     .s_axis_data_tready(s_axis_data_tready_porta),       
     .s_axis_data_tlast(fifo_adc_porta_last),             

     .m_axis_data_tdata(m_axis_data_tdata_porta),         
     .m_axis_data_tuser(m_axis_data_tuser_porta),         
     .m_axis_data_tvalid(m_axis_data_tvalid_porta),       
     .m_axis_data_tready(1'b1),            
     .m_axis_data_tlast(m_axis_data_tlast_porta) ,        

     .m_axis_status_tdata(),
     .m_axis_status_tvalid(),
     .m_axis_status_tready(1'b1),
     .event_frame_started(),
     .event_tlast_unexpected(),
     .event_tlast_missing(),
     .event_status_channel_halt(),
     .event_data_in_channel_halt(),
     .event_data_out_channel_halt(),
     .data_modulus(data_modulus_porta),
     .data_eop(data_eop_porta),
     .data_valid(data_valid_porta),
     .modulus_cnt(modulus_porta_cnt),
     .phase_cnt(phase_porta_cnt),
     .data_phase(data_phase_porta),
     .phase_valid(phase_valid_porta)

 );

 fft_ctrl  # (
    ._COUNTER_WIDTH(_COUNTER_WIDTH),
    ._DATA_WIDTH(_DATA_WIDTH),
    ._FIFO_DEPTH(_FIFO_DEPTH)
) u1_fft_ctrl
  (
     .aclk(clk_130m),                             
     .aresetn(rst_n),                            
     .s_axis_config_tdata({3'b0,FFT_NFFT}),      
     .s_axis_config_tvalid(1'b1),    
     .s_axis_config_tready(),    

     .s_axis_data_tdata({18'h0,fifo_data_portb}),         
     .s_axis_data_tvalid(fifo_adc_portb_sync),            
     .s_axis_data_tready(s_axis_data_tready_portb),       
     .s_axis_data_tlast(fifo_adc_portb_last),             

     .m_axis_data_tdata(m_axis_data_tdata_portb),         
     .m_axis_data_tuser(m_axis_data_tuser_portb),         
     .m_axis_data_tvalid(m_axis_data_tvalid_portb),            
     .m_axis_data_tready(1'b1),            
     .m_axis_data_tlast(m_axis_data_tlast_portb)  ,            

     .m_axis_status_tdata(),
     .m_axis_status_tvalid(),
     .m_axis_status_tready(1'b1),
     .event_frame_started(),
     .event_tlast_unexpected(),
     .event_tlast_missing(),
     .event_status_channel_halt(),
     .event_data_in_channel_halt(),
     .event_data_out_channel_halt(),
     .data_modulus(data_modulus_portb),
     .data_eop(data_eop_portb),
     .data_valid(data_valid_portb),
     .modulus_cnt(modulus_portb_cnt),
     .phase_cnt(phase_portb_cnt),
     .data_phase(data_phase_portb),
     .phase_valid(phase_valid_portb)
 );


assign test_ila = (|phase_portb_cnt) ? 1'b1:1'b0;
breath_led u_breath_led(
    .sys_clk       (clk_65m) ,      
    .sys_rst_n       (rst_n) ,    
    .led (led )           
);


parameter _CNT = 130000; // 默认值


reg [31:0] temp_cnt ;
always @(posedge clk_65m or negedge rst_n) begin
    if (!rst_n) begin
        temp_cnt <= 32'd0;
        temp_valid <= 1'b0;
    end
    else if (temp_cnt == _CNT) begin
        temp_cnt <= 32'd0;
    end
    else if (temp_cnt == 32'd199) begin
        temp_valid <= 1'b1;
        temp_cnt <= temp_cnt + 1'b1;
    end
    else begin
        temp_cnt <= temp_cnt + 1'b1;
        temp_valid <= 1'b0;
    end
end
//    assign temp_valid = ((temp_cnt == 32'd199)) ? 1'b1 : 1'b0;

endmodule
