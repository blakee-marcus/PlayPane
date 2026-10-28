# Native fullscreen and unobtrusive controls — issue #4

## Result and evidence limits

**Implemented and exercised with the real PS5 capture feed.** The existing standard macOS `Window` remains in charge of fullscreen. A new shared presentation preference hides gameplay toolbar items by default and exposes them through native menu commands. No custom fullscreen window, borderless replacement, capture restart, or audio-session reconfiguration is added.

Blake explicitly authorized relaunching the app and entering/exiting a fullscreen Space. Native screenshots showed recognizable moving Fortnite lobby content, including different animation poses and advancing countdown text. This is real console imagery, not a test feed. In the final build, pressing the standard green window button entered fullscreen with the complete picture visible and black letterboxing. The native View menu contained exactly **one** `Exit Full Screen` entry.

Blake subsequently answered the listening check: **“Audible and in sync, including fullscreen transitions.”** This establishes user-observed audibility and qualitative synchronization; it is not an instrumented A/V-offset or latency measurement. Issues #3 and #4 have not been closed or modified remotely.

## Changes

- `Sources/PlayPane/Views/CaptureStageView.swift`: app-owned presentation preference, conditional gameplay toolbar content, explicit preview expansion, and menu-accessible shared Connection Help state. Setup/video recovery keeps controls available. Audio failures reveal the toolbar without putting an automatic error panel over live video.
- `Sources/PlayPane/PlayPane.swift`: owns the presentation model once, preserves standard titled/resizable native window behavior, adds View → Show Controls During Gameplay (`⌥⌘T`) and native Help actions. Existing Device and Audio menus remain available when the toolbar is hidden. macOS supplies its own Enter/Exit Full Screen command and `⌃⌘F`.
- `Tests/PlayPaneTests/CaptureStageTests.swift`: real native preview layout/identity and mounted SwiftUI recomposition checks, plus controls/recovery policy assertions.
- `scripts/test.sh`: executes the native stage assertion harness.
- `CapturePreviewView.swift`, `CaptureCoordinator.swift`, `CaptureState.swift`, and the entire audio implementation are unchanged from the pre-fullscreen working-tree baseline. Preview gravity was already `.resizeAspect`; keeping it preserves native source aspect instead of stretching or filling/cropping. A 16:9 source is letterboxed/pillarboxed when the available area differs. Other aspect ratios are preserved rather than forced into 16:9.

## Exercised build and tests

```bash
bash scripts/test.sh
bash scripts/build-app.sh .build/fullscreen-milestone/PlayPane.app
codesign --verify .build/fullscreen-milestone/PlayPane.app
plutil -lint PlayPane.xcodeproj/project.pbxproj
git diff --check
```

- Final suite: **63 unique passing assertions** (48 prior video/audio checks plus 15 native-stage checks). Swift 6 app build passes with warnings treated as errors.
- Stage tests mount the production SwiftUI view with its production coordinators without opening capture inputs or requesting permissions. Three control-driven root recompositions preserve the same native preview, video session, video generation, and audio generation. No input or output is configured by layout/control changes.
- Native preview geometry was exercised at 960×540, 1280×800, 1920×1080, 2560×1080, and 480×700. The same preview layer/session remains attached, the layer follows the container bounds, and gravity stays `.resizeAspect`. These tests do not manufacture video frames or prove audible hardware output.
- The first controls-policy test failed before implementation. UI QA also caught two native fullscreen menu entries in an initial candidate. Removing the redundant custom command and its unnecessary window observer reduced the implementation; final native menu readback verified one command. The earlier 66-assertion exploratory suite included window-observer tests that were replaced by the smaller 63-assertion final suite.
- Final app launched from `.build/fullscreen-milestone/PlayPane.app`; exact process-path readback verified PID 16063 at that time. The process was still running at the last read-only check. No commit/push, deployment, system permission change, or system input/output configuration change was performed.

## Physical UI observations

1. Prior running build showed the real PS5 feed and `Audio: Monitoring game audio`.
2. Initial fullscreen candidate: `⌃⌘F` entered and exited native fullscreen; moving game content continued. `⌥⌘T` revealed device/audio/help controls while fullscreen, and the audio control still reported monitoring.
3. Final reduced build: moving PS5 feed visible in a native window with gameplay controls hidden. The standard green button entered native fullscreen. Subsequent screenshot showed a different game pose/countdown, intact outer game UI, black letterboxing, and no persistent gameplay toolbar.
4. Final native accessibility tree retained Device and Audio menus, source selection, audio help, the controls preference, and one system fullscreen command. Menu presence is verified; full keyboard navigation and VoiceOver traversal are not claimed.
5. Background automation later refused an Audio menu interaction and fullscreen-exit shortcut because the menu/window could not be resolved on the current Space. The requested foreground shortcut timed out without consent. It was not retried or replaced with another exit action. Final live visual verification is therefore green-button entry; the exit observation is from the earlier candidate, with Blake separately confirming audio synchronization through transitions. Later exact-window capture returned no on-screen surface while the process remained running; no Space change was forced.

## Environment and hardware

- MacBook Air `Mac16,12`, Apple M4, 24 GB RAM.
- macOS 26.1, build 25B78; Apple Swift 6.2.4, Swift 6 mode, macOS 14 deployment minimum.
- Command Line Tools build path; full Xcode build remains unverified.
- Capture identity previously observed: `USB Video`, MACROSILICON VID `0x534d` / PID `0x2109`; separate `USB Digital Audio` endpoint. Commercial capture-card model and hub/cable route remain undocumented.
- Read-only native audio discovery in this round reported System Default as **MacBook Air Speakers**. Blake confirmed audible synchronized output, but did not separately identify the listening route or duration. Do not extrapolate this into a verified headphone/speaker switching matrix.
- Captured sample dimensions/frame cadence were not collected during this round. Screenshot aspect-fit and a source-level default do not establish actual capture resolution or FPS.

## Remaining checks / next milestone

- Extended real gameplay stability, measured A/V offset, physical reconnect/error paths, broader aspect/monitor configurations, and full VoiceOver/navigation remain separate checks.
- No zero-drop/zero-blank-frame transition measurement or session-start counter trace was collected; source/lifecycle regression evidence and live picture observations must not be described as such a measurement.
- Next priority is [issue #5](https://github.com/blakee-marcus/PlayPane/issues/5): compare PlayPane and OBS using the same PS5, capture card, capture mode, output display, and visible stimulus. Film a suitable common reference and report distributions/uncertainty, not guessed milliseconds. No Marvel Rivals responsiveness claim is made here.
