#!/bin/bash
#
# install.sh - Install dependencies for the Pattern-Based Digital Lock project
#
# Usage: ./scripts/install.sh
#

set -e  # Exit on error

echo "=========================================="
echo "  Digital Lock - Dependency Installation"
echo "=========================================="
echo ""

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
            echo "debian"
        elif command -v dnf &> /dev/null; then
            echo "fedora"
        elif command -v pacman &> /dev/null; then
            echo "arch"
        else
            echo "linux-other"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
echo "Detected OS: $OS"
echo ""

# Check if GHDL is already installed
check_ghdl() {
    if command -v ghdl &> /dev/null; then
        echo "✓ GHDL is already installed: $(ghdl --version | head -n1)"
        return 0
    else
        return 1
    fi
}

# Check if GTKWave is already installed
check_gtkwave() {
    if command -v gtkwave &> /dev/null; then
        echo "✓ GTKWave is already installed"
        return 0
    else
        return 1
    fi
}

# Install for Debian/Ubuntu
install_debian() {
    echo "Installing for Debian/Ubuntu..."
    sudo apt update
    sudo apt install -y ghdl gtkwave
}

# Install for Fedora
install_fedora() {
    echo "Installing for Fedora..."
    sudo dnf install -y ghdl gtkwave
}

# Install for Arch Linux
install_arch() {
    echo "Installing for Arch Linux..."
    sudo pacman -S --noconfirm ghdl-llvm gtkwave
}

# Install for macOS
install_macos() {
    echo "Installing for macOS..."

    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew is not installed."
        echo "Please install Homebrew first: https://brew.sh"
        exit 1
    fi

    brew install ghdl
    brew install --cask gtkwave
}

# Main installation logic
main() {
    NEED_GHDL=false
    NEED_GTKWAVE=false

    if ! check_ghdl; then
        NEED_GHDL=true
    fi

    if ! check_gtkwave; then
        NEED_GTKWAVE=true
    fi

    if [ "$NEED_GHDL" = false ] && [ "$NEED_GTKWAVE" = false ]; then
        echo ""
        echo "All dependencies are already installed!"
        echo ""
        exit 0
    fi

    echo ""
    echo "Missing dependencies will be installed..."
    echo ""

    case $OS in
        debian)
            install_debian
            ;;
        fedora)
            install_fedora
            ;;
        arch)
            install_arch
            ;;
        macos)
            install_macos
            ;;
        *)
            echo "Error: Unsupported operating system."
            echo ""
            echo "Please install manually:"
            echo "  - GHDL: https://github.com/ghdl/ghdl/releases"
            echo "  - GTKWave: https://gtkwave.sourceforge.net/"
            exit 1
            ;;
    esac

    echo ""
    echo "=========================================="
    echo "  Installation Complete!"
    echo "=========================================="
    echo ""

    # Verify installation
    if command -v ghdl &> /dev/null; then
        echo "✓ GHDL: $(ghdl --version | head -n1)"
    else
        echo "✗ GHDL installation failed"
        exit 1
    fi

    if command -v gtkwave &> /dev/null; then
        echo "✓ GTKWave: installed"
    else
        echo "⚠ GTKWave not found (optional, for viewing waveforms)"
    fi

    echo ""
    echo "Next steps:"
    echo "  ./scripts/build.sh    - Compile the project"
    echo "  ./scripts/test.sh     - Run all tests"
    echo ""
}

main "$@"
