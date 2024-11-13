module phase_difference # (
    parameter _DATA_WIDTH = 14 ,
    parameter _COUNTER_WIDTH = 14)
 (
    input clk,
    input rst_n,
    input [_COUNTER_WIDTH -1:0] save_cnt,          // save the phase counter value
    input [_COUNTER_WIDTH -1:0] cnt_limit_down,    // which is from No.N of phase
    input [_DATA_WIDTH:0] data_phase_porta,
    input [_COUNTER_WIDTH -1:0] phase_porta_cnt,
    input [_DATA_WIDTH:0] data_phase_portb,
    input [_COUNTER_WIDTH -1:0] phase_portb_cnt,
    output [_DATA_WIDTH-1:0] phase_diff,
    output reg  polarity
);

wire phase_msb_porta ; //polarities of phase
wire phase_msb_portb ; 

wire [1:0] phase_inter_q_porta ; // interger part of a number
wire [1:0] phase_inter_q_portb ; 

wire [_DATA_WIDTH - 3 :0] phase_fract_porta ; // fractional part of a number
wire [_DATA_WIDTH - 3 :0] phase_fract_portb ; // fractional part of a number

wire [_DATA_WIDTH:0] valid_data_phase_porta; // valid data
wire [_DATA_WIDTH:0] valid_data_phase_portb;    

wire valid_num_porta ;
wire valid_num_portb ;

reg [_DATA_WIDTH - 2 :0] phase_diff_fract; //小数部分
reg phase_diff_fract_overflow;              //小数是否溢出

reg [2:0] phase_diff_inter_q;               //整数部分
reg phase_diff_inter_q_overflow;            //整数是否溢出



assign valid_data_phase_porta = (valid_num_porta)?  data_phase_porta : 0;
assign valid_data_phase_portb = (valid_num_portb)?  data_phase_portb : 0;

assign valid_num_porta = ((phase_porta_cnt > cnt_limit_down) &(phase_porta_cnt < save_cnt))? 1'b1 : 1'b0;
assign valid_num_portb = ((phase_portb_cnt > cnt_limit_down) &(phase_portb_cnt < save_cnt))? 1'b1 : 1'b0;

assign phase_msb_porta = valid_data_phase_porta[_DATA_WIDTH] ;
assign phase_msb_portb = valid_data_phase_portb[_DATA_WIDTH] ;

assign phase_inter_q_porta = valid_data_phase_porta[(_DATA_WIDTH - 2) +: 2] ;
assign phase_inter_q_portb = valid_data_phase_portb[(_DATA_WIDTH - 2) +: 2] ;

assign phase_fract_porta = valid_data_phase_porta[(_DATA_WIDTH - 3) : 0] ;
assign phase_fract_portb = valid_data_phase_portb[(_DATA_WIDTH - 3) : 0] ;

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        phase_diff_fract <= 'd0;
        phase_diff_fract_overflow <= 1'b0;
        phase_diff_inter_q <= 'd0;
        phase_diff_inter_q_overflow <= 1'b0;
        polarity <= 1'd0;
    end
    else if (phase_msb_porta^phase_msb_portb) begin  //diff polarity
            phase_diff_fract <= phase_fract_porta + phase_fract_portb;
            phase_diff_fract_overflow <= (phase_fract_porta + phase_fract_portb)>>(_DATA_WIDTH - 2);

            phase_diff_inter_q <= phase_inter_q_porta + phase_inter_q_portb;
            phase_diff_inter_q_overflow <= (phase_inter_q_porta + phase_inter_q_portb)>>2;

            if (~phase_msb_porta&phase_msb_portb) begin // a positive b negative
                polarity <= 1'b0;                       // diff polarity is positive
            end
            else if (phase_msb_porta&~phase_msb_portb) begin // a negative b positive
                polarity <= 1'b1;                       // diff polarity is negative
            end
    end
    else begin  //same polarity

            phase_diff_fract_overflow <= 1'b0;
            phase_diff_inter_q_overflow <= 1'b0;
            polarity <= phase_msb_porta;
            if (phase_fract_porta > phase_fract_portb) begin                //a > b
                phase_diff_fract <= phase_fract_porta - phase_fract_portb;
                
            end
            else begin
                phase_diff_fract <= phase_fract_portb - phase_fract_porta;
                
            end

            if (phase_inter_q_porta > phase_inter_q_portb) begin           // b>=a
                phase_diff_inter_q <= phase_inter_q_porta - phase_inter_q_portb;
                
            end
            else begin
                phase_diff_inter_q <= phase_inter_q_portb - phase_inter_q_porta;
                
            end
    end


end


assign phase_diff = {phase_diff_inter_q[1:0],phase_diff_fract[_DATA_WIDTH - 3 :0]};
endmodule