@preconcurrency import AVFoundation
import Foundation

@MainActor
final class AudioWorkerProbe {
    var events: [GameAudioEvent] = []
}

@main
struct GameAudioWorkerTests {
    @MainActor
    static func main() async throws {
        let probe = AudioWorkerProbe()
        let worker = GameAudioCaptureWorker()
        worker.onEvent = { event in Task { @MainActor in probe.events.append(event) } }
        worker.discover(request: 42)
        for _ in 0..<200 {
            if !probe.events.isEmpty { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        guard let first = probe.events.first, case .discovered(let request, let inputs, let output) = first else {
            print("FAIL: native worker returns discovery without capture permission"); exit(1)
        }
        guard request == 42, inputs.allSatisfy(\.isUSB), !output.isEmpty else {
            print("FAIL: native discovery filters non-USB inputs and resolves default output"); exit(1)
        }
        print("PASS: native worker returns tagged discovery without capture permission")
        print("PASS: native discovery excludes built-in microphones and resolves system output")
        print("OBSERVED: USB inputs=\(inputs.map(\.name)); default output=\(output)")
        let preview = GameAudioCaptureWorker.makePreviewOutput(muted: false)
        guard preview.outputDeviceUniqueID == nil, preview.volume == 0.5 else {
            print("FAIL: native preview uses system default at safe initial monitoring volume"); exit(1)
        }
        guard GameAudioCaptureWorker.makePreviewOutput(muted: true).volume == 0 else {
            print("FAIL: native mute sets preview volume to zero"); exit(1)
        }
        print("PASS: native preview configures system-default output and monitoring gain")
        print("PASS: native muted preview has zero output volume")
        probe.events.removeAll()
        worker.start(inputID: "BuiltInMicrophoneDevice", generation: 99, muted: false)
        for _ in 0..<200 {
            if !probe.events.isEmpty { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        guard let failure = probe.events.first, case .failed(let generation, _) = failure, generation == 99 else {
            print("FAIL: native worker rejects built-in input without starting capture"); exit(1)
        }
        print("PASS: native capture boundary refuses built-in microphone")
        worker.stop()
        // Add next native regression here.
    }
}
