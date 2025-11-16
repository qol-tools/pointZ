.PHONY: help setup pair check server-build server-run server-check server-clean server-release server-test client-get client-run client-build client-build-apk client-build-apk-debug client-install client-build-install client-build-install-debug client-devices client-logs client-clean client-test test run build clean server client

help:
	@echo "PointZ - Client/Server Commands"
	@echo ""
	@echo "Setup:"
	@echo "  make setup          - Run setup script (checks dependencies, installs deps)"
	@echo "  make pair           - Pair phone for wireless ADB (one-time setup)"
	@echo "  make check          - Check if all dependencies are installed"
	@echo ""
	@echo "Distribution:"
	@echo "  make server-release - Build release binary for distribution"
	@echo ""
	@echo "Quick shortcuts (run from root):"
	@echo "  make run              - Run Flutter app (hot reload: press 'r', hot restart: press 'R')"
	@echo "  make build            - Build debug APK (shortcut for client-build-apk-debug)"
	@echo "  make clean            - Clean Flutter build (shortcut for client-clean)"
	@echo "  make server           - Run server (shortcut for server-run)"
	@echo "  make client           - Run client (shortcut for client-run)"
	@echo ""
	@echo "Server (PointZerver):"
	@echo "  make server-build    - Build release binary"
	@echo "  make server-run      - Run server in debug mode"
	@echo "  make server-check    - Check code without building"
	@echo "  make server-test     - Run Rust unit tests"
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
	@echo "  make client-test      - Run Flutter unit tests"
	@echo "  make client-clean     - Clean Flutter build"
	@echo ""
	@echo "Testing:"
	@echo "  make test             - Run all tests (Flutter + Rust)"

# Setup
setup:
	@./setup.sh

pair:
	@bash scripts/adb-pair-wireless.sh

# Health check
check:
	@echo "Checking dependencies..."
	@command -v cargo >/dev/null 2>&1 && echo "✓ Rust/cargo installed" || echo "✗ Rust/cargo not found"
	@command -v flutter >/dev/null 2>&1 && echo "✓ Flutter installed" || echo "✗ Flutter not found"
	@command -v git >/dev/null 2>&1 && echo "✓ Git installed" || echo "✗ Git not found"
	@echo ""
	@if echo "$(CURDIR)" | grep -q " "; then \
		echo "✗ Project path contains spaces"; \
		echo "  Flutter/Gradle cannot build from paths with spaces."; \
		echo "  Move to a path without spaces (e.g., ~/pointZ)"; \
	else \
		echo "✓ Project path OK (no spaces)"; \
	fi
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

server-test:
	cd PointZerver && cargo test

server-clean:
	cd PointZerver && cargo clean

# Client commands
client-get:
	cd PointZ && flutter pub get

client-run:
	@bash scripts/adb-autoconnect.sh || true
	@if echo "$(CURDIR)" | grep -q " "; then \
		echo "⚠️  ERROR: Project path contains spaces"; \
		echo ""; \
		echo "Flutter/Gradle cannot build from paths with spaces."; \
		echo "Move the project to a path without spaces, e.g.:"; \
		echo "  ~/pointZ  or  /opt/pointZ  or  /home/username/dev/pointZ"; \
		echo ""; \
		exit 1; \
	else \
		cd PointZ && flutter run; \
	fi

client-build-apk:
	@if echo "$(CURDIR)" | grep -q " "; then \
		echo "⚠️  ERROR: Project path contains spaces."; \
		echo "Flutter/Gradle cannot build from paths with spaces."; \
		echo "Move the project to a path without spaces first."; \
		exit 1; \
	else \
		cd PointZ && flutter build apk --release; \
	fi

client-build-apk-debug:
	@if echo "$(CURDIR)" | grep -q " "; then \
		echo "⚠️  ERROR: Project path contains spaces."; \
		echo "Flutter/Gradle cannot build from paths with spaces."; \
		echo "Move the project to a path without spaces first."; \
		exit 1; \
	else \
		cd PointZ && flutter build apk --debug; \
	fi

client-build-install: client-build-apk
	cd PointZ && flutter install

client-build-install-debug: client-build-apk-debug
	cd PointZ && flutter install

client-logs:
	cd PointZ && flutter logs

client-test:
	cd PointZ && flutter test

client-clean:
	cd PointZ && flutter clean

# Testing
test:
	@echo "Running Flutter tests..."
	@cd PointZ && flutter test
	@echo ""
	@echo "Running Rust tests..."
	@cd PointZerver && cargo test

# Shortcuts
run: client-run
build: client-build-apk-debug
clean: client-clean
server: server-run
client: client-run

