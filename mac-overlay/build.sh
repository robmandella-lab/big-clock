#!/bin/sh
# Build "Teleprompter Overlay.app" from main.swift. Output: ./build/
set -e
cd "$(dirname "$0")"
APP="build/Teleprompter Overlay.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS"

swiftc -O main.swift -o "$APP/Contents/MacOS/TeleprompterOverlay"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>TeleprompterOverlay</string>
  <key>CFBundleIdentifier</key><string>com.robmandella.teleprompter-overlay</string>
  <key>CFBundleName</key><string>Teleprompter Overlay</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF

codesign --force -s - "$APP"
echo "built: $APP"
