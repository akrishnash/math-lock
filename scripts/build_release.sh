#!/usr/bin/env bash
# Build a signed release Android App Bundle for Play Store.
# Prereqs: android/key.properties and android/upload-keystore.jks (see docs/PLAY_STORE.md).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
KEY_PROPS="$PROJECT_DIR/android/key.properties"
KEYSTORE="$PROJECT_DIR/android/upload-keystore.jks"

cd "$PROJECT_DIR"

if [[ ! -f "$KEY_PROPS" ]]; then
  echo "Missing $KEY_PROPS"
  echo "Copy android/key.properties.example to android/key.properties and set your keystore passwords and alias."
  echo "See docs/PLAY_STORE.md for full steps."
  exit 1
fi

if [[ ! -f "$KEYSTORE" ]]; then
  echo "Missing $KEYSTORE"
  echo "Create it with: cd android && keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload"
  echo "See docs/PLAY_STORE.md for full steps."
  exit 1
fi

echo "==> Building release App Bundle..."
flutter build appbundle --release

AAB="$PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab"
if [[ ! -f "$AAB" ]]; then
  echo "Build failed: AAB not found at $AAB"
  exit 1
fi

echo ""
echo "==> Done. Release AAB:"
echo "    $AAB"
echo ""
echo "Upload this file in Play Console → Your app → Release → Production (or Testing) → Create new release."
