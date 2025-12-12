#!/bin/bash
#
# build.sh - Compile all VHDL source files
#
# Usage: ./scripts/build.sh [--clean]
#
# Options:
#   --clean    Remove compiled files before building
#

set -e  # Exit on error

# Get project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "  Digital Lock - Build"
echo "=========================================="
echo ""

# Handle --clean flag
if [[ "$1" == "--clean" ]]; then
    echo "Cleaning previous build artifacts..."
    rm -rf work-obj08.cf *.o *.cf
    rm -f tb_digital_lock tb_top_level tb_fsm_coverage tb_edge_cases tb_debouncer
    echo "Clean complete."
    echo ""
fi

# Check for GHDL
if ! command -v ghdl &> /dev/null; then
    echo "Error: GHDL is not installed."
    echo "Run: ./scripts/install.sh"
    exit 1
fi

echo "GHDL version: $(ghdl --version | head -n1)"
echo ""

# Compile source files in dependency order
echo "Compiling source files..."
echo ""

echo "  [1/3] Analyzing digital_lock.vhd..."
ghdl -a --std=08 src/digital_lock.vhd

echo "  [2/3] Analyzing button_debouncer.vhd..."
ghdl -a --std=08 src/button_debouncer.vhd

echo "  [3/3] Analyzing top_level.vhd..."
ghdl -a --std=08 src/top_level.vhd

echo ""
echo "=========================================="
echo "  Build Successful!"
echo "=========================================="
echo ""
echo "Source files compiled. Next steps:"
echo "  ./scripts/test.sh      - Run all tests"
echo "  ./scripts/synth.sh     - Check synthesizability"
echo ""
