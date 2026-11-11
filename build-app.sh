#!/bin/bash
# Compila NotchBar y lo empaqueta como NotchBar.app en ./build
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP="build/NotchBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$(swift build -c release --show-bin-path)/NotchBar" "$APP/Contents/MacOS/NotchBar"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>NotchBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.proteostudio.notchbar</string>
    <key>CFBundleExecutable</key>
    <string>NotchBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "Listo: $APP"
