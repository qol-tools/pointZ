#!/bin/bash
set -e

echo "PointZerver Setup"
echo "================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 not found"
        return 1
    fi
}

install_rust() {
    echo -e "${YELLOW}Installing Rust...${NC}"
    if command -v curl &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        export PATH="$HOME/.cargo/bin:$PATH"
        echo -e "${GREEN}✓ Rust installed${NC}"
    else
        echo -e "${RED}curl not found. Please install Rust manually: https://rustup.rs/${NC}"
        exit 1
    fi
}

echo -e "${BLUE}Checking dependencies...${NC}"
MISSING_DEPS=0

check_command curl || MISSING_DEPS=1
check_command git || MISSING_DEPS=1
check_command pkg-config || MISSING_DEPS=1

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if ! pkg-config --exists x11 2>/dev/null; then
        MISSING_DEPS=1
        echo -e "${RED}✗${NC} libx11-dev not found"
    fi
fi

if [ $MISSING_DEPS -eq 1 ]; then
    echo ""
    echo -e "${YELLOW}Some dependencies are missing.${NC}"
    echo "Install them with:"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "  Ubuntu/Debian: sudo apt install curl git pkg-config libx11-dev libxdo-dev"
        echo "  Fedora: sudo dnf install curl git pkg-config libX11-devel libxdo-devel"
        echo "  Arch: sudo pacman -S curl git pkg-config libx11 xdotool"
    else
        echo "  macOS: brew install curl git"
    fi
    exit 1
fi

echo ""

if ! check_command cargo; then
    echo ""
    read -p "Rust not found. Install automatically? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_rust
        export PATH="$HOME/.cargo/bin:$PATH"
    else
        echo "Install Rust: https://rustup.rs/"
        exit 1
    fi
fi

echo ""
echo -e "${BLUE}Fetching Rust dependencies...${NC}"
cd PointZerver
cargo fetch
cd ..

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Build and run:"
echo "  ${BLUE}make run${NC}"
echo ""
echo "Install to system:"
echo "  ${BLUE}make install${NC}"
echo ""
