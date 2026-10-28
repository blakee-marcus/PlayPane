# PlayPane

**Your console. Your Mac.**

PlayPane is an open-source, native macOS app intended to turn a MacBook into a display for a game console using a USB HDMI capture card. Built with SwiftUI and AVFoundation, it aims to provide a focused, lightweight alternative to opening OBS just to play.

> **Status: pre-alpha / real PS5 playback exercised.** The native app displays live PS5 video and supports native fullscreen with hidden gameplay controls. The local tester confirmed audible game audio synchronized through fullscreen transitions. This is qualitative hardware evidence, not a measured latency or stability certification. Extended stability, physical recovery, and broader compatibility remain unverified. There is no published release/download.

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
5. Select the USB video device in PlayPane and connect it. Then use **Audio → Start Game Audio** for capture-card sound.

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

# Build an ad-hoc-signed local development app with camera/microphone purpose metadata
bash scripts/build-app.sh
open .build/PlayPane.app
```

The Command Line Tools route was exercised. Full Xcode is not installed on the development Mac, so an Xcode build remains unverified. With Xcode installed, open `PlayPane.xcodeproj` and run the `PlayPane` scheme, or use:

```bash
xcodebuild -project PlayPane.xcodeproj -scheme PlayPane -configuration Debug build
```

The shared scheme builds/runs the application; it does not yet contain an XCTest target. This Mac's Command Line Tools do not provide `XCTest` or `Testing`, so `scripts/test.sh` compiles and executes standalone assertions against the production state model instead of claiming `swift test` support. These checks do not validate capture hardware.

The local app asks you to continue to the native camera permission prompt. Granting permission is your choice. After permission, choose **Connect** or select the USB device from the Device menu. Received frames do not prove a valid HDMI signal: some cards generate their own no-signal image.

### Fullscreen and controls

- Use the standard green window button or **View → Enter Full Screen** (`⌃⌘F`). macOS owns the fullscreen Space and exit behavior; PlayPane does not create a borderless imitation.
- Video uses aspect-fit, not fill/crop. A 16:9 console source retains its ratio with black letterboxing/pillarboxing as needed.
- Device/audio/help toolbar items hide during healthy gameplay. Use **View → Show Controls During Gameplay** (`⌥⌘T`) to keep them visible. Setup and recovery keep controls available.
- **Device**, **Audio**, and **Help** remain in the menu bar when gameplay controls are hidden. In fullscreen, move to the top edge to reveal the native menu bar.
- Fullscreen, layout, and controls have no capture/audio-session ownership. Native preview identity and coordinator generations are covered by regression checks.

The fullscreen development build is `.build/fullscreen-milestone/PlayPane.app`. See [fullscreen evidence and limits](docs/FULLSCREEN_VALIDATION.md). The final suite has 63 passing standalone assertions, including native view/layout/recomposition checks—not just value-model tests.

### Game audio

Use **Audio → Start Game Audio** after video is connected. If microphone access is needed, the app explains why before you explicitly choose **Allow Capture Audio…** and answer the native prompt. This permission is for the capture card's audio input, not the built-in microphone.

- Video and audio are discovered independently. The observed MACROSILICON card presents `USB Video` and `USB Digital Audio` with different IDs.
- One unambiguous match using observed USB location and vendor/product identifiers can preselect the audio input. Unknown or ambiguous hardware requires an explicit USB source choice. The app never falls back to a built-in microphone or changes the system microphone.
- Playback uses `AVCaptureAudioPreviewOutput` with **System Default** routing. The observed default output was **External Headphones**. Initial monitoring gain is 50%; mute/unmute changes preview volume without rebuilding the audio session. Normal Mac output volume remains yours to control.
- The Audio menu and **Audio Status and Help…** provide source selection, start/stop, mute, scan, permission guidance, and status. No custom audio engine, recording, or streaming is introduced.
- Sample delivery, real audibility, and A/V synchronization are separate evidence. The attached card advertises 96 kHz mono to AVFoundation; pitch, channel content, and sound quality still need a listening check.

To build without replacing an existing running bundle:

```bash
bash scripts/build-app.sh .build/audio-milestone/PlayPane.app
# Quit the previous app before opening the updated build.
open .build/audio-milestone/PlayPane.app
```

Local ad-hoc development signatures may require permissions again after rebuilding. The local tester has now confirmed audible, synchronized PS5 audio through fullscreen transitions; measured A/V offset, listening duration, output-switching coverage, and extended stability remain unverified. See [game-audio validation](docs/GAME_AUDIO_VALIDATION.md). Output-device selection, monitoring-volume UI, and saved preferences are tracked separately in [Audio Settings #9](https://github.com/blakee-marcus/PlayPane/issues/9); baseline audible playback remains [#3](https://github.com/blakee-marcus/PlayPane/issues/3).

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
