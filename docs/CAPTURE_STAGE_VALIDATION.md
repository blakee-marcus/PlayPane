# CaptureStage validation record

> **Historical first-milestone snapshot.** Later work observed real moving PS5 imagery and native fullscreen, with user-confirmed synchronized audio. See [fullscreen validation](FULLSCREEN_VALIDATION.md) for current evidence and remaining limits. The original table below is retained as the initial permission-gated record, not a claim that playback is still unobserved.

## Scope and current status

This milestone covers native windowing, external capture-device selection, camera authorization, video preview, and basic failure/recovery. Game audio, recording, streaming, advanced format controls, custom fullscreen controls, and an end-to-end latency benchmark are excluded.

**Status: partial implementation.** The Swift 6 app builds with warnings treated as errors, the signed local development bundle launches, and the native window lists the attached `USB Video` device. Verification is paused at the app's camera-access explanation; no system permission was granted by automation and actual PS5 playback remains unverified. State-model assertions are not physical-device tests.

Canonical interaction requirements: [PlayPane design bible](PlayPane_Design_Bible.md). Broader hardware and latency protocol: [VALIDATION.md](VALIDATION.md).

## Observed development environment

Recorded through `sw_vers`, `swift --version`, `xcode-select -p`, and `system_profiler SPHardwareDataType SPCameraDataType -json`:

| Field | Observation |
| --- | --- |
| Mac | MacBook Air, Mac16,12, Apple M4, 24 GB memory |
| macOS | 26.1, build 25B78 |
| Swift | Apple Swift 6.2.4; arm64-apple-macosx26.0 target |
| Developer directory | `/Library/Developer/CommandLineTools` |
| Full Xcode | Not installed at initial inspection; `xcodebuild -version` reports that full Xcode is required |
| OS-visible external camera | `USB Video`, `UVC Camera VendorID_21325 ProductID_8457` |
| Other OS-visible cameras | MacBook Air Camera; OBS Virtual Camera |
| Capture card commercial make/model | Unknown; do not infer from its generic USB name |
| USB connection route | Not yet documented |
| PS5 connection / source image | Not yet observed |
| Active PlayPane capture format | Not yet measured |

A device appearing in `system_profiler` is OS enumeration only, not proof of application detection, HDMI signal, resolution, or FPS.

## Acceptance evidence

| Requirement | Current status | Evidence required |
| --- | --- | --- |
| Builds and launches through Xcode | BLOCKED: full Xcode absent | Actual `xcodebuild` command/result and launched app; keep any Command Line Tools build evidence separate |
| Detects/selects connected USB HDMI capture device | PARTIAL: native selector shows USB Video; capture not started | Actual selection and capture; built-in and virtual cameras excluded |
| Displays actual PS5 gameplay | UNVERIFIED | Observe recognizable console gameplay in the app; neither test images nor a webcam satisfy this |
| Preserves aspect ratio on resize | UNVERIFIED | Resize wide/tall against visible gameplay landmarks; no stretching or default cropping |
| Shows appropriate connection states | PARTIAL: permission explanation observed; seven state assertions pass | Exercise real no-device, connecting, active-frame, interruption, and stalled/disconnected paths |
| Appropriate camera permission and denied guidance | UNVERIFIED | Native permission request and actionable denied UI, with no permission bypass or database edits |
| Unplug does not present stale gameplay as live | UNVERIFIED | Physically unplug during playback; persistent recovery state replaces or obscures stale imagery |
| SwiftUI redraw does not restart capture | UNVERIFIED | Exercise ordinary UI changes; compare session lifecycle observations before/after |
| Native Mac behavior and keyboard accessibility | PARTIAL: native window and accessible controls observed | Exercise focus, shortcuts, VoiceOver, and recovery |
| Documents real hardware path and format | PARTIAL: OS hardware inventory only | Actual build/run commands, capture mode, console source, and observed behavior |

Do not mark a requirement PASS solely because the implementation contains code for it. Controlled-input unit tests must be reported separately from physical-device checks.

## Manual exercise

1. Confirm the PS5 HDMI output is connected to the capture card's HDMI input, and the capture card is connected by USB to the Mac. Record any hub/dock. Do not assume a generic UVC camera is an HDMI card without user confirmation.
2. Build and launch the actual application bundle with an accurate camera purpose string. Request access through the app at the point of use. The user decides native camera permission prompts; do not change TCC databases or silently grant access.
3. Confirm source selection lists the external capture device and does not offer built-in or virtual cameras as the console source. If permission limits enumeration, record that explicitly.
4. Select/connect the device. Record connecting behavior, permission outcome, and whether frames actually arrive. Session `isRunning` alone is not frame evidence.
5. Identify the source visually as actual PS5 content. Check a moving scene and the console UI; a static black image or a capture-card test pattern is not proof of a valid console signal.
6. Resize the native window to wide and tall proportions. Verify letterboxing/pillarboxing and uninterrupted capture. Exercise native fullscreen if available, without adding custom fullscreen controls.
7. Open/close menus and change non-capture UI state. Confirm capture does not restart merely because SwiftUI updates. Use lifecycle evidence rather than inferring stability from a screenshot.
8. Unplug USB during visible gameplay. Confirm stale imagery is not represented as current gameplay. Reconnect and exercise the supported recovery action.
9. Separately interrupt HDMI while leaving USB attached. Record whether the card stops delivering frames or substitutes its own black/blue/no-signal output.
10. Test keyboard operation and meaningful accessibility labels. Record VoiceOver as untested unless actually exercised.

### No-signal detection boundary

UVC frames prove that the device is delivering frames, not that a console is supplying a valid HDMI signal. Some capture cards continue producing black, blue, or branded frames after HDMI loss. A frame-stall watchdog can detect missing frames but cannot universally distinguish those synthetic card-generated images from legitimate game content. Use accurate labels and troubleshooting; do not promise universal HDCP/HDMI detection or classify a black scene as a failure merely from pixel color.

On the inspected macOS SDK, `AVCaptureVideoPreviewLayer` does not provide `isReadyForDisplay`, and its `isPreviewing` property is unavailable on macOS. Do not borrow `AVPlayerLayer` readiness assumptions for capture preview. Validate the implementation's actual frame-observation mechanism independently from session startup.

## Run results

### Exercised locally

- `bash scripts/test.sh`: seven standalone assertions passed, followed by a successful Swift 6 application build with `-warnings-as-errors`.
- Assertions cover frame-driven readiness, idempotent repeated connect, late frames after disconnect, stale callbacks after source change, missing-frame recovery state, resumed-frame recovery, and stale frames after permission denial. They exercise the production `CaptureModel`; they do not exercise AVFoundation hardware, native permissions, or preview rendering.
- `bash scripts/build-app.sh`: built `.build/PlayPane.app`, wrote generated camera purpose metadata, and passed local ad-hoc signature verification.
- `plutil -lint PlayPane.xcodeproj/project.pbxproj` and structural checks of the shared scheme/source references passed. The app bundle camera purpose metadata was verified. This is not a full Xcode build.
- `open -g .build/PlayPane.app`: launched the real native application. App-scoped screenshot/accessibility capture showed its titled window, `USB Video` source selector, **Allow camera access** explanation, **Continue**, and **Connection Help** controls. No simulated video was used.
- Native camera access was not requested/granted by automation. Testing stopped at the contextual explanation, before the native system prompt.
- A background UI attempt to open Connection Help was refused by the desktop driver (`off_space_or_ax_unresolved`); no foreground escalation was performed. Help interaction and keyboard/VoiceOver behavior remain unverified.
- The initial delegated draft was rejected: it had a non-launching entry point, no frame delegate, a dummy test, and unsafe isolation. It was preserved outside the repository before replacement; none of those draft claims count as verification.

### Remaining acceptance work

- Install/open full Xcode separately, then exercise the shared project/scheme. Property-list/XML validation is not an Xcode build.
- User approves the native camera permission prompt and confirms that PS5 gameplay is connected to the detected USB capture device.
- Verify actual moving console imagery, capture format, aspect-preserving resize, fullscreen continuity, hardware unplug/replug, HDMI loss behavior, and native denied-permission recovery.
- Record active format from received frames; no format or FPS has been observed yet.
- Update the acceptance evidence table only from those actual observations.
