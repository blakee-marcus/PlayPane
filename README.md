# PlayPane

**Your console. Your Mac.**

PlayPane is an open-source, native macOS app intended to turn a MacBook into a display for a game console using a USB HDMI capture card. Built with SwiftUI and AVFoundation, it aims to provide a focused, lightweight alternative to opening OBS just to play.

> **Status: pre-alpha / partial CaptureStage implementation.** The local SwiftUI app builds and launches, detects the attached USB video device, and presents contextual camera-access guidance. Actual PS5 gameplay, physical unplug/replug recovery, audio, and latency are not yet verified. There is no published release/download. Xbox, Switch, and other capture cards remain untested.

## The idea

```text
PS5 ──HDMI──> USB HDMI capture card ──USB──> MacBook ──> PlayPane
```

A MacBook's HDMI port, when present, is an **output**, not a console video input. A supported USB capture device is required. PlayPane is local capture, not game streaming or PS Remote Play, so the signal path does not depend on your network.

## What we're building first

- A real PS5 video preview in a native macOS window.
- Game audio through the Mac's selected audio output.
- Fullscreen viewing without recording or streaming UI.
- Device selection and clear connection/permission errors.
- Reproducible display-latency and frame-pacing measurements against OBS on the **same** hardware.

The first working build should do one thing well: **let you play using the Mac screen**. Streaming, recording, overlays, accounts, and remote access are out of scope.

## Hardware and setup

**Initial test platform:** Apple Silicon MacBook + a USB Video Class (UVC) HDMI capture device. We will document verified macOS versions, frame rates, and device compatibility as testing progresses.

1. Connect the console's HDMI output to the capture card's HDMI input.
2. Connect the capture card's USB output to your MacBook.
3. On PS5, if capture is black, check **Settings → System → HDMI → Enable HDCP** and disable HDCP for gameplay capture. HDCP-protected content (including many media apps) is not supported.
4. Allow PlayPane camera access when prompted, and microphone/audio-input access if required for the capture device's audio.
5. Select the capture device in PlayPane once a working build exists.

A capture card imposes its own limits. A 30 fps device cannot become 60 fps through software. Resolution, frame rate, USB bandwidth, capture-device buffering, and macOS rendering all affect results.

## Development

- **Language:** Swift
- **UI:** SwiftUI, with AppKit interop where necessary
- **Capture:** AVFoundation
- **Video baseline:** Start with `AVCaptureVideoPreviewLayer` in a native view; profile before investing in custom Metal rendering
- **Audio:** AVFoundation / macOS audio APIs, validated on real capture hardware

The repository includes `PlayPane.xcodeproj` with a shared `PlayPane` scheme and a dependency-free SwiftPM executable. Minimum target: macOS 14; source compiles in Swift 6 mode.

```bash
# Controlled-input state assertions plus a warnings-as-errors app build
bash scripts/test.sh

# Build an ad-hoc-signed local development app with camera purpose metadata
bash scripts/build-app.sh
open .build/PlayPane.app
```

The Command Line Tools route was exercised. Full Xcode is not installed on the development Mac, so an Xcode build remains unverified. With Xcode installed, open `PlayPane.xcodeproj` and run the `PlayPane` scheme, or use:

```bash
xcodebuild -project PlayPane.xcodeproj -scheme PlayPane -configuration Debug build
```

The shared scheme builds/runs the application; it does not yet contain an XCTest target. This Mac's Command Line Tools do not provide `XCTest` or `Testing`, so `scripts/test.sh` compiles and executes standalone assertions against the production state model instead of claiming `swift test` support. These checks do not validate capture hardware.

The local app will ask you to continue to the native camera permission prompt. Granting permission is your choice. After permission, choose **Connect** or select the USB device from the Device menu. This milestone has no game audio. Received frames do not prove a valid HDMI signal: some cards generate their own no-signal image.

See [CaptureStage evidence](docs/CAPTURE_STAGE_VALIDATION.md), [contributing](CONTRIBUTING.md), [validation approach](docs/VALIDATION.md), and [engineering guidance](AGENTS.md).

## Roadmap

Development is tracked in [GitHub Issues](https://github.com/blakee-marcus/PlayPane/issues). Priorities are:

1. First live video frame on macOS
2. Working game audio
3. Fullscreen display and minimal controls
4. Measured latency / frame pacing against OBS
5. Recovery, device compatibility, and a repeatable release process

Issue descriptions define what must be demonstrated before a milestone can be called complete.

## Contributing

Bug reports, capture-card compatibility results, and focused pull requests are welcome. Please include macOS version, Mac model, capture card, observed input format, and a reproducible test path. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 Blake Marcus.
