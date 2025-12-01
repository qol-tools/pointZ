# PointZ Flutter Client

## Development Setup

**⚠️ IMPORTANT:** Clone to a path **without spaces**. Flutter/Gradle cannot build from paths containing spaces.

```bash
# ✓ Good
git clone <repo> ~/pointZ

# ✗ Bad - will fail to build
git clone <repo> "~/My Projects/pointZ"
```

## Quick Start

From the root directory:

```bash
make check    # Verify setup
make pair     # One-time phone pairing
make client   # Run app
```

## Commands

- `make client` - Run Flutter app with hot reload
- `make build` - Build debug APK
- `make test` - Run tests

## Troubleshooting

If phone doesn't connect:
1. Enable wireless debugging on phone
2. Run `make pair` from root directory
3. Follow on-screen instructions
