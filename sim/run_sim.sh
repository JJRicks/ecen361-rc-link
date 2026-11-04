#!/usr/bin/env bash
# Runs all three testbenches with Icarus Verilog (iverilog 12 or newer).
#   macOS:  brew install icarus-verilog
#   Ubuntu: sudo apt install iverilog
# Usage, from anywhere:  ./sim/run_sim.sh
# Exit code is 0 only if every check in every testbench passes.

set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build

run() {   # run <name> <files...>
    local name=$1; shift
    echo "=== $name ==="
    iverilog -g2012 -o "build/$name" "$@"
    vvp -n "build/$name" | tee "build/$name.log"
    grep -q "ALL TESTS PASSED" "build/$name.log"
}

run IBUS_RX_tb       hdl/UART_RX.sv hdl/IBUS_RX.sv sim/IBUS_RX_tb.sv
run IBUS_TEST_TOP_tb hdl/UART_RX.sv hdl/IBUS_RX.sv hdl/IBUS_TEST_TOP.sv team-snapshot/PWM.sv sim/IBUS_TEST_TOP_tb.sv
run RC_ARMING_EXAMPLE_tb hdl/UART_RX.sv hdl/IBUS_RX.sv team-snapshot/PWM.sv examples/RC_ARMING_EXAMPLE.sv examples/RC_ARMING_EXAMPLE_tb.sv

echo
echo "All testbenches passed."
