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
    wire        clk_100m;            //100MHz时钟
    wire        clkA_65m;             //65MHz时钟
    wire        clkB_65m;             //65MHz时钟
    wire        locked;              //PLL锁定信号
    wire        rst_n;               //系统复位信号
    wire  [31:0] BUS_ADDR;
//   wire  [3:0]  BUS_BE；
    wire  [31:0] BUS_DATA_WR;
    wire  [31:0] BUS_DATA_RD;

    //AD转换模块的接口
    reg adc_porta_en  = 1'b1;
    reg adc_portb_en  = 1'b1;

    //
    wire  [13:0]       sync_porta_data    	;  //AD转换模块的数据
    wire  [13:0]       sync_portb_data    	;  //AD转换模块的数据
    wire  [13:0]       fifo_data_porta    	;  //AD转换模块的数据
    wire  [13:0]       fifo_data_portb    	;  //AD转换模块的数据


    assign rst_n =  sys_rst_n && locked; 
    assign ad_shdna = 1'b1;
    assign ad_shdnb = 1'b1;
    // assign ad_clk =  clkB_65m; 

    //PLL模块
    clk_wiz_0 u_pll
    (
    //时钟输出
    .clk_out1(clk_65m),
    .clk_out2(clkA_65m),
    .clk_out3(clkB_65m),
    .clk_out4(clk_100m),
    //状态和控制信号               
    .resetn(sys_rst_n), 
    .locked(locked),
    //时钟输入
    .clk_in1(sys_clk)
    );
  
    //instance bus bridge
fsmc_bridge u_fsmc_bridge(
	.sys_clk(sys_clk),
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
 //时钟信号缓冲
    BUFG bufa (.I(clkA_65m),.O(ad_porta_clk));
    BUFG bufb (.I(clkB_65m),.O(ad_portb_clk));

//
adc_data_sync #(
    ._DATA_WIDTH(14)
) u_adc_sync_a(
    .clk_sync(clk_65m),
    .sys_rst(rst_n),
    .adc_data(ad_porta_data),
    .sync_data(sync_porta_data)
);

adc_data_sync #(
    ._DATA_WIDTH(14)
) u_adc_sync_b(
    .clk_sync(clk_65m),
    .sys_rst(rst_n),
    .adc_data(ad_portb_data),
    .sync_data(sync_portb_data)
);

adc_dram u1(
    .adc_clk        (clk_65m),
    .sys_clk        (clk_100m),
    .rst            (rst_n),
    .sync_data     (sync_porta_data),
    .fifo_data      (fifo_data_porta),
    .fifo_enbale    (temp_valid),
    .cycle_valid    ()
    );

adc_dram u2(
    .adc_clk        (clk_65m),
    .sys_clk        (clk_100m),
    .rst            (rst_n),
    .sync_data     (sync_portb_data),
    .fifo_data      (fifo_data_portb),
    .fifo_enbale    (temp_valid),
    .cycle_valid    ()
    );

// compile
assign  BUS_DATA_RD = ad_porta_data;

//test creat enable signal
reg [15:0] temp_cnt ;
reg temp_valid;
always @(posedge clk_100m or negedge rst_n) begin
    if (!rst_n) begin
        temp_cnt <= 16'd0;
        temp_valid <= 1'b0;
    end
    else if (temp_cnt == 16'd10000) begin
        temp_cnt <= temp_cnt;
        temp_valid <= 1'b1;
    end
    else begin
        temp_cnt <= temp_cnt + 1'b1;
    end
end

endmodule
