#!/bin/bash
#
# clean.sh - Remove all generated files
#
# Usage: ./scripts/clean.sh [--all]
#
# Options:
#   --all    Also remove waveform files from simulation/
#

# Get project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "  Digital Lock - Clean"
echo "=========================================="
echo ""

# Remove GHDL work library and object files
echo "Removing build artifacts..."
rm -rf work-obj08.cf work-obj93.cf work-obj87.cf 2>/dev/null || true
rm -f *.o *.cf 2>/dev/null || true

# Remove elaborated executables
echo "Removing executables..."
rm -f tb_digital_lock tb_top_level tb_fsm_coverage tb_edge_cases tb_debouncer 2>/dev/null || true
rm -f digital_lock button_debouncer top_level 2>/dev/null || true

# Remove e~ files (GHDL elaboration)
rm -f e~*.o 2>/dev/null || true

if [[ "$1" == "--all" ]]; then
    echo "Removing waveform files..."
    rm -f simulation/*.ghw 2>/dev/null || true
    rm -f simulation/*.vcd 2>/dev/null || true
    rm -f simulation/*.fst 2>/dev/null || true
fi

echo ""
echo "✓ Clean complete!"
echo ""

if [[ "$1" != "--all" ]]; then
    echo "Note: Waveform files in simulation/ were preserved."
    echo "Use './scripts/clean.sh --all' to remove everything."
    echo ""
fi
