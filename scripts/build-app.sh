#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build
BIN_DIR="$(swift build --show-bin-path)"
APP="${1:-.build/PlayPane.app}"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/PlayPane" "$APP/Contents/MacOS/PlayPane"
python3 -c 'import plistlib,sys; from pathlib import Path; info={"CFBundleExecutable":"PlayPane","CFBundleIdentifier":"com.blakeemarcus.PlayPane","CFBundleName":"PlayPane","CFBundleDisplayName":"PlayPane","CFBundlePackageType":"APPL","CFBundleVersion":"1","CFBundleShortVersionString":"0.1.0","LSMinimumSystemVersion":"14.0","NSHighResolutionCapable":True,"NSCameraUsageDescription":"PlayPane uses your selected HDMI capture device to show console video on your Mac.","NSMicrophoneUsageDescription":"PlayPane uses the selected USB capture card audio input to play console sound through your Mac output. It does not record or use the built-in microphone."}; (Path(sys.argv[1])/"Contents/Info.plist").write_bytes(plistlib.dumps(info))' "$APP"
codesign --force --sign - "$APP"
codesign --verify "$APP"
printf 'Built local development app: %s/%s\n' "$PWD" "$APP"
