import Foundation

enum CaptureState: Equatable, Sendable {
    case noDevice
    case permissionRequired
    case permissionDenied
    case ready
    case connecting(String)
    case playing(String)
    case noSignal(String)
    case disconnected
    case failed(String)

    var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }
}

/// Small value model shared by production orchestration and controlled-input tests.
struct CaptureModel: Sendable {
    private(set) var state: CaptureState = .noDevice
    private(set) var generation = 0
    private(set) var selectedID: String?

    @discardableResult
    mutating func connect(to id: String) -> Int {
        if selectedID == id {
            switch state {
            case .playing, .connecting: return generation
            default: break
            }
        }
        generation += 1
        selectedID = id
        state = .connecting(id)
        return generation
    }

    mutating func stalled(generation: Int) {
        guard generation == self.generation, let id = selectedID else { return }
        state = .noSignal(id)
    }

    mutating func reset(to state: CaptureState) {
        generation += 1
        selectedID = nil
        self.state = state
    }

    mutating func receivedFrame(generation: Int) {
        guard generation == self.generation, let id = selectedID else { return }
        state = .playing(id)
    }
}
