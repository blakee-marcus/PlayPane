# Game audio: implementation and validation

**Status: audible playback user-confirmed; extended validation remains partial.** During the subsequent fullscreen milestone, real PS5 imagery and the app's audio-monitoring state were observed. Blake confirmed: **“Audible and in sync, including fullscreen transitions.”** This is a real listening report, not inferred from a successful build or delivered buffers. Measured A/V offset, extended stability, exact listening duration/route, and physical recovery remain unverified. Issue [#3](https://github.com/blakee-marcus/PlayPane/issues/3) remains open and has not been modified remotely. See [the later fullscreen validation](FULLSCREEN_VALIDATION.md).

The implementation/discovery results below retain the initial audio-milestone snapshot. Its permission/listening blocker was subsequently advanced by the user confirmation above; the historical blocked attempt is not the current audibility result. The later complete regression suite has 63 unique assertions (48 prior checks plus 15 stage checks).

## Architecture and safety boundary

- `Audio/AudioState.swift`: pure state/generation model and conservative hardware-identity matching.
- `Audio/GameAudioCoordinator.swift`: main-actor UI projection, permission actions, source association, stale-event rejection, mute, stop, and retry.
- `Audio/GameAudioCaptureWorker.swift`: independent serial queue and audio-only `AVCaptureSession`; `AVCaptureAudioPreviewOutput` does playback. A parallel `AVCaptureAudioDataOutput` observes sample delivery/format only; it does not retain samples, record, or implement playback.
- `Views/GameAudioHelpView.swift`: native source selection, setup/status, mute, and recovery. Audio failures appear in the toolbar/menu, not as an automatic gameplay-covering error sheet.
- Existing `CaptureCoordinator.swift`, `CaptureState.swift`, and `CapturePreviewView.swift` are unchanged. Audio code has no reference to the video session. This source-level separation is not proof against hardware-level contention; concurrent playback still needs a physical check.
- Preview output explicitly sets `outputDeviceUniqueID = nil` for System Default. No system input/output or volume setting is written. Monitoring gain starts at `0.5`; mute sets only the preview's volume to zero, unmute restores `0.5` without a session restart.
- No built-in, Continuity, virtual, or other non-USB microphone is eligible. Other USB inputs require explicit selection unless the observed identity adapter produces one unambiguous match. USB transport alone does not certify an HDMI capture card.
- Discovery and source selection do not request microphone access or start capture. The user chooses Start, sees the explanation when needed, then explicitly chooses Allow Capture Audio to invoke the native prompt. No system permission dialog was accepted by automation.

## Observed development hardware

Mac model: `Mac16,12` (MacBook Air). macOS `26.1`, build `25B78`. Apple Swift `6.2.4`; project source uses Swift 6 mode, macOS 14 minimum. Full Xcode is not installed; Command Line Tools builds are the exercised path.

| Path | Observed identity / format |
| --- | --- |
| USB hardware | `MACROSILICON`, product `USB Video`; vendor `0x534d`, product `0x2109`, location `0x01140000` in IORegistry |
| AVFoundation video | `USB Video`; UID `0x1140000534d2109`; model `UVC Camera VendorID_21325 ProductID_8457` |
| AVFoundation audio | `USB Digital Audio`; UID `AppleUSBAudioEngine:MACROSILICON:USB Video:1140000:3`; model `USB Digital Audio:534D:2109` |
| Core Audio input | Same audio UID, observed object ID `86` (ephemeral; not persisted) |
| Advertised audio formats | AVFoundation returned two entries reporting `96000 Hz`, `1 channel`; these are advertised descriptions, not captured-buffer or audibility evidence |
| System default output | `External Headphones`, UID `BuiltInHeadphoneOutputDevice`; Core Audio object ID `89` at observation time |
| System default input | Built-in MacBook microphone; left unchanged and excluded from PlayPane audio selection |

The selected video's UID encodes the observed USB location and VID/PID. The audio UID contains that same location, while its model contains the VID/PID. The matcher compares those three fields, **not equal video/audio IDs or similar names**. This adapter is deliberately restricted to the observed UID shapes, which are not promised public cross-device identity contracts. Unknown shapes, another port, and multiple matches fail closed to explicit selection. Re-discover after hub/port changes; do not persist these IDs as universal hardware identities.

The card's advertised mono/96 kHz mode is a reason to check pitch, channel content, and sound quality physically. It is not evidence of a defect, stereo output, or support for forcing a different mode. No mode was forced.

## Commands actually exercised

```bash
bash scripts/test.sh
bash scripts/build-app.sh .build/audio-milestone/PlayPane.app
plutil -lint PlayPane.xcodeproj/project.pbxproj
codesign --verify .build/audio-milestone/PlayPane.app
git diff --check
```

- `scripts/test.sh`: **48 unique passing assertions**, followed by a successful Swift 6 build with warnings treated as errors. This includes the original seven video-state assertions, audio-state/identity checks, production-coordinator tests with controlled OS boundaries, and read-only native-worker checks. These are standalone assertion executables, not an XCTest scheme or hardware playback suite.
- Observed red-to-green failures included: selected USB input not startable; permission denial accepting stale events; mute not changing state; disappearance accepting late samples; source change accepting old samples; hardware matcher returning no match; coordinator not issuing discovery; coordinator not consuming sample events; native discovery returning no event; native preview missing default-output/gain configuration; native worker failing to reject a built-in input. Each corresponding implementation change was followed by a passing focused run.
- Native-worker tests exercised real AVFoundation/Core Audio discovery, real preview-output property configuration, and rejection of a built-in input before capture. They did not open the USB audio input or hear sound. Controlled coordinator sample events are test inputs, not invented hardware samples.
- Local bundle signature and camera/microphone purpose strings were verified. Xcode project property-list validation passed; the Xcode build itself remains unverified.
- With Blake's approval, the previous PlayPane process was gracefully quit, its exit verified, and `.build/audio-milestone/PlayPane.app` launched. Exact process-path readback confirmed the new bundle was running.
- Native screenshot/accessibility inspection showed the new audio toolbar control and Help sheet, current default output `External Headphones`, disabled Start before video association, and actionable setup text. Mute checkbox changes were visually confirmed in both directions and restored to unmuted. This validates the UI binding, not audible muting.
- A keyboard Return test was blocked by tool consent timeout and was not retried or replaced with another dismissal action. Keyboard accessibility is not claimed verified.
- The new build remained at its camera-access explanation. The request for user-completed camera/microphone steps and listening feedback timed out. No native permission was granted by automation, no USB audio capture was started, and no listening result was supplied. The Help sheet remains open; no further dismissal action was attempted after the keyboard-action refusal.

## Real-device acceptance still required

1. Complete the native camera permission step, connect `USB Video`, and confirm moving PS5 imagery in this build.
2. Choose Audio → Start Game Audio. Confirm `USB Digital Audio` is selected from the hardware association, then explicitly approve the microphone prompt through Allow Capture Audio.
3. Observe actual incoming sample format in Audio Status and Help. Samples establish delivery, not audible playback or valid PS5 sound.
4. Listen through the current headphones for several minutes of gameplay. Check silence, pitch/channel issues, crackling, dropouts, duplicate sound, and obvious delay against visible actions. Record game, duration, output route, and observations.
5. Check mute/unmute during real playback, including that video remains live and is not reconnected.
6. Verify audio unplug/replug, permission-denied recovery, HDMI audio loss versus digital silence, and source reassociation after moving USB ports/hubs. Do not silently substitute another input.
7. Separately verify Mac speakers and headphone/default-output changes. Native `nil` routing is configured, but those audible routes have not been tested.

## Follow-up settings scope

[Issue #9: Audio Settings](https://github.com/blakee-marcus/PlayPane/issues/9) tracks output-device selection, monitoring-volume UI, preference restoration, and expanded physical routing checks. Its creation was read back from GitHub. No acceptance boxes were checked and no issue was closed. Baseline audible playback stays under #3.

## Apple API references

- [Audio preview output](https://developer.apple.com/documentation/avfoundation/avcaptureaudiopreviewoutput)
- [System-default routing via nil outputDeviceUniqueID](https://developer.apple.com/documentation/avfoundation/avcaptureaudiopreviewoutput/outputdeviceuniqueid)
- [Preview monitoring volume and mute](https://developer.apple.com/documentation/avfoundation/avcaptureaudiopreviewoutput/volume)
