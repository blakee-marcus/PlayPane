import Foundation

// Inject only OS permission/capture boundaries; exercise the production coordinator.
final class ControlledAudioCapture: GameAudioCapturing, @unchecked Sendable {
    var onEvent: (@Sendable (GameAudioEvent) -> Void)?
    private(set) var requests: [Int] = []
    private(set) var starts: [(id: String, generation: Int, muted: Bool)] = []
    private(set) var stops = 0
    private(set) var muteChanges: [Bool] = []
    func discover(request: Int) { requests.append(request) }
    func start(inputID: String, generation: Int, muted: Bool) { starts.append((inputID, generation, muted)) }
    func stop() { stops += 1 }
    func setMuted(_ value: Bool, generation: Int) { muteChanges.append(value) }
}

@MainActor
final class ControlledAudioPermissions: GameAudioPermissions {
    var status: GameAudioPermission = .notDetermined
    var requests = 0
    var completion: (@Sendable (Bool) -> Void)?
    func request(_ completion: @escaping @Sendable (Bool) -> Void) { requests += 1; self.completion = completion }
}

@MainActor
func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { print("FAIL: \(message)"); exit(1) }
    print("PASS: \(message)")
}

@main
struct GameAudioCoordinatorTests {
    @MainActor
    static func main() async throws {
        let backend = ControlledAudioCapture()
        let permissions = ControlledAudioPermissions()
        let audio = GameAudioCoordinator(backend: backend, permissions: permissions)
        let usb = AudioInputInfo(id: "AppleUSBAudioEngine:MACROSILICON:USB Video:1140000:3", name: "USB Digital Audio", modelID: "USB Digital Audio:534D:2109", isUSB: true)
        audio.followVideo("0x1140000534d2109")
        check(backend.requests.count == 1, "video association starts independent audio discovery")
        backend.onEvent?(.discovered(request: backend.requests.last!, inputs: [usb], outputName: "External Headphones"))
        try await settle()
        check(audio.model.selectedInputID == usb.id, "coordinator selects the observed matching USB endpoint")
        check(backend.starts.isEmpty && permissions.requests == 0, "discovery never starts capture or requests permission")
        audio.start()
        check(audio.model.state == .permissionRequired && backend.starts.isEmpty, "start explains microphone access before prompting")
        audio.requestPermission()
        audio.requestPermission()
        check(permissions.requests == 1, "repeated permission action creates one native request")
        permissions.status = .denied
        permissions.completion?(false)
        try await settle()
        check(audio.model.state == .permissionDenied && backend.starts.isEmpty, "denied permission never starts audio capture")
        permissions.status = .authorized
        audio.start()
        audio.start()
        check(backend.starts.count == 1 && backend.starts[0].id == usb.id, "authorized start targets only selected USB input and is idempotent")
        let active = backend.starts[0].generation
        backend.onEvent?(.samples(generation: active, description: "48000 Hz · 2 channels"))
        try await settle()
        check(audio.model.state == .playing && audio.sampleDescription == "48000 Hz · 2 channels", "production coordinator waits for actual sample events")
        audio.setMuted(true)
        check(backend.muteChanges == [true] && backend.starts.count == 1 && audio.model.state == .muted, "mute reaches audio backend without rebuilding a session")
        audio.setMuted(false)
        check(backend.muteChanges == [true, false] && audio.model.state == .playing, "unmute resumes the existing monitor")
        audio.stop()
        backend.onEvent?(.samples(generation: active, description: "late"))
        try await settle()
        check(audio.model.state == .ready && audio.sampleDescription.isEmpty, "stop rejects queued sample events")
        audio.start()
        let resumed = backend.starts.last!.generation
        backend.onEvent?(.failed(generation: active, message: "old session"))
        try await settle()
        check(audio.model.state == .connecting, "stale runtime errors cannot stop a new connection")
        backend.onEvent?(.failed(generation: resumed, message: "USB audio interrupted"))
        try await settle()
        check(audio.model.state == .failed("USB audio interrupted"), "current audio interruption becomes a recoverable audio failure")
        audio.refresh()
        let staleDiscovery = backend.requests.last!
        audio.followVideo("different-video")
        backend.onEvent?(.discovered(request: staleDiscovery, inputs: [usb], outputName: "old output"))
        try await settle()
        check(audio.model.selectedInputID == nil && audio.outputName != "old output", "stale discovery cannot reassociate a changed video device")
        permissions.status = .notDetermined
        audio.followVideo("0x1140000534d2109")
        backend.onEvent?(.discovered(request: backend.requests.last!, inputs: [usb], outputName: "External Headphones"))
        try await settle()
        audio.requestPermission()
        let pendingGrant = permissions.completion
        audio.followVideo(nil)
        permissions.status = .authorized
        let startsBeforeGrant = backend.starts.count
        pendingGrant?(true)
        try await settle()
        check(backend.starts.count == startsBeforeGrant && audio.model.videoID == nil, "permission grant after video removal cannot start capture")
        audio.followVideo("0x1140000534d2109")
        backend.onEvent?(.discovered(request: backend.requests.last!, inputs: [usb], outputName: "External Headphones"))
        try await settle()
        audio.start()
        let preDisconnect = backend.starts.last!.generation
        backend.onEvent?(.hardwareChanged)
        try await settle()
        backend.onEvent?(.discovered(request: backend.requests.last!, inputs: [], outputName: "External Headphones"))
        try await settle()
        backend.onEvent?(.samples(generation: preDisconnect, description: "late"))
        try await settle()
        check(audio.model.state == .disconnected && audio.model.selectedInputID == nil, "disconnected input stops audio and rejects late samples")
        let startsBeforeReplug = backend.starts.count
        audio.refresh()
        backend.onEvent?(.discovered(request: backend.requests.last!, inputs: [usb], outputName: "External Headphones"))
        try await settle()
        check(audio.model.state == .ready && backend.starts.count == startsBeforeReplug, "replug prepares recovery without unsolicited playback")
        // Add next coordinator regression here.
    }

    static func settle() async throws { try await Task.sleep(for: .milliseconds(30)) }
}
