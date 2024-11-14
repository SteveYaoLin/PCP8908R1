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
    output [_DATA_WIDTH:0] phase_diff,
    output  polarity
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

reg [_DATA_WIDTH - 2 :0] phase_diff_fract; //§³??????
reg phase_diff_fract_overflow;              //§³????????

reg [2:0] phase_diff_inter_q;               //????????
reg phase_diff_inter_q_overflow;            //??????????

wire signed [15:0] phase_a_ext;       // Extended sign for phase A
wire signed [15:0] phase_b_ext;       // Extended sign for phase B
wire signed [15:0] diff;              // 16-bit result for phase difference



assign valid_num_porta = ((phase_porta_cnt > cnt_limit_down) &(phase_porta_cnt < save_cnt))? 1'b1 : 1'b0;
assign valid_num_portb = ((phase_portb_cnt > cnt_limit_down) &(phase_portb_cnt < save_cnt))? 1'b1 : 1'b0;

assign valid_data_phase_porta = (valid_num_porta)?  data_phase_porta : 0;
assign valid_data_phase_portb = (valid_num_portb)?  data_phase_portb : 0;

// assign phase_msb_porta = valid_data_phase_porta[_DATA_WIDTH] ;
// assign phase_msb_portb = valid_data_phase_portb[_DATA_WIDTH] ;

// assign phase_inter_q_porta = valid_data_phase_porta[(_DATA_WIDTH - 2) +: 2] ;
// assign phase_inter_q_portb = valid_data_phase_portb[(_DATA_WIDTH - 2) +: 2] ;

// assign phase_fract_porta = valid_data_phase_porta[(_DATA_WIDTH - 3) : 0] ;
// assign phase_fract_portb = valid_data_phase_portb[(_DATA_WIDTH - 3) : 0] ;

// module phase_difference have vafilicated at RF floder

    // Extend inputs to 16-bit signed to handle overflow during subtraction
    assign phase_a_ext = {valid_data_phase_porta[_DATA_WIDTH], valid_data_phase_porta};  // Sign-extend phase A
    assign phase_b_ext = {valid_data_phase_portb[_DATA_WIDTH], valid_data_phase_portb};  // Sign-extend phase B

    // Perform subtraction with extended width
    assign diff = phase_a_ext - phase_b_ext;
    assign phase_diff = diff[14:0];
    assign polarity = diff[15];


endmodule