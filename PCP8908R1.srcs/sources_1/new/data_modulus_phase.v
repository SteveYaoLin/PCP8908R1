module data_modulus_phase # (_DATA_WIDTH = 14)
(
    input             clk,
    input             rst_n,
    input             aclken,
    // FFT ST接口
    input   [_DATA_WIDTH:0]     source_real,   // 实部 有符号数
    input   [_DATA_WIDTH:0]     source_imag,   // 虚部 有符号数
    input             source_eop,    // FFT数据通道接收最后一个数据标志信号
    input             source_valid,  // 输出有效信号，FFT变换完成后，此信号置高，开始输出数据
    // 取模运算后的数据接口
    output  [15:0]    data_modulus,  // 取模后的数据
    output            data_eop,      // 取模后输出的终止信号
    output            data_valid,    // 取模后的数据有效信号
    // 取相位运算后的数据接口
    output  [15:0]    data_phase,    // 取相位后的数据
    output            phase_valid    // 取相位后的数据有效信号
);

// reg define
reg  [2*_DATA_WIDTH - 1 :0]    source_data;         // 原码平方和
reg  [_DATA_WIDTH - 1 :0]     data_real;           // 实部原码
reg  [_DATA_WIDTH - 1 :0]     data_imag;           // 虚部原码
reg  [_DATA_WIDTH - 1 :0]     source_valid_d;
reg  [_DATA_WIDTH - 1 :0]     source_eop_d;



assign  data_eop = source_eop_d[7];

// 取实部和虚部的平方和
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        source_data <= 'd0;
        data_real   <= 'd0;
        data_imag   <= 'd0;
    end
    else begin
        if(source_real[_DATA_WIDTH] == 1'b0)             // 由补码计算原码
            data_real <= source_real[_DATA_WIDTH - 1 :0];
        else
            data_real <= ~source_real[_DATA_WIDTH - 1 :0] + 1'b1;
            
        if(source_imag[_DATA_WIDTH] == 1'b0)             // 由补码计算原码
            data_imag <= source_imag[_DATA_WIDTH - 1 :0];
        else
            data_imag <= ~source_imag[_DATA_WIDTH - 1 :0] + 1'b1;

        source_data <= (data_real * data_real) + (data_imag * data_imag); // 计算原码平方和
    end
end
  
// 对信号进行打拍延时处理
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        source_eop_d   <= 8'd0;
        source_valid_d <= 8'd0;
    end
    else begin
        source_valid_d <= {source_valid_d[6:0], source_valid};
        source_eop_d   <= {source_eop_d[6:0], source_eop};
    end
end

// 例化cordic模块，进行开根号运算以求模
cordic_0 u_cordic_0 (
    .aclk(clk),
    .aclken(aclken),
    .s_axis_cartesian_tvalid(source_valid_d[1]),
    .s_axis_cartesian_tdata(source_data),
    .m_axis_dout_tvalid(data_valid),
    // .m_axis_dout_tlast(),
    .m_axis_dout_tdata(data_modulus)
);

// 例化第二个cordic模块，进行arctan运算以求相位
cordic_1 u_cordic_1 (
    .aclk(clk),
    .aclken(aclken),
    .s_axis_cartesian_tvalid(source_valid_d[1]),
    .s_axis_cartesian_tdata({data_real, data_imag}),
    .m_axis_dout_tvalid(phase_valid),
    .m_axis_dout_tdata(data_phase)
);

endmodule
