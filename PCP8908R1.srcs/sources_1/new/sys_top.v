`timescale 1ns / 1ps
module sys_top # (
    // parameter _COUNTER_WIDTH = 14,
    parameter _DATA_WIDTH = 14,
    parameter _FIFO_DEPTH = 16384
)
(
    input                 sys_clk     	,  //时钟信号
    input                 sys_rst_n   	,  //复位信号
    output                 led   		,  //按键信号
    //STM32H7的FMC接口
    inout     [15:0]       fmc_adda_data     ,  //FMC的ADDA数据
    input     fmc_clk     ,  //FMC的ADDA时钟
    input     fmc_nl        ,  //低电平有效的FMC总线忙闲信号
    output    fmc_nwait     ,  //低电平有效的FMC总线等待信号
    input    fmc_nwe       ,  //低电平有效的FMC总线写使能信号
    input    fmc_ncs       ,  //低电平有效的FMC总线片选信号
    input    fmc_noe       ,  //低电平有效的FMC总线读使能信号
    output    fmc_int       ,  //MCU的中断信号
    output    mcu_int       ,  //MCU的中断信号
    //AD转换模块的接口
    input     [_DATA_WIDTH - 1:0]       ad_porta_data    	,  //AD转换模块的数据
    input     [_DATA_WIDTH - 1:0]       ad_portb_data    	,  //AD转换模块的数据
   
    input                 ad_ofa      	,  //AD转换模块的使能信号
    output                ad_shdna      	,
    output                ad_porta_oen      	,
    output                ad_porta_clk      	,  //AD转换模块的时钟

    //AD转换模块的接口
    input                 ad_ofb      	,  //AD转换模块的使能信号
    output                ad_shdnb      	,
    output                ad_portb_oen      	,
    output                ad_portb_clk      	  //AD转换模块的时钟

    );
    parameter _COUNTER_WIDTH = $clog2(_FIFO_DEPTH);
    //信号定义
    wire        clk_65m;            //65MHz时钟
    wire        clk_130m;            //100MHz时钟
    wire        clkA_65m;             //65MHz时钟
    wire        clkB_65m;             //65MHz时钟
    wire        locked;              //PLL锁定信号
    wire        rst_n;               //系统复位信号
    wire  [15:0] BUS_ADDR;
//   wire  [3:0]  BUS_BE；
    wire  [15:0] BUS_DATA_WR;
    wire  [15:0] BUS_DATA_RD;

    //
    reg adc_porta_en  = 1'b0;
    reg adc_portb_en  = 1'b0;
    
    //
    wire  [_DATA_WIDTH - 1:0]       sync_porta_data    	;  //AD转换模块的数据
    wire  [_DATA_WIDTH - 1:0]       sync_portb_data    	;  //AD转换模块的数据
    wire  [_DATA_WIDTH - 1:0]       fifo_data_porta    	;  //AD转换模块的数据
    wire  [_DATA_WIDTH - 1:0]       fifo_data_portb    	;  //AD转换模块的数据

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

    // wire [31:0]m_axis_data_tdata_portb;
    // wire [23:0]m_axis_data_tuser_portb;
    wire m_axis_data_tvalid_portb;
    wire m_axis_data_tlast_portab;
    wire s_axis_data_tready_portb;

    wire  [15:0]    data_modulus_porta  ;  // 取模后的数据
    wire            data_eop_porta      ;      // 取模后输出的终止信号
    wire            data_valid_porta    ;    // 取模后的数据有效信号
    wire  [_DATA_WIDTH:0]    data_phase_porta    ;    // 取相位后的数据
    wire            phase_valid_porta   ;    // 取相位后的数据有效信号

    wire  [15:0]    data_modulus_portb  ;  // 取模后的数据
    wire            data_eop_portb      ;      // 取模后输出的终止信号
    wire            data_valid_portb    ;    // 取模后的数据有效信号
    wire  [_DATA_WIDTH:0]    data_phase_portb    ;    // 取相位后的数据
    wire            phase_valid_portb   ;    // 取相位后的数据有效信号

    wire [_COUNTER_WIDTH - 1 :0] modulus_porta_cnt;
    wire [_COUNTER_WIDTH - 1 :0] phase_porta_cnt;
    wire [_COUNTER_WIDTH - 1 :0] modulus_portb_cnt;
    wire [_COUNTER_WIDTH - 1 :0] phase_portb_cnt;

    wire [_DATA_WIDTH:0]          phase_diff;
    wire                            polarity;

    wire [15:0] cnt_limit_down           ;
    wire [15:0] store_cnt                ;

    reg temp_valid;
    

    //assign BUS_BE = 4'b1111;

    assign rst_n =  sys_rst_n && locked; 
    assign ad_shdna =1'b0;// module_control[0];
    assign ad_shdnb =1'b0;// module_control[1];
    assign ad_porta_oen = 1'b0;
    assign ad_portb_oen = 1'b0;
    assign fmc_nwait =  1'b1; 

    //PLL模块
    clk_wiz_0 u_pll
    (
    //时钟输出
    .clk_out1(clk_130m),
    .clk_out2(clk_65m),
    .clk_out3(clkA_65m),
    .clk_out4(clkB_65m),
//    .clk_out4(clk_130m),
    //状态和控制信号               
    .resetn(sys_rst_n), 
    .locked(locked),
    //时钟输入
    .clk_in1(sys_clk)
    );
  
    //instance bus bridge
// fsmc_bridge u_fsmc_bridge(
// 	.sys_clk(clk_65m),
// 	.rst_n(rst_n),
	
// 	//fsmc总线相关信号
// 	.fsmc_nadv(fmc_nl),
// 	.fsmc_wr(fmc_nwe),
// 	.fsmc_rd(fmc_noe),
// 	.fsmc_cs(fmc_ncs),
// 	.fsmc_db(fmc_adda_data),

// 	//外部接口
// 	//.BUS_CLK(BUS_CLK),
// 	.BUS_ADDR(BUS_ADDR),
// 	//.BUS_BE(BUS_BE),
// 	.BUS_DATA_WR(BUS_DATA_WR),
// 	.BUS_DATA_RD(BUS_DATA_RD)
// );

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
    .module_status3( {polarity,phase_diff} ),
    .module_status4( data_phase_portb ),
    .cnt_limit_down(cnt_limit_down),
    .store_cnt(store_cnt),
    .module_control(module_control)
);

phase_difference # (
    ._DATA_WIDTH(_DATA_WIDTH),
    ._COUNTER_WIDTH(_COUNTER_WIDTH)
) u_phase_difference (
    .clk(clk_130m),
    .rst_n(rst_n),
`ifdef SIM   
    .cnt_limit_up(16383),
    .cnt_limit_down(0),
`else
    .cnt_limit_up(store_cnt + cnt_limit_down),
    .cnt_limit_down(cnt_limit_down),
`endif
    .data_phase_porta(data_phase_porta),
    .phase_porta_cnt(phase_porta_cnt),
    .data_phase_portb(data_phase_portb),
    .phase_portb_cnt(phase_portb_cnt),
    .phase_diff(phase_diff),
    .polarity(polarity)
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
.probe2	(modulus_portb_cnt),
.probe3	(phase_portb_cnt),
.probe4	(data_phase_portb),
.probe5	(data_modulus_porta),
.probe6	(data_phase_porta),
.probe7	(modulus_porta_cnt),
.probe8	({polarity,phase_diff}),
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
     .aclk(clk_130m),                             //sample clock，130m时钟               
     .aresetn(rst_n),                             //复位信号，低电平有效  
     .s_axis_config_tdata(8'b1),      //配置通道的输入数据，1：fft   0：ifft
     .s_axis_config_tvalid(1'b1),    //配置通道的输入数据有效使能
     .s_axis_config_tready(),    //外部模块准备接收配置通道数据

     .s_axis_data_tdata({18'h0,fifo_data_porta}),            //输入数据
     .s_axis_data_tvalid(fifo_adc_porta_sync),            //输入数据有效使能
     .s_axis_data_tready(s_axis_data_tready_porta),            //外部模块准备接收输入数据
     .s_axis_data_tlast(fifo_adc_porta_last),              //输入数据的最后一个数据

     .m_axis_data_tdata(m_axis_data_tdata_porta),              //输出数据
     .m_axis_data_tuser(m_axis_data_tuser_porta),              //输出数据的user信号
     .m_axis_data_tvalid(m_axis_data_tvalid_porta),            //输出数据有效使能
     .m_axis_data_tready(1'b1),            //外部模块准备接收输出数据
     .m_axis_data_tlast(m_axis_data_tlast_porta) ,             //输出数据的最后一个数据

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
     .aclk(clk_130m),                             //sample clock，130m时钟               
     .aresetn(rst_n),                             //复位信号，低电平有效  
     .s_axis_config_tdata(8'b1),      //配置通道的输入数据，1：fft   0：ifft
     .s_axis_config_tvalid(1'b1),    //配置通道的输入数据有效使能
     .s_axis_config_tready(),    //外部模块准备接收配置通道数据

     .s_axis_data_tdata({18'h0,fifo_data_portb}),            //输入数据
     .s_axis_data_tvalid(fifo_adc_portb_sync),            //输入数据有效使能
     .s_axis_data_tready(s_axis_data_tready_portb),            //外部模块准备接收输入数据
     .s_axis_data_tlast(fifo_adc_portb_last),              //输入数据的最后一个数据

     .m_axis_data_tdata(m_axis_data_tdata_portb),              //输出数据
     .m_axis_data_tuser(m_axis_data_tuser_portb),              //输出数据的user信号
     .m_axis_data_tvalid(m_axis_data_tvalid_portb),            //输出数据有效使能
     .m_axis_data_tready(1'b1),            //外部模块准备接收输出数据
     .m_axis_data_tlast(m_axis_data_tlast_portb)  ,            //输出数据的最后一个数据

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

// compile
//assign  BUS_DATA_RD = ad_porta_data;
// assign s_axis_data_tready_porta = 1'b1;
// assign s_axis_data_tready_portb = 1'b1;
//test creat enable signal

breath_led u_breath_led(
    .sys_clk       (clk_65m) ,      //系统时锟斤拷 50MHz
    .sys_rst_n       (rst_n) ,    //系统锟斤拷位锟斤拷锟酵碉拷平锟斤拷效
    .led (led )           //LED锟斤拷
);

// `ifdef SIM
// parameter _CNT = 200; // 测试时使用较小的值
// `else
parameter _CNT = 70000; // 默认值
// `endif

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
