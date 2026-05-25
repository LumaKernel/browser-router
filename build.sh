#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Browser Router"
BUNDLE_DIR="$SCRIPT_DIR/build/${APP_NAME}.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

echo "Compiling..."
cd "$SCRIPT_DIR"
swift build -c release

cp ".build/release/BrowserRouter" "$MACOS_DIR/BrowserRouter"
cp "$SCRIPT_DIR/BrowserRouter/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$SCRIPT_DIR/BrowserRouter/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

# Embed appVersion from Version.swift into Info.plist
APP_VERSION=$(grep -o 'appVersion: UInt = [0-9]*' "$SCRIPT_DIR/BrowserRouter/Version.swift" | grep -o '[0-9]*')
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $APP_VERSION" "$CONTENTS_DIR/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 0.0.$APP_VERSION" "$CONTENTS_DIR/Info.plist"
echo "Version: 0.0.$APP_VERSION ($APP_VERSION)"

echo "Signing..."
codesign --force --sign - "$BUNDLE_DIR"
codesign -v "$BUNDLE_DIR"

echo "Built: $BUNDLE_DIR"
echo ""
echo "To install, run:"
echo "  ./install.sh"
echo ""
echo "Then open System Settings > Desktop & Dock > Default web browser"
echo "and select 'Browser Router'."
