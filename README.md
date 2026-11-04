# ECEN 361 RC link: FlySky i-BUS to the Cmod A7

This repo holds everything for getting stick and switch positions from the handheld radio into the plane's FPGA:
- the decoder HDL and testbenches
- the bench test
- why we picked this radio
- step-by-step setup guides

```
 FS-i6X transmitter  ))) 2.4 GHz )))  FS-iA6B receiver  ── i-BUS, 1 wire ──>  Cmod A7-35T
 (in your hands)                      (in the plane)       115200 baud, 3.3 V   IBUS_RX.sv → Ch[1..14], Failsafe
```

The receiver sends every channel about every 7 ms as a 32-byte serial frame. `IBUS_RX.sv` checks each frame and turns it into `Ch[1]`…`Ch[14]`. The values are in microseconds, roughly 1000–2000 µs. It also raises a `Failsafe` flag when the radio link drops.

## Status

| Piece | State |
|---|---|
| Hardware | FS-i6X + FS-iA6B bought 2026-11-04 |
| `IBUS_RX` decoder | ✅ passes all 16 checks in simulation (Icarus Verilog 13) |
| Bench-test top, through the team's `PWM.sv` | ✅ passes all 5 end-to-end checks in simulation |
| Arming / throttle-failsafe example | ✅ passes all 10 checks in simulation |
| Vivado synthesis and implementation | ⬜ not done yet |
| Real radio and real FPGA | ⬜ not tested yet |
| `vivado/create_project.tcl` | ⬜ written but not run yet |

Update this table as you finish each step.

## Do these in order

| # | Guide | Needs hardware? | About |
|---|---|---|---|
| 1 | [Why this radio](docs/01-hardware-choice.md) | no | 5 min read, optional |
| 2 | [Radio setup](docs/02-radio-setup.md) | radio, receiver, 5 V source | 30 min |
| 3 | [Wiring and the voltage check](docs/03-wiring.md) | + multimeter, Cmod, breadboard | 20 min |
| 4 | [Simulation](docs/04-simulation.md) | no (do it any time) | 5 min |
| 5 | [Vivado bench test](docs/05-vivado-bench-test.md) | + a hobby PWM servo | 45 min |
| 6 | [Putting it in the real design](docs/06-integration.md) | + ESC and motor, **propeller off** | session |
| 7 | [Preflight and range check](docs/07-preflight.md) | the finished plane | before every first flight |

Reference material:
- [i-BUS protocol and how the decoder works](docs/ibus-protocol-and-decoder.md)
- [Troubleshooting](docs/troubleshooting.md)

## Quick start (for someone who has done this before)

```bash
./sim/run_sim.sh                                # needs iverilog; expect "All testbenches passed."
```
1. **Radio:** set Output mode → Serial = **i-BUS**. Set Aux channels CH5 = **SwA** and CH6 = **SwC**. Set failsafe for CH3 to throttle low and CH5 to disarmed.
2. **Wiring:** the iA6B **SERVO** port goes to the Cmod: S → **G19** (Pmod JA2), + → **VU** (DIP 24), − → **GND** (DIP 25).
3. **Vivado:** part `xc7a35tcpg236-1`. Sources are `hdl/*.sv` and `team-snapshot/PWM.sv`, constraints are `constraints/IBUS_TEST.xdc`, and the top is `IBUS_TEST_TOP`.
4. **Expected result:** LED0 = link up. LED1 = CH5 high. A servo on **G17** (JA1) follows the aileron stick.

## Repo map

```
hdl/
  UART_RX.sv            8N1 serial receiver, single clock, 2-flop synchronizer
  IBUS_RX.sv            i-BUS frame decoder → Ch[1..14], FrameValid, Failsafe
  IBUS_TEST_TOP.sv      bench test: CH1 → servo, LEDs show link / CH5
sim/
  IBUS_RX_tb.sv         16 self-checks on the decoder
  IBUS_TEST_TOP_tb.sv   5 end-to-end checks: i-BUS in → servo pulse + LEDs out
  run_sim.sh            runs all three testbenches with Icarus Verilog
examples/
  RC_ARMING_EXAMPLE.sv  how to use IBUS_RX in the flight top: arm switch, throttle failsafe
  RC_ARMING_EXAMPLE_tb.sv  10 self-checks on it
constraints/
  IBUS_TEST.xdc         Cmod A7 pins for the bench test
team-snapshot/
  PWM.sv                copy of the team's PWM module (may be stale, see its README)
vivado/
  create_project.tcl    one-command Vivado project (not yet run)
docs/                   the guides above
```

## Pins at a glance (Cmod A7-35T)

| Signal | FPGA pin | Where on the board |
|---|---|---|
| 12 MHz clock | L17 | on board |
| i-BUS in, from the iA6B SERVO port "S" | **G19** | Pmod JA pin 2 |
| Servo PWM out (bench test) | **G17** | Pmod JA pin 1 |
| LED0: link OK | A17 | green LED |
| LED1: CH5 > 1500 | C16 | green LED |
| Receiver power + | VU | DIP pin 24 (3.3–5.5 V) |
| Ground | GND | DIP pin 25, or Pmod pin 5 or 11 |

## Safety rules (read these even if you skip everything else)

1. **Measure before you connect.** Cmod pins are 3.3 V only, and 5 V on an I/O pin can kill the FPGA. See [guide 3](docs/03-wiring.md).
2. **Take the propeller off** for every bench test that has the ESC and motor connected.
3. **Throttle failsafe must be 1000 µs (motor off).** Never use 1500 µs; on an ESC that's half throttle.
4. **Set failsafe on the transmitter.** The factory default is "Off", which makes the receiver hold the last stick position forever if the link drops.
5. **Unplug the flight battery before plugging the Cmod into USB.** Both of them power the VU pin.
6. **The plane weighs more than 250 g.** It needs FAA registration and a TRUST certificate, plus Remote ID or flying at a FRIA. See [guide 7](docs/07-preflight.md).
