`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/04/2026
// Design Name:
// Module Name: IBUS_TEST_TOP_tb
// Project Name:
// Target Devices:
// Tool Versions:
// Description: End-to-end check of the bench-test top: i-BUS frames in,
//              servo pulse width and LEDs out. Self-checking.
//
// Dependencies: IBUS_TEST_TOP, IBUS_RX, UART_RX, PWM (team-snapshot/PWM.sv)
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Run time ~90ms of sim time (Vivado: set xsim run time to "all").
//////////////////////////////////////////////////////////////////////////////////


module IBUS_TEST_TOP_tb();

    logic clk = 0, IBUS = 1;
    wire OUT;
    wire [1:0] led;

    IBUS_TEST_TOP DUT (clk, IBUS, OUT, led);

    // PWM.sv's counter has no initial value. Real hardware powers up at 0;
    // the simulator would start it at X, so set it here.
    initial DUT.P1.count = 0;

    always #41.667 clk = ~clk;          // 12 MHz

    real bit_ns = 1.0e9 / 115200;
    logic [15:0] ch [1:14];
    int errors = 0;

    task automatic send_byte(input [7:0] b);
        IBUS = 0; #(bit_ns);
        for (int i = 0; i < 8; i++) begin IBUS = b[i]; #(bit_ns); end
        IBUS = 1; #(bit_ns);
    endtask

    task automatic send_frame();
        logic [15:0] sum;
        sum = 16'h20 + 16'h40;
        for (int n = 1; n <= 14; n++) sum = sum + ch[n][7:0] + ch[n][15:8];
        sum = 16'hFFFF - sum;
        send_byte(8'h20); send_byte(8'h40);
        for (int n = 1; n <= 14; n++) begin send_byte(ch[n][7:0]); send_byte(ch[n][15:8]); end
        send_byte(sum[7:0]); send_byte(sum[15:8]);
    endtask

    // measure one OUT pulse and compare it (and led[0]) to what we expect
    task automatic measure(input string what, input real expect_us, input bit expect_led0);
        realtime t0;
        real width_us;
        @(posedge OUT); t0 = $realtime; @(negedge OUT);
        width_us = ($realtime - t0) / 1000.0;
        if (width_us > expect_us - 0.2 && width_us < expect_us + 0.2 && led[0] === expect_led0)
            $display("pass: %s: OUT pulse = %0.1f us, led = %b", what, width_us, led);
        else begin
            errors++;
            $display("FAIL: %s: OUT pulse = %0.1f us (want %0.1f), led = %b (want led[0]=%b)",
                     what, width_us, expect_us, led, expect_led0);
        end
    endtask

    task automatic check(input string what, input bit ok);
        if (ok) $display("pass: %s", what);
        else begin
            errors++;
            $display("FAIL: %s", what);
        end
    endtask

    initial begin
        for (int n = 1; n <= 14; n++) ch[n] = 1500;

        // no radio: servo should sit at center, link LED off
        measure("no link (failsafe)", 1500.0, 0);

        // CH1 = 1250us, CH5 = 1900 (switch "on")
        ch[1] = 1250; ch[5] = 1900;
        fork
            begin repeat (6) begin send_frame(); #4_200_000; end end
            begin #30_000_000; measure("CH1=1250", 1250.0, 1); end
        join
        check("led[1] on when CH5 > 1500", led[1] === 1);

        // CH1 = 1800us, CH5 = 1000 (switch "off")
        ch[1] = 1800; ch[5] = 1000;
        fork
            begin repeat (6) begin send_frame(); #4_200_000; end end
            begin #30_000_000; measure("CH1=1800", 1800.0, 1); end
        join
        check("led[1] off when CH5 < 1500", led[1] === 0);

        if (errors == 0) $display("ALL TESTS PASSED");
        else $display("%0d CHECK(S) FAILED", errors);
        $finish;
    end
endmodule
