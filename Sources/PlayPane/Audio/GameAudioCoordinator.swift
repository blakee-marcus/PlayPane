@preconcurrency import AVFoundation
import Combine
import Foundation

enum GameAudioEvent: Sendable {
    case discovered(request: Int, inputs: [AudioInputInfo], outputName: String)
    case samples(generation: Int, description: String)
    case failed(generation: Int, message: String)
    case hardwareChanged
}

protocol GameAudioCapturing: AnyObject, Sendable {
    var onEvent: (@Sendable (GameAudioEvent) -> Void)? { get set }
    func discover(request: Int)
    func start(inputID: String, generation: Int, muted: Bool)
    func stop()
    func setMuted(_ value: Bool, generation: Int)
}

enum GameAudioPermission { case notDetermined, denied, authorized }

@MainActor
protocol GameAudioPermissions: AnyObject {
    var status: GameAudioPermission { get }
    func request(_ completion: @escaping @Sendable (Bool) -> Void)
}

@MainActor
final class GameAudioCoordinator: ObservableObject {
    @Published private(set) var model = GameAudioModel()
    @Published private(set) var inputs: [AudioInputInfo] = []
    @Published private(set) var outputName = "System Default"
    @Published private(set) var sampleDescription = ""
    @Published var showHelp = false
    private let backend: any GameAudioCapturing
    private let permissions: any GameAudioPermissions
    private var discoveryRequest = 0
    private var permissionRequest = 0
    private var permissionPending = false

    init(backend: any GameAudioCapturing, permissions: any GameAudioPermissions) {
        self.backend = backend
        self.permissions = permissions
        backend.onEvent = { [weak self] event in
            Task { @MainActor [weak self] in self?.receive(event) }
        }
    }

    convenience init() {
        self.init(backend: GameAudioCaptureWorker(), permissions: NativeGameAudioPermissions())
    }

    var isActive: Bool {
        switch model.state {
        case .connecting, .playing, .muted: true
        default: false
        }
    }

    var needsAttention: Bool {
        switch model.state {
        case .permissionRequired, .permissionDenied, .disconnected, .failed: true
        default: false
        }
    }

    var statusText: String {
        switch model.state {
        case .unavailable: model.videoID == nil ? "Connect video before enabling game audio" : "Choose a USB capture audio input"
        case .ready: "Game audio is ready to start"
        case .permissionRequired: "Microphone access is required for capture-card audio"
        case .permissionDenied: "Microphone access is off. Enable PlayPane in Privacy & Security → Microphone."
        case .connecting: "Waiting for capture-card audio samples…"
        case .playing: "Monitoring game audio"
        case .muted: "Game audio is muted"
        case .disconnected: "USB audio disconnected. Scan again and reconnect audio."
        case .failed(let reason): reason
        }
    }

    func followVideo(_ id: String?) {
        guard model.videoID != id || discoveryRequest == 0 else { return }
        permissionRequest += 1
        model.followVideo(id)
        sampleDescription = ""
        backend.stop()
        refresh()
    }

    func refresh() {
        discoveryRequest += 1
        backend.discover(request: discoveryRequest)
    }

    func selectInput(_ id: String) {
        let oldGeneration = model.generation
        model.select(id, from: inputs)
        if model.generation != oldGeneration {
            permissionRequest += 1
            sampleDescription = ""
            backend.stop()
        }
    }

    func start() {
        guard !permissionPending, model.videoID != nil, let inputID = model.selectedInputID,
              inputs.contains(where: { $0.id == inputID && $0.isUSB }) else { return }
        switch permissions.status {
        case .notDetermined:
            model.invalidate(to: .permissionRequired)
            showHelp = true
        case .denied:
            model.invalidate(to: .permissionDenied)
            backend.stop()
            showHelp = true
        case .authorized:
            if model.state == .permissionDenied || model.state == .permissionRequired { model.invalidate(to: .ready) }
            guard let generation = model.begin() else { return }
            sampleDescription = ""
            backend.start(inputID: inputID, generation: generation, muted: model.isMuted)
        }
    }

    func requestPermission() {
        guard !permissionPending, model.videoID != nil, model.selectedInputID != nil else { return }
        guard permissions.status == .notDetermined else { start(); return }
        permissionPending = true
        permissionRequest += 1
        let request = permissionRequest
        permissions.request { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.permissionPending = false
                guard request == self.permissionRequest else { return }
                if granted {
                    self.model.invalidate(to: .ready)
                    self.start()
                } else {
                    self.model.invalidate(to: .permissionDenied)
                    self.backend.stop()
                }
            }
        }
    }

    func stop() {
        permissionRequest += 1
        model.invalidate(to: model.selectedInputID == nil ? .unavailable : .ready)
        sampleDescription = ""
        backend.stop()
    }

    func setMuted(_ value: Bool) {
        guard model.isMuted != value else { return }
        model.setMuted(value)
        backend.setMuted(value, generation: model.generation)
    }

    private func receive(_ event: GameAudioEvent) {
        switch event {
        case .discovered(let request, let found, let output):
            guard request == discoveryRequest else { return }
            inputs = found.filter(\.isUSB)
            outputName = output
            let oldGeneration = model.generation
            model.reconcile(inputs)
            if model.generation != oldGeneration {
                permissionRequest += 1
                sampleDescription = ""
                backend.stop()
            }
            if model.selectedInputID == nil, let videoID = model.videoID,
               let match = AudioEndpointMatcher.match(videoID: videoID, inputs: inputs) {
                model.select(match, from: inputs)
            }
        case .samples(let generation, let description):
            guard generation == model.generation, model.selectedInputID != nil else { return }
            if model.state != .playing && model.state != .muted { model.receivedSamples(generation: generation) }
            if sampleDescription != description { sampleDescription = description }
        case .failed(let generation, let message):
            guard generation == model.generation else { return }
            model.invalidate(to: .failed(message))
            sampleDescription = ""
            backend.stop()
        case .hardwareChanged: refresh()
        }
    }
}
