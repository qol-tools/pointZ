# PointZ

Mobile app for controlling your PC cursor from Android/iOS.

## Quick Start

**Server (PC):**
```bash
make server  # Builds and runs on port 45454/45455
```

**Client (Mobile):**
```bash
make run  # Runs Flutter app with hot reload
```

## Commands

See `make help` for all available commands.

**Common:**
- `make server` - Run server
- `make run` - Run Flutter app
- `make build` - Build debug APK
- `make clean` - Clean Flutter build

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

## Architecture

- **PointZerver**: Rust UDP server (ports 45454/45455)
- **PointZ**: Flutter mobile app
- SOLID architecture with feature-based structure
