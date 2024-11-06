module data_modulus_phase # (
    parameter _DATA_WIDTH = 14,
    parameter _FIFO_DEPTH = 16384,
    parameter _COUNTER_WIDTH = 14
    
    )
(
    input             clk,
    input             rst_n,
    input             aclken,
    // FFT ST�ӿ�
    input   [_DATA_WIDTH:0]     source_real,   // ʵ�� �з�����
    input   [_DATA_WIDTH:0]     source_imag,   // �鲿 �з�����
    input             source_eop,    // FFT����ͨ���������һ�����ݱ�־�ź�?
    input             source_valid,  // �����Ч�źţ�FFT�任��ɺ�?���ź��øߣ���ʼ�������?
    // ȡģ���������ݽӿ�
    output  [15:0]    data_modulus,  // ȡģ�������?
    output            data_eop,      // ȡģ���������ֹ�ź�?
    output            data_valid,    // ȡģ���������Ч�ź�?

    output [_COUNTER_WIDTH - 1 :0] modulus_cnt,
    output [_COUNTER_WIDTH - 1 :0] phase_cnt,
    // ȡ��λ���������ݽӿ�
    output  [15:0]    data_phase,    // ȡ��λ�������?
    output            phase_valid    // ȡ��λ���������Ч�ź�?
);

// reg define
reg  [2*_DATA_WIDTH - 1 :0]    source_data;         // ԭ��ƽ����
reg  [_DATA_WIDTH - 1 :0]     data_real;           // ʵ��ԭ��
reg  [_DATA_WIDTH - 1 :0]     data_imag;           // �鲿ԭ��
reg  [_DATA_WIDTH - 1 :0]     source_valid_d;
reg  [_DATA_WIDTH - 1 :0]     source_eop_d;

// parameter _FIFO_DEPTH_LOG2 = 14;
parameter _FIFO_DEPTH_LOG2 = $clog2(_FIFO_DEPTH);

reg [_COUNTER_WIDTH - 1 :0] modulus_cnt;
reg [_COUNTER_WIDTH - 1 :0] phase_cnt;

assign  data_eop = source_eop_d[7];

// ȡʵ�����鲿��ƽ����
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        source_data <= 'd0;
        data_real   <= 'd0;
        data_imag   <= 'd0;
    end
    else begin
        if(source_real[_DATA_WIDTH] == 1'b0)             // �ɲ�������?��
            data_real <= source_real[_DATA_WIDTH - 1 :0];
        else
            data_real <= ~source_real[_DATA_WIDTH - 1 :0] + 1'b1;
            
        if(source_imag[_DATA_WIDTH] == 1'b0)             // �ɲ�������?��
            data_imag <= source_imag[_DATA_WIDTH - 1 :0];
        else
            data_imag <= ~source_imag[_DATA_WIDTH - 1 :0] + 1'b1;

        source_data <= (data_real * data_real) + (data_imag * data_imag); // ����ԭ��ƽ����
    end
end
  
// ���źŽ��д�����ʱ����
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
//create modulus_cnt
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        modulus_cnt <= 'h0;
    end
    else if(source_valid_d[0] == 1'b1) begin
        modulus_cnt <= modulus_cnt + 1'b1;
    end
    else begin
        modulus_cnt <= 'h0;
    end
end
//create phase_cnt
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        phase_cnt <= 'h0;
    end
    else if(source_valid_d[0] == 1'b1) begin
        phase_cnt <= phase_cnt + 1'b1;
    end
    else begin
        phase_cnt <= 'h0;
    end
end


// ����cordicģ�飬���п�������������ģ
cordic_0 u_cordic_0 (
    .aclk(clk),
    .aclken(aclken),
    .aresetn(rst_n),
    .s_axis_cartesian_tvalid(source_valid_d[1]),
    .s_axis_cartesian_tdata({4'h0,source_data}),
    .m_axis_dout_tvalid(data_valid),
    // .m_axis_dout_tlast(),
    .m_axis_dout_tdata(data_modulus)
);

// �����ڶ���cordicģ�飬����arctan����������λ
cordic_1 u_cordic_1 (
    .aclk(clk),
    .aclken(aclken),
    .aresetn(rst_n),
    .s_axis_cartesian_tvalid(source_valid_d[1]),
    .s_axis_cartesian_tdata({data_real, data_imag}),
    .m_axis_dout_tvalid(phase_valid),
    .m_axis_dout_tdata(data_phase)
);

endmodule
