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
// Description: Example of using IBUS_RX in the 20MHz flight design: arm switch
//              with a throttle-low interlock, throttle failsafe = motor off
//              (1000us), and control surfaces centered in failsafe.
//
// Dependencies: IBUS_RX, IBUS_UART_RX, PWM, SCS009_Interpreter, UART_TX
//               (the last three are in team-snapshot/)
//
// Revision:
// Revision 0.02 - Moved to 20MHz and the team's current PWM, added the servos
// Additional Comments:
//   Copy the body into the flight top level. Checked by RC_ARMING_EXAMPLE_tb.
//   Assumes SwA DOWN = CH5 high = armed (check with bench test step F4).
//////////////////////////////////////////////////////////////////////////////////

module RC_ARMING_EXAMPLE(
    input clk_20MHz,            // from the clock wizard (12MHz in, 20MHz out)
    input IBUS,                 // FS-iA6B SERVO port signal
    output ESC_PWM,             // to the ESC signal wire
    output SERVO_TX             // SCS0009 serial bus, via the URT-2 board
    );
    logic [14:1][11:0] Ch;
    logic FrameValid, Failsafe;

    IBUS_RX #(.CLK_HZ(20_000_000)) RC (clk_20MHz, IBUS, Ch, FrameValid, Failsafe);

    // keep a channel inside 1000..2000 us
    function automatic logic [11:0] clamp_us(input logic [11:0] v);
        return (v < 12'd1000) ? 12'd1000 : (v > 12'd2000) ? 12'd2000 : v;
    endfunction

    // Arm switch with a throttle-low interlock:
    //   disarms instantly on failsafe or when SwA (CH5) goes to "disarmed"
    //   only arms while SwA is "armed" AND the throttle stick is low
    // armed starts at 0, so the ESC sees 1000us from the first PWM period.
    logic armed = 0;
    always_ff @(posedge clk_20MHz)
        if (Failsafe || Ch[5] < 12'd1700) armed <= 0;
        else if (Ch[3] < 12'd1100)        armed <= 1;

    // Throttle to the ESC: 1000 us (motor off) unless armed. PWM counts 20 clocks per us.
    logic [18:0] esc_width;
    assign esc_width = armed ? clamp_us(Ch[3]) * 19'd20 : 19'd20_000;
    PWM ESC (clk_20MHz, esc_width, ESC_PWM);

    // Control surfaces: centered in failsafe
    logic [11:0] aileron_us, elevator_us;
    assign aileron_us  = Failsafe ? 12'd1500 : clamp_us(Ch[1]);
    assign elevator_us = Failsafe ? 12'd1500 : clamp_us(Ch[2]);

    // Stick (1000..2000 us) to SCS0009 position (387..637, 512 = center).
    // A starting point: set the real throw on the airframe.
    function automatic logic [9:0] to_pos(input logic [11:0] us);
        logic [11:0] d;
        d = us - 12'd1000;
        return 10'd387 + d[9:2];
    endfunction

    logic [9:0] pos_aileron, pos_elevator;
    assign pos_aileron  = to_pos(aileron_us);
    assign pos_elevator = to_pos(elevator_us);

    // Send positions every 20ms. This runs off a timer rather than FrameValid
    // because frames can stop when the link drops, and the centered failsafe
    // position still has to reach the servos.
    logic [18:0] servo_timer = 0;
    logic servo_send = 0;
    logic servo_ready;
    always_ff @(posedge clk_20MHz) begin
        servo_send <= 0;
        if (servo_timer == 19'd399_999) begin
            servo_timer <= 0;
            servo_send <= servo_ready;
        end
        else
            servo_timer <= servo_timer + 1;
    end

    // To mirror a surface that moves the wrong way, use (10'd1024 - pos).
    SCS009_Interpreter SERVOS (
        .clk_20MHz(clk_20MHz),
        .TX(SERVO_TX),
        .Pos1(pos_aileron),     // left aileron
        .Pos2(pos_aileron),     // right aileron
        .Pos3(pos_elevator),
        .data_Valid(servo_send),
        .Ready(servo_ready)
    );
endmodule
