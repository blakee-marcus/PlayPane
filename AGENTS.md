# PlayPane — Engineering Instructions

## Mission and boundaries

PlayPane is a **native macOS console-display app**, not a screen recorder or streaming platform. The canonical repository is `blakee-marcus/PlayPane`. The first target is **PS5 → HDMI capture card → USB → MacBook display and audio**.

- Owner of engineering implementation and verification: Coeus when working with the Hermes team.
- Inspect repository state and `git status` before editing; protect dirty work.
- Implement the smallest playable path first. Do not build a second architecture or introduce dependency-heavy frameworks before evidence requires them.
- No streaming, recording, account system, virtual camera, controller remapping, or visual-design framework in the MVP.
- Do not claim low latency, a particular FPS, broad console support, or capture-card compatibility without real measurements.

## Technical defaults (hypotheses, not proven choices)

- Swift + SwiftUI for the window and controls; AppKit interop where native video views demand it.
- AVFoundation for USB Video Class capture discovery and session management.
- Start with `AVCaptureVideoPreviewLayer` as the video baseline. Compare alternatives only when measured latency or frame pacing justifies them.
- Keep capture/session work off the UI thread; reflect state changes safely on the main actor.
- Treat capture-video and capture-audio enumeration as potentially separate device paths; do not assume every card exposes embedded audio under the same device identity.
- Check and request capture permissions intentionally. Supply required privacy usage descriptions and entitlements.
- Maintain explicit states for not connected, permission denied, connecting, displaying, interrupted, and failed, with actionable messages.
- Honor hardware-supported modes; do not silently promise 60 fps from a 30 fps device.

## First acceptance path

1. Xcode builds and launches the macOS target.
2. The app detects a physically connected USB HDMI capture device and distinguishes it from built-in cameras.
3. A real PS5 gameplay signal renders correctly in a resizable Mac window.
4. Moving to fullscreen and back does not break capture.
5. PS5 audio reaches the selected Mac output without recording or streaming.
6. Unplug/replug and permissions-denied paths are observed and correctly explained.
7. Video latency is measured and compared with OBS using the same console, card, format, and test method.

Early iterations can pass a subset, but must report **partial**, not end-to-end complete.

## Verification discipline

- Before claiming success, report the actual build/test command and result, plus the Mac model, macOS version, capture card identifier, active capture format, and real-device behavior.
- Do not treat mock frames, preview-layer initialization, a device-enumeration test, or a successful build as proof that PS5 gameplay is usable.
- Measure end-to-end latency using a common visual stimulus, filmed with a suitable high-frame-rate reference, and report the method and uncertainty. Also record dropped frames and audio behavior.
- Test through the real capture-card → app → screen/speakers path. Compare with OBS using identical source hardware and format.
- Record known failing hardware and conditions, rather than hiding them behind a green status.
- Keep changes scoped to the current issue. Include a concise tested/unverified checklist in each PR.

## Reference

- [Validation protocol](docs/VALIDATION.md)
- [GitHub issues](https://github.com/blakee-marcus/PlayPane/issues)
- [Apple: Capture preview layer](https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer)
- [Apple: Capture authorization on macOS](https://developer.apple.com/documentation/bundleresources/requesting-authorization-for-media-capture-on-macos)
