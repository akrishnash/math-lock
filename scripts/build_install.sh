#!/usr/bin/env bash
# Build the Math-Lock app and install it on the connected Android device.
# Usage: ./scripts/build_install.sh [debug|release]
# Requires: Flutter SDK, Android device/emulator with USB debugging, adb in PATH.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_TYPE="${1:-debug}"

cd "$PROJECT_DIR"

echo "==> Checking for connected device..."
if ! adb devices | grep -q 'device$'; then
  echo "No Android device/emulator found. Connect a device or start an emulator."
  exit 1
fi

echo "==> Building APK ($BUILD_TYPE)..."
if [[ "$BUILD_TYPE" == "release" ]]; then
  flutter build apk --release
  APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
else
  flutter build apk --debug
  APK="$PROJECT_DIR/build/app/outputs/flutter-apk/app-debug.apk"
fi

if [[ ! -f "$APK" ]]; then
  echo "Build failed: APK not found at $APK"
  exit 1
fi

echo "==> Installing on device..."
adb install -r "$APK"

echo "==> Done. App installed. Launch with: adb shell am start -n com.earnyourscreen.app/.MainActivity"
