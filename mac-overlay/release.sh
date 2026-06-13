#!/bin/sh
# One-command release: build → sign → notarize → staple → install → publish.
# Prereqs (already set up once, persist in the keychain):
#   - "Developer ID Application: Robert Mandella Jr (JV75QKVC2H)" signing identity
#   - notarytool keychain profile named "bigclock"
set -e
cd "$(dirname "$0")"
IDENTITY="Developer ID Application: Robert Mandella Jr (JV75QKVC2H)"
APP="build/Big Clock.app"

echo "==> Building universal app"
./build.sh   # produces an ad-hoc signed universal build

echo "==> Signing with Developer ID + hardened runtime"
codesign --force --deep --options runtime --timestamp -s "$IDENTITY" "$APP"

echo "==> Zipping for notarization"
ditto -c -k --keepParent "$APP" /tmp/BigClock-notarize.zip

echo "==> Submitting to Apple notary service (waits for verdict)"
xcrun notarytool submit /tmp/BigClock-notarize.zip --keychain-profile bigclock --wait

echo "==> Stapling ticket"
xcrun stapler staple "$APP"
spctl -a -vvv -t install "$APP" 2>&1 | head -2

echo "==> Refreshing /Applications copy"
rm -rf "/Applications/Big Clock.app"
cp -R "$APP" /Applications/

echo "==> Publishing zip to GitHub release v1.1"
ditto -c -k --keepParent "$APP" /tmp/Big-Clock-Mac.zip
gh release upload v1.1 /tmp/Big-Clock-Mac.zip --clobber

echo "==> Done. Notarized app installed and published."
