# 7. Preflight and range check

**Goal:** the radio link holds up in the finished plane, and the team is legal to fly.

---

## Part A: Antenna placement (do this while building)

The FS-iA6B has **two antennas**. Each is a thin coax lead, and only the last ~26 mm (the bare tip) actually receives. The receiver uses whichever antenna hears better.

1. **Point the two tips at 90° to each other.** For example, one vertical and one horizontal, or both at 45° in a "V". That way, at least one antenna is well-oriented whatever way the plane is banked.
2. **Keep the tips away from carbon.** The carbon rods in the wing and fuselage block 2.4 GHz.
   - Keep the tips as far from the rods as you can, a few centimeters at least.
   - If the rods surround the receiver bay, route the tips out through the side of the fuselage.
3. **Keep the tips away from metal and noise:** the motor, ESC, flight battery and wiring bundles.
4. **Don't cut, kink or sharply bend the coax,** and don't run it alongside power wires.
5. **Fix the antennas in place** with tape, a straw or tube, or printed guides, so they can't flop into the prop or move between flights.

## Part B: Range check (first flight, and after any change to antennas or electronics)

This is the ground walk test from the FS-i6X manual (section 4.3), done with the motor running so ESC and motor noise are included.

**You need:** two people, an open field, propeller **on**, and the plane **held firmly** or tied down by the helper.

1. Fly-ready setup: flight design flashed, flight battery in, antennas fixed in their final positions.
2. The plane sits at ground level with the helper holding it. The pilot stands next to it with the transmitter.
3. Arm, and run the motor at low to medium throttle.
4. The pilot walks away while continuously moving the aileron and elevator sticks. The helper calls out whether the surfaces follow smoothly.
5. Keep walking to at least **100 m**.
   - Ground range is much shorter than air range. The receiver is rated "more than 300 m" on the ground.
   - If surfaces stutter, lag or stop **before 100 m**, **don't fly.** Fix the antennas (Part A) and test again.
6. Repeat with the plane turned 90° and then 180°, so the fuselage is between the antennas and the transmitter.
7. **Optional:** if the transmitter can show receiver telemetry (**System → RX setup → Choose sensors**), put signal or error readings on the home screen and watch them during the walk.

## Part C: Rules (the plane is over 250 g)

These are the FAA rules for recreational flying as of 2026. **Check [faa.gov/uas](https://www.faa.gov/uas) for current rules,** and **ask the instructor whether the class flies under the recreational rules or under Part 107.**

- [ ] **Register** the plane on [FAADroneZone](https://faadronezone-access.faa.gov/). Recreational registration costs $5 and lasts 3 years. Put the registration number on the **outside** of the plane.
- [ ] **TRUST certificate:** every pilot takes the free online Recreational UAS Safety Test and carries the certificate when flying.
- [ ] **Remote ID:** fit a broadcast module, **or** fly only at an FAA-Recognized Identification Area (**FRIA**). Many AMA club fields are FRIAs.
- [ ] **Airspace:** check the location in the **B4UFLY** app. Controlled airspace needs LAANC authorization; stay at or below **400 ft** above ground.
- [ ] **Line of sight:** the pilot, or a visual observer standing with them, can see the plane at all times.

## Part D: Field checklist (print this)

**Before powering up**
- [ ] Transmitter has fresh batteries (the low-voltage warning starts below 4.2 V)
- [ ] Correct **model name** on the transmitter home screen
- [ ] The Cmod is running the **flight design**, not the bench test
- [ ] Antennas fixed and pointing correctly; prop tight; battery secured; center of gravity checked
- [ ] Flight battery charged

**Power-up (in this order)**
- [ ] Throttle down, **SwA up (disarmed)**, all switches up
- [ ] Transmitter **on**
- [ ] Flight battery **in**; the ESC startup tones finish; the receiver LED is **solid**

**Control checks (disarmed)**
- [ ] Right stick **right:** right aileron goes **up**, left aileron goes **down**
- [ ] Right stick **back (toward you):** elevator goes **up**
- [ ] Surfaces center when the stick is released; no binding at full travel

**Safety checks (prop on, helper holding the plane)**
- [ ] Arm (SwA down) with throttle low; a little throttle → motor responds
- [ ] **Failsafe:** motor at low throttle, **transmitter off** → motor stops and surfaces go to their failsafe position. Transmitter back on; the motor stays off until throttle is lowered.
- [ ] Range check done (Part B) if this is the first flight or anything changed

**Flight**
- [ ] Arm only at the takeoff spot; disarm right after landing

**Shutdown (in this order)**
- [ ] Disarm (SwA up)
- [ ] Unplug the flight battery
- [ ] Transmitter **off** last. The FS-i6X manual says always remove receiver power before turning off the transmitter.
