#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="URL Catcher"
SRC="$SCRIPT_DIR/build/${APP_NAME}.app"
DEST="/Applications/${APP_NAME}.app"

if [ ! -d "$SRC" ]; then
    echo "Error: Run build.sh first"
    exit 1
fi

echo "Installing..."
rm -rf "$DEST"
cp -R "$SRC" "$DEST"
codesign --force --sign - "$DEST"
echo "Installed: $DEST"

codesign -v "$DEST"
echo "Signature verified."

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST"
echo "Registered with LaunchServices."
