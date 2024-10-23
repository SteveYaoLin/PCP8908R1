`timescale 1ns / 1ps
module sys_top(
    input                 sys_clk     	,  //时钟信号
    input                 sys_rst_n   	,  //复位信号
    // input                 key   		,  //按键信号
    //STM32H7的FMC接口
    inout     [15:0]       fmc_adda_data     ,  //FMC的ADDA数据
    input     fmc_clk     ,  //FMC的ADDA时钟
    input     fmc_nl        ,  //低电平有效的FMC总线忙闲信号
    output    fmc_nwait     ,  //低电平有效的FMC总线等待信号
    output    fmc_nwe       ,  //低电平有效的FMC总线写使能信号
    output    fmc_ncs       ,  //低电平有效的FMC总线片选信号
    output    fmc_noe       ,  //低电平有效的FMC总线读使能信号
    output    fmc_int       ,  //MCU的中断信号
    output    mcu_int       ,  //MCU的中断信号
    //AD转换模块的接口
    input     [13:0]       ad_porta_data    	,  //AD转换模块的数据
    input     [13:0]       ad_portb_data    	,  //AD转换模块的数据
   
    input                 ad_ofa      	,  //AD转换模块的使能信号
    output                ad_shdna      	,
    output                ad_porta_clk      	,  //AD转换模块的时钟

    //AD转换模块的接口
    input                 ad_ofb      	,  //AD转换模块的使能信号
    output                ad_shdnb      	,
    output                ad_portb_clk      	  //AD转换模块的时钟

    );

    //信号定义
    wire        clk_65m;            //65MHz时钟
    wire        clk_130m;            //100MHz时钟
    wire        clkA_65m;             //65MHz时钟
    wire        clkB_65m;             //65MHz时钟
    wire        locked;              //PLL锁定信号
    wire        rst_n;               //系统复位信号
    wire  [31:0] BUS_ADDR;
//   wire  [3:0]  BUS_BE；
    wire  [31:0] BUS_DATA_WR;
    wire  [31:0] BUS_DATA_RD;
    reg temp_valid;
    //AD转换模块的接口
    reg adc_porta_en  = 1'b1;
    reg adc_portb_en  = 1'b1;
    reg [15:0] temp_cnt ;
    //
    wire  [13:0]       sync_porta_data    	;  //AD转换模块的数据
    wire  [13:0]       sync_portb_data    	;  //AD转换模块的数据
    wire  [13:0]       fifo_data_porta    	;  //AD转换模块的数据
    wire  [13:0]       fifo_data_portb    	;  //AD转换模块的数据

    wire  [15:0]       module_status;
    wire  [15:0]       module_control;

    wire fifo_adc_porta_sync;
    wire fifo_adc_portb_sync;
    wire fifo_adc_porta_last;
    wire fifo_adc_portb_last;

    wire [31:0]m_axis_data_tdata;
    wire [23:0]m_axis_data_tuser;
    wire m_axis_data_tvalid;
    wire m_axis_data_tlast;

    //assign BUS_BE = 4'b1111;

    assign rst_n =  sys_rst_n && locked; 
    assign ad_shdna = module_control[0];
    assign ad_shdnb = module_control[1];
    // assign ad_clk =  clkB_65m; 

    //PLL模块
    clk_wiz_0 u_pll
    (
    //时钟输出
    .clk_out1(clk_130m),
    .clk_out2(clkA_65m),
    .clk_out3(clkB_65m),
    .clk_out4(clk_65m),
//    .clk_out4(clk_130m),
    //状态和控制信号               
    .resetn(sys_rst_n), 
    .locked(locked),
    //时钟输入
    .clk_in1(sys_clk)
    );
  
    //instance bus bridge
fsmc_bridge u_fsmc_bridge(
	.sys_clk(clk_65m),
	.rst_n(rst_n),
	
	//fsmc总线相关信号
	.fsmc_nadv(fmc_nl),
	.fsmc_wr(fmc_nwe),
	.fsmc_rd(fmc_noe),
	.fsmc_cs(fmc_ncs),
	.fsmc_db(fmc_adda_data),

	//外部接口
	//.BUS_CLK(BUS_CLK),
	.BUS_ADDR(BUS_ADDR),
	//.BUS_BE(BUS_BE),
	.BUS_DATA_WR(BUS_DATA_WR),
	.BUS_DATA_RD(BUS_DATA_RD)
);

BUS u_bus(
    .io_clk(clk_65m),
    .io_be(2'b11),
    .io_addr(BUS_ADDR),
    .io_data_i(BUS_DATA_WR),
    .io_data_o(BUS_DATA_RD),
    // .module_status(module_status),
    .module_status(m_axis_data_tdata),
    .module_control(module_control)
);

 //时钟信号缓冲
    BUFG bufa (.I(clkA_65m),.O(ad_porta_clk));
    BUFG bufb (.I(clkB_65m),.O(ad_portb_clk));

//
adc_data_sync #(
    ._DATA_WIDTH(14)
) u_adc_sync_a(
    .clk_sync(clkA_65m),
    .sys_rst(rst_n),
    .adc_data(ad_porta_data),
    .sync_data(sync_porta_data)
);

adc_data_sync #(
    ._DATA_WIDTH(14)
) u_adc_sync_b(
    .clk_sync(clkB_65m),
    .sys_rst(rst_n),
    .adc_data(ad_portb_data),
    .sync_data(sync_portb_data)
);

adc_fifo_ctrl u1(
    .adc_clk            (clkA_65m),
    .sys_clk            (clk_130m),
    .rst                (rst_n),
    .sync_data          (sync_porta_data),
    .fifo_data          (fifo_data_porta),
    .fifo_enbale        (temp_valid),
    .fifo_data_last_d1  (fifo_adc_porta_last),
    .cycle_valid        (fifo_adc_porta_sync)
    );

adc_fifo_ctrl u2(
    .adc_clk            (clkB_65m),
    .sys_clk            (clk_130m),
    .rst                (rst_n),
    .sync_data          (sync_portb_data),
    .fifo_data          (fifo_data_portb),
    .fifo_enbale        (temp_valid),
    .fifo_data_last_d1  (fifo_adc_portb_last),
    .cycle_valid        (fifo_adc_portb_sync)
    );
// instance fft module
// fft_ctrl u1_fft_ctrl (
//     .aclk(clk_130m),                             //sample clock，130m时钟               
//     .aresetn(rst_n),                             //复位信号，低电平有效  
//     .s_axis_config_tdata(8'b1),      //配置通道的输入数据，1：fft   0：ifft
//     .s_axis_config_tvalid(1'b1),    //配置通道的输入数据有效使能
//     .s_axis_config_tready(),    //外部模块准备接收配置通道数据

//     .s_axis_data_tdata(fifo_data_portb),            //输入数据
//     .s_axis_data_tvalid(fifo_adc_portb_sync),            //输入数据有效使能
//     .s_axis_data_tready(),            //外部模块准备接收输入数据
//     .s_axis_data_tlast(fifo_adc_portb_last),              //输入数据的最后一个数据

//     .m_axis_data_tdata(m_axis_data_tdata),              //输出数据
//     .m_axis_data_tuser(m_axis_data_tuser),              //输出数据的user信号
//     .m_axis_data_tvalid(m_axis_data_tvalid),            //输出数据有效使能
//     .m_axis_data_tready(1'b1),            //外部模块准备接收输出数据
//     .m_axis_data_tlast(m_axis_data_tlast)              //输出数据的最后一个数据

//     // .m_axis_status_tdata(),
//     // .m_axis_status_tvalid(),
//     // .m_axis_status_tready(1'b1),
//     // .event_frame_started(),
//     // .event_tlast_unexpected(),
//     // .event_tlast_missing(),
//     // .event_status_channel_halt(),
//     // .event_data_in_channel_halt(),
//     // .event_data_out_channel_halt()
// );
// compile
//assign  BUS_DATA_RD = ad_porta_data;

//test creat enable signal


always @(posedge clk_130m or negedge rst_n) begin
    if (!rst_n) begin
        temp_cnt <= 16'd0;
        temp_valid <= 1'b0;
    end
    else if (temp_cnt == 16'd10000) begin
        temp_cnt <= temp_cnt;
        // temp_valid <= 1'b1;
    end
    else begin
        temp_cnt <= temp_cnt + 1'b1;
    end
end

endmodule
