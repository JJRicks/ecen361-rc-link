`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/04/2026
// Design Name:
// Module Name: RC_ARMING_EXAMPLE_tb
// Project Name:
// Target Devices: Cmod A7-35T
// Tool Versions:
// Description: Self-checking testbench for RC_ARMING_EXAMPLE at 20MHz: arming,
//              interlock, clamping, link loss and recovery, the real ESC pulse
//              in microseconds, and the bytes sent to the servos.
//
// Dependencies: RC_ARMING_EXAMPLE, IBUS_RX, IBUS_UART_RX, PWM, SCS009_Interpreter, UART_TX
//
// Revision:
// Revision 0.02 - 20MHz, real pulse measurement, servo packet checks
// Additional Comments:
//   Run time ~570ms of sim time (Vivado: set xsim run time to "all").
//////////////////////////////////////////////////////////////////////////////////

module RC_ARMING_EXAMPLE_tb();
    logic clk = 0, IBUS = 1;
    wire ESC_PWM, SERVO_TX;

    RC_ARMING_EXAMPLE DUT (clk, IBUS, ESC_PWM, SERVO_TX);

    // FPGA flip-flops power up at 0, but these team-module registers have no
    // initial value, so the simulator would start them at X.
    initial begin
        DUT.ESC.count = 0;
        DUT.SERVOS.U1.bauder = 0;
        DUT.SERVOS.U1.sender = 0;
        DUT.SERVOS.U1.wReady = 0;
    end

    always #25 clk = ~clk;              // 20 MHz

    real bit_ns = 1.0e9 / 115200;
    logic [15:0] ch [1:14];
    int errors = 0;

    task automatic send_byte(input [7:0] b);
        IBUS = 0; #(bit_ns);
        for (int i = 0; i < 8; i++) begin IBUS = b[i]; #(bit_ns); end
        IBUS = 1; #(bit_ns);
    endtask

    task automatic send_frames(input int n);
        repeat (n) begin
            logic [15:0] sum;
            sum = 16'h60;
            for (int k = 1; k <= 14; k++) sum = sum + ch[k][7:0] + ch[k][15:8];
            sum = 16'hFFFF - sum;
            send_byte(8'h20); send_byte(8'h40);
            for (int k = 1; k <= 14; k++) begin send_byte(ch[k][7:0]); send_byte(ch[k][15:8]); end
            send_byte(sum[7:0]); send_byte(sum[15:8]);
            #4_200_000;
        end
    endtask

    task automatic check(input string what, input bit ok);
        if (ok) $display("pass: %s (armed=%b esc=%0d ail=%0d)", what, DUT.armed, DUT.esc_width/20, DUT.aileron_us);
        else begin
            errors++;
            $display("FAIL: %s (armed=%b esc=%0d ail=%0d)", what, DUT.armed, DUT.esc_width/20, DUT.aileron_us);
        end
    endtask

    // Measure the pulse the ESC really sees, in microseconds, and its period.
    task automatic check_pulse(input string what, input real expect_us);
        realtime t0;
        real width_us, period_ms;
        @(posedge ESC_PWM); t0 = $realtime; @(negedge ESC_PWM);
        width_us = ($realtime - t0) / 1000.0;
        @(posedge ESC_PWM);
        period_ms = ($realtime - t0) / 1.0e6;
        if (width_us > expect_us - 0.2 && width_us < expect_us + 0.2 && period_ms > 19.9 && period_ms < 20.1)
            $display("pass: %s: ESC pulse = %0.1f us every %0.2f ms", what, width_us, period_ms);
        else begin
            errors++;
            $display("FAIL: %s: ESC pulse = %0.1f us (want %0.1f) every %0.2f ms (want 20)",
                     what, width_us, expect_us, period_ms);
        end
    endtask

    // Capture the bytes on the servo bus. UART_TX runs at 175 clocks per bit.
    localparam real SERVO_BIT_NS = 175 * 50.0;
    logic [7:0] srx [0:255];
    logic [7:0] srx_byte;
    int srx_n = 0;

    initial forever begin
        @(negedge SERVO_TX);
        #(SERVO_BIT_NS * 1.5);
        for (int i = 0; i < 8; i++) begin srx_byte[i] = SERVO_TX; #(SERVO_BIT_NS); end
        if (srx_n < 256) begin srx[srx_n] = srx_byte; srx_n++; end
    end

    // Wait for a complete sync-write packet and check every byte that matters.
    task automatic check_servos(input string what, input int pos_ail, input int pos_ele);
        int at;
        bit ok;
        logic [7:0] sum;
        at = -1;
        srx_n = 0;
        #45_000_000;                    // packets go out every 20ms
        for (int i = 0; i + 17 <= srx_n && at < 0; i++)
            if (srx[i] == 8'hFF && srx[i+1] == 8'hFF && srx[i+2] == 8'hFE && srx[i+3] == 8'h0D &&
                srx[i+4] == 8'h83 && srx[i+5] == 8'h2A && srx[i+6] == 8'h02) at = i;
        ok = (at >= 0);
        if (ok) begin
            sum = 0;
            for (int j = 2; j <= 15; j++) sum = sum + srx[at+j];
            ok = srx[at+7]  == 1 && {srx[at+8],  srx[at+9]}  == pos_ail &&
                 srx[at+10] == 2 && {srx[at+11], srx[at+12]} == pos_ail &&
                 srx[at+13] == 3 && {srx[at+14], srx[at+15]} == pos_ele &&
                 srx[at+16] == ~sum;
        end
        if (ok) $display("pass: %s: servo packet Pos1=%0d Pos2=%0d Pos3=%0d", what,
                         {srx[at+8], srx[at+9]}, {srx[at+11], srx[at+12]}, {srx[at+14], srx[at+15]});
        else begin
            errors++;
            $display("FAIL: %s: no matching servo packet (found at %0d, want Pos1=Pos2=%0d Pos3=%0d)",
                     what, at, pos_ail, pos_ele);
        end
    endtask

    initial begin
        for (int k = 1; k <= 14; k++) ch[k] = 1500;
        #1_000_000;
        check("no link: motor off, surfaces centered", DUT.armed === 0 && DUT.esc_width == 20000 && DUT.aileron_us == 1500);
        check_pulse("no link", 1000.0);
        check_servos("no link", 512, 512);

        ch[5] = 2000; ch[3] = 1600; ch[1] = 1200; ch[2] = 1800;
        send_frames(3);
        check("SwA armed but throttle high: stays disarmed", DUT.armed === 0 && DUT.esc_width == 20000 && DUT.aileron_us == 1200);
        check_servos("link up", 437, 587);

        ch[3] = 1000; send_frames(2);
        check("throttle low: arms", DUT.armed === 1 && DUT.esc_width == 20000);
        ch[3] = 1600; send_frames(2);
        check("armed: throttle passes through", DUT.armed === 1 && DUT.esc_width == 1600*20);
        check_pulse("armed at 1600", 1600.0);
        send_frames(1);
        ch[3] = 2100; send_frames(2);
        check("throttle clamped to 2000", DUT.esc_width == 2000*20);
        check_pulse("clamped full throttle", 2000.0);
        send_frames(1);
        ch[3] = 1600; ch[5] = 1000; send_frames(2);
        check("SwA disarm: motor off", DUT.armed === 0 && DUT.esc_width == 20000);
        ch[5] = 2000; send_frames(2);
        check("re-arm with throttle high: blocked", DUT.armed === 0);
        ch[3] = 1000; send_frames(2); ch[3] = 1500; send_frames(2);
        check("re-armed after throttle low", DUT.armed === 1 && DUT.esc_width == 1500*20);

        // link lost: no frames at all, the timer still has to send centered positions
        #150_000_000;
        check("link lost 150ms: motor off, surfaces centered", DUT.armed === 0 && DUT.esc_width == 20000 && DUT.aileron_us == 1500);
        check_pulse("link lost", 1000.0);
        check_servos("link lost", 512, 512);

        send_frames(3);
        check("link back with throttle up: stays disarmed", DUT.armed === 0 && DUT.esc_width == 20000);

        if (errors == 0) $display("ALL TESTS PASSED");
        else $display("%0d CHECK(S) FAILED", errors);
        $finish;
    end
endmodule
