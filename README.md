# PlayPane

**Your console. Your Mac.**

PlayPane is an open-source, native macOS app intended to turn a MacBook into a display for a game console using a USB HDMI capture card. Built with SwiftUI and AVFoundation, it aims to provide a focused, lightweight alternative to opening OBS just to play.

> **Status: pre-alpha / not yet implemented.** There is no playable build or download yet. PlayStation 5 is the first validation target; Xbox, Switch, and additional capture cards are *not yet tested*. Performance claims will be published only after hardware measurements.

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

There is not yet an Xcode project. The first implementation milestone is [a running Mac app that displays the PS5 feed](https://github.com/blakee-marcus/PlayPane/issues). See [contributing](CONTRIBUTING.md), [validation approach](docs/VALIDATION.md), and [engineering guidance](AGENTS.md).

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
