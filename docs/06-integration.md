# 6. Putting it in the real design

**Goal:** move from the bench test to the flight top level, safely.
**Start here only after** the [bench test](05-vivado-bench-test.md) passes on real hardware.

> ⚠️ **Propeller OFF** for everything on this page until the preflight guide says otherwise.

---

## Step 1: Add the files

Add to the flight project:
- `hdl/IBUS_UART_RX.sv`
- `hdl/IBUS_RX.sv`

These can sit next to the team's own `UART_RX.sv`; the names don't clash. [Here's why the decoder has its own UART.](ibus-protocol-and-decoder.md#why-not-the-teams-uart_rx)

The flight design runs at **20 MHz**. A Clocking Wizard takes the Cmod's 12 MHz clock (pin L17) and outputs 20 MHz, as the team's ESC test block design does. That output is `clk_20MHz` below.

Then add one input pin to the flight XDC; it's the same pin as the bench test:

```tcl
set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports IBUS]    ; # Pmod JA pin 2
```

## Step 2: Instantiate the decoder

```systemverilog
logic [14:1][11:0] Ch;          // Ch[1]..Ch[14], microseconds (about 1000..2000)
logic FrameValid, Failsafe;

IBUS_RX #(.CLK_HZ(20_000_000)) RC (clk_20MHz, IBUS, Ch, FrameValid, Failsafe);
```

**What the outputs mean:**

| Signal | Meaning |
|---|---|
| `Ch[n]` | FlySky channel *n*, in µs. It only changes when a frame with a good checksum arrives (about every 7 ms), and it holds the last good value in between. |
| `FrameValid` | A 1-clock pulse each time `Ch` updates. Useful if you want to act once per frame. |
| `Failsafe` | **1** at power-up and whenever no good frame has arrived for 100 ms. **While it's 1, don't use `Ch`.** |

**Parameters:**
- **`CLK_HZ` must match the clock you feed it.** The baud timing and the 100 ms timeout are both computed from it. At 20 MHz the baud error is 0.2%, which is fine.
- **The team's `PWM` module counts 20 clocks per µs** on `clk_20MHz`, with a 20 ms period (`Pulse_Period` = 400,000).
- **`TIMEOUT_MS`** (default 100) sets how long without a good frame before `Failsafe` goes high. Leave it at 100 unless there's a reason; one missed frame is 7 ms.

**If the flight top uses a block design:** Vivado needs a block-design module to be Verilog or VHDL at its top level, so its wrapper has to be a `.v` file. `Ch` is a 2D port, which plain Verilog can't declare. Keep `Ch` inside a `.sv` module and have the wrapper instantiate that, the way `Test_Wrapper.v` calls `BUTTONS`. `RC_ARMING_EXAMPLE` from Step 3 only has plain ports, so it works as is:

```verilog
module Flight_Wrapper(input clk_20MHz, input IBUS, output ESC_PWM, output SERVO_TX);
    RC_ARMING_EXAMPLE U1 (clk_20MHz, IBUS, ESC_PWM, SERVO_TX);
endmodule
```

If the `.v` file itself needs a channel, connect a flat `wire [167:0]` to the port. `Ch[n]` is then bits `[12*n-1 : 12*(n-1)]`, so throttle `Ch[3]` is `[35:24]`.

## Step 3: The safety rules (non-negotiable)

1. **Throttle failsafe is 1000 µs (motor off).** The bench test centers its servo at 1500 µs in failsafe, which is right for a surface. **On an ESC, 1500 µs is half throttle.** For the team's `PWM` module, 1000 µs is `Durration = 19'd20_000`.
2. **Arm switch:** the motor only gets throttle while CH5 (SwA) says "armed."
3. **Throttle-low interlock:** arming only happens while the throttle stick is low. That way, flipping SwA with the stick up doesn't launch the motor.
4. **Clamp channels** to 1000–2000 µs before using them. Trims, subtrim or end points can push values outside that range.
5. **Control surfaces in failsafe:** centered (1500 µs) is the simple choice. Some people prefer a gentle turn so the plane circles down instead of flying away. Make it a team decision and write it down.

All five are in **`examples/RC_ARMING_EXAMPLE.sv`**, which is **simulated and passing** (17 checks in `examples/RC_ARMING_EXAMPLE_tb.sv`). Copy its body into the flight top:

```systemverilog
// keep a channel inside 1000..2000 us
function automatic logic [11:0] clamp_us(input logic [11:0] v);
    return (v < 12'd1000) ? 12'd1000 : (v > 12'd2000) ? 12'd2000 : v;
endfunction

// Arm switch with a throttle-low interlock:
//   disarms instantly on failsafe or when SwA (CH5) goes to "disarmed"
//   only arms while SwA is "armed" AND the throttle stick is low
logic armed = 0;
always_ff @(posedge clk_20MHz)
    if (Failsafe || Ch[5] < 12'd1700) armed <= 0;
    else if (Ch[3] < 12'd1100)        armed <= 1;

// Throttle to the ESC: 1000 us (motor off) unless armed. PWM counts 20 clocks per us.
logic [18:0] esc_width;
assign esc_width = armed ? clamp_us(Ch[3]) * 19'd20 : 19'd20_000;
PWM ESC (clk_20MHz, esc_width, ESC_PWM);

// Control surfaces: centered in failsafe
logic [11:0] aileron_us, elevator_us;
assign aileron_us  = Failsafe ? 12'd1500 : clamp_us(Ch[1]);
assign elevator_us = Failsafe ? 12'd1500 : clamp_us(Ch[2]);
```

**What the testbench checks:**
- no link → motor off and surfaces centered
- SwA armed with throttle up → stays disarmed
- throttle lowered → arms
- throttle passes through, clamped at 2000
- SwA off → motor off
- re-arming with throttle up is blocked
- link lost for 150 ms → motor off and surfaces centered
- link back with throttle up → stays disarmed
- the ESC pulse, measured on the pin: 1000 µs when disarmed or in failsafe, 1600 µs and 2000 µs when armed, every 20 ms
- the servo packets, read back off `SERVO_TX`: header, IDs, positions and checksum, including centered positions after the link is lost

**What the pilot needs to know:**
- **After any link dropout,** the motor stays off until the throttle stick is brought low again. That's deliberate.
- **In the air after a dropout:** pull throttle to idle, then advance.
- **SwA direction:** the example treats SwA **down** (CH5 ≈ 2000) as armed. Check that against what you recorded in bench test step F4. If it's the other way, flip the comparison.

**Answers to the questions in the comments of the team's `PWM.sv`:**
- **What data arrives?** `Ch[3]`, the throttle channel, in µs (about 1000–2000). Multiply by 20 to get `Durration`.
- **Does the ESC need a startup init module?** No. `armed` starts at 0, so `PWM` sends 1000 µs from its first period, which is the low-throttle signal an ESC waits for at power-up.

**`ESC_Controller` isn't in this path.** The team's documentation describes one with an 8-bit `Speed` input, but there's no source for it yet. This design drives `PWM` directly: `Ch[3] × 20` is already 20,000–40,000, which is `PWM`'s range, and 8 bits would coarsen the throttle to about 4 µs steps. If the team adds it later, keep the rule that disarmed or failsafe always means 1000 µs.

## Step 4: Scale channels to the actuators

- **ESC:** done above. µs × 20 = `PWM` clocks.
- **SCS0009 servos:** the example drives the team's `SCS009_Interpreter` directly.
  - **Range:** `to_pos` maps 1000–2000 µs to positions 387–637, with 512 at center. That's only a starting point. Pick the end positions on the real airframe so the surfaces don't hit their stops.
  - **Timing:** positions go out every 20 ms from a timer, not from `FrameValid`. Frames can stop when the link drops, and the centered failsafe position still has to reach the servos.
  - **Two ailerons:** the example sends both the same position. If one moves the wrong way, use `10'd1024 - pos` for that one.
  - **Pin:** `SERVO_TX` goes to the URT-2 board, on whatever pin the team's XDC uses for the servo bus.
- **Reversing a channel:** use `12'd3000 - value`. That maps 1000↔2000 and leaves 1500 alone. Reverse in the FPGA only, not also on the transmitter (see guide 2 Part C).
- **Mixing** (elevons, flaperons and so on), if ever needed, also goes in the FPGA.

## Step 5: First power-up with the ESC (propeller off)

**Before you start:** sort out the 5 V supply and measure it. See [guide 3, Step 4](03-wiring.md#step-4-in-plane-wiring-later-for-reference).

1. **Propeller off.** Plane on the bench.
2. Flash the flight design to the Cmod, then **unplug USB**.
3. Transmitter **on**: throttle down, **SwA up** (disarmed).
4. Plug in the flight battery. The receiver and Cmod power up from the 5 V rail, and the ESC plays its startup tones; that means it saw a valid 1000 µs signal.
   - If it beeps continuously or doesn't finish its tones, see [troubleshooting](troubleshooting.md#esc).
5. **Arm:** flip SwA down. Nothing should happen yet, because throttle is low.
6. Raise throttle slightly. The motor spins. Return to low.
7. **Disarm test:** with the motor spinning slowly, flip SwA up. The motor must stop immediately.
8. **Interlock test:**
   1. With SwA up, raise throttle to about half.
   2. Flip SwA down. The motor must **not** start.
   3. Lower throttle: it arms.
   4. Raise throttle a little: the motor spins.
9. **Failsafe test:** motor spinning slowly, **switch the transmitter off.** The motor must stop within about 0.1–1 s, depending on the case recorded in bench test F5.
10. Transmitter back on with the throttle still up: the motor must **stay off** until throttle is lowered.
11. Unplug the flight battery first, then switch the transmitter off.

**ESC throttle-range calibration:** some ESCs need to learn the 1000–2000 µs range once. The method is in the ESC's manual; usually it's "full throttle at power-up, then low."
- **The interlock blocks this on purpose.** You can't send full throttle at power-up through the flight design.
- **If you need it,** use a short-lived test build that drives the ESC straight from `Ch[3]`, with the **propeller off**. Then go back to the flight design.

## Done when

- [ ] 5 V supply chosen and measured
- [ ] Flight top builds with `IBUS_RX` and the arming logic
- [ ] Steps 5.1–5.11 all behave as described
- [ ] Each surface moves the right way (checked again in guide 7)

Next: [7. Preflight and range check](07-preflight.md)
