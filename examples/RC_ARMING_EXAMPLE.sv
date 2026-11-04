`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/04/2026
// Design Name:
// Module Name: RC_ARMING_EXAMPLE
// Project Name:
// Target Devices: Cmod A7-35T
// Tool Versions:
// Description: Example of using IBUS_RX in a real top: arm switch with a
//              throttle-low interlock, throttle failsafe = motor off (1000us),
//              control surfaces centered in failsafe.
//
// Dependencies: IBUS_RX, UART_RX, PWM (team-snapshot/PWM.sv)
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Copy the body into the flight top level. Checked by RC_ARMING_EXAMPLE_tb.
//   Assumes SwA DOWN = CH5 high = armed (check with bench test step F4).
//////////////////////////////////////////////////////////////////////////////////

module RC_ARMING_EXAMPLE(
    input clk_12MHz,
    input IBUS,                 // FS-iA6B SERVO port signal
    output ESC_PWM              // to the ESC signal wire
    );
    logic [14:1][11:0] Ch;
    logic FrameValid, Failsafe;

    IBUS_RX #(.CLK_HZ(12_000_000)) RC (clk_12MHz, IBUS, Ch, FrameValid, Failsafe);

    // keep a channel inside 1000..2000 us
    function automatic logic [11:0] clamp_us(input logic [11:0] v);
        return (v < 12'd1000) ? 12'd1000 : (v > 12'd2000) ? 12'd2000 : v;
    endfunction

    // Arm switch with a throttle-low interlock:
    //   disarms instantly on failsafe or when SwA (CH5) goes to "disarmed"
    //   only arms while SwA is "armed" AND the throttle stick is low
    logic armed = 0;
    always_ff @(posedge clk_12MHz)
        if (Failsafe || Ch[5] < 12'd1700) armed <= 0;
        else if (Ch[3] < 12'd1100)        armed <= 1;

    // Throttle to the ESC: 1000 us (motor off) unless armed
    logic [17:0] esc_width;
    assign esc_width = armed ? clamp_us(Ch[3]) * 18'd12 : 18'd12_000;
    PWM ESC (clk_12MHz, esc_width, ESC_PWM);

    // Control surfaces: centered in failsafe
    logic [11:0] aileron_us, elevator_us;
    assign aileron_us  = Failsafe ? 12'd1500 : clamp_us(Ch[1]);
    assign elevator_us = Failsafe ? 12'd1500 : clamp_us(Ch[2]);

    // aileron_us / elevator_us go on to the SCS0009 position logic (not shown).
    // To reverse a surface that moves the wrong way use (12'd3000 - value).
endmodule
