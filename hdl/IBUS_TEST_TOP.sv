`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/04/2026
// Design Name:
// Module Name: IBUS_TEST_TOP
// Project Name:
// Target Devices: Cmod A7-35T
// Tool Versions:
// Description: Bench test for the RC link. Aileron stick (CH1) drives a PWM
//              servo on OUT, LEDs show link status.
//
// Dependencies: IBUS_RX, UART_RX, PWM (Servo PWM/PWM.srcs/sources_1/new/PWM.sv)
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   led[0] on  = good i-BUS frames arriving (off = failsafe)
//   led[1] on  = CH5 above center
//////////////////////////////////////////////////////////////////////////////////


module IBUS_TEST_TOP(
    input clk_12MHz,
    input IBUS,                 // signal pin of the FS-iA6B SERVO port
    output OUT,                 // servo signal, follows CH1
    output [1:0] led
    );

    logic [14:1][11:0] Ch;
    logic FrameValid, Failsafe;
    logic [17:0] width;

    IBUS_RX R1 (clk_12MHz, IBUS, Ch, FrameValid, Failsafe);

    // PWM counts 12MHz clocks, so 12 clocks per us. Center the servo (1500us) in failsafe.
    assign width = Failsafe ? 18'd18000 : Ch[1] * 18'd12;
    PWM P1 (clk_12MHz, width, OUT);

    assign led[0] = ~Failsafe;
    assign led[1] = Ch[5] > 1500;
endmodule
