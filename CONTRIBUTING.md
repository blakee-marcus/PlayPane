# Contributing to PlayPane

PlayPane is at the beginning of development. The most useful contributions are **reproducible device results, focused fixes, and improvements that make console gameplay more usable**.

## Before you start

1. Check the [open issues](https://github.com/blakee-marcus/PlayPane/issues), prioritizing the first playable capture path.
2. For a substantial change, describe the proposed approach in an issue before implementing it.
3. Keep changes small and native to macOS: Swift, SwiftUI, and system capture APIs before third-party dependencies.
4. Include a test plan, actual commands/results, and any manual hardware checks with pull requests.

## Hardware reports

Capture hardware varies substantially. Include:

- Mac model, chip, and macOS version
- Capture-card make/model and USB connection/hub
- Console and HDMI output settings
- Advertised capture formats and the format actually selected (resolution, FPS, pixel format if known)
- Whether video and audio work, plus measured latency if available
- Exact steps to reproduce any black frame, freeze, audio problem, or disconnect

Never upload proprietary game footage or personal device identifiers when they are not necessary.

## Pull requests

- Explain the user-visible change and link the relevant issue.
- State which paths were verified **on real hardware** and which were not.
- Run the existing build/test targets once added; do not invent passing test output.
- Avoid unrelated refactors, unnecessary dependencies, and broad feature expansion.
- Keep UI consistent with macOS conventions (system controls, keyboard access, VoiceOver, fullscreen behavior).

See [AGENTS.md](AGENTS.md) for project-level engineering constraints and [docs/VALIDATION.md](docs/VALIDATION.md) for the performance test protocol.

## Code of conduct

Be respectful, stay specific, and discuss technical evidence rather than people. Maintainers may close off-topic or abusive contributions.
