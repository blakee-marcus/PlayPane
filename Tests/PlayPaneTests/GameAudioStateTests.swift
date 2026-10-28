import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { print("FAIL: \(message)"); exit(1) }
    print("PASS: \(message)")
}

@main
struct GameAudioStateTests {
    static func main() {
        let usb = AudioInputInfo(id: "audio-usb", name: "USB Audio", modelID: "unknown", isUSB: true)
        let builtIn = AudioInputInfo(id: "builtin", name: "Microphone", modelID: "built-in", isUSB: false)
        var model = GameAudioModel()
        model.followVideo("video-usb")
        model.select(usb.id, from: [usb, builtIn])
        guard let generation = model.begin() else { print("FAIL: selected USB input must be startable"); exit(1) }
        expect(model.state == .connecting, "session start is not proof of audio samples")
        model.receivedSamples(generation: generation)
        expect(model.state == .playing, "current input samples enable monitoring state")
        model.invalidate(to: .permissionDenied)
        model.receivedSamples(generation: generation)
        expect(model.state == .permissionDenied, "permission denial rejects stale audio events")
        model.select(usb.id, from: [usb])
        let reconnected = model.begin()!
        model.receivedSamples(generation: generation)
        expect(model.state == .connecting, "reconnect rejects previous connection events")
        model.receivedSamples(generation: reconnected)
        model.followVideo("different-video")
        model.receivedSamples(generation: reconnected)
        expect(model.state == .unavailable && model.selectedInputID == nil, "video switch invalidates the old audio association")
        model.select(builtIn.id, from: [builtIn])
        expect(model.selectedInputID == nil, "built-in microphone can never be selected as fallback")
        model.select(usb.id, from: [usb])
        let active = model.begin()!
        model.receivedSamples(generation: active)
        model.setMuted(true)
        expect(model.state == .muted && model.generation == active, "mute changes playback state without reconnecting")
        model.receivedSamples(generation: active)
        expect(model.state == .muted, "incoming audio cannot undo user mute")
        model.setMuted(false)
        expect(model.state == .playing && model.generation == active, "unmute preserves the active audio connection")
        expect(model.begin() == nil && model.generation == active, "repeated start is idempotent while monitoring")
        model.reconcile([])
        model.receivedSamples(generation: active)
        expect(model.state == .disconnected, "input disappearance rejects late samples")
        model.reconcile([builtIn])
        expect(model.selectedInputID == nil && model.state == .disconnected, "disconnect never falls back to system microphone")
        model.select(usb.id, from: [usb])
        let beforeSwitch = model.begin()!
        let other = AudioInputInfo(id: "other-usb", name: "Other USB", modelID: "unknown", isUSB: true)
        model.select(other.id, from: [usb, other])
        model.receivedSamples(generation: beforeSwitch)
        expect(model.state == .ready && model.selectedInputID == other.id, "input switch invalidates old audio samples")
        let switched = model.begin()!
        model.receivedSamples(generation: switched)
        model.select(other.id, from: [other])
        expect(model.state == .playing && model.generation == switched, "reselecting the active input preserves monitoring")
        let hardware = AudioInputInfo(id: "AppleUSBAudioEngine:MACROSILICON:USB Video:1140000:3", name: "USB Digital Audio", modelID: "USB Digital Audio:534D:2109", isUSB: true)
        expect(AudioEndpointMatcher.match(videoID: "0x1140000534d2109", inputs: [hardware]) == hardware.id, "hardware match uses USB location plus vendor and product, not equal IDs")
        let wrongPort = AudioInputInfo(id: "AppleUSBAudioEngine:MACROSILICON:USB Video:1150000:3", name: hardware.name, modelID: hardware.modelID, isUSB: true)
        expect(AudioEndpointMatcher.match(videoID: "0x1140000534d2109", inputs: [wrongPort, builtIn]) == nil, "same name and model on another USB port is not a match")
        expect(AudioEndpointMatcher.match(videoID: "unknown-video", inputs: [hardware]) == nil, "unknown video identity requires explicit audio selection")
        let duplicate = AudioInputInfo(id: "AppleUSBAudioEngine:MACROSILICON:USB Video:1140000:4", name: hardware.name, modelID: hardware.modelID, isUSB: true)
        expect(AudioEndpointMatcher.match(videoID: "0x1140000534d2109", inputs: [hardware, duplicate]) == nil, "ambiguous matching endpoints require explicit selection")
        let wrongModel = AudioInputInfo(id: hardware.id, name: hardware.name, modelID: "USB Audio:1234:5678", isUSB: true)
        expect(AudioEndpointMatcher.match(videoID: "0x1140000534d2109", inputs: [wrongModel]) == nil, "location alone is insufficient for hardware matching")
        // Add next regression here.
    }
}
