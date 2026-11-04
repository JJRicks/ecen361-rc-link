# 1. Why this radio

**Decision:** FlySky **FS-i6X** transmitter + **FS-iA6B** receiver, about $62 for the pair. Bought 2026-11-04.
**Runner-up:** RadioMaster **Pocket** (ExpressLRS) + **RP1 V2** receiver, about $105–110.

A note on words: in RC, the handheld unit is the **transmitter** or **radio**, and **flight controller** means the onboard brain. In this plane, the flight controller is the FPGA.

## What the choice had to satisfy

- **FPGA side:**
  - The Cmod A7-35T has 3.3 V I/O that is **not** 5 V tolerant.
  - It has a 12 MHz clock and plenty of spare pins.
  - The team already has a 115200-baud `UART_TX.sv`, so a receiver that outputs plain serial at that speed is the least new work.
- **Weight:** `Plane specs.docx` totals about 751 g before the motor and ESC. Eclipson designed the LW-PLA Gö 1 Wolf for about 600 g, so a light receiver helps.
- **Channels:** ailerons, elevator, throttle, plus 1–2 switches for FPGA modes. That's about 6 channels.
- **Range:** the plane is slow and flown line-of-sight (1.2 m span, stalls around 24–32 km/h), so long range isn't needed.

## The two candidates

| | **FlySky FS-i6X + FS-iA6B** (picked) | **RadioMaster Pocket ELRS + RP1 V2** |
|---|---|---|
| Cost | about $61–63 for the pair, plus 4×AA | $71.50 radio + $23–25 receiver + two 18650 cells ≈ $105–110 |
| Signal to the FPGA | i-BUS: 115200 baud serial, 1 wire | CRSF: 420000 baud serial, 1 wire (2 with telemetry) |
| Receiver | 14.9 g, 4.0–8.4 V | 2.2 g, 5 V |
| Range | rated "more than 300 m" on the ground | several km |
| Setup | comes paired, works out of the box | flash and pair it yourself over Wi-Fi |
| Telemetry to the radio | receiver voltage and signal | link quality with voice alerts; the FPGA can send its own data to the radio screen |
| Failsafe | must be set on the transmitter (default holds last position) | receiver stops sending, which is easy to detect |

### Why the FlySky won
- **Cheapest complete pair, and no setup:** the transmitter and receiver ship already paired.
- **Same speed as our UART code:** i-BUS runs at 115200 baud, the same as `UART_TX.sv`, and its checksum is a simple 16-bit sum.
- **Backup plan:** the receiver also puts out standard servo pulses on CH1–CH6. If the serial decoder ever gives trouble, measuring those pulses is the reverse of what `PWM.sv` already does.

### Why ELRS would be the upgrade
ExpressLRS (ELRS) is the current hobby standard. Over the FlySky it offers:
- a receiver about 13 g lighter
- far more range margin
- cleaner failsafe: the receiver just goes silent
- real two-way telemetry, which would make a good "ground comms" demo

**What changes if we ever switch:**
- **New decoder:** CRSF needs one. Its 16 channels are packed 11 bits each, and it uses a CRC-8 instead of a sum.
- **New baud rate:** 420000 by default, adjustable to 115200 in the receiver's web page.
- **Firmware versions:** ELRS 4.0 (Feb 2026) can't talk to 3.x, so flash the radio and the receiver to the same major version before pairing.

### Rejected
- **FS-A8S receiver:** only 1.2 g, but listings say it has no failsafe.
- **DIY ESP32 or nRF24 link:** the parts are cheaper, but we'd be building a safety-critical radio link from scratch in about 7 weeks.

## Things that shaped the rest of these docs

- **Signal level:** the iA6B's signal has been measured at about 3 V, so it can go straight to a Cmod pin set to LVCMOS33. [Guide 3](03-wiring.md) has you confirm this with a meter first.
- **Failsafe:** the FlySky's factory default is to hold the last position when the link drops. That's why [guide 2](02-radio-setup.md) sets failsafe on the transmitter, and the FPGA also has its own timeout.
- **Antennas:** the build puts carbon rods in the fuselage and wing, and carbon blocks 2.4 GHz. [Guide 7](07-preflight.md) covers antenna placement.
- **Power:** the Cmod's VU pin takes 3.3–5.5 V. Plugging in USB pushes 5 V back onto VU, so never connect USB and the ESC's 5 V at the same time.

## Sources

- **Receiver:** [FS-iA6B manual](https://originhobbies.com/wp-content/uploads/2025/11/FS-iA6B-User-manual-20240327.pdf) · [FS-iA6B signal measured at ~3 V](https://mcspider.codeberg.page/arduino-rc-receiver-ibus-communication.html)
- **Transmitter:** [FS-i6X user manual, 2016-08-17 edition](https://static1.squarespace.com/static/5bc852d6b9144934c40d499c/t/5d6f66305487dc0001e34939/1567581800555/FS-i6X+User+manual+20160817.pdf) · [NHBM FlySky programming guide](https://www.nhbm.org/wp-content/uploads/2025/08/FlySky-6-Programming.pdf) · [Walmart FS-i6X listing](https://www.walmart.com/c/kp/flysky-remote) · [RC Drone Top FS-i6X](https://rcdrone.top/bn/products/flysky-fs-i6x-transmitters)
- **i-BUS protocol:** [frame format (Parallax forum)](https://forums.parallax.com/discussion/comment/1523583/) · [Betaflight i-BUS wiki](https://betaflight.com/docs/wiki/guides/current/IBus-telemetry)
- **Rejected receiver:** [FS-A8S specs](https://www.getfpv.com/flysky-fs-a8s-fs-a8s-2-4g-8ch-mini-receiver-with-ppm-i-bus-sbus-output.html)
- **Runner-up hardware:** [RadioMaster Pocket](https://radiomasterrc.com/products/pocket-radio-controller-m2) · [RP1 V2 specs (GetFPV)](https://www.getfpv.com/radios/receivers/radiomaster-rp1-v2-expresslrs-2-4ghz-nano-receiver-w-65mm-ufl-t-antenna.html) · [RP1 V2 price (WREKD)](https://wrekd.com/products/radiomaster-rp1-elrs-2-4ghz-nano-receiver-w-ufl-antenna)
- **ELRS docs:** [Web UI](https://www.expresslrs.org/quick-start/webui/) · [user defines (baud)](https://www.expresslrs.org/software/user-defines/) · [serial protocols](https://www.expresslrs.org/software/serial-protocols/) · [ELRS 4.0 compatibility](https://oscarliang.com/expresslrs-4/)
- **Cmod A7 power:** [Mouser](https://www.mouser.it/digilent-a7-modules) · [VU warning (Digilent forum)](https://forum.digilent.com/topic/17336-cmod-a7-datasheet-warning/)
- **Airframe:** [Gö 1 Wolf specs](https://www.skyraccoon.com/aircraft/Eclipson-Airplanes_Go-1-WOLF_go1wolf)
