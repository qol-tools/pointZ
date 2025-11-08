#!/bin/bash
set -e

echo "PointZ Setup"
echo "============"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check system dependencies
echo -e "${BLUE}Checking system dependencies...${NC}"
MISSING_DEPS=0

if ! check_command curl; then
    MISSING_DEPS=1
fi

if ! check_command git; then
    MISSING_DEPS=1
fi

if [ $MISSING_DEPS -eq 1 ]; then
    echo ""
    echo -e "${YELLOW}Some system dependencies are missing.${NC}"
    echo "Install them with your package manager:"
    echo "  Ubuntu/Debian: sudo apt install curl git"
    echo "  Fedora: sudo dnf install curl git"
    echo "  macOS: brew install curl git"
    exit 1
fi

echo ""

# Check Rust
if ! check_command cargo; then
    echo ""
    read -p "Rust not found. Install automatically? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_rust
        # Reload PATH
        export PATH="$HOME/.cargo/bin:$PATH"
    else
        echo "Install Rust: https://rustup.rs/"
        exit 1
    fi
fi

# Check Flutter
if ! check_command flutter; then
    echo ""
    echo -e "${YELLOW}Flutter not found.${NC}"
    echo "Install Flutter: https://docs.flutter.dev/get-started/install"
    echo ""
    echo "Quick install options:"
    echo "  Ubuntu/Debian: sudo snap install flutter --classic"
    echo "  Or download from: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo ""
echo -e "${BLUE}Installing project dependencies...${NC}"
echo ""

# Server dependencies
echo "Server (Rust)..."
cd PointZerver
cargo fetch
cd ..

# Client dependencies
echo "Client (Flutter)..."
cd PointZ
flutter pub get
cd ..

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Quick start:"
echo "  1. Server: ${BLUE}make server${NC}"
echo "  2. Client: ${BLUE}make run${NC}"
echo ""

