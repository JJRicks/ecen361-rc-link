`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Justin Hutchens
// 
// Create Date: 10/12/2026 01:24:11 PM
// Design Name: 
// Module Name: UART_TX
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


module UART_TX(
        //clk
        input clk_20MHz,
        
        //UART_I/O
        output logic TX,
                
        // TX inputs
        input [7:0] wData,
        input wValid,
        output logic wReady
    );
    
    logic [9:0] data;
    
    logic [3:0] sender; // how many bits we've sent
    
    logic [7:0] bauder; 
    logic state = 0; // 0 = waiting for data; 1 = data is sending
    logic next_state = 0;
    
    always_ff @(posedge clk_20MHz)
    begin
        if (bauder > 8'hAD) bauder <= 0;
        else bauder ++;
        
        state <= next_state;
    end
    
    always_ff @(negedge bauder[7]) begin
        if (state) begin
            TX <= data[0];
            data <= {1'b1, data[9:1]};
            
            sender++;            
            if (sender == 4'd10) // if we are done sending, end send state
            begin
                sender <= 4'h0;
                next_state <= 0;
                wReady <= 1;
            end
        end
        else begin
            TX <= 1;
            if (wValid) begin
               next_state <= 1;
               wReady <= 0;
               data <= {1'b1, wData, 1'b0};

            end
        end
    end
endmodule
