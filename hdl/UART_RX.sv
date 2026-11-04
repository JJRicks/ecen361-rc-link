`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/04/2026
// Design Name:
// Module Name: UART_RX
// Project Name:
// Target Devices: Cmod A7-35T
// Tool Versions:
// Description: 8N1 UART receiver. Runs entirely on clk (no derived clocks).
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module UART_RX #(
    parameter int CLK_HZ = 12_000_000,
    parameter int BAUD = 115_200
    )(
        //clk
        input clk,

        //UART_I/O
        input RX,                       // idle high, asynchronous to clk

        // RX outputs
        output logic [7:0] rData,
        output logic rValid             // high for one clk when rData is new
    );

    localparam int BIT_CLKS = (CLK_HZ + BAUD/2) / BAUD;    // clocks per bit (104 at 12MHz / 115200)

    logic rx_meta = 1, rx_s = 1;        // 2 flop synchronizer on the async input
    logic [$clog2(BIT_CLKS)-1:0] timer = 0;
    logic [3:0] bitnum = 0;             // 0 = start bit, 1-8 = data bits, 9 = stop bit
    logic [7:0] shift = 0;
    logic busy = 0;

    always_ff @(posedge clk)
    begin
        rx_meta <= RX;
        rx_s <= rx_meta;
        rValid <= 0;

        if (~busy) begin
            if (~rx_s) begin            // falling edge = start bit
                busy <= 1;
                bitnum <= 0;
                timer <= BIT_CLKS / 2;  // first sample lands in the middle of the start bit
            end
        end
        else if (timer != 0)
            timer <= timer - 1;
        else begin                      // middle of a bit: sample it
            timer <= BIT_CLKS - 1;
            bitnum <= bitnum + 1;

            if (bitnum == 0) begin
                if (rx_s) busy <= 0;    // line went back high: glitch, not a start bit
            end
            else if (bitnum <= 8)
                shift <= {rx_s, shift[7:1]};    // LSB first
            else begin                  // stop bit
                busy <= 0;
                if (rx_s) begin         // only keep bytes with a good stop bit
                    rData <= shift;
                    rValid <= 1;
                end
            end
        end
    end
endmodule
