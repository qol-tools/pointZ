# PointZ

Flutter mobile client for remote PC control. Control your computer's mouse and keyboard from your phone.

**Platforms:** Android, iOS

## Features

- Touch-based mouse control with configurable sensitivity and acceleration
- Multi-finger gestures (2-finger right-click, 3-finger middle-click)
- Hardware keyboard passthrough
- Tap-and-hold drag mode
- Automatic server discovery via UDP broadcast
- Settings for sensitivity, acceleration, and scroll speed

## Prerequisites

- Flutter SDK 3.0+
- For Android: ADB tools (included in Android SDK)
- A running PointZerver instance on your PC

## Development Setup

**⚠️ IMPORTANT:** Clone to a path **without spaces**. Flutter/Gradle cannot build from paths containing spaces.

```bash
# ✓ Good
git clone <repo> ~/pointz

# ✗ Bad - will fail to build
git clone <repo> "~/My Projects/pointz"
```

## Quick Start

```bash
make check    # Verify Flutter setup
make pair     # One-time phone pairing (Android)
make run      # Run app with hot reload
```

## Commands

- `make run` - Run Flutter app with hot reload
- `make build` - Build debug APK
- `make release` - Build release APK
- `make test` - Run tests
- `make pair` - Pair phone via wireless ADB
- `make check` - Verify Flutter and ADB setup

## Usage

1. Start PointZerver on your PC
2. Ensure phone and PC are on the same network
3. Launch the PointZ app
4. Tap your computer's name from the discovery list
5. Use the touchpad interface to control your PC

## Settings

- **Mouse Sensitivity** - How fast the cursor moves (default: 2.5)
- **Min/Max Acceleration** - Speed curve for faster movements (default: 1.0-1.8)
- **Acceleration Threshold** - When acceleration kicks in (default: 25.0)
- **Scroll Speed** - Scrolling sensitivity (default: 0.2)

## Architecture

```
lib/
├── services/           # Core services (discovery, commands, settings)
├── features/           # Feature modules (gesture, keyboard, mouse)
├── screens/            # UI screens (discovery, control, settings)
└── domain/             # Data models
```

## Troubleshooting

**Phone doesn't connect:**
1. Enable wireless debugging on phone (Settings → Developer Options → Wireless Debugging)
2. Run `make pair` and follow on-screen instructions
3. Ensure phone and PC are on same network

**Gradle build errors:**
- Workaround: Use `flutter build apk` then `adb install -r build/app/outputs/flutter-apk/app-debug.apk`

**Can't find server:**
- Check that PointZerver is running on your PC
- Verify firewall isn't blocking UDP ports 45454-45455
- Try connecting via hotspot instead of WiFi

## Development

The app uses a clean architecture with feature modules:

- **Gesture Recognition** (`features/gesture/`) - Converts touch events to mouse commands
- **Command Service** (`services/command_service.dart`) - Sends UDP commands to server
- **Discovery Service** (`services/discovery_service.dart`) - Finds servers via UDP broadcast

## License

See LICENSE file for details.
