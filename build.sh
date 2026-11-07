#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="AudioExtractor"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

TARGET_ARCH="${1:-$(uname -m)}"
# Normalize
if [ "$TARGET_ARCH" = "x86_64" ] || [ "$TARGET_ARCH" = "intel" ]; then
    TARGET_ARCH="x86_64"
elif [ "$TARGET_ARCH" = "arm64" ] || [ "$TARGET_ARCH" = "silicon" ] || [ "$TARGET_ARCH" = "apple-silicon" ]; then
    TARGET_ARCH="arm64"
else
    echo "Unknown architecture: $TARGET_ARCH (supported: arm64, x86_64)"
    exit 1
fi

echo "=== Building $APP_NAME for macOS ($TARGET_ARCH) ==="

# 1. Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# 2. Generate App Icon
echo "-> Generating App Icon..."
swift "$PROJECT_DIR/scripts/generate_icon.swift"
iconutil -c icns /tmp/AppIcon.iconset -o "$PROJECT_DIR/Resources/AppIcon.icns"
rm -rf /tmp/AppIcon.iconset
cp "$PROJECT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/"
cp "$PROJECT_DIR/Resources/pop.wav" "$RESOURCES_DIR/"
cp "$PROJECT_DIR/Resources/remove.wav" "$RESOURCES_DIR/"
cp "$PROJECT_DIR/Resources/save.wav" "$RESOURCES_DIR/"

# 3. Copy Info.plist
echo "-> Copying Info.plist..."
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# 4. Compile Swift Sources (safely handling spaces in paths)
echo "-> Compiling Swift sources for $TARGET_ARCH..."
find "$PROJECT_DIR/Sources" -name "*.swift" -print0 | xargs -0 swiftc \
    -parse-as-library \
    -O \
    -target "${TARGET_ARCH}-apple-macosx14.0" \
    -sdk "$(xcrun --show-sdk-path)" \
    -o "$MACOS_DIR/$APP_NAME"

# 5. Ad-hoc Codesign (Required on modern macOS)
echo "-> Ad-hoc signing app bundle..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "=== Build Succeeded for $TARGET_ARCH! ==="
echo "App bundle created at: $APP_BUNDLE"

# If matching current machine arch, install to ~/Applications and /Applications
CURRENT_ARCH="$(uname -m)"
if [ "$TARGET_ARCH" = "$CURRENT_ARCH" ]; then
    mkdir -p "$HOME/Applications"
    rm -rf "$HOME/Applications/$APP_NAME.app"
    cp -R "$APP_BUNDLE" "$HOME/Applications/"
    echo "Installed to $HOME/Applications/$APP_NAME.app"

    rm -rf "/Applications/$APP_NAME.app" 2>/dev/null || true
    cp -R "$APP_BUNDLE" "/Applications/" 2>/dev/null && echo "Installed to /Applications/$APP_NAME.app" || true
fi
