#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "==> Building SlopMonster Release Executable..."
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build -c release

APP_BUNDLE="$DIR/SlopMonster.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Creating macOS Application Bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

RELEASE_BIN="$(find "$DIR/.build" -type f -name "SlopMonster" -perm +111 | grep -i "release" | head -n 1)"
if [ -z "$RELEASE_BIN" ]; then
  # Fallback to Debug binary if release search differs
  RELEASE_BIN="$(find "$DIR/.build" -type f -name "SlopMonster" -perm +111 | head -n 1)"
fi

echo "==> Copying binary from $RELEASE_BIN..."
cp "$RELEASE_BIN" "$MACOS/SlopMonster"
chmod +x "$MACOS/SlopMonster"

if [ -f "$DIR/AppIcon.icns" ]; then
  echo "==> Installing AppIcon.icns..."
  cp "$DIR/AppIcon.icns" "$RESOURCES/AppIcon.icns"
fi

cat << 'EOF' > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>SlopMonster</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.aniketraj.slopmonster</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>SlopMonster</string>
    <key>CFBundleDisplayName</key>
    <string>SlopMonster</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>3.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
</dict>
</plist>
EOF

echo "==> SlopMonster.app successfully built!"
echo "You can launch it via:"
echo "    open '$APP_BUNDLE'"
