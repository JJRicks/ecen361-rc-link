# Troubleshooting

Find the symptom, then work through the causes in order. The most likely cause is first.

---

## Radio

### Transmitter shows a "Warning" screen at power-on
A switch isn't up, or the throttle isn't down. Flip **SwA–SwD up** and pull the **throttle stick down**.

### A setting doesn't stick
- **Short CANCEL instead of long:** a short press cancels. **Hold CANCEL** about 1 s to save; listen for the higher-pitched beep.
- **Receiver was off:** anything under **RX setup** (Output mode, Failsafe, RF std) is stored in the receiver. The receiver must be **on and linked** (solid LED) when you save.

### Receiver LED blinks slowly
It isn't linked. Work through these:
1. **Transmitter on?** Correct model selected?
2. **Protocol:** System → RX setup → **RF std** must be **AFHDS 2A**.
3. **Re-pair:** see [guide 2, Pairing](02-radio-setup.md#pairing-only-if-the-led-isnt-solid).

### Receiver LED blinks fast
The bind plug is still in B/VCC. Power off, remove it, power on.

### A knob moves CH5/CH6 instead of the switch
Aux. channels hasn't been changed yet. Follow [guide 2, Part D](02-radio-setup.md#part-d-put-switches-on-ch5-and-ch6). If SwA isn't offered as a source, enable it first in **System → Aux. switches**.

---

## Bench test

### LED0 never comes on
Work down the list:
1. **Bitstream loaded?** JTAG programming is lost at power-off; re-program (guide 5 Part E).
2. **Receiver linked?** Its LED must be solid.
3. **i-BUS enabled?** Check System → RX setup → Output mode → **Serial = i-BUS**.
4. **Right port?** It must be the **SERVO** port, not SENS and not CH1–CH6.
5. **Right pin?** The signal wire goes to **G19 = Pmod JA pin 2**. Count from the pin-1 mark on the silkscreen.
6. **Ground shared?** Receiver − must connect to Cmod GND.
7. **Signal present?** Measure S to − with a meter (about 3 V expected) or look with a scope. See [guide 3, Step 2](03-wiring.md#step-2-measure-the-signal-voltage-before-it-touches-the-fpga).
8. **Clock parameter:** if you changed the clock, `CLK_HZ` must match it.
9. **Pin names:** check the Vivado messages for `[DRC NSTD-1]` or `[DRC UCIO-1]`. Those mean a port isn't constrained; the XDC port names must match the top module (`clk_12MHz`, `IBUS`, `OUT`, `led[0]`, `led[1]`).

### LED0 flickers, or goes off now and then
Some frames are failing the checksum, or the line is noisy.
- **Wiring:** use short wires and a firm ground connection.
- **Routing:** keep the signal wire away from servo and motor power wires.
- **Divider:** if you fitted the resistor divider, check the values (1 kΩ series, 2 kΩ to ground).

### LED0 on but the servo doesn't move
- **Signal wire:** the servo signal goes to **G17 = Pmod JA pin 1**.
- **Servo power:** the servo needs 5 V on its red wire, and its ground must be shared with the Cmod.
- **Servo type:** the SCS0009s are serial servos and ignore PWM. Use an ordinary PWM servo.
- **PWM module:** if the team's `PWM` module interface changed, update the `PWM P1 (...)` line in `IBUS_TEST_TOP.sv`. See `team-snapshot/README.md`.

### Servo jitters, or the Cmod resets when the servo moves
The servo is pulling too much current from USB. Give it its own 5 V supply, and tie the grounds together.

### Servo moves the wrong way
That's fine for the bench test. In the flight design, reverse the channel in the FPGA with `12'd3000 - value`. Don't also reverse it on the transmitter.

### LED1 never changes when flipping SwA
CH5 is still on a knob. See "A knob moves CH5/CH6" above.

### Failsafe test (F5) gives case 3: servo stays where it was
Failsafe isn't set on the transmitter, or it didn't save. Redo [guide 2, Part F](02-radio-setup.md#part-f-failsafe-dont-skip-this) and re-open the menu to confirm it shows percentages.

---

## Vivado

### Wrong top module, or "BUTTONS" shows up
`team-snapshot/PWM.sv` also contains the team's old `BUTTONS` module. In Sources, right-click **IBUS_TEST_TOP** → **Set as Top** (or **IBUS_RX_tb** for simulation).

### `[DRC NSTD-1] Unspecified I/O Standard` or `[DRC UCIO-1] Unconstrained Logical Port`
A top-level port has no line in the XDC. Usually the XDC isn't added to the project, or a port name differs. Check the names match exactly.

### `[Place 30-574] Poor placement for routing between an IO pin and BUFG`
The clock isn't on the clock pin. `clk_12MHz` must be **L17**.

### Simulation stops at 1000 ns with no pass/fail output
Type `run all` in the Tcl Console. To make it permanent: Settings → Simulation → Simulation tab → `xsim.simulate.runtime` = `all`.

### Simulation shows X on the PWM output
`PWM.sv`'s counter has no initial value. The end-to-end testbench sets `DUT.P1.count = 0` for that reason. On real hardware it starts at 0, so this only matters in simulation.

### The create_project.tcl script fails
It hasn't been run on a real Vivado install yet. Use the GUI steps in [guide 5, Part B Option 2](05-vivado-bench-test.md#option-2-by-hand). Also tell whoever maintains this repo what the error said, so the script can be fixed.

### No .bin file after Generate Bitstream
Bitstream Settings → tick **-bin_file**, then Generate Bitstream again.

### Flash programs, but the design doesn't start after power-cycling
- **Wrong file:** you need the **.bin** (not the .bit), from `ibus_test.runs/impl_1/`.
- **Wrong part:** the memory part must be **mx25l3273f-spi-x1_x2_x4**.
- **Missing config lines:** `CONFIG_MODE SPIx4` and `BITSTREAM.GENERAL.COMPRESS TRUE` must be in the XDC; they're in `IBUS_TEST.xdc`.

---

## ESC

### ESC beeps continuously, or never finishes its startup tones
It isn't seeing a valid "throttle low" signal.
- **Signal:** check the ESC signal wire goes to the FPGA's PWM output pin, and the grounds are shared.
- **Pulse width:** check the flight design sends **1000 µs** when disarmed.
- **Throttle range:** some ESCs need throttle-range calibration first. See [guide 6, Step 5](06-integration.md#step-5-first-power-up-with-the-esc-propeller-off). **Propeller off.**

### Motor doesn't stop when the transmitter is turned off
**Stop and don't fly.**
- **Case 3:** check bench test F5 for a case 3 result; failsafe may not be set.
- **Wrong failsafe value:** check the flight design commands 1000 µs (not 1500) when `Failsafe` is high or when disarmed.

---

## Simulation (Icarus)

### `iverilog: command not found`
Install it: `brew install icarus-verilog` (Mac) or `sudo apt install iverilog` (Ubuntu).

### Syntax errors on `logic [14:1][11:0]` or `task automatic`
Your iverilog is too old. Install version 12 or newer; `iverilog -V` shows the version.
