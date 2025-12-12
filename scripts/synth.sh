#!/bin/bash
#
# synth.sh - Check design synthesizability
#
# Usage: ./scripts/synth.sh
#
# This script verifies that the design can be synthesized for FPGA/ASIC.
# It uses GHDL's synthesis checking capability.
#

set -e  # Exit on error

# Get project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "  Digital Lock - Synthesis Check"
echo "=========================================="
echo ""

# Check for GHDL
if ! command -v ghdl &> /dev/null; then
    echo "Error: GHDL is not installed."
    echo "Run: ./scripts/install.sh"
    exit 1
fi

# Build sources first
echo "Analyzing source files..."
ghdl -a --std=08 src/digital_lock.vhd
ghdl -a --std=08 src/button_debouncer.vhd
ghdl -a --std=08 src/top_level.vhd
echo ""

# Check if GHDL supports synthesis
if ! ghdl --help | grep -q "synth"; then
    echo "Warning: This GHDL build may not support synthesis checking."
    echo "The design analysis passed, which is a good indicator of synthesizability."
    echo ""
    echo "For full synthesis, use vendor tools:"
    echo "  - Xilinx Vivado"
    echo "  - Intel Quartus"
    echo "  - Lattice Diamond"
    echo ""
    exit 0
fi

echo "Running synthesis check..."
echo ""

# Check each component
echo "Checking digital_lock..."
if ghdl --synth --std=08 digital_lock 2>&1; then
    echo "✓ digital_lock is synthesizable"
else
    echo "✗ digital_lock has synthesis issues"
    exit 1
fi
echo ""

echo "Checking button_debouncer..."
if ghdl --synth --std=08 button_debouncer 2>&1; then
    echo "✓ button_debouncer is synthesizable"
else
    echo "✗ button_debouncer has synthesis issues"
    exit 1
fi
echo ""

echo "Checking top_level..."
if ghdl --synth --std=08 top_level 2>&1; then
    echo "✓ top_level is synthesizable"
else
    echo "✗ top_level has synthesis issues"
    exit 1
fi
echo ""

echo "=========================================="
echo "  Synthesis Check Passed!"
echo "=========================================="
echo ""
echo "The design is synthesizable and ready for FPGA deployment."
echo ""
echo "Next steps for FPGA implementation:"
echo "  1. Open your vendor tool (Vivado, Quartus, etc.)"
echo "  2. Create a new project"
echo "  3. Add files from src/ directory"
echo "  4. Set 'top_level' as the top module"
echo "  5. Add pin constraints for your board"
echo "  6. Run synthesis, implementation, and generate bitstream"
echo ""
echo "See synthesis/README.md for constraint file examples."
echo ""
