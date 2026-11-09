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
    input clk_20MHz,
    output OUT
    );
    
    logic [17:0] size = 14'h2000;
    logic [7:0] clk_Slow;
    
    always_ff @(posedge clk_20MHz)
        clk_Slow++;
    
    always_ff @(posedge clk_Slow[7])
    begin
    size = size + (size > 16'h7800 ? 0 : RED) - (size < 13'h1600 ? 0 : BLUE);
    end
    
    PWM P1 (clk_20MHz, size, OUT);
    
endmodule 

module PWM # (
    parameter int Pulse_Period = 19'h61A80
    //parameter int Max_Speed = 16'h9C40 //variable to be used for comparison later when making ranges 
    //parameter int Min_Speed = 15'h4E20 //see above as well as to be used in the initialization module (potentially)
    )
    (
    input clk_20MHz,
    input[18:0] Durration,
    output pulse
    );
    
    logic [18:0] count;
    
    always_ff @(posedge clk_20MHz)
        begin
        //Send a minimum throttle from the flight controller (FPGA) to the ESC to initialize
        //maybe I need to make an initialization module that the FPGA will run on startup that is 
        //seperate from this module so that it can send the minimum throttle right out the gate. 
        // Ask Justin about this
        count++;
        if (count > Pulse_Period) count <= 0;
        // get sample of desired speed from flight controller (FPGA) compare it to the ranges based
        // on number of bits sent, then send the desired pulse based on the speed range sent
        
        end
        // this is where the data actually gets sent to the ESC
        // so it will probably need to be modified when we know what kind of data we are getting
        //Something to ask Joel and Justin about
    assign pulse = count < Durration;
    
endmodule
