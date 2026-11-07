#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="AudioExtractor"
DMG_BASE_NAME="SonicExtractor"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_DIR="$BUILD_DIR/dmg_staging"
DIST_DIR="$PROJECT_DIR/dist"

create_dmg() {
    local ARCH="$1"
    local DMG_OUTPUT_NAME="$2"
    local OUTPUT_DMG="$DIST_DIR/$DMG_OUTPUT_NAME"

    echo "=== Building & Packaging DMG for $ARCH ($DMG_OUTPUT_NAME) ==="
    bash "$PROJECT_DIR/build.sh" "$ARCH"

    rm -rf "$DMG_DIR"
    mkdir -p "$DMG_DIR" "$DIST_DIR"

    echo "-> Staging application and Applications symlink..."
    cp -R "$APP_BUNDLE" "$DMG_DIR/"
    ln -s /Applications "$DMG_DIR/Applications"

    echo "-> Creating compressed DMG with hdiutil..."
    rm -f "$OUTPUT_DMG"
    hdiutil create \
        -volname "$DMG_BASE_NAME" \
        -srcfolder "$DMG_DIR" \
        -ov \
        -format UDZO \
        "$OUTPUT_DMG"

    rm -rf "$DMG_DIR"
    echo "=== DMG Created: $OUTPUT_DMG ==="
    ls -lh "$OUTPUT_DMG"
}

ARCH_TARGET="${1:-all}"

if [ "$ARCH_TARGET" = "arm64" ]; then
    create_dmg "arm64" "${DMG_BASE_NAME}-AppleSilicon-arm64.dmg"
elif [ "$ARCH_TARGET" = "x86_64" ]; then
    create_dmg "x86_64" "${DMG_BASE_NAME}-Intel-x86_64.dmg"
elif [ "$ARCH_TARGET" = "all" ]; then
    create_dmg "arm64" "${DMG_BASE_NAME}-AppleSilicon-arm64.dmg"
    create_dmg "x86_64" "${DMG_BASE_NAME}-Intel-x86_64.dmg"
else
    echo "Usage: ./scripts/create_dmg.sh [arm64|x86_64|all]"
    exit 1
fi

echo "=== All packaging complete in $DIST_DIR ==="
ls -lh "$DIST_DIR"
