`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/01/2026 07:30:28 PM
// Design Name: 
// Module Name: PWM
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

module BUTTONS (
    input logic RED,
    input logic BLUE,
    input clk_12MHz,
    output OUT
    );
    
    logic [17:0] size = 14'h2000;
    logic [7:0] clk_Slow;
    
    always_ff @(posedge clk_12MHz)
        clk_Slow++;
    
    always_ff @(posedge clk_Slow[7])
    begin
    size = size + (size > 16'h7800 ? 0 : RED) - (size < 13'h1600 ? 0 : BLUE);
    end
    
    PWM P1 (clk_12MHz, size, OUT);
    
endmodule 

module PWM(
    input clk_12MHz,
    input[17:0] Durration,
    output pulse
    );
    
    logic [17:0] count;
    
    always_ff @(posedge clk_12MHz)
        begin
        count++;
        if (count > 18'h3A980) count <= 0;
        end
    assign pulse = count < Durration;
    
endmodule
