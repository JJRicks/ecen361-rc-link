`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/04/2026
// Design Name:
// Module Name: IBUS_RX_tb
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Self-checking testbench for IBUS_RX. Prints pass/FAIL per check
//              and a summary line at the end.
//
// Dependencies: IBUS_RX, IBUS_UART_RX
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   Run time ~85ms of sim time (Vivado: set xsim run time to "all").
//   CLK_HZ defaults to the flight clock; sim/run_sim.sh also runs it at 12MHz.
//////////////////////////////////////////////////////////////////////////////////


module IBUS_RX_tb #(parameter int CLK_HZ = 20_000_000) ();

    logic clk = 0;
    logic RX = 1;
    logic [14:1][11:0] Ch;
    logic FrameValid, Failsafe;

    // short timeout so the failsafe test doesn't take forever
    IBUS_RX #(.CLK_HZ(CLK_HZ), .TIMEOUT_MS(20)) DUT (clk, RX, Ch, FrameValid, Failsafe);

    localparam real HALF_NS = 1.0e9 / CLK_HZ / 2.0;
    always #(HALF_NS) clk = ~clk;

    localparam real NOMINAL_BIT_NS = 1.0e9 / 115200;
    real bit_ns = NOMINAL_BIT_NS;

    logic [15:0] tx_ch [1:14];          // channel values the "receiver" sends
    int frames = 0;                     // FrameValid pulses seen
    int errors = 0;

    always @(posedge clk) if (FrameValid) frames++;

    task automatic send_byte(input [7:0] b);
        RX = 0; #(bit_ns);                                  // start bit
        for (int i = 0; i < 8; i++) begin RX = b[i]; #(bit_ns); end
        RX = 1; #(bit_ns);                                  // stop bit
    endtask

    task automatic send_frame(input bit bad_checksum, input real gap_ns);
        logic [15:0] sum;
        sum = 16'h20 + 16'h40;
        for (int n = 1; n <= 14; n++) sum = sum + tx_ch[n][7:0] + tx_ch[n][15:8];
        sum = 16'hFFFF - sum;
        if (bad_checksum) sum = sum ^ 16'h0001;

        send_byte(8'h20);
        send_byte(8'h40);
        for (int n = 1; n <= 14; n++) begin
            send_byte(tx_ch[n][7:0]);
            send_byte(tx_ch[n][15:8]);
        end
        send_byte(sum[7:0]);
        send_byte(sum[15:8]);
        #(gap_ns);
    endtask

    task automatic check(input string what, input bit ok);
        if (ok) $display("pass: %s", what);
        else begin
            errors++;
            $display("FAIL: %s", what);
        end
    endtask

    task automatic check_channels(input string what);
        bit ok;
        ok = 1;
        for (int n = 1; n <= 14; n++)
            if (Ch[n] !== tx_ch[n][11:0]) begin
                ok = 0;
                $display("      Ch[%0d] = %0d, expected %0d", n, Ch[n], tx_ch[n]);
            end
        check(what, ok);
    endtask

    initial begin
        for (int n = 1; n <= 14; n++) tx_ch[n] = 1500;
        #1_000_000;
        check("Failsafe high at power up", Failsafe === 1);

        // normal frame, ~7ms frame period
        tx_ch[1] = 1000; tx_ch[2] = 2000; tx_ch[3] = 1234;
        tx_ch[4] = 1500; tx_ch[5] = 1100; tx_ch[6] = 1900;
        send_frame(0, 4_200_000);
        check_channels("good frame decoded");
        check("FrameValid pulsed once", frames == 1);
        check("Failsafe low after a good frame", Failsafe === 0);

        // bad checksum: outputs must not change
        tx_ch[3] = 1999;
        send_frame(1, 4_200_000);
        tx_ch[3] = 1234;
        check_channels("bad checksum frame ignored");
        check("no FrameValid for bad checksum", frames == 1);

        // a frame that gets cut off, then the next good frame
        send_byte(8'h20); send_byte(8'h40); send_byte(8'hDC); send_byte(8'h05);
        #2_000_000;
        tx_ch[3] = 1777;
        send_frame(0, 4_200_000);
        check_channels("resyncs after a partial frame");

        // noise glitch on the idle line
        RX = 0; #500; RX = 1; #100_000;
        tx_ch[2] = 1555;
        send_frame(0, 4_200_000);
        check_channels("ignores a 0.5us glitch");

        // receiver clock off by +/-2%
        bit_ns = NOMINAL_BIT_NS * 1.02;
        tx_ch[1] = 1111;
        send_frame(0, 4_200_000);
        check_channels("baud rate 2% slow");
        bit_ns = NOMINAL_BIT_NS * 0.98;
        tx_ch[1] = 1888;
        send_frame(0, 4_200_000);
        check_channels("baud rate 2% fast");
        bit_ns = NOMINAL_BIT_NS;

        // two frames back to back with no idle gap
        tx_ch[4] = 1001;
        send_frame(0, 0);
        tx_ch[4] = 1999;
        send_frame(0, 4_200_000);
        check_channels("back-to-back frames");
        check("FrameValid count", frames == 7);
        check("Failsafe stayed low while frames arrive", Failsafe === 0);

        // radio link lost: frames stop
        #25_000_000;
        check("Failsafe high after 20ms with no frames", Failsafe === 1);

        // link comes back
        tx_ch[6] = 1400;
        send_frame(0, 1_000_000);
        check_channels("decodes again after failsafe");
        check("Failsafe clears on the next good frame", Failsafe === 0);

        if (errors == 0) $display("ALL TESTS PASSED");
        else $display("%0d CHECK(S) FAILED", errors);
        $finish;
    end
endmodule
