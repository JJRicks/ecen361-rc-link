# 2. Radio setup (FS-i6X + FS-iA6B)

**Goal:** the receiver sends all the sticks and switches to the FPGA over i-BUS, unchanged by the transmitter, with a safe failsafe.
**Time:** about 30 minutes.

**You need:**
- the FS-i6X transmitter and 4 fresh AA batteries
- the FS-iA6B receiver
- the bind plug that came in the box (only needed if the pair isn't linked)
- a 4.0–8.4 V supply for the receiver; Part A below gives easy options

Menu steps come from the official FS-i6X manual (sections 4.2, 5.x, 7.x and 8.x). Linked in [guide 1](01-hardware-choice.md#sources).

---

## Buttons cheat sheet

The FS-i6X saves settings in an odd way. Learn this first:

| To do this | Press |
|---|---|
| Open the main menu | **Hold OK** for about a second |
| Choose between **System** and **Functions** on the main menu | **UP** / **DOWN**, then **OK** |
| Move through a list or change a value | **UP** / **DOWN** |
| Open an item, or move to the next field on a screen | **OK** (short press) |
| **Save** and go back | **Hold CANCEL** for about 1 s (higher-pitched beep) |
| Go back **without saving** | Short-press **CANCEL** (lower-pitched beep) |
| Reset the current item to its default | Hold **OK** for 3 s, then hold **CANCEL** to save |

If a setting "didn't stick," you almost certainly short-pressed CANCEL. Settings under **RX setup** are stored in the receiver, so the receiver must be powered and linked when you save them.

---

## Part A: Power up and check the link

1. Put 4 AA batteries in the transmitter.
2. Flip all four top switches (**SwA, SwB, SwC, SwD**) **up**, away from you.
3. Pull the **throttle** stick all the way down. In Mode 2 that's the left stick, the one that doesn't spring back to center.
4. Switch the transmitter **on**.
   - If you see a **Warning** screen, a switch isn't up or the throttle isn't down. Fix it and the warning clears.
5. Power the receiver. Any one of these works:
   - **Easiest, using the Cmod:** plug the Cmod into USB. Connect the receiver's **SERVO** port **−** pin to Cmod **GND** (DIP pin 25) and its **+** pin to Cmod **VU** (DIP pin 24). **Leave the S (signal) pin unconnected for now.** [Guide 3](03-wiring.md) has you measure it first.
   - A 4×AA battery box with a servo plug, into any receiver port.
   - A USB-to-servo-lead 5 V cable, into any receiver port.

   Power order: always transmitter on first, then receiver. When shutting down, receiver off first, then transmitter.
6. Look at the receiver's red LED:

   | LED | Meaning | Do this |
   |---|---|---|
   | **Solid** | Paired and linked | Go to Part B |
   | **Slow blink** | Not linked | Check that the transmitter is on, then do **Pairing** below |
   | **Fast blink** | In bind mode | The bind plug is in B/VCC; finish **Pairing** below |

### Pairing (only if the LED isn't solid)
The combo ships pre-paired, so you usually skip this.

1. Check the protocol first: **System → RX setup → RF std** must be **AFHDS 2A**, since the iA6B only speaks AFHDS 2A. If you change it, confirm "Yes" and hold CANCEL.
2. Turn the receiver **off**. Push the bind plug into the **B/VCC** port.
3. Power the receiver through a **different** port, such as the SERVO port wiring from Part A. The LED blinks fast.
4. On the transmitter, start binding:
   - Look for **RX bind** in the **System** menu; on some firmware versions it's inside **RX setup**. Select it.
   - If there's no RX bind item, follow the 2016 manual: switch the transmitter off, then hold the **BIND** key while switching it on.
5. Wait about 5 seconds for the transmitter to finish binding.
6. Receiver **off** → pull out the bind plug → receiver **on**. The LED should now be **solid**.

---

## Part B: Make a model for the plane

1. **System → Model select:** choose model **1**, or any unused slot, and hold CANCEL.
2. **System → Model name:** type something like `GO1WOLF` (UP/DOWN picks a letter, OK moves on). Hold CANCEL.
   - Later, this name on the home screen is how you know you're on the right model.
3. **System → Type select:** choose **Airplane** (it may show as Airplane/Glider). Hold CANCEL.
4. **System → Sticks mode:** check it says **Mode 2**, the usual US layout: throttle on the left, ailerons and elevator on the right.
   - **Mode 2 physically:** the left stick stays put when you let go vertically; the right stick springs back to center both ways.
   - **If the hardware is Mode 1:** the gimbals have to be swapped (manual section 4.4), or the pilot can just fly Mode 1 (choose Mode 1 here). Agree on this with whoever is flying.

---

## Part C: Turn off everything that changes the stick values

The FPGA is the flight controller, so it should see the raw sticks. If the transmitter also reverses, mixes or curves channels, nobody can tell where a weird value came from. **Do reversing and mixing in one place only: the FPGA.**

Open **Functions** (hold OK, then pick Functions) and check each item:

| Item | Set to | How to get there quickly |
|---|---|---|
| **Reverse** | All channels **Nor** | OK steps through channels; UP/DOWN toggles |
| **End points** | **100%** on both sides of every channel | Hold OK 3 s on each to reset |
| **Subtrim** | **0** on every channel | Hold OK 3 s on each to reset |
| **Dual rate/exp.** | Rate **100%**, Exp **0%** for CH1, CH2, CH4 | Hold OK 3 s to reset |
| **Throttle curve** | Default (straight line) | Hold OK 3 s to reset |
| **Mixes** | All 3 mixes **Off** | |
| **Elevon** | **Off** | |
| **V-tail** | **Off** | |
| **Throttle hold** | **Off** | |

Hold CANCEL after each one to save.

Then center the **trims**, the four little tabs beside the sticks. Click each one toward the middle; the beep changes when it reaches center.

With end points at 100% and trims centered, sticks span about **1000–2000 µs** and sit at about **1500 µs** when centered.

---

## Part D: Put switches on CH5 and CH6

Out of the box, CH5 and CH6 are the two knobs (VrA and VrB). We want switches there instead.

1. **System → Aux. switches:**
   - OK steps through SwA, SwB, SwC, SwD, VrA and VrB. Make sure **SwA** and **SwC** are **On** (UP/DOWN toggles).
   - Keep pressing OK until **Ch** is selected and check it's at least **6**.
   - Hold CANCEL to save.
2. **Functions → Aux. channels:**
   - **Channel 5** → UP/DOWN to **SwA**.
   - Press OK, then **Channel 6** → **SwC**.
   - Hold CANCEL.
3. **Check it:** open **Functions → Display**.
   - Flip **SwA**: the CH5 bar should jump end to end.
   - Flip **SwC**: the CH6 bar should have three positions.
   - Move each stick and watch its bar.
   - Short-press CANCEL to leave.

> ⚠️ **Don't hold OK** on the Display screen. That starts "scrub mode", which sweeps every channel through its full range, including throttle.

### Channel map (write it on tape on the back of the transmitter)

| Ch | Control (Mode 2) | Our use |
|---|---|---|
| 1 | Right stick, left/right | Ailerons |
| 2 | Right stick, up/down | Elevator |
| 3 | Left stick, up/down | Throttle |
| 4 | Left stick, left/right | Rudder (spare; no rudder servo in the current build) |
| 5 | **SwA** (2 positions) | **Arm switch:** up = disarmed |
| 6 | **SwC** (3 positions) | Flight mode / spare |
| 7–14 | not sent | i-BUS has slots for these, but they don't carry anything; ignore them |

---

## Part E: Make the receiver output i-BUS

The receiver must be **on and linked** (solid LED), because this setting is stored in the receiver.

1. **System → RX setup → Output mode**.
2. Two settings show:
   - **Output** (PWM / PPM): leave it on **PWM**. It only affects the CH1–CH6 servo ports.
   - **Serial** (i-BUS / S.BUS): set it to **i-BUS**.
3. Hold CANCEL.

i-BUS now comes out of the receiver's port labelled **SERVO**. The other i-BUS port, **SENS**, is for telemetry sensors; don't use it. The CH1–CH6 ports keep putting out normal servo pulses, which is handy for testing.

---

## Part F: Failsafe (don't skip this)

**Why:** failsafe is **Off** from the factory. Off means that if the link drops (transmitter off, out of range, dead batteries), the receiver **keeps sending the last stick positions forever**. That includes throttle.

**Goal:** on link loss, the receiver sends throttle low, the arm switch disarmed, and surfaces centered.

1. Set the controls to the safe position, and keep them there:
   - **throttle stick all the way down**
   - **SwA up** (disarmed)
   - right stick centered, rudder centered
2. Open **System → RX setup → Failsafe**.
3. **Channel 3 (throttle):**
   1. UP/DOWN to select Channel 3, then press OK.
   2. UP/DOWN to switch it **On**.
   3. Keep the throttle stick at the bottom and **hold CANCEL**.
   4. The channel now shows a **percentage** (about −100%) instead of Off.
4. **Channel 5 (arm switch):** same steps with **SwA up**.
5. **Channels 1, 2, 4:** same steps with the sticks centered. They should show about 0%.
6. Short-press CANCEL back out, then **re-open the Failsafe menu and check** that each channel shows a percentage. If any says **Off**, the CANCEL press was too short; redo it.

> **Shortcut:** the menu also has an **All channels** item. Put every control in the safe position, then select All channels to set them all at once. Still do step 6.

You'll **test** failsafe from the FPGA side in [guide 5, step F5](05-vivado-bench-test.md#part-f-bench-checks).

---

## Done when

- [ ] Receiver LED is solid with the transmitter on
- [ ] Model is named and type is Airplane
- [ ] Reverse, end points, subtrim, D/R, curves and mixes are all at defaults; trims centered
- [ ] CH5 = SwA, CH6 = SwC (checked on the Display screen)
- [ ] Output mode: Serial = i-BUS
- [ ] Failsafe shows percentages (not Off) on CH1–CH5

Next: [3. Wiring and the voltage check](03-wiring.md)
