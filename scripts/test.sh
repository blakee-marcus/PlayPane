#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
swiftc -swift-version 6 -warnings-as-errors -parse-as-library \
  Sources/PlayPane/Capture/CaptureState.swift \
  Tests/PlayPaneTests/CaptureCoordinatorTests.swift \
  -o .build/CaptureCoordinatorTests
.build/CaptureCoordinatorTests
for TEST in GameAudioStateTests GameAudioCoordinatorTests GameAudioWorkerTests; do
  swiftc -swift-version 6 -warnings-as-errors -parse-as-library \
    Sources/PlayPane/Audio/*.swift \
    "Tests/PlayPaneTests/$TEST.swift" \
    -o ".build/$TEST"
  ".build/$TEST"
done
swiftc -swift-version 6 -warnings-as-errors -parse-as-library \
  Sources/PlayPane/Capture/*.swift Sources/PlayPane/Audio/*.swift \
  Sources/PlayPane/Views/*.swift Tests/PlayPaneTests/CaptureStageTests.swift \
  -o .build/CaptureStageTests
.build/CaptureStageTests
swift build -Xswiftc -warnings-as-errors
