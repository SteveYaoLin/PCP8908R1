module data_modulus_phase # (
    parameter _DATA_WIDTH = 14,
    parameter _FIFO_DEPTH = 16384,
    parameter _COUNTER_WIDTH = 14
    
    )
(
    input             clk,
    input             rst_n,
    input             aclken,
    
    input   [_DATA_WIDTH-1:0]     source_real,   
    input   [_DATA_WIDTH-1:0]     source_imag,   
    input             source_eop,    
    input             source_valid,  
    
    output  [15:0]    data_modulus,  
    output            data_eop,      
    output            data_valid,    

    output reg  [_COUNTER_WIDTH - 1 :0] modulus_cnt,
    output reg  [_COUNTER_WIDTH - 1 :0] phase_cnt,
    
    output  [15:0]    data_phase,    
    output            phase_valid    
);

// reg define
reg  [2*_DATA_WIDTH - 2 :0]    source_data;        
reg  [_DATA_WIDTH - 2 :0]     data_real;           
reg  [_DATA_WIDTH - 2 :0]     data_imag;           
reg  [_DATA_WIDTH - 1 :0]     source_valid_d;
reg  [_DATA_WIDTH - 1 :0]     source_eop_d;
wire [15:0] data_modulus_cordic;
// wire test = 1'b1;


assign  data_eop = source_eop_d[7];

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        source_data <= 'd0;
        data_real   <= 'd0;
        data_imag   <= 'd0;
    end
    else begin
        if(source_real[_DATA_WIDTH - 1] == 1'b0)             
            data_real <= source_real[_DATA_WIDTH - 2 :0];
        else
            data_real <= ~source_real[_DATA_WIDTH - 2 :0] + 1'b1;
            
        if(source_imag[_DATA_WIDTH - 1] == 1'b0)             
            data_imag <= source_imag[_DATA_WIDTH - 2 :0];
        else
            data_imag <= ~source_imag[_DATA_WIDTH - 2 :0] + 1'b1;

        source_data <= (data_real * data_real) + (data_imag * data_imag); 
    end
end
  

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
    else if(data_valid == 1'b1) begin
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
    else if(phase_valid == 1'b1) begin
        phase_cnt <= phase_cnt + 1'b1;
    end
    else begin
        phase_cnt <= 'h0;
    end
end

assign data_modulus = {data_modulus_cordic[14:0],1'b0};

cordic_0 u_cordic_0 (
    .aclk(clk),
    .aclken(aclken),
    .aresetn(rst_n),
    .s_axis_cartesian_tvalid(source_valid_d[1]),
    .s_axis_cartesian_tdata({4'h0,source_data}),
    .m_axis_dout_tvalid(data_valid),
    // .m_axis_dout_tlast(),
    .m_axis_dout_tdata(data_modulus_cordic)
);


cordic_1 u_cordic_1 (
    .aclk(clk),
    .aclken(aclken),
    .aresetn(rst_n),
    .s_axis_cartesian_tvalid(source_valid),
    .s_axis_cartesian_tdata({source_imag[_DATA_WIDTH-1],source_imag[_DATA_WIDTH-1],source_imag,source_real[_DATA_WIDTH-1],source_real[_DATA_WIDTH-1],source_real}),
    .m_axis_dout_tvalid(phase_valid),
    .m_axis_dout_tdata(data_phase)
);

endmodule
