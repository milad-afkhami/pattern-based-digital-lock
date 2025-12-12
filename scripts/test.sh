#!/bin/bash
#
# test.sh - Run all testbenches
#
# Usage: ./scripts/test.sh [testbench_name] [--no-wave]
#
# Options:
#   testbench_name   Run specific testbench (e.g., tb_digital_lock)
#   --no-wave        Skip waveform generation (faster)
#
# Examples:
#   ./scripts/test.sh                    # Run all tests with waveforms
#   ./scripts/test.sh --no-wave          # Run all tests without waveforms
#   ./scripts/test.sh tb_digital_lock    # Run only FSM unit test
#

set -e  # Exit on error

# Get project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Parse arguments
GENERATE_WAVE=true
SPECIFIC_TEST=""

for arg in "$@"; do
    case $arg in
        --no-wave)
            GENERATE_WAVE=false
            ;;
        tb_*)
            SPECIFIC_TEST="$arg"
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: ./scripts/test.sh [testbench_name] [--no-wave]"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "  Digital Lock - Test Suite"
echo "=========================================="
echo ""

# Check for GHDL
if ! command -v ghdl &> /dev/null; then
    echo "Error: GHDL is not installed."
    echo "Run: ./scripts/install.sh"
    exit 1
fi

# Ensure simulation directory exists
mkdir -p simulation

# Build sources first
echo "Building source files..."
ghdl -a --std=08 src/digital_lock.vhd
ghdl -a --std=08 src/button_debouncer.vhd
ghdl -a --std=08 src/top_level.vhd
echo ""

# Define testbenches
TESTBENCHES=(
    "tb_digital_lock:testbench/tb_digital_lock.vhd:FSM Unit Tests"
    "tb_top_level:testbench/tb_top_level.vhd:Full System Integration"
    "tb_fsm_coverage:testbench/tb_fsm_coverage.vhd:State Coverage"
    "tb_edge_cases:testbench/tb_edge_cases.vhd:Edge Cases"
    "tb_debouncer:testbench/tb_debouncer.vhd:Debouncer Unit Tests"
)

# Counters
TOTAL=0
PASSED=0
FAILED=0

# Run a single testbench
run_testbench() {
    local name="$1"
    local file="$2"
    local desc="$3"

    echo "----------------------------------------"
    echo "Running: $name ($desc)"
    echo "----------------------------------------"

    # Analyze testbench
    ghdl -a --std=08 "$file"

    # Elaborate
    ghdl -e --std=08 "$name"

    # Run simulation
    if [ "$GENERATE_WAVE" = true ]; then
        if ghdl -r --std=08 "$name" --wave="simulation/${name}.ghw" 2>&1; then
            echo ""
            echo "✓ $name PASSED"
            echo "  Waveform: simulation/${name}.ghw"
            ((PASSED++)) || true
        else
            echo ""
            echo "✗ $name FAILED"
            ((FAILED++)) || true
        fi
    else
        if ghdl -r --std=08 "$name" 2>&1; then
            echo ""
            echo "✓ $name PASSED"
            ((PASSED++)) || true
        else
            echo ""
            echo "✗ $name FAILED"
            ((FAILED++)) || true
        fi
    fi

    ((TOTAL++)) || true
    echo ""
}

# Run tests
if [ -n "$SPECIFIC_TEST" ]; then
    # Run specific test
    for tb in "${TESTBENCHES[@]}"; do
        IFS=':' read -r name file desc <<< "$tb"
        if [ "$name" == "$SPECIFIC_TEST" ]; then
            run_testbench "$name" "$file" "$desc"
            break
        fi
    done

    if [ "$TOTAL" -eq 0 ]; then
        echo "Error: Testbench '$SPECIFIC_TEST' not found."
        echo ""
        echo "Available testbenches:"
        for tb in "${TESTBENCHES[@]}"; do
            IFS=':' read -r name file desc <<< "$tb"
            echo "  - $name"
        done
        exit 1
    fi
else
    # Run all tests
    for tb in "${TESTBENCHES[@]}"; do
        IFS=':' read -r name file desc <<< "$tb"
        run_testbench "$name" "$file" "$desc"
    done
fi

# Summary
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo ""
echo "  Total:  $TOTAL"
echo "  Passed: $PASSED"
echo "  Failed: $FAILED"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo "✓ All tests passed!"
    echo ""
    if [ "$GENERATE_WAVE" = true ]; then
        echo "View waveforms with:"
        echo "  gtkwave simulation/tb_digital_lock.ghw"
    fi
    exit 0
else
    echo "✗ Some tests failed!"
    exit 1
fi
