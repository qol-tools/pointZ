# PointZ

Mobile app for controlling your PC cursor from Android/iOS.

## End-User Setup (Simple)

**On PC:**
1. Download PointZ server binary for your OS
2. Run it → QR code appears in terminal
3. Scan QR code with phone → downloads app
4. App auto-discovers and connects

**That's it.** No configuration needed.

## Developer Setup

**One command setup:**
```bash
./setup.sh
# or
make setup
```

**Linux GUI dependencies (required for system tray):**
```bash
# Ubuntu/Debian
sudo apt install libgtk-3-dev libgdk-pixbuf2.0-dev libatk1.0-dev libpango1.0-dev libcairo2-dev libglib2.0-dev libwebkit2gtk-4.1-dev libayatana-appindicator3-dev libx11-dev libxcb1-dev libxkbcommon-dev libxkbcommon-x11-dev libxdo-dev pkg-config

# Fedora
sudo dnf install gtk3-devel gdk-pixbuf2-devel atk-devel pango-devel cairo-devel glib2-devel webkit2gtk3-devel libappindicator-gtk3-devel libX11-devel libxcb-devel libxkbcommon-devel pkg-config

# Arch
sudo pacman -S gtk3 gdk-pixbuf2 atk pango cairo glib2 webkit2gtk libappindicator-gtk3 libx11 libxcb libxkbcommon pkg-config
```

**Check setup:**
```bash
make check  # Verify all dependencies are installed
```

**Manual setup:**
- **Rust**: Install from [rustup.rs](https://rustup.rs/)
- **Flutter**: Install from [flutter.dev](https://docs.flutter.dev/get-started/install)

## Quick Start

**Server (PC):**
```bash
make server  # Builds and runs on port 45454/45455
```

**Client (Mobile):**
```bash
make run  # Runs Flutter app with hot reload
```

## Usage

1. Start server: `make server`
2. Run app: `make run` (or install APK manually)
3. App auto-discovers server on same Wi-Fi
4. Tap "Connect" to control

**Gestures:**
- One finger: Move/Click
- Two fingers: Right click/Scroll
- Three fingers: Middle click
- Double tap: Select/Drag

## Commands

See `make help` for all available commands.

**Common:**
- `make server` - Run server
- `make run` - Run Flutter app
- `make build` - Build debug APK
- `make clean` - Clean Flutter build

## Architecture

- **PointZerver**: Rust UDP server (ports 45454/45455)
- **PointZ**: Flutter mobile app
- SOLID architecture with feature-based structure
