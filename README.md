# PointZ

Mobile app for controlling your PC cursor from Android/iOS.

## Quick Start

**On PC:**
1. Download the PointZ server binary for your operating system from the [Releases page](https://github.com/KMRH47/pointZ-new/releases/latest)
2. Run the binary (it will appear in your system tray)
3. Right-click the tray icon → "Show QR Code"
4. Scan the QR code with your phone to download the mobile app
5. The app will auto-discover and connect to your server

**That's it.** No configuration needed.

## Features

- **System Tray Integration**: Server runs in the background without a console window
- **QR Code Download**: Easy app installation via QR code scan
- **Auto-Discovery**: Automatically finds the server on your local network
- **Cross-Platform**: Works on Linux, Windows, and macOS

## Usage

**Server:**
- Runs automatically in the system tray after starting
- Right-click the tray icon for options:
  - **Show QR Code**: Display QR code for app download
  - **Quit**: Stop the server

**Mobile App:**
- Automatically discovers servers on the same Wi-Fi network
- Tap "Connect" to start controlling your PC

**Gestures:**
- One finger: Move cursor / Click
- Two fingers: Right click / Scroll
- Three fingers: Middle click
- Double tap: Select / Drag

## Downloads

Get the latest server binary from the [Releases page](https://github.com/KMRH47/pointZ-new/releases/latest).

The releases page automatically detects your platform and shows the correct download for:
- Linux (x86_64)
- Windows (x86_64)
- macOS (Intel)
- macOS (Apple Silicon)

## Requirements

- PC and mobile device on the same Wi-Fi network
- No firewall configuration needed (uses local network discovery)
