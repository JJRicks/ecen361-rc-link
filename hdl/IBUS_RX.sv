`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/04/2026
// Design Name:
// Module Name: IBUS_RX
// Project Name:
// Target Devices: Cmod A7-35T
// Tool Versions:
// Description: Decodes FlySky i-BUS (FS-iA6B "SERVO" port) into channel values.
//
// Dependencies: IBUS_UART_RX
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   i-BUS = 115200 8N1, one 32 byte frame about every 7ms:
//     [0x20][0x40][ch1 lo][ch1 hi] ... [ch14 lo][ch14 hi][chk lo][chk hi]
//     channels are ~1000-2000 (us), chk = 0xFFFF - (sum of bytes 0-29)
//   Ch only updates on frames with a good checksum.
//   Failsafe is high at power up and whenever no good frame has arrived for
//   TIMEOUT_MS. Don't trust Ch while Failsafe is high.
//////////////////////////////////////////////////////////////////////////////////


module IBUS_RX #(
    parameter int CLK_HZ = 20_000_000,
    parameter int TIMEOUT_MS = 100
    )(
        //clk
        input clk,

        // i-BUS line from the receiver
        input RX,

        // outputs
        output logic [14:1][11:0] Ch,   // Ch[n] = FlySky channel n
        output logic FrameValid,        // high for one clk after each good frame
        output logic Failsafe
    );

    localparam int GAP_CLKS = CLK_HZ / 1000;                // 1ms of idle line = gap between frames
    localparam int TIMEOUT_CLKS = CLK_HZ / 1000 * TIMEOUT_MS;

    logic [7:0] rData;
    logic rValid;

    logic [4:0] idx = 0;                // which byte of the frame is next (0-31)
    logic [15:0] sum = 0;               // running sum of bytes 0-29
    logic [7:0] lo = 0;                 // low byte of the channel / checksum being received
    logic [14:1][11:0] shadow;          // channels of the frame being received
    logic [$clog2(GAP_CLKS+1)-1:0] gap = 0;
    logic [$clog2(TIMEOUT_CLKS+1)-1:0] silence = TIMEOUT_CLKS;  // clks since last good frame

    assign Failsafe = (silence == TIMEOUT_CLKS);

    always_ff @(posedge clk)
    begin
        FrameValid <= 0;
        if (~Failsafe) silence <= silence + 1;

        if (rValid) begin
            gap <= 0;
            idx <= idx + 1;
            if (idx == 0) sum <= rData;
            else if (idx < 30) sum <= sum + rData;

            case (idx)
                0: if (rData != 8'h20) idx <= 0;            // length byte (32)
                1: if (rData != 8'h40) idx <= 0;            // command byte (servo data)
                30: lo <= rData;                            // checksum low byte
                31: begin                                   // checksum high byte
                    idx <= 0;
                    if ({rData, lo} == 16'hFFFF - sum) begin
                        Ch <= shadow;
                        FrameValid <= 1;
                        silence <= 0;
                    end
                end
                default:
                    if (~idx[0]) lo <= rData;                       // even byte = channel low byte
                    else shadow[idx[4:1]] <= {rData[3:0], lo};      // odd byte = channel high byte
            endcase
        end
        else if (gap != GAP_CLKS)
            gap <= gap + 1;
        else
            idx <= 0;                   // line has been idle: next byte starts a new frame
    end

    IBUS_UART_RX #(.CLK_HZ(CLK_HZ), .BAUD(115_200)) U1 (clk, RX, rData, rValid);
endmodule
