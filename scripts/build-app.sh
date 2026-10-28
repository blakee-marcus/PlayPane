#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build
BIN_DIR="$(swift build --show-bin-path)"
APP=".build/PlayPane.app"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/PlayPane" "$APP/Contents/MacOS/PlayPane"
python3 -c 'import plistlib; from pathlib import Path; info={"CFBundleExecutable":"PlayPane","CFBundleIdentifier":"com.blakeemarcus.PlayPane","CFBundleName":"PlayPane","CFBundleDisplayName":"PlayPane","CFBundlePackageType":"APPL","CFBundleVersion":"1","CFBundleShortVersionString":"0.1.0","LSMinimumSystemVersion":"14.0","NSHighResolutionCapable":True,"NSCameraUsageDescription":"PlayPane uses your selected HDMI capture device to show console video on your Mac."}; Path(".build/PlayPane.app/Contents/Info.plist").write_bytes(plistlib.dumps(info))'
codesign --force --sign - "$APP"
codesign --verify "$APP"
printf 'Built local development app: %s/%s\n' "$PWD" "$APP"
