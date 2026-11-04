# 4. Simulation

**Goal:** prove the decoder works before touching hardware. No hardware needed; do this any time.

There are three testbenches. Both print `pass:` or `FAIL:` for each check, then `ALL TESTS PASSED` at the end.

| Testbench | Tests | Checks | Sim time |
|---|---|---|---|
| `sim/IBUS_RX_tb.sv` | `IBUS_RX` + `UART_RX` | 16 | ~85 ms |
| `sim/IBUS_TEST_TOP_tb.sv` | the whole bench-test top, including the team's `PWM.sv` | 5 | ~85 ms |
| `examples/RC_ARMING_EXAMPLE_tb.sv` | the arming and throttle-failsafe example from [guide 6](06-integration.md) | 10 | ~290 ms |

---

## Option A: Icarus Verilog (Mac or Linux, about 2 seconds)

1. Install Icarus Verilog, version 12 or newer:
   - Mac: `brew install icarus-verilog`
   - Ubuntu: `sudo apt install iverilog`
2. From the repo folder, run:
   ```bash
   ./sim/run_sim.sh
   ```
3. Expected output (last lines):
   ```
   === IBUS_TEST_TOP_tb ===
   pass: no link (failsafe): OUT pulse = 1500.0 us, led = x0
   pass: CH1=1250: OUT pulse = 1250.0 us, led = 11
   pass: led[1] on when CH5 > 1500
   pass: CH1=1800: OUT pulse = 1800.0 us, led = 01
   pass: led[1] off when CH5 < 1500
   ALL TESTS PASSED
   ...
   === RC_ARMING_EXAMPLE_tb ===
   ...
   ALL TESTS PASSED

   All testbenches passed.
   ```
   The script exits with code 0 only if every check passes. In the `no link` line above, `led = x0` is expected: before any frame arrives, CH5 has no value yet, so LED1 shows `x` in simulation. On real hardware it powers up as 0.

**Windows:** run the same script from **Git Bash** after installing Icarus for Windows. Or just use Option B.

## Option B: Vivado's simulator (xsim)

1. Create the project. Either:
   - run `vivado/create_project.tcl`, or
   - follow the GUI steps in [guide 5, Part B](05-vivado-bench-test.md#part-b-create-the-vivado-project).
2. In the **Sources** window, open **Simulation Sources → sim_1**. Check that **IBUS_RX_tb** is bold (bold means it's the top).
   - If it isn't, right-click it → **Set as Top**.
3. Check the run time: **Settings → Simulation → Simulation tab → `xsim.simulate.runtime`** should be **all**.
   - The Tcl script sets this. If you made the project by hand, type `all` in that field.
4. **Flow Navigator → Run Simulation → Run Behavioral Simulation.**
5. Wait. xsim takes noticeably longer than Icarus, roughly a minute.
6. In the **Tcl Console** at the bottom, look for **`ALL TESTS PASSED`**.
   - If the sim stopped at 1000 ns with no pass/fail lines, type `run all` in the Tcl Console and press Enter.
7. To run the end-to-end testbench:
   1. Close the simulation.
   2. Right-click **IBUS_TEST_TOP_tb** → **Set as Top**.
   3. Run it again.
8. The arming example's testbench isn't in the bench-test project. To run it in Vivado, add `examples/RC_ARMING_EXAMPLE.sv` and `examples/RC_ARMING_EXAMPLE_tb.sv` as simulation sources, then set the testbench as top.

**Waveforms:** Vivado opens a waveform window automatically. Useful signals to drag in from the Scope panel:
- under `DUT`: `RX`, `idx`, `sum`, `FrameValid`, `Failsafe`, `Ch`
- under `DUT/U1`: `rValid`, `rData`

## What the checks cover

`IBUS_RX_tb`, which runs `IBUS_RX` with a 20 ms timeout so the test is quick:

| Check | What it proves |
|---|---|
| Failsafe high at power up | Outputs aren't trusted before the first good frame |
| good frame decoded | All 14 channels come out right; byte order is correct |
| FrameValid pulsed once | Exactly one pulse per frame |
| Failsafe low after a good frame | The link-up path works |
| bad checksum frame ignored | A corrupted frame can't change any channel |
| no FrameValid for bad checksum | |
| resyncs after a partial frame | A frame cut off part-way doesn't knock the decoder out of step |
| ignores a 0.5 µs glitch | A noise spike on the line isn't read as a start bit |
| baud rate 2% slow / 2% fast | Tolerates a receiver clock that's off by ±2% |
| back-to-back frames | Works even with no idle gap between frames |
| FrameValid count | Running total = 7 good frames so far, so no extra or missed pulses |
| Failsafe stayed low while frames arrive | No false failsafe during normal operation |
| Failsafe high after 20 ms with no frames | Link loss is detected |
| decodes again after failsafe | Recovers when the link comes back |
| Failsafe clears on the next good frame | |

`IBUS_TEST_TOP_tb`:

| Check | What it proves |
|---|---|
| no link → 1500.0 µs, LED0 off | Servo centers and the link LED is off with no radio |
| CH1 = 1250 → 1250.0 µs, LED0 on | Channel value → PWM width scaling is exact |
| LED1 on when CH5 > 1500 | Switch LED works |
| CH1 = 1800 → 1800.0 µs | |
| LED1 off when CH5 < 1500 | |

**Do the testbenches actually catch bugs?** Yes, checked by planting bugs in scratch copies. Each planted bug made checks fail:
- swapped channel bytes
- skipped checksum check
- disabled gap resync
- wrong PWM scale factor

## If you change the HDL

Run `./sim/run_sim.sh` again before committing. If you add a feature, add a check for it to the testbench.

Next: [5. Vivado bench test](05-vivado-bench-test.md)
