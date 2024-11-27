module dual_ram_data # (
    parameter _COUNTER_WIDTH = 14,
    parameter _DATA_WIDTH = 14,
    parameter _DUAL_WIDTH = 12  
)   (
    input clk,
    input rst_n,
    input [_DATA_WIDTH:0] data_in,
    input [_COUNTER_WIDTH - 1:0] data_cnt,
    input [_COUNTER_WIDTH - 1:0] cnt_limit_up,          // save the phase counter value
    input [_COUNTER_WIDTH - 1:0] cnt_limit_down,    // which is from No.N of phase
//dual RAM
    input porta_en,
    input [_DUAL_WIDTH - 1 :0] data_o_addr,
    output [_DATA_WIDTH:0] data_o,
    output data_ram_busy

);



wire data_valid      ;
reg data_we         ;
reg [_DATA_WIDTH:0] data_writed;
reg [_COUNTER_WIDTH - 1:0] data_addrb;
assign data_valid = ((data_cnt >= cnt_limit_down)&(data_cnt < cnt_limit_up))? 1'b1 : 1'b0;


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_we <=0;
        data_writed <=0;
    end
    else begin
        data_we <=data_valid;
        data_writed <=data_in;
    end
    
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_addrb <=0;
    end
    else if (data_we == 1'b1) begin
        data_addrb <= data_addrb + 1'b1;
    end
    else begin
        data_addrb <=0;
    end
end
assign data_ram_busy = data_we ;


blk_mem_gen_0  u_blk_mem_gen_0 (
    .clka(clk),
    .ena(data_valid),
    .wea(data_valid),
    .addra(data_addrb),
    .dina(data_writed),
    .clkb(clk),
    .enb(porta_en),
    .addrb(data_o_addr),
    .doutb(data_o)
);

endmodule