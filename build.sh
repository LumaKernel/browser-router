#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="URL Catcher"
BUNDLE_DIR="$SCRIPT_DIR/build/${APP_NAME}.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "Compiling..."
cd "$SCRIPT_DIR"
swift build -c release

cp ".build/release/URLCatcher" "$MACOS_DIR/URLCatcher"
cp "$SCRIPT_DIR/URLCatcher/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "Signing..."
codesign --force --sign - "$BUNDLE_DIR"
codesign -v "$BUNDLE_DIR"

echo "Built: $BUNDLE_DIR"
echo ""
echo "To install, run:"
echo "  cp -r \"$BUNDLE_DIR\" /Applications/"
echo ""
echo "Then open System Settings > Desktop & Dock > Default web browser"
echo "and select 'URL Catcher'."
