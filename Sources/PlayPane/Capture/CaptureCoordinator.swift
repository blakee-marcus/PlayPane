@preconcurrency import AVFoundation
import CoreAudio
import Foundation
import Combine

struct CaptureDeviceInfo: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
}

@MainActor
final class CaptureCoordinator: ObservableObject {
    @Published private(set) var model = CaptureModel()
    @Published private(set) var devices: [CaptureDeviceInfo] = []
    @Published private(set) var selectedID = ""
    @Published private(set) var frameDescription = ""
    private var permissionRequestPending = false
    private var bootstrapped = false
    private let worker: CaptureWorker
    var state: CaptureState { model.state }
    var session: AVCaptureSession { worker.session }

    init() {
        worker = CaptureWorker()
        worker.onEvent = { [weak self] event in
            Task { @MainActor [weak self] in self?.receive(event) }
        }
    }

    func bootstrap() {
        guard !bootstrapped else { return }
        bootstrapped = true
        refresh()
    }

    func refresh() { worker.discover() }

    func connect(to id: String? = nil) {
        if let id { selectedID = id }
        guard !permissionRequestPending else { return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            model.reset(to: .permissionRequired)
        case .denied, .restricted:
            model.reset(to: .permissionDenied)
            worker.stop()
        case .authorized:
            guard devices.contains(where: { $0.id == selectedID }) else {
                model.reset(to: .noDevice)
                return
            }
            let oldGeneration = model.generation
            let generation = model.connect(to: selectedID)
            guard generation != oldGeneration else { return }
            frameDescription = ""
            worker.start(id: selectedID, generation: generation)
        @unknown default:
            model.reset(to: .failed("Unknown camera authorization state."))
        }
    }

    func requestPermission() {
        guard !permissionRequestPending else { return }
        permissionRequestPending = true
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.permissionRequestPending = false
                if granted {
                    self.model.reset(to: .ready)
                    self.refresh()
                } else {
                    self.model.reset(to: .permissionDenied)
                }
            }
        }
    }

    func reconnect() {
        model.reset(to: .ready)
        connect()
    }

    private func receive(_ event: CaptureWorker.Event) {
        switch event {
        case .devices(let found):
            devices = found
            if let active = model.selectedID, !found.contains(where: { $0.id == active }) {
                model.reset(to: .disconnected)
                frameDescription = ""
                worker.stop()
            }
            if !found.contains(where: { $0.id == selectedID }) { selectedID = found.first?.id ?? "" }
            if model.state == .disconnected { return }
            if model.selectedID == nil {
                switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .denied, .restricted: model.reset(to: .permissionDenied)
                case .notDetermined: model.reset(to: found.isEmpty ? .noDevice : .permissionRequired)
                default: model.reset(to: found.isEmpty ? .noDevice : .ready)
                }
            }
        case .frame(let generation, let description):
            guard generation == model.generation else { return }
            if !model.state.isPlaying { model.receivedFrame(generation: generation) }
            if frameDescription != description { frameDescription = description }
        case .stalled(let generation):
            guard generation == model.generation else { return }
            if case .noSignal = model.state { return }
            model.stalled(generation: generation)
        case .failure(let generation, let message):
            guard generation == model.generation else { return }
            model.reset(to: .failed(message))
            frameDescription = ""
            worker.stop()
        }
    }
}

/// All mutable capture objects below are confined to queue, including delegate callbacks.
/// The immutable session reference is also used by the main-thread preview layer.
private final class CaptureWorker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    enum Event: Sendable {
        case devices([CaptureDeviceInfo])
        case frame(Int, String)
        case stalled(Int)
        case failure(Int, String)
    }
    let session = AVCaptureSession()
    var onEvent: (@Sendable (Event) -> Void)?
    private let queue = DispatchQueue(label: "com.playpane.capture", qos: .userInitiated)
    private var output: AVCaptureVideoDataOutput?
    private var timer: DispatchSourceTimer?
    private var observers: [NSObjectProtocol] = []
    private var generation = 0
    private var lastFrame = 0.0
    private var lastPublished = 0.0

    override init() {
        super.init()
        for name in [AVCaptureDevice.wasConnectedNotification, AVCaptureDevice.wasDisconnectedNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in self?.discover() })
        }
        for name in [AVCaptureSession.runtimeErrorNotification, AVCaptureSession.wasInterruptedNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: session, queue: nil) { [weak self] _ in
                guard let self else { return }
                self.queue.async { self.onEvent?(.failure(self.generation, "Capture was interrupted. Reconnect the device and try again.")) }
            })
        }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        timer?.cancel()
    }

    private func availableDevices() -> [AVCaptureDevice] {
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
        return discovery.devices.filter {
            UInt32(bitPattern: $0.transportType) == kAudioDeviceTransportTypeUSB
        }
    }

    func discover() {
        queue.async {
            let devices = self.availableDevices().map { CaptureDeviceInfo(id: $0.uniqueID, name: $0.localizedName) }
            self.onEvent?(.devices(devices))
        }
    }

    func start(id: String, generation: Int) {
        queue.async {
            self.stopOnQueue()
            self.generation = generation
            guard let device = self.availableDevices().first(where: { $0.uniqueID == id }) else {
                self.onEvent?(.failure(generation, "The selected USB capture device is no longer available."))
                return
            }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                let output = AVCaptureVideoDataOutput()
                output.alwaysDiscardsLateVideoFrames = true
                output.setSampleBufferDelegate(self, queue: self.queue)
                self.session.beginConfiguration()
                guard self.session.canAddInput(input), self.session.canAddOutput(output) else {
                    self.session.commitConfiguration()
                    self.onEvent?(.failure(generation, "This device cannot provide a supported capture pipeline."))
                    return
                }
                self.session.addInput(input)
                self.session.addOutput(output)
                self.session.commitConfiguration()
                self.output = output
                self.lastFrame = ProcessInfo.processInfo.systemUptime
                self.lastPublished = 0
                self.session.startRunning()
                guard self.session.isRunning else {
                    self.onEvent?(.failure(generation, "The capture session did not start."))
                    self.stopOnQueue()
                    return
                }
                let timer = DispatchSource.makeTimerSource(queue: self.queue)
                timer.schedule(deadline: .now() + 1, repeating: 1)
                timer.setEventHandler { [weak self] in
                    guard let self else { return }
                    if ProcessInfo.processInfo.systemUptime - self.lastFrame > 3 {
                        self.onEvent?(.stalled(self.generation))
                    }
                }
                self.timer = timer
                timer.resume()
            } catch {
                self.onEvent?(.failure(generation, error.localizedDescription))
                self.stopOnQueue()
            }
        }
    }

    func stop() { queue.async { self.stopOnQueue() } }

    private func stopOnQueue() {
        timer?.cancel()
        timer = nil
        output?.setSampleBufferDelegate(nil, queue: nil)
        session.stopRunning()
        session.beginConfiguration()
        session.inputs.forEach(session.removeInput)
        session.outputs.forEach(session.removeOutput)
        session.commitConfiguration()
        output = nil
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard output === self.output, CMSampleBufferDataIsReady(sampleBuffer) else { return }
        lastFrame = ProcessInfo.processInfo.systemUptime
        // No pixel copying, rendering, or main-actor work for each frame.
        guard lastPublished == 0 || lastFrame - lastPublished >= 1 else { return }
        lastPublished = lastFrame
        let format = CMSampleBufferGetFormatDescription(sampleBuffer)
        let dimensions = format.map { CMVideoFormatDescriptionGetDimensions($0) }
        let description = dimensions.map { "Received frame: \($0.width) × \($0.height)" } ?? "Receiving video frames"
        onEvent?(.frame(generation, description))
    }
}
