<div align="center">
  <a href="https://github.com/qol-tools/pointZ">
    <img
      src="assets/pz-banner.svg"
      alt="PointZ"
      width="442"
      height="159"
    />
  </a>
</div>

<br>

<p align="center">Headless server for remote PC control from mobile devices</p>

## Overview

PointZerver is a headless daemon that enables remote control of your PC from mobile devices. It runs as a [qol-tray](https://github.com/qol-tools/qol-tray) plugin.

## Installation

### As a qol-tray plugin

Install via the qol-tray Plugin Store, or manually:

```bash
git clone https://github.com/qol-tools/plugin-pointz ~/.config/qol-tray/plugins/plugin-pointz
```

### Standalone

```bash
make install
```

## Usage

When running as a qol-tray plugin:
1. The daemon starts automatically with qol-tray
2. Click "PointZ → Settings" in the tray menu
3. Scan the QR code to download the mobile app
4. The app auto-discovers and connects to the server

## Building

```bash
make build    # Debug build
make release  # Release build
make run      # Build and run
make test     # Run tests
```

## Ports

| Port  | Protocol | Purpose           |
|-------|----------|-------------------|
| 45454 | UDP      | Discovery         |
| 45455 | TCP      | Command/Control   |
| 45460 | HTTP     | Status API        |
