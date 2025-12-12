#!/bin/bash
#
# wave.sh - Open waveform viewer for a testbench
#
# Usage: ./scripts/wave.sh [testbench_name]
#
# Arguments:
#   testbench_name   Name of testbench (default: tb_digital_lock)
#
# Examples:
#   ./scripts/wave.sh                    # Open tb_digital_lock waveform
#   ./scripts/wave.sh tb_top_level       # Open tb_top_level waveform
#

# Get project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Default testbench
TB_NAME="${1:-tb_digital_lock}"
WAVE_FILE="simulation/${TB_NAME}.ghw"

echo "=========================================="
echo "  Digital Lock - Waveform Viewer"
echo "=========================================="
echo ""

# Check for GTKWave
if ! command -v gtkwave &> /dev/null; then
    echo "Error: GTKWave is not installed."
    echo ""
    echo "Install with:"
    echo "  Ubuntu/Debian: sudo apt install gtkwave"
    echo "  macOS:         brew install --cask gtkwave"
    echo "  Fedora:        sudo dnf install gtkwave"
    echo ""
    exit 1
fi

# Check if waveform file exists
if [ ! -f "$WAVE_FILE" ]; then
    echo "Waveform file not found: $WAVE_FILE"
    echo ""
    echo "Run the test first to generate waveforms:"
    echo "  ./scripts/test.sh $TB_NAME"
    echo ""

    # List available waveforms
    if ls simulation/*.ghw 1> /dev/null 2>&1; then
        echo "Available waveforms:"
        for f in simulation/*.ghw; do
            name=$(basename "$f" .ghw)
            echo "  - $name"
        done
        echo ""
        echo "Usage: ./scripts/wave.sh <testbench_name>"
    fi
    exit 1
fi

echo "Opening: $WAVE_FILE"
echo ""
echo "GTKWave Tips:"
echo "  - Expand hierarchy in left panel to find signals"
echo "  - Double-click signals to add them to the view"
echo "  - Use mouse wheel to zoom"
echo "  - Press 'M' to add a marker"
echo ""

# Open GTKWave
gtkwave "$WAVE_FILE" &

echo "GTKWave launched in background."
