#!/bin/sh
# Build "Big Clock.app" from main.swift. Output: ./build/
set -e
cd "$(dirname "$0")"
APP="build/Big Clock.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Universal binary: runs on Apple Silicon and Intel Macs
swiftc -O main.swift -target arm64-apple-macos12 -o /tmp/bigclock-arm64
swiftc -O main.swift -target x86_64-apple-macos12 -o /tmp/bigclock-x86_64
lipo -create /tmp/bigclock-arm64 /tmp/bigclock-x86_64 -output "$APP/Contents/MacOS/BigClock"
rm -f /tmp/bigclock-arm64 /tmp/bigclock-x86_64
cp AppIcon.icns "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>BigClock</string>
  <key>CFBundleIdentifier</key><string>com.robmandella.big-clock</string>
  <key>CFBundleName</key><string>Big Clock</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.1</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF

codesign --force -s - "$APP"
echo "built: $APP"
