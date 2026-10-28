import Foundation

struct AudioInputInfo: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let modelID: String
    let isUSB: Bool
}

enum AudioState: Equatable, Sendable {
    case unavailable, ready, permissionRequired, permissionDenied
    case connecting, playing, muted, disconnected
    case failed(String)
}

enum AudioEndpointMatcher {
    /// Conservative adapter for the USB UID formats observed on the development Mac.
    /// Unknown formats or multiple endpoints deliberately require manual confirmation.
    static func match(videoID: String, inputs: [AudioInputInfo]) -> String? {
        guard videoID.hasPrefix("0x"), let packed = UInt64(videoID.dropFirst(2), radix: 16), packed > UInt64(UInt32.max) else { return nil }
        let location = packed >> 32
        let vendor = (packed >> 16) & 0xffff
        let product = packed & 0xffff
        let matches = inputs.filter { input in
            guard input.isUSB else { return false }
            let uid = input.id.split(separator: ":", omittingEmptySubsequences: false)
            let model = input.modelID.split(separator: ":", omittingEmptySubsequences: false)
            guard uid.count == 5, uid[0] == "AppleUSBAudioEngine", model.count == 3 else { return false }
            return UInt64(uid[3], radix: 16) == location &&
                UInt64(model[1], radix: 16) == vendor && UInt64(model[2], radix: 16) == product
        }
        return matches.count == 1 ? matches[0].id : nil
    }
}

struct GameAudioModel: Sendable {
    private(set) var state: AudioState = .unavailable
    private(set) var generation = 0
    private(set) var selectedInputID: String?
    private(set) var videoID: String?
    private(set) var isMuted = false

    mutating func followVideo(_ id: String?) {
        guard videoID != id else { return }
        invalidate(to: .unavailable)
        videoID = id
        selectedInputID = nil
    }
    mutating func reconcile(_ inputs: [AudioInputInfo]) {
        if let selectedInputID, !inputs.contains(where: { $0.id == selectedInputID && $0.isUSB }) {
            invalidate(to: .disconnected)
            self.selectedInputID = nil
        }
    }
    mutating func select(_ id: String, from inputs: [AudioInputInfo]) {
        guard videoID != nil, inputs.contains(where: { $0.id == id && $0.isUSB }) else { return }
        guard selectedInputID != id else { return }
        invalidate(to: .ready)
        selectedInputID = id
    }
    mutating func begin() -> Int? {
        guard selectedInputID != nil, videoID != nil else { return nil }
        switch state {
        case .connecting, .playing, .muted: return nil
        default: break
        }
        generation += 1
        state = .connecting
        return generation
    }
    mutating func receivedSamples(generation: Int) {
        guard generation == self.generation, selectedInputID != nil else { return }
        state = isMuted ? .muted : .playing
    }
    mutating func setMuted(_ value: Bool) {
        isMuted = value
        if state == .playing || state == .muted { state = value ? .muted : .playing }
    }
    mutating func invalidate(to state: AudioState) {
        generation += 1
        self.state = state
    }
}
