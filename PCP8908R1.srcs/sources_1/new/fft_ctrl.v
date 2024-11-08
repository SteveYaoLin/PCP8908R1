module fft_ctrl # (
    parameter _COUNTER_WIDTH = 14,
    parameter _DATA_WIDTH = 14,
    parameter _FIFO_DEPTH = 16384
    )
(
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
    output m_axis_data_tlast,
    output [7:0]m_axis_status_tdata,
    output m_axis_status_tvalid,
    input m_axis_status_tready,
    output event_frame_started,
    output event_tlast_unexpected,
    output event_tlast_missing,
    output event_status_channel_halt,
    output event_data_in_channel_halt,
    output event_data_out_channel_halt,
    // 
    output  [15:0]    data_modulus,  
    output            data_eop,      
    output            data_valid,    
    output [_COUNTER_WIDTH - 1 :0] modulus_cnt,
    output [_COUNTER_WIDTH - 1 :0] phase_cnt,
    // 
    output  [15:0]    data_phase,    
    output            phase_valid    

);

    wire [_COUNTER_WIDTH - 1:0] fft_cnt;
    assign fft_cnt = m_axis_data_tuser[_COUNTER_WIDTH - 1:0] ;
//    //create fft_cnt
//    always @(posedge aclk) begin
//        if(!aresetn) begin
//            fft_cnt <= 'h1;
//        end
//        else if(m_axis_status_tvalid) begin
//            fft_cnt <= fft_cnt + 1;
//        end
//        else begin
//            fft_cnt <= 'h1;
//        end
//    end

xfft_0 u_xfft_0 (
    .aclk(aclk),                                            
    .aresetn(aresetn),                             
    .s_axis_config_tdata(s_axis_config_tdata),     
    .s_axis_config_tvalid(s_axis_config_tvalid),   
    .s_axis_config_tready(s_axis_config_tready),   

    .s_axis_data_tdata(s_axis_data_tdata),         
    .s_axis_data_tvalid(s_axis_data_tvalid),       
    .s_axis_data_tready(s_axis_data_tready),       
    .s_axis_data_tlast(s_axis_data_tlast),         

    .m_axis_data_tdata(m_axis_data_tdata),         
    .m_axis_data_tuser(m_axis_data_tuser),         
    .m_axis_data_tvalid(m_axis_data_tvalid),       
    .m_axis_data_tready(m_axis_data_tready),       
    .m_axis_data_tlast(m_axis_data_tlast),         

    .m_axis_status_tdata(m_axis_status_tdata),
    .m_axis_status_tvalid(m_axis_status_tvalid),
    .m_axis_status_tready(m_axis_status_tready),
    .event_frame_started(event_frame_started),
    .event_tlast_unexpected(event_tlast_unexpected),
    .event_tlast_missing(event_tlast_missing),
    .event_status_channel_halt(event_status_channel_halt),
    .event_data_in_channel_halt(event_data_in_channel_halt),
    .event_data_out_channel_halt(event_data_out_channel_halt)
);

data_modulus_phase # (
    ._DATA_WIDTH(_DATA_WIDTH),
    ._FIFO_DEPTH(_FIFO_DEPTH),
    ._COUNTER_WIDTH(_COUNTER_WIDTH)
) u_data_modulus_phase (
    .clk(aclk),
    .rst_n(aresetn),
    .aclken(1'b1),
    .source_real(m_axis_data_tdata[0  +: (_DATA_WIDTH + 1)]),
    .source_imag(m_axis_data_tdata[16 +: (_DATA_WIDTH + 1)]),
    .source_eop(m_axis_data_tlast),
    .source_valid(m_axis_data_tvalid),
    .data_modulus(data_modulus),
    .data_eop(data_eop),
    .modulus_cnt(modulus_cnt),
    .phase_cnt(phase_cnt),
    .data_valid(data_valid),
    .data_phase(data_phase),
    .phase_valid(phase_valid)
);

endmodule