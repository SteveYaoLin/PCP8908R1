module fft_ctrl(
    input aclk, 
    input aresetn,
    input [7:0]s_axis_config_tdata,
    input s_axis_config_tvalid,
    output s_axis_config_tready,
    input [31:0]s_axis_data_tdata,
    input s_axis_data_tvalid,
    output s_axis_data_tready,
    input s_axis_data_tlast,
    output [31:0]m_axis_data_tdata,
    output [23:0]m_axis_data_tuser,
    output m_axis_data_tvalid,
    input m_axis_data_tready,
    output m_axis_data_tlast
    // output [7:0]m_axis_status_tdata,
    // output m_axis_status_tvalid,
    // input m_axis_status_tready
    // output event_frame_started,
    // output event_tlast_unexpected,
    // output event_tlast_missing,
    // output event_status_channel_halt,
    // output event_data_in_channel_halt,
    // output event_data_out_channel_halt
);
    wire [7:0]m_axis_status_tdata;
    wire m_axis_status_tvalid;
    wire event_frame_started;
    wire event_tlast_unexpected;
    wire event_tlast_missing;
    wire event_status_channel_halt;
    wire event_data_in_channel_halt;
    wire event_data_out_channel_halt;

xfft_0 xfft_0 (
    .aclk(aclk),                             //sample clock�?130m时钟               
    .aresetn(rst_n),                             //复位信号，低电平有效  
    .s_axis_config_tdata(s_axis_config_tdata),      //配置通道的输入数据，1：fft   0：ifft
    .s_axis_config_tvalid(s_axis_config_tvalid),    //配置通道的输入数据有效使�?
    .s_axis_config_tready(s_axis_config_tready),    //外部模块准备接收配置通道数据

    .s_axis_data_tdata(s_axis_data_tdata),            //输入数据
    .s_axis_data_tvalid(s_axis_data_tvalid),            //输入数据有效使能
    .s_axis_data_tready(s_axis_data_tready),            //外部模块准备接收输入数据
    .s_axis_data_tlast(s_axis_data_tlast),              //输入数据的最后一个数�?

    .m_axis_data_tdata(m_axis_data_tdata),              //输出数据
    .m_axis_data_tuser(m_axis_data_tuser),              //输出数据的user信号
    .m_axis_data_tvalid(m_axis_data_tvalid),            //输出数据有效使能
    .m_axis_data_tready(m_axis_data_tready),            //外部模块准备接收输出数据
    .m_axis_data_tlast(m_axis_data_tlast),              //输出数据的最后一个数�?

    .m_axis_status_tdata(m_axis_status_tdata),
    .m_axis_status_tvalid(m_axis_status_tvalid),
    .m_axis_status_tready(1'b1),
    .event_frame_started(event_frame_started),
    .event_tlast_unexpected(event_tlast_unexpected),
    .event_tlast_missing(event_tlast_missing),
    .event_status_channel_halt(event_status_channel_halt),
    .event_data_in_channel_halt(event_data_in_channel_halt),
    .event_data_out_channel_halt(event_data_out_channel_halt)
);
endmodule