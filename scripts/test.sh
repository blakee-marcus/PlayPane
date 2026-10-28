#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
swiftc -swift-version 6 -warnings-as-errors -parse-as-library \
  Sources/PlayPane/Capture/CaptureState.swift \
  Tests/PlayPaneTests/CaptureCoordinatorTests.swift \
  -o .build/CaptureCoordinatorTests
.build/CaptureCoordinatorTests
swift build -Xswiftc -warnings-as-errors
