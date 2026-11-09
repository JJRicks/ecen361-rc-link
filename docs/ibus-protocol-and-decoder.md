# i-BUS protocol and how the decoder works

Reference material. You don't need it to follow the setup guides. It's useful when debugging, extending the decoder, or writing the project's Interface Requirements section.

---

## Part 1: The i-BUS servo frame

**Line format:** UART, **115200 baud, 8 data bits, no parity, 1 stop bit (8N1)**, idle high, LSB first. On the FS-iA6B, the high level is about 3.3 V.

**Frame:** 32 bytes, sent about every **7 ms**. The frame itself takes 32 × 10 bits ÷ 115200 = **2.78 ms**, so there's about 4 ms of idle line between frames.

| Byte | Content |
|---|---|
| 0 | `0x20`, frame length (32) |
| 1 | `0x40`, command: servo/channel data |
| 2, 3 | CH1 low byte, CH1 high byte |
| 4, 5 | CH2 low, high |
| … | … |
| 28, 29 | CH14 low, high |
| 30, 31 | Checksum low, high |

**Channels:**
- **Format:** 16-bit **little-endian** (low byte first), the pulse width in µs. Typically 1000 (stick at one end), 1500 (center) and 2000 (other end).
- **Bits used:** only the low 12 bits matter. Some FlySky receivers reuse the top 4 bits of each channel's high byte for extra channels 15–18; the decoder ignores them.

**Checksum:**
- **Formula:** `checksum = 0xFFFF − (byte0 + byte1 + … + byte29)`, computed in 16 bits and sent little-endian.
- **Checking it:** a receiver can either recompute it, or add all 30 bytes plus the checksum and expect `0xFFFF`.

**Worked example:** CH1 = 1000, CH3 = 1000, every other channel = 1500.

```
20 40 | E8 03 | DC 05 | E8 03 | DC 05 DC 05 DC 05 DC 05 DC 05 DC 05 DC 05 DC 05 DC 05 DC 05 DC 05 | 3D F3
hdr     CH1     CH2     CH3     CH4 … CH14                                                          chk
1000 = 0x03E8 → E8 03     1500 = 0x05DC → DC 05
sum of bytes 0..29 = 0x0CC2 → checksum = 0xFFFF − 0x0CC2 = 0xF33D → 3D F3
```

That's exactly what you'd see on a logic analyzer with a UART decoder at 115200 8N1.

**Other frame types:** the **SENS** port carries a different, two-way telemetry protocol, using other command bytes. The decoder only accepts frames starting `0x20 0x40`, so anything else is ignored.

---

## Part 2: The decoder (`hdl/IBUS_RX.sv` + `hdl/IBUS_UART_RX.sv`)

```
              ┌─────────── IBUS_RX ────────────────────────────────────────────┐
  RX pin ──►  │  IBUS_UART_RX ──rData/rValid──►  byte index (idx 0..31)         │
              │  (2-flop sync,               running sum of bytes 0..29         │
              │   mid-bit sample,            shadow[1..14] ◄─ channel bytes     │──► Ch[1..14]
              │   stop-bit check)            on byte 31: checksum OK?           │──► FrameValid
              │                                 yes → Ch <= shadow              │
              │  gap timer: 1 ms idle → idx = 0 (resync)                        │
              │  silence timer: 100 ms without a good frame → Failsafe          │──► Failsafe
              └─────────────────────────────────────────────────────────────────┘
```

### `IBUS_UART_RX`
- **Single clock.** Everything runs on `clk`, with no derived clocks, so Vivado can time it properly.
- **2-flop synchronizer.** The RX pin is asynchronous to the FPGA clock, so it passes through two flip-flops (`rx_meta` → `rx_s`) before anything looks at it. This guards against metastability.
- **Start-bit detection with glitch rejection.**
  - A low level starts a byte, and the timer then waits half a bit to land in the middle of the start bit.
  - If the line is high again at that point, it was a glitch and the byte is abandoned. The testbench checks a 0.5 µs glitch.
- **Mid-bit sampling.** Each data bit is sampled once, one full bit-time after the previous sample.
  - The bit time is `round(CLK_HZ / BAUD)` clocks: **104** at 12 MHz (0.16% error) and 174 at 20 MHz (−0.22%).
- **Stop-bit check.** A byte is only delivered (`rValid` pulse) if the stop bit is high. That rejects some framing errors.
- **Baud tolerance:** the testbench checks ±2%. 8N1 with mid-bit sampling tolerates roughly ±4–5% in theory.

### Why not the team's `UART_RX`?

The team has its own `UART_RX` for the 20 MHz design, with a handshake and majority-vote sampling. `IBUS_RX` uses a separate receiver because i-BUS sends 32 bytes in a row:
- The team's module counts 175 clocks per bit, while an i-BUS bit at 20 MHz is about 173.6 clocks.
- It waits for the end of the stop bit before looking for the next byte, so that difference adds up from byte to byte when there's no gap.

A simulated i-BUS frame fed into it, with `rReady` held high, gave:

| Idle gap between bytes | Bytes correct |
|---|---|
| 0 bits | 5 of 32 |
| 0.05 bit | 7 of 32 |
| 0.10 bit | 31 of 32 |
| 0.15 bit or more | 32 of 32 |

We haven't measured the gap the iA6B really leaves, so the decoder uses `IBUS_UART_RX`, which handles no gap at all. The names differ, so both can be in the same project.

### `IBUS_RX`
- **Byte index `idx`** counts 0–31 through the frame:
  - byte 0 must be `0x20` and byte 1 must be `0x40`, otherwise `idx` goes back to 0
  - even bytes 2–28 are saved as the channel low byte
  - odd bytes 3–29 combine with the saved low byte into `shadow[n]`
  - byte 30 is the checksum low byte
  - byte 31 is the checksum high byte, which triggers the check
- **Shadow registers.**
  - Channels are assembled in `shadow` and copied to `Ch` **all at once**, and only if the checksum matches.
  - Downstream logic never sees a half-updated frame, and a corrupted frame changes nothing.
- **Resync on idle.**
  - If the line is idle for **1 ms** (`GAP_CLKS`), `idx` resets to 0. Bytes inside a frame are about 87 µs apart, while the gap between frames is about 4 ms, so this reliably finds frame starts.
  - The header check also helps resync, and the checksum catches anything that slips through.
  - Back-to-back frames with no gap still decode, because `idx` wraps from 31 to 0 on its own.
- **Failsafe.**
  - A counter (`silence`) counts clocks since the last good frame, and stops counting once it reaches `TIMEOUT_CLKS`.
  - `Failsafe` is simply `silence == TIMEOUT_CLKS`.
  - It starts at `TIMEOUT_CLKS`, so **`Failsafe` is high at power-up** until the first good frame.
- **Ports:**

```systemverilog
module IBUS_RX #(
    parameter int CLK_HZ = 20_000_000,    // must match clk
    parameter int TIMEOUT_MS = 100        // no good frame for this long → Failsafe
)(
    input  clk,
    input  RX,                            // i-BUS line (async, idle high)
    output logic [14:1][11:0] Ch,         // Ch[n] = FlySky channel n, µs
    output logic FrameValid,              // 1 clk pulse when Ch updates
    output logic Failsafe                 // 1 = don't trust Ch
);
```

**Size:** about 14 × 12 × 2 flip-flops for `shadow` and `Ch`, plus small counters. Synthesis removes the channels a design never reads.

---

## Part 3: Text for the project definition's "Interface Requirements"

> **RC receiver → FPGA.** The FS-iA6B receiver's SERVO port connects to Cmod A7 pin G19 (Pmod JA2), LVCMOS33.
> - **Signal:** FlySky i-BUS, UART 115200 8N1, idle high, 3.3 V.
> - **Frame:** 32 bytes every ~7 ms: header `0x20 0x40`, then 14 channels as 16-bit little-endian µs values (1000–2000), then a 16-bit checksum = 0xFFFF − sum of bytes 0–29.
> - **Decoding:** the FPGA updates channel values only on frames with a valid checksum.
> - **Link loss:** if no valid frame arrives for 100 ms, the FPGA declares failsafe. In failsafe it commands throttle to 1000 µs (motor off), disarms, and centers the control surfaces.
> - **Power:** the receiver runs from the plane's 5 V rail (4.0–8.4 V allowed).

## Sources

- [i-BUS frame format (Parallax forum)](https://forums.parallax.com/discussion/comment/1523583/)
- [Betaflight i-BUS wiki](https://betaflight.com/docs/wiki/guides/current/IBus-telemetry)
- [FS-iA6B signal measured at ~3 V](https://mcspider.codeberg.page/arduino-rc-receiver-ibus-communication.html)
- [FS-iA6B manual](https://originhobbies.com/wp-content/uploads/2025/11/FS-iA6B-User-manual-20240327.pdf)
