`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/10/16 17:37:37
// Design Name: 
// Module Name: adc_data_sync
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adc_data_sync # (
    parameter _DATA_WIDTH = 14
    )
    (
    input clk_sync,
    input sys_rst,
    input [_DATA_WIDTH -1:0] adc_data,
    output [ _DATA_WIDTH -1:0] sync_data
    );
    reg  [_DATA_WIDTH -1:0] sync_data_reg_d1;
    reg  [_DATA_WIDTH -1:0] sync_data_reg_d2;
    always @(posedge clk_sync or negedge sys_rst) begin
        if (!sys_rst) begin
            sync_data_reg_d1 <= 0;
            sync_data_reg_d2 <= 0;
        end
        else begin
            sync_data_reg_d1 <= adc_data;
            sync_data_reg_d2 <= sync_data_reg_d1;
        end
    end
    assign sync_data = sync_data_reg_d2;
endmodule
