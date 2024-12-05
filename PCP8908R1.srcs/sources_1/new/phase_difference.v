module phase_difference # (
    parameter _DATA_WIDTH = 14 ,
    parameter _COUNTER_WIDTH = 14)
 (
    input clk,
    input rst_n,
    input [_COUNTER_WIDTH -1:0] cnt_limit_up,          
    input [_COUNTER_WIDTH -1:0] cnt_limit_down,    
    input [_DATA_WIDTH:0] data_phase_porta,
    input [_COUNTER_WIDTH -1:0] phase_porta_cnt,
    input [_DATA_WIDTH:0] data_phase_portb,
    input [_COUNTER_WIDTH -1:0] phase_portb_cnt,
    output [_DATA_WIDTH:0] phase_diff,
    output  polarity
);



wire [_DATA_WIDTH:0] valid_data_phase_porta; 
wire [_DATA_WIDTH:0] valid_data_phase_portb;    

wire valid_num_porta ;
wire valid_num_portb ;


wire signed [15:0] phase_a_ext;       
wire signed [15:0] phase_b_ext;       
wire signed [15:0] diff;              



assign valid_num_porta = ((phase_porta_cnt > cnt_limit_down) &(phase_porta_cnt < cnt_limit_up))? 1'b1 : 1'b0;
assign valid_num_portb = ((phase_portb_cnt > cnt_limit_down) &(phase_portb_cnt < cnt_limit_up))? 1'b1 : 1'b0;

assign valid_data_phase_porta = (valid_num_porta)?  data_phase_porta : 0;
assign valid_data_phase_portb = (valid_num_portb)?  data_phase_portb : 0;



   
    assign phase_a_ext = {valid_data_phase_porta[_DATA_WIDTH], valid_data_phase_porta};  
    assign phase_b_ext = {valid_data_phase_portb[_DATA_WIDTH], valid_data_phase_portb};  

    
    assign diff = phase_a_ext - phase_b_ext;
    assign phase_diff = diff[14:0];
    assign polarity = diff[15];


endmodule