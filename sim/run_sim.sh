#!/usr/bin/env bash
# Runs every testbench with Icarus Verilog (iverilog 12 or newer).
#   macOS:  brew install icarus-verilog
#   Ubuntu: sudo apt install iverilog
# Usage, from anywhere:  ./sim/run_sim.sh
# Exit code is 0 only if every check in every testbench passes.

set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build

run() {   # run <log name> <iverilog options and files...>
    local name=$1; shift
    echo "=== $name ==="
    iverilog -g2012 -o "build/$name" "$@"
    vvp -n "build/$name" | tee "build/$name.log"
    grep -q "ALL TESTS PASSED" "build/$name.log"
}

run IBUS_RX_tb_20MHz -s IBUS_RX_tb hdl/IBUS_UART_RX.sv hdl/IBUS_RX.sv sim/IBUS_RX_tb.sv
run IBUS_RX_tb_12MHz -s IBUS_RX_tb -PIBUS_RX_tb.CLK_HZ=12000000 hdl/IBUS_UART_RX.sv hdl/IBUS_RX.sv sim/IBUS_RX_tb.sv
run IBUS_TEST_TOP_tb hdl/IBUS_UART_RX.sv hdl/IBUS_RX.sv hdl/IBUS_TEST_TOP.sv team-snapshot/PWM.sv sim/IBUS_TEST_TOP_tb.sv
run RC_ARMING_EXAMPLE_tb hdl/IBUS_UART_RX.sv hdl/IBUS_RX.sv team-snapshot/PWM.sv team-snapshot/UART_TX.sv team-snapshot/UART_OUT_SCS0009.sv examples/RC_ARMING_EXAMPLE.sv examples/RC_ARMING_EXAMPLE_tb.sv

echo
echo "All testbenches passed."
