# Team snapshot

These are **copies** of the team's modules, taken on 2026-11-09 from
`ECEN 361 Fixed Wing Airplane 2/`:

| File | Where it came from | Used by |
|---|---|---|
| `PWM.sv` | `ESC PWM  test (incomplete)/PWM.srcs/sources_1/new/PWM.sv` | bench test, flight example |
| `UART_OUT_SCS0009.sv` | `Source Files/UART_OUT_SCS0009.sv` | flight example |
| `UART_TX.sv` | `Source Files/UART_TX.sv` | flight example, through `SCS009_Interpreter` |

They're here only so the tests build on their own. **They may be out of date.**
If the team's copy has changed, use theirs.

What this repo relies on:

```systemverilog
module PWM #(
    parameter int Pulse_Period = 19'h61A80    // 400,000 clocks = 20 ms at 20 MHz
)(
    input clk_20MHz,
    input [18:0] Durration,   // pulse width in clocks: 20 per us at 20 MHz, so 1500us = 30000
    output pulse
);

module SCS009_Interpreter #(
    parameter int ID1 = 1, ID2 = 2, ID3 = 3
)(
    input clk_20MHz,
    output TX,
    input [9:0] Pos1, Pos2, Pos3,
    input data_Valid,
    output logic Ready
);
```

`PWM` only counts clocks, so the bench test runs it from 12 MHz with
`Pulse_Period` set to 240,000, despite the port name.

If the team renames the ports or changes the units, the lines to update are
`PWM P1 (...)` in `hdl/IBUS_TEST_TOP.sv`, and `PWM ESC (...)` and
`SCS009_Interpreter SERVOS (...)` in `examples/RC_ARMING_EXAMPLE.sv`. The
testbenches also pre-set registers that have no initial value: see
`DUT.P1.count` in `sim/IBUS_TEST_TOP_tb.sv`, and `DUT.ESC.count` and
`DUT.SERVOS.U1.*` in `examples/RC_ARMING_EXAMPLE_tb.sv`.

`PWM.sv` also contains the `BUTTONS` top module. It isn't used here, which is
why the Vivado steps set `IBUS_TEST_TOP` as top by hand.
