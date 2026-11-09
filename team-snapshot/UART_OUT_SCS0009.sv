`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Justin Hutchens
// 
// Create Date: 10/12/2026 01:24:11 PM
// Design Name: 
// Module Name: UART_OUT_SCS0009
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: UART_TX
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module SCS009_Interpreter #(
    parameter int ID1 = 1,
    parameter int ID2 = 2,
    parameter int ID3 = 3
    )(
    input clk_20MHz, // clk
    
    output TX, // UART TX output to servos
    
    input [9:0] Pos1,  
    input [9:0] Pos2,  
    input [9:0] Pos3,  
    input data_Valid,
    
    output logic Ready // high when data_writing is available
    );
    
    logic [9:0] Pos [2:0];
    
    logic wValid, wReady;
    logic [7:0] data;
    logic state = 0;
    logic next_state = 0, prev_state = 0;
    logic [4:0] step = 0;
    logic wReadyPrev = 0;       // previous stae of wReady
    
    always_ff @(posedge clk_20MHz) begin
        
        if (state) begin                        // enter send state
            if (~wReady & wReadyPrev) begin     // negedge of wReady (I.E. data was loaded
               step <= step + 1;
               wValid <= 0;
               if (step >= 8'h10) begin
                    next_state <= 0;
                    step <= 0;
                end
            end
            else if (wReady & ~wReadyPrev | ~prev_state)
                wValid <= 1;
        end
        else begin                      // await instructions to go to send state
            Ready <= 1;
            wValid <= 0;
            if (data_Valid) begin
                next_state <= 1;
                Ready <= 0;
                Pos[0] <= Pos1;
                Pos[1] <= Pos2;
                Pos[2] <= Pos3;
            end
        end   
        
        wReadyPrev <= wReady;
        prev_state <= state;
        state <= next_state;
    end    
    
    always_comb
    case (step)                     // assign data depending on what step we're on
        5'h0: data = 8'hFF;         // starting buffer
        5'h1: data = 8'hFF;         // starting buffer
        5'h2: data = 8'hFE;         // "ID" made to show them that it is not for any indavidual, but ID is required
        5'h3: data = 8'h0D;         // Data length (13 bytes after this
        5'h4: data = 8'h83;         // instruction "Sync Write" = 0x83
        5'h5: data = 8'h2A;         // write address (2A is target position
        5'h6: data = 8'h02;         // data length (2 bytes)
        5'h7: data = ID1;                       // ID
        5'h8: data = {2'b00 , Pos[0][9:8]};     // data_higher
        5'h9: data = Pos[0][7:0];               // data_lower
        5'hA: data = ID2;
        5'hB: data = {2'b00 , Pos[1][9:8]};
        5'hC: data = Pos[1][7:0];
        5'hD: data = ID3;
        5'hE: data = {2'b00 , Pos[2][9:8]};
        5'hF: data = Pos[2][7:0];
        5'h10: data = ~(8'hBA + ID1 + ID2 + ID3 +   // checksum (inverse of sum of all bytes after FF FF
                      Pos[0][7:0] + {2'b00 , Pos[0][9:8]} + 
                      Pos[1][7:0] + {2'b00 , Pos[1][9:8]} + 
                      Pos[2][7:0] + {2'b00 , Pos[2][9:8]});
    endcase
    
    UART_TX U1 (clk_20MHz, TX, data, wValid, wReady);
endmodule

