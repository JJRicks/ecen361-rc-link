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
// Description: Self-checking testbench for RC_ARMING_EXAMPLE: arming, interlock,
//              clamping, and link loss / recovery.
//
// Dependencies: RC_ARMING_EXAMPLE, IBUS_RX, UART_RX, PWM
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Run time ~290ms of sim time (Vivado: set xsim run time to "all").
//////////////////////////////////////////////////////////////////////////////////

module RC_ARMING_EXAMPLE_tb();
    logic clk = 0, IBUS = 1; wire ESC_PWM;
    RC_ARMING_EXAMPLE DUT (clk, IBUS, ESC_PWM);
    initial DUT.ESC.count = 0;
    always #41.667 clk = ~clk;
    real bit_ns = 1.0e9 / 115200;
    logic [15:0] ch [1:14];
    int errors = 0;
    task automatic send_byte(input [7:0] b);
        IBUS = 0; #(bit_ns); for (int i = 0; i < 8; i++) begin IBUS = b[i]; #(bit_ns); end IBUS = 1; #(bit_ns);
    endtask
    task automatic send_frames(input int n);
        repeat (n) begin
            logic [15:0] sum; sum = 16'h60;
            for (int k = 1; k <= 14; k++) sum = sum + ch[k][7:0] + ch[k][15:8];
            sum = 16'hFFFF - sum;
            send_byte(8'h20); send_byte(8'h40);
            for (int k = 1; k <= 14; k++) begin send_byte(ch[k][7:0]); send_byte(ch[k][15:8]); end
            send_byte(sum[7:0]); send_byte(sum[15:8]);
            #4_200_000;
        end
    endtask
    task automatic check(input string what, input bit ok);
        if (ok) $display("pass: %s (armed=%b esc=%0d ail=%0d)", what, DUT.armed, DUT.esc_width/12, DUT.aileron_us);
        else begin errors++; $display("FAIL: %s (armed=%b esc=%0d ail=%0d)", what, DUT.armed, DUT.esc_width/12, DUT.aileron_us); end
    endtask
    initial begin
        for (int k = 1; k <= 14; k++) ch[k] = 1500;
        #1_000_000;
        check("no link: motor off, surfaces centered", DUT.armed === 0 && DUT.esc_width == 12000 && DUT.aileron_us == 1500);
        ch[5] = 2000; ch[3] = 1600; ch[1] = 1200;
        send_frames(3);
        check("SwA armed but throttle high: stays disarmed", DUT.armed === 0 && DUT.esc_width == 12000 && DUT.aileron_us == 1200);
        ch[3] = 1000; send_frames(2);
        check("throttle low: arms", DUT.armed === 1 && DUT.esc_width == 12000);
        ch[3] = 1600; send_frames(2);
        check("armed: throttle passes through", DUT.armed === 1 && DUT.esc_width == 1600*12);
        ch[3] = 2100; send_frames(2);
        check("throttle clamped to 2000", DUT.esc_width == 2000*12);
        ch[3] = 1600; ch[5] = 1000; send_frames(2);
        check("SwA disarm: motor off", DUT.armed === 0 && DUT.esc_width == 12000);
        ch[5] = 2000; send_frames(2);
        check("re-arm with throttle high: blocked", DUT.armed === 0);
        ch[3] = 1000; send_frames(2); ch[3] = 1500; send_frames(2);
        check("re-armed after throttle low", DUT.armed === 1 && DUT.esc_width == 1500*12);
        #150_000_000;
        check("link lost 150ms: motor off, surfaces centered", DUT.armed === 0 && DUT.esc_width == 12000 && DUT.aileron_us == 1500);
        send_frames(3);
        check("link back with throttle up: stays disarmed", DUT.armed === 0 && DUT.esc_width == 12000);
        if (errors == 0) $display("ALL TESTS PASSED"); else $display("%0d CHECK(S) FAILED", errors);
        $finish;
    end
endmodule
