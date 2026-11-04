# Team snapshot: PWM.sv

`PWM.sv` is a **copy** of the team's servo PWM module, taken on 2026-11-04 from
`ECEN 361 Fixed Wing Airplane/Servo PWM/PWM.srcs/sources_1/new/PWM.sv`.

It's here only so the bench test and the end-to-end testbench build on their
own. **It may be out of date.** If the team's copy has changed, use theirs.

What this repo relies on:

```systemverilog
module PWM(
    input clk_12MHz,
    input [17:0] Durration,   // pulse width in 12 MHz clocks (12 per us), so 1500us = 18000
    output pulse              // 20 ms period
);
```

If the team renamed the ports or changed the units, the lines to update are
the `PWM P1 (...)` line in `hdl/IBUS_TEST_TOP.sv` and the `PWM ESC (...)`
line in `examples/RC_ARMING_EXAMPLE.sv`. The testbenches also pre-set the
counter, because it has no initial value: see `DUT.P1.count` in
`sim/IBUS_TEST_TOP_tb.sv` and `DUT.ESC.count` in
`examples/RC_ARMING_EXAMPLE_tb.sv`.

The file also contains the older `BUTTONS` top module. It isn't used here,
which is why the Vivado steps set `IBUS_TEST_TOP` as top by hand.
