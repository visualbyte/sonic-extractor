#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="AudioExtractor"
DMG_NAME="SonicExtractor"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_DIR="$BUILD_DIR/dmg_staging"
OUTPUT_DMG="$PROJECT_DIR/dist/$DMG_NAME.dmg"

echo "=== Creating DMG for $DMG_NAME ==="

# 1. Rebuild app to ensure latest binary
bash "$PROJECT_DIR/build.sh"

# 2. Setup staging folder
rm -rf "$DMG_DIR" "$PROJECT_DIR/dist"
mkdir -p "$DMG_DIR" "$PROJECT_DIR/dist"

echo "-> Staging application and Applications symlink..."
cp -R "$APP_BUNDLE" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# 3. Create compressed read-only DMG
echo "-> Creating compressed DMG with hdiutil..."
hdiutil create \
    -volname "$DMG_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$OUTPUT_DMG"

# Clean staging
rm -rf "$DMG_DIR"

echo "=== DMG Created Successfully! ==="
echo "Distributable DMG: $OUTPUT_DMG"
ls -lh "$OUTPUT_DMG"
