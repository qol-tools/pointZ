# Flutter Installation & Android Setup

## Install Flutter

1. Download Flutter SDK:
```bash
cd ~
git clone https://github.com/flutter/flutter.git -b stable
```

2. Add to PATH (add to ~/.bashrc):
```bash
export PATH="$PATH:$HOME/flutter/bin"
```

3. Reload shell or run:
```bash
source ~/.bashrc
```

4. Verify installation:
```bash
flutter doctor
```

5. Accept Android licenses (if needed):
```bash
flutter doctor --android-licenses
```

## Initialize Flutter Project

If the PointZ directory isn't fully initialized yet:
```bash
cd PointZ
flutter create .
```

This will generate the complete Android/iOS project structure.

## Android Setup

1. **Install Android Studio** (optional, for GUI) or **Android SDK Command Line Tools**

2. **Enable USB Debugging on your phone:**
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"
   - Connect phone via USB

3. **Verify device connection:**
```bash
flutter devices
# or
adb devices
```

## Build & Install APK

**Build release APK:**
```bash
make client-build-apk
# APK location: PointZ/build/app/outputs/flutter-apk/app-release.apk
```

**Install to connected device:**
```bash
make client-install
```

**Run directly on connected device (for debugging):**
```bash
make client-run
```

**Check connected devices:**
```bash
make client-devices
```

## Troubleshooting

- **Device not detected:** Check USB debugging is enabled, try different USB cable/port
- **Flutter not found:** Make sure PATH is set correctly, restart terminal
- **Build errors:** Run `flutter clean` then `flutter pub get`

