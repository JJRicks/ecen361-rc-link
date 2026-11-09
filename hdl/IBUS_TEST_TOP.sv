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
// Dependencies: IBUS_RX, IBUS_UART_RX, PWM (team-snapshot/PWM.sv)
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
    logic [18:0] width;

    IBUS_RX #(.CLK_HZ(12_000_000)) R1 (clk_12MHz, IBUS, Ch, FrameValid, Failsafe);

    // The bench test runs straight off the board's 12MHz clock, so it needs no
    // clock wizard. PWM just counts clocks (whatever its port is called):
    // 12 per us here, 240,000 per 20ms. Center the servo (1500us) in failsafe.
    assign width = Failsafe ? 19'd18000 : Ch[1] * 19'd12;
    PWM #(.Pulse_Period(240_000)) P1 (clk_12MHz, width, OUT);

    assign led[0] = ~Failsafe;
    assign led[1] = Ch[5] > 1500;
endmodule
