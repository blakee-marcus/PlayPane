# Capture and latency validation

**Status:** protocol only. No PlayPane measurements have been collected yet.

## Core question

Can a PS5 be played comfortably through a capture card and a native Mac app, and how does that experience compare with OBS on the **same hardware**?

## Test setup (record for every run)

| Field | Value |
| --- | --- |
| Date / build SHA | |
| Mac model / chip / macOS | |
| PS5 display settings | |
| Capture card make/model/USB VID:PID | |
| Direct USB or hub/dock | |
| Device output format (resolution, FPS, pixel format) | |
| App render path | |
| OBS version / preview configuration | |
| Audio device and output path | |

Use identical source hardware, USB routing, console settings, capture format, and screen conditions across PlayPane and OBS trials.

## Checks

### Functional

- Permission prompt and denial flow
- Detection of the **correct** capture device
- Stable live gameplay video; no aspect-ratio distortion
- Audio from capture card to Mac speakers/headphones
- Enter and exit fullscreen
- Disconnect while running → clear status → reconnect and recover

### Performance

1. Show a repeatable visual event visible in the console's source path and captured on the Mac.
2. Record source and Mac display together using a sufficiently high-frame-rate camera, or a comparable externally verifiable reference.
3. Estimate display delay in milliseconds for multiple trials; report median, spread, and measurement uncertainty.
4. Repeat for OBS with matching settings.
5. Observe frame pacing, dropped frames, audio continuity, and audio/video sync over a sustained session.
6. Change one variable at a time (capture format, render path, or USB routing) to explain any improvement or regression.

A software timestamp inside the app measures part of the pipeline, **not** HDMI-input-to-screen latency. Do not present it as end-to-end latency.

## Acceptance reporting

For each issue, provide:

- **PASS / PARTIAL / FAIL** with evidence
- What was tested through the physical PS5 → card → Mac path
- Relevant commands and recorded observations
- Device-specific limitations and unresolved failures

The first release must not promise 60 fps, near-zero latency, or universal compatibility unless the release's specific supported hardware has demonstrated those claims.
