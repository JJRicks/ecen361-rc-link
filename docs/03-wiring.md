# 3. Wiring and the voltage check

**Goal:** connect the receiver's i-BUS output to the Cmod without damaging the FPGA.
**Time:** about 20 minutes.

**You need:**
- the receiver, already set up in [guide 2](02-radio-setup.md)
- the Cmod A7 on a breadboard
- a multimeter
- a 3-wire servo extension lead, or 3 female-to-male jumper wires
- for the bench test: one ordinary hobby PWM servo (an SG90 or similar). The team's SCS0009 servos won't work for this; they are serial servos and ignore PWM.

---

## Step 1: Find the three pins on the receiver's SERVO port

Every receiver port is a set of 3 pins: **S (signal)**, **+ (power)** and **− (ground)**.
- **Use the port labelled SERVO.** It's the i-BUS output. The one next to it, labelled **SENS**, is a sensor input.
- **Check the labels on the case** for which pin is which, then confirm with the multimeter's continuity (beep) mode:
  - All **−** pins on the receiver are connected to each other. Beep between SERVO's − and CH1's −.
  - All **+** pins are connected to each other.
  - The pin left over on SERVO is **S**.

Standard servo lead colors: **brown/black = −**, **red = +**, **orange/yellow/white = S**.

## Step 2: Measure the signal voltage (before it touches the FPGA)

The Cmod's I/O pins are **3.3 V maximum and not 5 V tolerant**. The iA6B is reported to output about 3 V, but check your unit.

1. Power the receiver from 5 V. The Cmod's VU pin on USB, as in guide 2 Part A, is fine.
2. Turn the transmitter on and wait for the receiver LED to go **solid**.
3. Set the multimeter to **DC volts**. Black probe on **−**, red probe on SERVO **S**.
4. Read the value:

| Reading | Meaning | Next |
|---|---|---|
| **2.8–3.4 V** | Normal. The line idles high and the meter averages the data bursts. | Go to Step 3 |
| **above 3.6 V** | Too high for the FPGA | **Don't connect directly.** Use the divider below |
| **about 0 V** | i-BUS isn't on, or wrong pin/port | Recheck guide 2 Part E (Serial = i-BUS) and Step 1 |

**If you have a scope or logic analyzer**, you should see:
- bursts about **2.8 ms** long, repeating every **~7 ms**
- **115200 baud**, idle high
- the first two bytes of each burst are `0x20 0x40`

**Divider, only if it reads above 3.6 V:**

```
SERVO S ──[ 1 kΩ ]──┬──── Cmod G19
                    │
                 [ 2 kΩ ]
                    │
                   GND
```

## Step 3: Bench wiring (Cmod powered from USB)

**Receiver SERVO port → Cmod:**

| Receiver SERVO pin | Goes to | Cmod A7 pin |
|---|---|---|
| **S** (signal) | **G19** | **Pmod JA, pin 2** |
| **+** | **VU** | **DIP pin 24** |
| **−** | **GND** | **DIP pin 25** (or Pmod JA pin 5 or 11) |

**Test servo → Cmod:**

| Servo wire | Goes to |
|---|---|
| Signal (orange/yellow/white) | **G17**, **Pmod JA pin 1** |
| + (red) | A **separate 5 V supply** is best. A micro servo off VU usually works for a quick test. |
| − (brown/black) | **GND**. If the servo has its own supply, tie that supply's ground to Cmod GND too. |

**Finding the pins:**
- **Pmod JA** is the 12-pin header at the end of the Cmod.
- **Pin 1** is marked on the silkscreen. Pins 1–6 are one row; 7–12 are the other.
- In each row, the first four pins are I/O, then **GND**, then **3.3 V**.
- The **DIP pins** are the breadboard legs, numbered 1–24 down one side and 25–48 back up the other. **VU (24)** and **GND (25)** face each other across the same end of the board. Check the board's silkscreen labels before wiring.

```
           FS-iA6B                                 Cmod A7-35T
       ┌──────────────┐                        ┌──────────────────┐
       │  SERVO  S ───┼────────────────────────┤ G19  (Pmod JA2)  │
       │         + ───┼────────────────────────┤ VU   (DIP 24)    │
       │         − ───┼──────────┬─────────────┤ GND  (DIP 25)    │
       └──────────────┘          │             │                  │
                                 │   servo ────┤ G17  (Pmod JA1)  │
                                 └── servo −   │                  │
                                               │   USB ── laptop  │
                                               └──────────────────┘
```

> ⚠️ **Never put the receiver's + on a Pmod 3.3 V pin** (Pmod pin 6 or 12). That pin is an *output*, and 3.3 V is below the receiver's 4.0 V minimum anyway.
> ⚠️ **Never put + (5 V) on any I/O pin.** Before powering up, check that only **S** goes to G19.

**USB current:** a USB port gives about 500 mA. The receiver takes little, but a micro servo can pull a few hundred mA when it moves fast. If the Cmod resets or the LEDs flicker when the servo moves, give the servo its own 5 V supply.

## Step 4: In-plane wiring (later; for reference)

In the plane there's no USB, so the receiver and the Cmod need 5 V from the flight battery. **Don't assume the ESC provides it.**

**First, check the ESC.** The team's documentation lists an "RCtimer Multicopter 40A esc". RCTimer's closest listing, the [Multicopter SimonK ESC 40A (OPTO)](https://rctimer.com/multicopter-simonk-speed-controller-esc-40a-opto-p0035.html), shows **BEC: N/A**, meaning no 5 V output. Confirm on the actual unit:

1. **Propeller off.** Nothing plugged into the ESC's thin signal lead.
2. Connect the flight battery.
3. Set the meter to **DC volts**. Black probe on the lead's black or brown wire, red probe on its red wire (if it has one).
4. Note the reading and unplug the battery.

| Reading | Meaning | What to do |
|---|---|---|
| **about 0 V, or no red wire** | No 5 V output | Use a separate 5 V regulator (a "UBEC"), wired as below. That's a purchase, so check with Justin. |
| **4.8–5.5 V** | The ESC has a BEC | It can feed the 5 V rail in place of the UBEC, if its current rating covers everything on the rail. |
| **above 5.5 V** | Too high for VU | Don't connect it to the Cmod. Use a UBEC. |

**Wiring with a UBEC:**

```
 Flight battery ──┬── ESC ──── motor (3 wires)
                  │
                  └── 5 V UBEC ──┬─ + ──┬─ receiver + (any port, e.g. B/VCC)
                                 │      └─ Cmod VU (DIP 24)
                                 └─ − ──┬─ receiver −
                                        ├─ Cmod GND (DIP 25)
                                        └─ ESC signal lead − (black/brown)

 ESC signal lead S ── Cmod PWM output pin (from the FPGA, not from the receiver)
 Receiver SERVO S ─── Cmod G19            (+ and − are already on the rail above)
```

- **The ESC takes its throttle signal from the FPGA,** not from receiver CH3, because the FPGA is the flight controller.
- **All the grounds must connect.** The ESC can't read the FPGA's signal without a shared ground, even when its lead carries no power.
- **One supply per rail.** If the ESC's lead does have 5 V and you use a UBEC anyway, leave the ESC's red wire unconnected.
- **Choosing a UBEC:** its input range must cover the flight battery, and its output must be 5 V. A 5 V, 3 A unit leaves plenty of margin for the receiver and Cmod. If the servos will share it, add their stall current from the datasheet.
- **Measure the 5 V rail before connecting the Cmod.** It must be within VU's 3.3–5.5 V range.
- **Unplug the flight battery before plugging in USB.** USB also drives VU, and two supplies fighting on one rail is how boards die.
- **The SCS0009 servos and their URT-2 board** have their own power and wiring; that isn't covered here.

## Done when

- [ ] Signal voltage measured and in range (or divider fitted)
- [ ] S → G19 (JA2), + → VU, − → GND
- [ ] Test servo on G17 (JA1) with a shared ground

Next: [4. Simulation](04-simulation.md), or jump to [5. Vivado bench test](05-vivado-bench-test.md) if you've already simulated.
