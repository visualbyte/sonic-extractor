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

    echo "-> Staging application, Applications symlink, and First-Time Launch Guide..."
    cp -R "$APP_BUNDLE" "$DMG_DIR/"
    ln -s /Applications "$DMG_DIR/Applications"

    cat << 'EOF' > "$DMG_DIR/First-Time Launch Guide.txt"
==================================================
      SonicExtractor — Installation Guide
==================================================

1. INSTALLATION:
   Drag "AudioExtractor" into the "Applications" shortcut.

2. FIRST-TIME LAUNCH (One-Time macOS Approval):
   Because SonicExtractor is a free, independent open-source
   app (not distributed via the Apple App Store):

   • Double-click AudioExtractor in your Applications folder.
   • macOS will show a pop-up:
     "Apple could not verify 'AudioExtractor' is free of malware..."
   • Click "Done" (do NOT click "Move to Bin" / "Move to Trash").
   • Open: System Settings -> Privacy & Security.
   • Scroll down to the "Security" section.
   • Look for:
     "AudioExtractor was blocked from use because it is not from an identified developer."
   • Click "Open Anyway" (enter your Touch ID or Mac password).
   • Click "Open" on the confirmation prompt.

macOS will remember this approval permanently. You will never see the prompt again!
==================================================
EOF

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

ARCH_TARGET="${1:-universal}"

if [ "$ARCH_TARGET" = "universal" ]; then
    create_dmg "universal" "${DMG_BASE_NAME}-Universal.dmg"
    cp "$DIST_DIR/${DMG_BASE_NAME}-Universal.dmg" "$DIST_DIR/${DMG_BASE_NAME}.dmg"
elif [ "$ARCH_TARGET" = "arm64" ]; then
    create_dmg "arm64" "${DMG_BASE_NAME}-AppleSilicon-arm64.dmg"
elif [ "$ARCH_TARGET" = "x86_64" ]; then
    create_dmg "x86_64" "${DMG_BASE_NAME}-Intel-x86_64.dmg"
elif [ "$ARCH_TARGET" = "all" ]; then
    create_dmg "universal" "${DMG_BASE_NAME}-Universal.dmg"
    cp "$DIST_DIR/${DMG_BASE_NAME}-Universal.dmg" "$DIST_DIR/${DMG_BASE_NAME}.dmg"
    create_dmg "arm64" "${DMG_BASE_NAME}-AppleSilicon-arm64.dmg"
    create_dmg "x86_64" "${DMG_BASE_NAME}-Intel-x86_64.dmg"
else
    echo "Usage: ./scripts/create_dmg.sh [universal|arm64|x86_64|all]"
    exit 1
fi

echo "=== All packaging complete in $DIST_DIR ==="
ls -lh "$DIST_DIR"
