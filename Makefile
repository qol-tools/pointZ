.PHONY: help build run check test clean release install

help:
	@echo "PointZerver - Headless remote control server"
	@echo ""
	@echo "Commands:"
	@echo "  make build    - Build debug binary"
	@echo "  make release  - Build release binary"
	@echo "  make run      - Build and run in debug mode"
	@echo "  make check    - Check code without building"
	@echo "  make test     - Run unit tests"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make install  - Install release binary to /usr/local/bin"

build:
	cd PointZerver && cargo build

release:
	cd PointZerver && cargo build --release
	@echo "Release binary: PointZerver/target/release/pointzerver"

run:
	cd PointZerver && RUST_LOG=info cargo run

check:
	cd PointZerver && cargo check

test:
	cd PointZerver && cargo test

clean:
	cd PointZerver && cargo clean

install: release
	sudo cp PointZerver/target/release/pointzerver /usr/local/bin/
	@echo "Installed pointzerver to /usr/local/bin/"
