.PHONY: help setup check server-build server-run server-check server-clean server-release client-get client-run client-build client-build-apk client-build-apk-debug client-install client-build-install client-build-install-debug client-devices client-logs client-clean run build clean server

help:
	@echo "PointZ - Client/Server Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup          - Run setup script (checks dependencies, installs deps)"
	@echo "  make check          - Check if all dependencies are installed"
	@echo ""
	@echo "Distribution:"
	@echo "  make server-release - Build release binary for distribution"
	@echo ""
	@echo "Quick shortcuts (run from root):"
	@echo "  make run              - Run Flutter app (hot reload: press 'r', hot restart: press 'R')"
	@echo "  make build            - Build debug APK (shortcut for client-build-apk-debug)"
	@echo "  make clean            - Clean Flutter build (shortcut for client-clean)"
	@echo "  make server            - Run server (shortcut for server-run)"
	@echo ""
	@echo "Server (PointZerver):"
	@echo "  make server-build    - Build release binary"
	@echo "  make server-run      - Run server in debug mode"
	@echo "  make server-check    - Check code without building"
	@echo "  make server-clean    - Clean build artifacts"
	@echo ""
	@echo "Client (PointZ):"
	@echo "  make client-get      - Get Flutter dependencies"
	@echo "  make client-run       - Run Flutter app on connected device (hot reload: press 'r', hot restart: press 'R')"
	@echo "  make client-build-apk - Build release APK"
	@echo "  make client-build-apk-debug - Build debug APK (faster, ~3-5s)"
	@echo "  make client-install   - Install APK to connected device"
	@echo "  make client-build-install - Build release APK and install"
	@echo "  make client-build-install-debug - Build debug APK and install (faster)"
	@echo "  make client-devices   - List connected devices"
	@echo "  make client-logs      - Stream logs from connected device"
	@echo "  make client-clean     - Clean Flutter build"

# Setup
setup:
	@./setup.sh

# Health check
check:
	@echo "Checking dependencies..."
	@command -v cargo >/dev/null 2>&1 && echo "✓ Rust/cargo installed" || echo "✗ Rust/cargo not found"
	@command -v flutter >/dev/null 2>&1 && echo "✓ Flutter installed" || echo "✗ Flutter not found"
	@command -v git >/dev/null 2>&1 && echo "✓ Git installed" || echo "✗ Git not found"
	@echo ""
	@echo "Checking project dependencies..."
	@cd PointZerver && cargo check --quiet 2>/dev/null && echo "✓ Server dependencies OK" || echo "✗ Server dependencies missing (run: make setup)"
	@cd PointZ && flutter pub get --quiet >/dev/null 2>&1 && echo "✓ Client dependencies OK" || echo "✗ Client dependencies missing (run: make setup)"

# Server commands
server-build:
	cd PointZerver && cargo build --release

server-release: server-build
	@echo "Release binary built at: PointZerver/target/release/pointzerver"
	@echo "Copy this binary to distribute to end users."

server-run:
	cd PointZerver && cargo build && cargo run

server-check:
	cd PointZerver && cargo check

server-clean:
	cd PointZerver && cargo clean

# Client commands
client-get:
	cd PointZ && flutter pub get

client-run:
	cd PointZ && flutter run

client-build-apk:
	cd PointZ && flutter build apk --release

client-build-apk-debug:
	cd PointZ && flutter build apk --debug

client-build-install: client-build-apk
	cd PointZ && flutter install

client-build-install-debug: client-build-apk-debug
	cd PointZ && flutter install

client-logs:
	cd PointZ && flutter logs

client-clean:
	cd PointZ && flutter clean

# Shortcuts
run: client-run
build: client-build-apk-debug
clean: client-clean
server: server-run

