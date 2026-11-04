# 5. Vivado bench test

**Goal:** prove the real radio talks to the real FPGA.
**Time:** about 45 minutes the first time; most of it is waiting for Vivado.

**You need:**
- Vivado (the team uses 2025.2)
- the Cmod A7 wired as in [guide 3](03-wiring.md)
- the radio set up as in [guide 2](02-radio-setup.md)
- a hobby PWM servo

## Part A: What the bench test does

`hdl/IBUS_TEST_TOP.sv` is a tiny top level:

| Output | Behavior |
|---|---|
| Servo on **G17** (JA1) | Follows **CH1** (aileron stick). With no link it sits at center (1500 µs). |
| **LED0** (A17) | **On** = good i-BUS frames arriving. **Off** = failsafe (no good frame for 100 ms). |
| **LED1** (C16) | **On** when **CH5** (SwA) is above 1500 |

> The test top centers the servo in failsafe, which is right for a control surface. **It is not right for throttle.** See [guide 6](06-integration.md).

---

## Part B: Create the Vivado project

### Option 1: script (fast; not yet tried on a real Vivado install)
1. Open Vivado.
2. **Tools → Run Tcl Script…** → choose `vivado/create_project.tcl` from this repo.
3. The project opens. Skip to Part C.

If the script errors, use Option 2. It does the same thing by hand.

### Option 2: by hand
1. **File → Project → New…** → Next.
2. **Project name:** `ibus_test`. Location: anywhere outside the repo, or `vivado/` inside it (git ignores that). Next.
3. **RTL Project.** Tick **"Do not specify sources at this time."** Next.
4. **Default Part:** in the Search box type `xc7a35tcpg236-1` and select it. Next → Finish.
5. **Design sources:**
   1. **Flow Navigator → Add Sources → Add or create design sources** → Next → **Add Files**.
   2. Select from the repo: `hdl/UART_RX.sv`, `hdl/IBUS_RX.sv`, `hdl/IBUS_TEST_TOP.sv`, `team-snapshot/PWM.sv`.
   3. **Untick "Copy sources into project"** so Vivado uses the repo files directly and your edits show up in git. Finish.
6. **Constraints:** **Add Sources → Add or create constraints** → Add Files → `constraints/IBUS_TEST.xdc`. Untick copy. Finish.
7. **Simulation sources:** **Add Sources → Add or create simulation sources** → Add Files → `sim/IBUS_RX_tb.sv` and `sim/IBUS_TEST_TOP_tb.sv`. Untick copy. Finish.
8. **Set the design top:** in the **Sources** window under **Design Sources**, right-click **IBUS_TEST_TOP** → **Set as Top**. It turns bold.
   - `PWM.sv` also contains the team's old `BUTTONS` module, so Vivado may have guessed the wrong top.
9. **Set the sim top:** under **Simulation Sources → sim_1**, right-click **IBUS_RX_tb** → **Set as Top**.
10. **Sim run time:** **Settings** (Flow Navigator, top) → **Simulation** → **Simulation** tab → set `xsim.simulate.runtime` to `all` → OK.
11. **Turn on the .bin file**, which the flash step needs:
    1. Flow Navigator → **Program and Debug** → **Bitstream Settings**.
    2. Tick **-bin_file** → OK.

## Part C: Simulate in Vivado (optional, recommended once)

Flow Navigator → **Run Simulation → Run Behavioral Simulation**. The Tcl Console should end with `ALL TESTS PASSED`. Details are in [guide 4, Option B](04-simulation.md#option-b-vivados-simulator-xsim).

## Part D: Build the bitstream

1. Flow Navigator → **Generate Bitstream**.
   - If asked to run synthesis and implementation first, click **Yes / OK**.
2. Wait. The status is in the top right.
3. When it finishes, choose **Open Implemented Design** (or **View Reports**) and check:
   - **Messages tab:** **0 errors** and ideally **0 critical warnings**. Ordinary warnings are normal.
   - **Timing:** **Report Timing Summary**, or look in the Project Summary. **WNS should be positive**; the design runs at only 12 MHz, so it should have lots of slack.
   - **Utilization:** tiny, well under 2% of the chip. Vivado also trims the channels the test top never reads.
4. **Update the README status table:** "Vivado synthesis and implementation ✅".

Hit an error? See [troubleshooting](troubleshooting.md#vivado).

## Part E: Load it onto the FPGA (temporary)

This loads the design over JTAG. It is gone at the next power cycle, which is perfect for testing.

1. Plug the Cmod into USB.
   - **The flight battery must not be connected.**
2. Flow Navigator → **Open Hardware Manager** → **Open Target → Auto Connect**.
3. **Program Device** → **xc7a35t_0**.
   - The bitstream path should already point at `ibus_test.runs/impl_1/IBUS_TEST_TOP.bit`.
4. Click **Program**. The design starts right away.

## Part F: Bench checks

Work down the table. Tick each one off.

| # | Do this | Expect | If not |
|---|---|---|---|
| F1 | Transmitter **off**, receiver powered | LED0 **off**, servo at **center** | Servo not centered: check servo wiring on G17. LEDs odd: re-program. |
| F2 | Transmitter **on** (switches up, throttle down) | Receiver LED solid, then **LED0 on** within about a second | LED0 stays off: see [troubleshooting: LED0 never comes on](troubleshooting.md#led0-never-comes-on) |
| F3 | Move the **aileron stick** (right stick, left/right) slowly end to end | Servo follows smoothly, full travel each way, still at rest | Jitter or reset: give the servo its own 5 V supply |
| F4 | Flip **SwA** back and forth | **LED1** toggles | Recheck guide 2 Part D (CH5 = SwA) |
| F5 | **Failsafe test:** hold the aileron stick at **full right**, put **SwA down**, then switch the **transmitter off** while still holding the stick | See the three cases below | |
| F6 | Transmitter back **on** | LED0 on again; servo follows the stick again | |

**F5: what you might see.** Write down which case you get; it tells the team how this receiver behaves.

| Case | LED0 | Servo | LED1 | Meaning |
|---|---|---|---|---|
| **1** | **goes off** within ~0.1 s | goes to **center** | (ignore) | The receiver **stops sending** frames when the link drops. `IBUS_RX`'s 100 ms timeout caught it. ✅ Safe. |
| **2** | stays on | moves to the **CH1 failsafe position** (center, if set as in guide 2) | goes to the **SwA-up** state | The receiver **keeps sending**, but with the failsafe values you set. ✅ Safe, because throttle failsafe is low. |
| **3** | stays on | **stays at full right** | unchanged | **Failsafe is not set on the transmitter.** ❌ Go back to [guide 2 Part F](02-radio-setup.md#part-f-failsafe-dont-skip-this). **Do not fly like this.** |

**Also write down which SwA position lights LED1.** LED1 on means CH5 is above 1500. Guide 6 uses this for the arm switch; the docs assume SwA **down** = high = armed.

## Part G: Store it in flash (survives power-off)

Do this only if you want the bench test to boot by itself without Vivado. These steps follow the team's *Project Documentation*.

1. Make sure Part B step 11 (**-bin_file**) was done before the bitstream was built.
   - If not, tick it and run **Generate Bitstream** again.
2. **Hardware Manager:** connect as in Part E.
3. Right-click **xc7a35t_0** → **Add Configuration Memory Device…**
4. Search for `mx25l3273f` → select **mx25l3273f-spi-x1_x2_x4** → OK.
5. Vivado asks whether to program the memory now → **OK**.
   - Later, you can get here again with right-click the memory device → **Program Configuration Memory Device…**
6. **Configuration file:** browse to `ibus_test.runs/impl_1/IBUS_TEST_TOP.bin`. Leave **Erase**, **Program** and **Verify** ticked → **OK**.
7. When it finishes, **unplug USB and plug it back in.** The design should start on its own; LED0 behaves as in F1/F2.

> ⚠️ The Cmod now boots the **bench test** every time it powers up. Before any flight, flash the **real flight design**. The preflight checklist reminds you.

## Done when

- [ ] Bitstream builds with no errors and positive WNS
- [ ] F1–F6 pass
- [ ] F5 case (1 or 2) written down in the team docs
- [ ] SwA position that lights LED1 written down
- [ ] README status table updated

Next: [6. Putting it in the real design](06-integration.md)
