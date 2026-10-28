---
title: PlayPane — Design Bible
aliases:
  - PlayPane Design System
  - PlayPane Human Interface Guide
type: design-bible
project: PlayPane
platform: macOS
status: proposed
authority: Apple Human Interface Guidelines + PlayPane product decisions
created: 2026-10-27
version: 1.0
tags:
  - playpane
  - macos
  - swiftui
  - design-system
  - ux
  - hig
---

# PlayPane — Design Bible

> [!abstract] The product in one sentence
> **Your console. Your Mac.** PlayPane turns a MacBook into a focused display for a console connected through a USB HDMI capture device. The gameplay image—not the app's interface—is the main event.

**Project:** [blakee-marcus/PlayPane](https://github.com/blakee-marcus/PlayPane)  
**Audience:** MacBook owners playing PS5 (initially), and later users of other consoles where hardware compatibility is demonstrated.  
**Scope:** Native macOS application, SwiftUI + AVFoundation, focused on previewing console video and audio.  
**Status:** Design specification, **not** an assertion that the application or device support has shipped.

> [!important] How to use this bible
> **Apple HIG guidance** below describes principles from the linked Apple references; **PlayPane rule** is our project-level interpretation. Proposed interaction thresholds, copy, layout, and feature priorities are *design decisions*, not Apple mandates. When an implementation choice conflicts with the latest platform behavior, prefer working native macOS behavior and document the deviation. This file does not replace capture-framework documentation or real-device validation.

## 1. North star and decision hierarchy

**Primary user job:** Connect a console via a supported capture card, open PlayPane, and see and hear gameplay on the MacBook screen with as little friction as possible.

**Emotional goal:** *Calm confidence.* The app feels ordinary and dependable, almost invisible. It should not look like an RGB gaming control panel or a broadcast production suite.

### Principles, in order

1. **The image wins.** Avoid UI that steals space, attention, input focus, or rendering resources from the live feed.
2. **Working video before polish.** A playable image and audible game are the first milestone, not an elaborate shell.
3. **Native is the design language.** Standard Mac windows, menu bar, dialogs, keyboard shortcuts, controls, appearance, and accessibility behavior.
4. **Truth over promises.** Show actual capture-card modes and real connection states; never advertise 60 fps or low latency from unsupported or unmeasured hardware.
5. **Immediate recovery.** When hardware or permission fails, explain what happened and offer the next relevant action.
6. **Expert capability without complexity.** Automatic sensible defaults; advanced settings only when tested hardware demonstrates a need.
7. **Privacy by construction.** Local live preview; do not imply recording, cloud uploads, or access to unrelated devices.

Apple's [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles) name **Purpose, Agency, Responsibility, Familiarity, Flexibility, Simplicity, Craft, and Delight**. In PlayPane: purpose means *play*, agency means *control the display and recover*, responsibility means *honest permissions and capability labels*, familiarity means *macOS conventions*, flexibility means *windowed and fullscreen use*, simplicity means *no unnecessary panels*, craft means *smooth dependable capture*, and delight means *getting into the game without friction*. The eight named principles are source-derived; their mapping to PlayPane is a product decision.

### Anti-goals

- **Not OBS Lite:** no scenes, streaming, capture recording, broadcast audio mixers, or virtual cameras in MVP.
- **Not a console emulator or remote-play client:** no wireless game streaming or PS5 input forwarding.
- **Not a native game:** the controller remains connected to the console; PlayPane manages the *viewer*.
- **Not an Apple imitation:** use system controls rather than reproducing proprietary Apple screens or branding.
- **Not a benchmark claim:** end-to-end HDMI-to-screen latency must be physically measured before marketing comparisons.

---

## 2. The Apple HIG, applied to PlayPane

The five HIG areas provided in the brief are useful as **design lenses**, not five separate user-facing sections in the app.

| HIG area | Key references | PlayPane application |
| --- | --- | --- |
| **Foundations** | [Foundations](https://developer.apple.com/design/human-interface-guidelines/foundations), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), [Color](https://developer.apple.com/design/human-interface-guidelines/color), [Materials](https://developer.apple.com/design/human-interface-guidelines/materials) | Semantic system colors, SF Symbols, legible overlays, light/dark/high-contrast support, understated app identity. |
| **Patterns** | [Patterns](https://developer.apple.com/design/human-interface-guidelines/patterns), [Going full screen](https://developer.apple.com/design/human-interface-guidelines/going-full-screen), [Live-viewing apps](https://developer.apple.com/design/human-interface-guidelines/live-viewing-apps), [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback), [Settings](https://developer.apple.com/design/human-interface-guidelines/settings) | Instant media focus, native fullscreen, contextual status/recovery, minimal settings. |
| **Components** | [Components](https://developer.apple.com/design/human-interface-guidelines/components), [Windows](https://developer.apple.com/design/human-interface-guidelines/windows), [Menus](https://developer.apple.com/design/human-interface-guidelines/menus), [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars) | Standard title bar, system menu commands, source picker, native buttons, concise popovers. |
| **Inputs** | [Inputs](https://developer.apple.com/design/human-interface-guidelines/inputs), [Keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards), [Pointing devices](https://developer.apple.com/design/human-interface-guidelines/pointing-devices) | Keyboard and pointer access to all viewer commands; preserve OS shortcuts; no mouse-only gestures. |
| **Technologies** | [Technologies](https://developer.apple.com/design/human-interface-guidelines/technologies), [Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy), [AVFoundation documentation](https://developer.apple.com/documentation/avfoundation) | Appropriate permission prompts, direct capture, macOS API integration. Technology hub is not itself a capture API specification. |

**Mac-specific authority:** Apple's [Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos) describes a flexible, keyboard-and-pointer-driven environment with resizable windows, fullscreen, a menu bar, and simultaneous app use. These are **requirements for feeling like a Mac app**, not optional decoration.

### Resolving HIG tradeoffs

- **Live-viewing guidance** favors fast access to live content. But a console capture preview is **not** television programming. Apply content primacy and immediate playback, **not** channel guides, timelines, Record buttons, or VOD controls.
- **Materials guidance** favors clear separation between content and interactive layers. Use system materials in native controls; **do not turn the gameplay image into a blurred/glass panel**.
- **Accessibility guidance** prioritizes legibility and recoverability over decorative auto-hiding. Immersive viewing is compatible with an accessible menu bar and reliable way to reveal controls.
- **macOS control sizing** is generally denser than touch platforms. Apple's accessibility guidance describes macOS default control size around **28×28 pt** and a platform minimum of **20×20 pt**; PlayPane should prefer native size in standard settings and more generous hit regions for floating in-video controls. Do not indiscriminately apply iPhone-sized touch UI.

---

## 3. Information architecture

There is **one main window** and at most **one Settings window** in MVP. No sidebar, tab bar, dashboard, library, or permanent inspector.

```text
PlayPane
├── Main window
│   ├── Content stage: live video / contextual empty state / error
│   ├── Native title bar and window controls
│   └── Lightweight, on-demand viewing controls
├── macOS menu bar
│   ├── PlayPane: About, Settings…, Quit
│   ├── File: no invented file actions
│   ├── View: Enter/Exit Full Screen, Show/Hide Controls
│   ├── Device: select source, Reconnect (only when supported)
│   ├── Window: standard window commands
│   └── Help: connection help, report issue, About/Support
└── Settings (only as needs become real)
    ├── General: startup/reconnection behavior (if needed)
    └── Advanced: validated device/format overrides (later)
```

**PlayPane rule:** Put frequently used actions beside the viewer; infrequently used configuration belongs in **PlayPane → Settings… (⌘,)**. Every toolbar action must also be available in the menu bar. The menu bar is the accessible fallback when floating controls are hidden. See [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars), [Menus](https://developer.apple.com/design/human-interface-guidelines/menus), and [Settings](https://developer.apple.com/design/human-interface-guidelines/settings).

### Window behavior

- Create a **standard titled, resizable, movable macOS window** with native traffic-light controls and normal activation behavior.
- Preserve video aspect ratio. When window proportions differ from the capture image, **letterbox/pillarbox** instead of stretching or cropping by default.
- Use a plain black (or near-black) *video canvas* for unused letterboxed space; the rest of the app follows system appearance.
- Let the system handle entering and leaving fullscreen, including the camera-housing/safe region; do not synthesize a borderless fake fullscreen window.
- The standard fullscreen command uses **Control–Command–F** where the system provides it. The green window control remains available.
- Do not change display resolution, refresh rate, or monitor arrangement merely because fullscreen is entered.
- Window resize and focus changes must not stop the feed; don't unnecessarily recreate the capture session.
- When closed/reopened, a safe preferred-size window is fine; persist its last sensible size if reliable. Avoid surprising automatic fullscreen on first launch.

Sources: [Windows](https://developer.apple.com/design/human-interface-guidelines/windows), [Going full screen](https://developer.apple.com/design/human-interface-guidelines/going-full-screen), [Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos).

---

## 4. Main window anatomy

### 4.1 First launch / disconnected

```text
┌─────────────────────────────────────────────────────────────┐
│ ● ● ●   PlayPane                                           │  native title bar
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                                                             │
│               [external-display symbol]                     │
│               Connect a capture card                        │
│       Plug a USB HDMI capture card into your Mac.           │
│          Then connect your console by HDMI.                 │
│                                                             │
│               [Choose Capture Device…]                      │
│                    Connection Help                          │
│                                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

The button can select a recognized capture device; if there is none, show **Scan Again** or **Connection Help** as appropriate. Don't show a disabled fake Connect button if the actual path is automatic.

### 4.2 Active gameplay, windowed

```text
┌─────────────────────────────────────────────────────────────┐
│ ● ● ●   PlayPane — [Capture Card]                 [Controls]│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                 LIVE CONSOLE VIDEO                          │
│                                                             │
│        Video takes all available content space.             │
│        No permanent overlay on the game HUD.                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Priority:** video pixels → persistent system frame → optional controls. Status metadata can be accessed through **Device → Device Information** or a small popover rather than a permanent overlay.

### 4.3 Fullscreen

- Render the video in the system fullscreen window with correct aspect ratio.
- Keep controls out of view during normal play. A pointer movement, explicit **Show Controls** command, or another documented mechanism should reveal necessary controls.
- Don't hide a blocking failure: if the capture feed stops, show a persistent contextual recovery message instead of uninterrupted black.
- Do not use a timed toast for actions whose result is important or whose controls must remain available for assistive technology.
- Cursor hiding is **optional** and must never remove the user's ability to restore system controls; investigate native behavior before implementing custom pointer timers.

> [!note] Proposed overlay treatment
> If an overlay proves necessary in fullscreen, use a **small native-looking floating control group** against the video. Prefer system material and appropriate contrast; on bright footage, a translucent/dim backing is safer than unprotected white symbols. Apple's [Materials](https://developer.apple.com/design/human-interface-guidelines/materials) describes regular versus clear Liquid Glass. Use the system-provided appearance wherever possible, and respect Reduce Transparency.

---

## 5. Core user journeys

### Journey A — first playable frame

1. User opens PlayPane. The app discovers candidate UVC devices without requiring a separate project or setup wizard.
2. If a single previously chosen capture source is available and authorized, **attempt to show its live image directly**.
3. If permission is needed, explain why in context, then invoke the **system permission prompt**.
4. When multiple devices are available, show recognizable device names in a **Choose Capture Device** pop-up or menu.
5. Show a useful **Connecting to [device]…** state while starting the session; replace it as soon as frames arrive.
6. If frames arrive, video occupies the stage. Audio starts when the capture path supports it and is ready.
7. If frames do not arrive, show **No video signal** with card/HDMI/HDCP troubleshooting rather than an endless spinner.

**Do not:** require an account, present a multi-page onboarding carousel, or force people to select resolution/FPS before a working preview exists. Apple's [Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding) favors short optional guidance; [Loading](https://developer.apple.com/design/human-interface-guidelines/loading) favors immediate feedback.

### Journey B — switch devices

1. Open **Device → Capture Device** (or the equivalent compact source picker).
2. Show device names and a checkmark for the current source.
3. Choose another device; preserve the window and show a connecting state.
4. If it fails, say why and offer the previous known-good source when possible.

**Never** imply another device supports a mode until the API enumerates it and it is tested.

### Journey C — interruption and recovery

1. If USB is unplugged, report **Capture card disconnected** promptly.
2. Pause/stop the relevant output safely, with no misleading frozen image presented as live.
3. On reconnect, attempt a bounded recovery or provide **Reconnect**.
4. If the card appears under a new OS identity, match cautiously; don't assume the string identity remains stable after a hub change.
5. Restore live video and audio; only then clear the failure state.

### Journey D — quick fullscreen

1. Choose **View → Enter Full Screen**, green traffic-light control, or native shortcut.
2. Video remains uninterrupted, correctly scaled, with system safe area respected.
3. Reveal accessible controls, switch app, and return without the capture session restarting unnecessarily.
4. Exit via native fullscreen mechanism; window geometry and feed remain sound.

---

## 6. Capture-state model and user-visible copy

**Design requirement:** the UI must describe the *current real state*, not a hoped-for state. These are product states, not an imposed AVFoundation enum.

| State | Stage presentation | Suggested user text | Action |
| --- | --- | --- | --- |
| No device | Calm empty canvas + source icon | **Connect a capture card** · Connect a USB HDMI capture device to your Mac. | **Connection Help** / **Scan Again** |
| Permission required | Contextual explanation | **Allow camera access** · PlayPane needs access to the capture card’s video feed. | **Continue** → system prompt |
| Permission denied | Persistent contextual state | **Camera access is off** · Enable PlayPane in System Settings → Privacy & Security → Camera. | **Open System Settings** (when supported) |
| Connecting | Small indeterminate activity indicator | **Connecting to [device]…** | **Cancel** only if connection is cancellable |
| Device ready, no signal | Dark stage; no fake video | **No video signal** · Check the HDMI cable, console output, and capture-card input. | **Troubleshoot** / **Reconnect** |
| Live video, audio pending | Live video, subtle nonblocking notice if needed | **Waiting for game audio** | **Audio Help** / choose supported input |
| Playing | Video-first UI | Avoid a permanent **LIVE** banner; the actual image communicates state. | On-demand controls |
| Device lost | Persistent state, not a toast | **Capture card disconnected** · Reconnect the device to resume. | **Reconnect** |
| Unsupported mode | Clear explanatory state | **This video format isn’t supported** · Choose another output format on your console or capture card. | **Device Settings** / **Help** |
| Unrecoverable error | Contextual, specific failure | **Couldn’t start video capture** · [Accurate reason, if known.] | **Try Again** / **View Details** |

**Error-message formula:** **what happened** → **what to do now** → **technical detail on demand**. Avoid raw OSStatus numbers in the primary message; provide them in copyable diagnostics. Avoid accusatory wording. Use an interrupting alert only if a genuinely critical, actionable decision requires immediate attention; ordinary capture errors belong **in the stage**. Sources: [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback), [Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts), [Loading](https://developer.apple.com/design/human-interface-guidelines/loading).

### PS5-specific helper copy

> **Black screen?** The PS5 may be using HDCP. For gameplay capture, check **Settings → System → HDMI → Enable HDCP** on your console. HDCP-protected media may not be capturable. Also confirm the HDMI cable is connected to the capture card's **input**.

This is **device troubleshooting guidance**, not a requirement of Apple's HIG. Keep it in Help or a contextual **No video signal** detail, not as a permanent warning on every launch.

---

## 7. Components and interactions

| Need | Preferred native component/pattern | Rule / avoidance |
| --- | --- | --- |
| Select capture source | SwiftUI `Picker` in menu/pop-up form, or native menu | Show actual devices; identify selected source. No giant cards. |
| Begin/retry capture | `Button` | Clear verb: **Reconnect**, **Try Again**. Disable only when action truly unavailable. |
| Fullscreen | Native window control + View menu command | Do not invent a custom fullscreen implementation. |
| Show/hide viewing controls | View menu toggle, optional compact control | State-specific label and predictable reveal. |
| Audio output | Prefer macOS standard output routing; add in-app choice only if supported and necessary | Don't promise routing to hardware not actually enumerated. |
| Audio mute | Native `Toggle`/button with correct pressed/checked state | Clearly distinguish **Mute Game Audio** from macOS system volume. |
| Mode selection (later) | Compact `Picker` with supported device formats | Format labels reflect actual active FPS/resolution. Never show imaginary presets. |
| Technical details | Popover or small nonmodal inspector | Device, resolution, frame rate, USB path for troubleshooting; avoid game-overlay clutter. |
| Advanced configuration | macOS Settings scene | No fullscreen settings dashboard; no gear in every corner. |
| Help | Help menu and contextual link | Open the relevant hardware/permission instructions. |

Use **system** buttons to gain pressed, hover, disabled, focus, accessibility, and material behavior automatically. A custom control must recreate these states correctly. Text labels are preferable when icon semantics aren't universally clear. Sources: [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons), [Menus](https://developer.apple.com/design/human-interface-guidelines/menus), [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars).

### Menu and keyboard contract

**Expected base commands** (verify actual framework behavior; do not create duplicate shortcuts):

| Command | Placement | Shortcut |
| --- | --- | --- |
| Settings… | PlayPane menu | **⌘,** |
| Quit PlayPane | PlayPane menu | **⌘Q** |
| Enter/Exit Full Screen | View menu | Native **⌃⌘F** where available |
| Show/Hide Controls | View menu | No custom shortcut in MVP unless user testing shows value |
| Select Capture Device | Device menu | No custom shortcut needed |
| Reconnect | Device menu | Assign later only if proven frequent |
| Connection Help | Help menu | Menu item; accessible without hidden overlay |

Respect **Escape** for dismissal/return where appropriate, but avoid hijacking it to close the entire app. Preserve platform-standard keyboard shortcuts and text/VoiceOver focus behavior. **The PS5 controller should continue controlling the PS5**, not a shadow set of PlayPane menus. Source: [Keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards).

---

## 8. Visual system: restraint as a feature

### Color and surfaces

**System chrome:** Prefer semantic SwiftUI/AppKit colors and system materials. Do not hard-code Apple system color hex values: they change across appearances, contrast settings, and OS versions. See [Color](https://developer.apple.com/design/human-interface-guidelines/color).

| Semantic role | Design token (conceptual) | Behavior |
| --- | --- | --- |
| Video stage | `stage.background` | Solid black or near-black behind video (not a forced dark app theme). |
| Primary text | `text.primary` | System primary label color; adapts to appearance. |
| Supporting text | `text.secondary` | System secondary label; retain readability. |
| Dividers | `border.separator` | System separator where needed, never decorative grid lines. |
| Primary action | `action.accent` | Use user's macOS accent preference; do not flood UI with color. |
| Success/ready | `state.ready` | Status text/symbol plus semantic color only when useful. |
| Warning/recovery | `state.warning` | Plain-language status with icon; never rely on color alone. |
| Failure | `state.error` | Error text with actionable recovery, not pulsing red. |
| Floating control backing | `surface.controls` | Native system material if needed, with a dimming treatment over bright footage. |

**Brand recommendation:** PlayPane's brand can lean toward soft silver/blue-white with a restrained cyan accent in marketing assets and the app icon. **This is a PlayPane art direction, not an Apple requirement.** Let the live gameplay supply most of the visual color.

### Typography

- Use the system font through native SwiftUI text styles. Never ship an embedded typeface just to imitate Apple's system font.
- The viewer needs very little text. Prefer a short title, one-line supporting instruction, and a clear action.
- Avoid all-caps tracking, neon/glow labels, aggressive gradients, or exaggerated title scale in utility states.
- Prefer native text wrapping and layout adaptation. Device names and localized strings must not truncate essential error details.
- Preserve system accessibility contrast and appearance choices. Source: [Typography](https://developer.apple.com/design/human-interface-guidelines/typography), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).

### Icons and SF Symbols

- Prefer SF Symbols for common interface concepts (display, cable, speaker, fullscreen, connection failure), with actual symbols verified in the installed SF Symbols catalog and targeted macOS SDK.
- Never use symbols as the only way to communicate an unfamiliar hardware action; supplement with a concise accessibility label or text.
- Keep toolbar symbols visually consistent in scale and rendering mode. Do not combine unrelated line weights or mixing emoji with system iconography.
- The **PlayPane app icon** should be a **simple, recognizable display/window motif** rather than a screenshot of gameplay or a drawing of a PS5/Apple hardware device.
- Follow Apple's current app-icon production specifications, including system masking and 1024×1024 source layout where applicable. See [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons) and [SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols).

### Motion and materials

- Do not animate live gameplay pixels as part of the app UI.
- Use restrained native transitions for showing settings, a popover, or controls. No gratuitous intro animation or moving decorative background.
- Respect Reduce Motion and Reduce Transparency settings. Use system-provided controls rather than manually synthesizing Liquid Glass.
- If controls float above video, maintain readability on both nearly-white and nearly-black scenes; test both. Source: [Materials](https://developer.apple.com/design/human-interface-guidelines/materials), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).

---

## 9. Accessibility is part of the MVP

**Apple source guidance:** Native controls are easier to make accessible; use consistent labels, keyboard navigation, adequate contrast, clear feedback, alternative input methods, and support system preferences. [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).

**PlayPane acceptance standards:**

- [ ] All commands are reachable without a mouse (menu bar, tab navigation, keyboard access).
- [ ] VoiceOver announces source name, capture state, controls, selected/muted state, and changes in meaningful connection status.
- [ ] Avoid announcing every video frame or constantly reading status updates during gameplay.
- [ ] Controls have text labels or meaningful accessibility descriptions; don't rely on icon shape or color alone.
- [ ] Test both Light and Dark appearance and **Increase Contrast**, including bright/dark video behind controls.
- [ ] Aim for at least **4.5:1** contrast for ordinary text and **3:1** for large text, using Apple's cited WCAG-based thresholds as the default validation reference; test actual rendered UI.
- [ ] Native control sizes on Mac are retained; any custom floating controls have generous hit regions and separation.
- [ ] Respect **Reduce Motion** and **Reduce Transparency** and use system colors/material variants where available.
- [ ] Do not auto-dismiss an error or instruction before a user can read or operate it. Essential controls remain discoverable without relying on a timeout.
- [ ] In-video controls are never the sole path to a feature: the menu bar provides a predictable fallback.
- [ ] Test VoiceOver, Full Keyboard Access, large text where relevant, and hardware disconnect while the user has keyboard focus.

**Important boundary:** PlayPane can make *its own UI* accessible; it cannot guarantee that third-party console/game content becomes accessible merely by displaying it.

---

## 10. Privacy and trust

- Capture only from the selected device, and request permissions with a specific purpose string.
- Suggested camera purpose string: **“PlayPane uses your selected HDMI capture device to show console video on your Mac.”**
- Suggested microphone/audio-input purpose string, **only if the capture-audio path requires it**: **“PlayPane uses your selected capture device’s audio input to play game sound on your Mac.”**
- Do **not** imply recording or cloud processing. The MVP does not need an account or telemetry SDK.
- Do not request access to unrelated devices or permissions as a workaround for a black screen.
- If permission is denied, direct the user to the appropriate macOS Privacy & Security control; the app cannot silently override a denial.
- Audio capture may appear as an input/microphone permission even though it's console game audio. Explain this when relevant.
- The exact permission APIs and prompts depend on the macOS version and capture route; verify with Apple framework documentation and a signed running build.

Apple's [Privacy HIG](https://developer.apple.com/design/human-interface-guidelines/privacy) recommends requesting permissions at a relevant moment and giving specific, plain-language reasons. **Do not create a fake system prompt or pressure users to grant access.**

---

## 11. SwiftUI implementation map (guidance, not prescribed architecture)

| UI responsibility | Candidate native tool | Separation rule |
| --- | --- | --- |
| App and window | SwiftUI `App` + `WindowGroup` or other appropriate scene | Let the system own window lifecycle and fullscreen behavior. |
| Menu commands | SwiftUI `.commands` / native menu APIs | Viewer commands usable even when video overlay is hidden. |
| Settings | SwiftUI `Settings` scene | Only real persistent options; standard ⌘, pathway. |
| Source picker | `Picker` / `Menu` | Bind to discovered devices; do not fabricate formats. |
| Transient status | SwiftUI text/progress controls | UI reflects actual capture state, not optimistic state. |
| Preview surface | AVFoundation preview layer hosted via AppKit/SwiftUI interop | Start with simplest working video path; measure before replacing with Metal. |
| Capture ownership | Separate observable capture coordinator/service | Avoid stopping/restarting session on unrelated SwiftUI view updates. |
| Audio | Capture-audio path + appropriate macOS output APIs | Treat audio device identity and routing as separate from video. |
| Privacy | AVFoundation authorization and macOS privacy declarations | Accurate, least-privilege requests tied to selected hardware. |

**Engineering note:** Apple's [AVFoundation](https://developer.apple.com/documentation/avfoundation) documents capture setup, external devices, and audio/video processing. It is the authority for capture APIs. HIG pages are authoritative for the interaction and presentation, **not** guarantees about external USB audio support, pixel formats, throughput, latency, or automatic reconnection behavior.

### Design constraints with runtime consequences

1. Do not couple animations, popovers, or title changes to capture reconfiguration; transient UI state must not interrupt frames.
2. Avoid polling and UI overlays whose work consumes significant time on the rendering path.
3. Source and mode changes should be explicit state transitions with rollback or truthful error feedback.
4. On source disconnect, do not leave a stale last frame that could be mistaken for live video.
5. Separate **FPS advertised by source**, **FPS actually received**, and **FPS rendered** in diagnostics; do not conflate them.
6. Distinguish game audio from app sound effects; the latter are unnecessary in MVP.

---

## 12. Design quality gates

### Gate A — native foundation

- [ ] Standard titled, movable, resizable Mac window; title bar and traffic lights behave normally.
- [ ] Main stage supports empty, connecting, failed, and playing states.
- [ ] Native menu bar and basic keyboard access.
- [ ] Source permission prompts are contextual and honest.
- [ ] System text, colors, and controls work in Light/Dark modes.

### Gate B — first usable gameplay

- [ ] Actual **PS5 → capture card → PlayPane → Mac display** is visible with correct aspect ratio.
- [ ] Real console audio is heard through the intended Mac output.
- [ ] Native fullscreen retains a usable video feed.
- [ ] Window resizing and app focus changes do not destroy the session.
- [ ] Hardware/model/format information is reported from observation, not marketing expectations.

### Gate C — recovery and accessibility

- [ ] Permission denied, absent device, no signal, and unplug/replug each have tested user-visible outcomes.
- [ ] VoiceOver and keyboard users can select a device, open Help, and recover without relying on the overlay.
- [ ] Status is persistent long enough to act upon; alerts reserved for true interruptive decisions.
- [ ] Contrast and visibility verified over bright and dark gameplay scenes.
- [ ] Settings are scoped to demonstrated needs and stay in a native Settings window.

### Gate D — performance and presentation

- [ ] End-to-end input-to-display observations compared with OBS on the **same** capture hardware and mode; method and uncertainty recorded.
- [ ] No claim of better latency without supporting measurements.
- [ ] Video cadence, game audio, and A/V sync checked across a sustained session.
- [ ] One screenshot of the empty state, one of actual live gameplay, one in fullscreen, and one of error recovery reviewed for UI obstruction/clarity.
- [ ] Accessibility behavior and system fullscreen transitions checked on target macOS versions.

**Definition of done:** A screenshot or successful Xcode build alone is insufficient. For a playback feature, require hardware-path evidence. Record *PASS / PARTIAL / FAIL* and unresolved cases for every gate.

---

## 13. Design review questions

Use these before accepting a new UI feature or visual treatment:

1. Does the feature help someone **start, continue, or recover gameplay**?
2. Could this be a standard macOS command instead of another on-video button?
3. Will the control cover critical game content or create additional latency?
4. Does it remain operable with keyboard/VoiceOver and readable over arbitrary game frames?
5. Is a value shown as **measured**, **supported**, **unknown**, or **unavailable**—not implied?
6. Can users recover from a bad device choice or failed session without relaunching?
7. Are settings necessary now, or is a good automatic default enough?
8. Does any animation, material, or icon actually improve clarity?
9. Is its behavior validated on the physical Mac/capture card, not only in previews?
10. Would removing the feature make PlayPane simpler without reducing usability? If yes, remove it.

### Example decisions

| Proposal | Decision | Rationale |
| --- | --- | --- |
| Persistent translucent control strip across the bottom of the game | **Reject for MVP** | Obscures gameplay; menu bar and on-demand controls are enough. |
| Custom borderless fake fullscreen | **Reject** | Breaks native window/Space expectations and adds edge cases. |
| Settings page with 15 untested video enhancements | **Reject** | Increases cognitive load; no performance evidence. |
| Device chooser with real friendly names | **Accept** | Solves a genuine hardware-selection task. |
| Clear HDCP troubleshooting on black signal | **Accept** | Reduces a common first-run failure mode. |
| Green 60 FPS badge based on console settings alone | **Reject** | Capture device may deliver 30 fps; false confidence. |
| One small source/status popover | **Conditional** | Useful if real users require diagnostics; keep out of gameplay by default. |
| Animated branded splash before capture | **Reject** | Directly delays the first useful frame. |

---

## 14. Backlog alignment

| GitHub work item | Design bible focus |
| --- | --- |
| [#1 — Scaffold SwiftUI app](https://github.com/blakee-marcus/PlayPane/issues/1) | Window anatomy, native menus, semantic styles, permission copy. |
| [#2 — First PS5 frame](https://github.com/blakee-marcus/PlayPane/issues/2) | Capture states, selected device, stage scaling, first-launch flow. |
| [#3 — Game audio](https://github.com/blakee-marcus/PlayPane/issues/3) | Audio clarity, routing vocabulary, no false mute state. |
| [#4 — Fullscreen](https://github.com/blakee-marcus/PlayPane/issues/4) | Native fullscreen, unobtrusive controls, accessibility. |
| [#5 — Latency vs OBS](https://github.com/blakee-marcus/PlayPane/issues/5) | Source of truth for performance messaging. |
| [#6 — Device recovery](https://github.com/blakee-marcus/PlayPane/issues/6) | Persistent actionable failure/reconnect states. |
| [#7 — Compatibility matrix](https://github.com/blakee-marcus/PlayPane/issues/7) | Honest supported/untested device descriptions. |
| [#8 — Release experience](https://github.com/blakee-marcus/PlayPane/issues/8) | First-run clarity, permissions, install confidence. |

**First design deliverable to implement:** One real capture stage with four complete visible states: **No Device → Connecting → Playing → Disconnected/No Signal**. Use native macOS fullscreen and a minimal Device menu. It is far more valuable than mockups of an elaborate settings interface.

---

## 15. Source library and evidence scope

> [!info] Source method
> Reviewed the **two supplied Apple page snapshots** (*Design principles* and *Designing for macOS*) and consulted Apple documentation/search-indexed excerpts for the five requested HIG sections and the relevant topic pages below. The five HIG hub pages are JavaScript-rendered in the web retrieval interface; their topic indexes were available, but not every child page was read in full. This bible is a **targeted PlayPane synthesis**, not a claim to have exhaustively audited every Apple HIG page. Apple can revise guidance; verify exact API behavior against the installed SDK and current documentation.

### Primary references supplied by the user

- [Foundations](https://developer.apple.com/design/human-interface-guidelines/foundations)
- [Patterns](https://developer.apple.com/design/human-interface-guidelines/patterns)
- [Components](https://developer.apple.com/design/human-interface-guidelines/components)
- [Inputs](https://developer.apple.com/design/human-interface-guidelines/inputs)
- [Technologies](https://developer.apple.com/design/human-interface-guidelines/technologies)

### Supplied supplementary snapshots

- [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles) — source for the eight named principles and their explanation.
- [Designing for macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos) — source for Mac window, input, menu, fullscreen, and multitasking conventions.

### Focused Apple design topics researched

- **Foundations:** [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) · [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons) · [Color](https://developer.apple.com/design/human-interface-guidelines/color) · [Materials](https://developer.apple.com/design/human-interface-guidelines/materials) · [Typography](https://developer.apple.com/design/human-interface-guidelines/typography) · [Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy) · [SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols).
- **Patterns:** [Going full screen](https://developer.apple.com/design/human-interface-guidelines/going-full-screen) · [Live-viewing apps](https://developer.apple.com/design/human-interface-guidelines/live-viewing-apps) · [Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback) · [Settings](https://developer.apple.com/design/human-interface-guidelines/settings) · [Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding) · [Loading](https://developer.apple.com/design/human-interface-guidelines/loading) · [Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts).
- **Components:** [Windows](https://developer.apple.com/design/human-interface-guidelines/windows) · [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars) · [Menus](https://developer.apple.com/design/human-interface-guidelines/menus) · [Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons).
- **Inputs:** [Keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards) · [Pointing devices](https://developer.apple.com/design/human-interface-guidelines/pointing-devices).
- **Technologies / implementation (separate technical authority):** [AVFoundation](https://developer.apple.com/documentation/avfoundation) · [SwiftUI](https://developer.apple.com/documentation/swiftui).

### Maintenance rule

When reviewing this note after an OS release, update only decisions impacted by new guidance or observed behavior. Keep **Apple guidance**, **PlayPane policy**, and **tested runtime evidence** distinct. Track implementation and results in the repository issues rather than appending volatile status here.
