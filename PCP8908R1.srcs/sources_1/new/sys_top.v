`timescale 1ns / 1ps
module sys_top(
    input                 sys_clk     	,  //ʱ���ź�
    input                 sys_rst_n   	,  //��λ�ź�
    // input                 key   		,  //�����ź�
    //STM32H7��FMC�ӿ�
    inout     [15:0]       fmc_adda_data     ,  //FMC��ADDA����
    input     fmc_clk     ,  //FMC��ADDAʱ��
    input     fmc_nl        ,  //�͵�ƽ��Ч��FMC����æ���ź�
    output    fmc_nwait     ,  //�͵�ƽ��Ч��FMC���ߵȴ��ź�
    output    fmc_nwe       ,  //�͵�ƽ��Ч��FMC����дʹ���ź�
    output    fmc_ncs       ,  //�͵�ƽ��Ч��FMC����Ƭѡ�ź�
    output    fmc_noe       ,  //�͵�ƽ��Ч��FMC���߶�ʹ���ź�
    output    fmc_int       ,  //MCU���ж��ź�
    output    mcu_int       ,  //MCU���ж��ź�
    //ADת��ģ��Ľӿ�
    input     [13:0]       ad_porta_data    	,  //ADת��ģ�������
    input     [13:0]       ad_portb_data    	,  //ADת��ģ�������
   
    input                 ad_ofa      	,  //ADת��ģ���ʹ���ź�
    output                ad_shdna      	,
    output                ad_porta_clk      	,  //ADת��ģ���ʱ��

    //ADת��ģ��Ľӿ�
    input                 ad_ofb      	,  //ADת��ģ���ʹ���ź�
    output                ad_shdnb      	,
    output                ad_portb_clk      	  //ADת��ģ���ʱ��

    );

    //�źŶ���
    wire        clk_65m;            //65MHzʱ��
    wire        clk_100m;            //100MHzʱ��
    wire        clkA_65m;             //65MHzʱ��
    wire        clkB_65m;             //65MHzʱ��
    wire        locked;              //PLL�����ź�
    wire        rst_n;               //ϵͳ��λ�ź�
    wire  [31:0] BUS_ADDR;
//   wire  [3:0]  BUS_BE��
    wire  [31:0] BUS_DATA_WR;
    wire  [31:0] BUS_DATA_RD;

    //ADת��ģ��Ľӿ�
    reg adc_porta_en  = 1'b1;
    reg adc_portb_en  = 1'b1;

    //
    wire  [13:0]       sync_porta_data    	;  //ADת��ģ�������
    wire  [13:0]       sync_portb_data    	;  //ADת��ģ�������
    wire  [13:0]       fifo_data_porta    	;  //ADת��ģ�������
    wire  [13:0]       fifo_data_portb    	;  //ADת��ģ�������


    assign rst_n =  sys_rst_n && locked; 
    assign ad_shdna = 1'b1;
    assign ad_shdnb = 1'b1;
    // assign ad_clk =  clkB_65m; 

    //PLLģ��
    clk_wiz_0 u_pll
    (
    //ʱ�����
    .clk_out1(clk_65m),
    .clk_out2(clkA_65m),
    .clk_out3(clkB_65m),
    .clk_out4(clk_100m),
    //״̬�Ϳ����ź�               
    .resetn(sys_rst_n), 
    .locked(locked),
    //ʱ������
    .clk_in1(sys_clk)
    );
  
    //instance bus bridge
fsmc_bridge u_fsmc_bridge(
	.sys_clk(sys_clk),
	.rst_n(rst_n),
	
	//fsmc��������ź�
	.fsmc_nadv(fmc_nl),
	.fsmc_wr(fmc_nwe),
	.fsmc_rd(fmc_noe),
	.fsmc_cs(fmc_ncs),
	.fsmc_db(fmc_adda_data),

	//�ⲿ�ӿ�
	//.BUS_CLK(BUS_CLK),
	.BUS_ADDR(BUS_ADDR),
	//.BUS_BE(BUS_BE),
	.BUS_DATA_WR(BUS_DATA_WR),
	.BUS_DATA_RD(BUS_DATA_RD)
);
 //ʱ���źŻ���
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
