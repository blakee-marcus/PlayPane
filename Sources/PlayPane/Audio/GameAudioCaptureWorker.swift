@preconcurrency import AVFoundation
import CoreAudio
import Foundation

/// The callback is installed once before discover/start. Mutable AVFoundation
/// objects, observers, and timers are confined to this independent serial queue.
final class GameAudioCaptureWorker: NSObject, GameAudioCapturing, AVCaptureAudioDataOutputSampleBufferDelegate, @unchecked Sendable {
    var onEvent: (@Sendable (GameAudioEvent) -> Void)?
    private let queue = DispatchQueue(label: "com.playpane.game-audio", qos: .userInitiated)
    private var session: AVCaptureSession?
    private var preview: AVCaptureAudioPreviewOutput?
    private var samples: AVCaptureAudioDataOutput?
    private var generation = 0
    private var lastSample = 0.0
    private var lastPublished = 0.0
    private var timer: DispatchSourceTimer?
    private var deviceObservers: [NSObjectProtocol] = []
    private var sessionObservers: [NSObjectProtocol] = []
    private var outputListener: AudioObjectPropertyListenerBlock?

    func discover(request: Int) {
        queue.async {
            self.installDeviceObserversIfNeeded()
            let inputs = self.availableInputs().map {
                AudioInputInfo(id: $0.uniqueID, name: $0.localizedName, modelID: $0.modelID, isUSB: true)
            }
            self.onEvent?(.discovered(request: request, inputs: inputs, outputName: Self.defaultOutputName()))
        }
    }

    private func availableInputs() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.microphone, .external], mediaType: .audio, position: .unspecified)
            .devices.filter { UInt32(bitPattern: $0.transportType) == kAudioDeviceTransportTypeUSB }
    }

    private static func defaultOutputName() -> String {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var id = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &id) == noErr, id != 0 else { return "System Default (no output available)" }
        address.mSelector = kAudioObjectPropertyName
        var name: CFString = "" as CFString
        size = UInt32(MemoryLayout<CFString>.size)
        let result = withUnsafeMutablePointer(to: &name) { AudioObjectGetPropertyData(id, &address, 0, nil, &size, $0) }
        return result == noErr ? name as String : "System Default"
    }
    static func makePreviewOutput(muted: Bool) -> AVCaptureAudioPreviewOutput {
        let output = AVCaptureAudioPreviewOutput()
        output.outputDeviceUniqueID = nil
        output.volume = muted ? 0 : 0.5
        return output
    }

    func start(inputID: String, generation: Int, muted: Bool) {
        queue.async {
            self.stopOnQueue()
            self.generation = generation
            guard let device = self.availableInputs().first(where: { $0.uniqueID == inputID }) else {
                self.onEvent?(.failed(generation: generation, message: "The selected USB audio input is unavailable. Scan again and choose the capture card's audio input."))
                return
            }
            guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
                self.onEvent?(.failed(generation: generation, message: "Allow PlayPane microphone access to monitor capture-card audio."))
                return
            }
            do {
                let session = AVCaptureSession()
                self.session = session
                let input = try AVCaptureDeviceInput(device: device)
                let preview = Self.makePreviewOutput(muted: muted)
                let samples = AVCaptureAudioDataOutput()
                samples.setSampleBufferDelegate(self, queue: self.queue)
                do {
                    session.beginConfiguration()
                    defer { session.commitConfiguration() }
                    guard session.canAddInput(input) else { throw AudioSetupError.unsupportedInput }
                    session.addInput(input)
                    guard session.canAddOutput(preview) else { throw AudioSetupError.unsupportedPreview }
                    session.addOutput(preview)
                    guard session.canAddOutput(samples) else { throw AudioSetupError.unsupportedSamples }
                    session.addOutput(samples)
                }
                self.preview = preview
                self.samples = samples
                for name in [AVCaptureSession.runtimeErrorNotification, AVCaptureSession.wasInterruptedNotification, AVCaptureSession.didStopRunningNotification] {
                    self.sessionObservers.append(NotificationCenter.default.addObserver(forName: name, object: session, queue: nil) { [weak self] _ in
                        guard let self else { return }
                        self.queue.async {
                            guard self.generation == generation, self.session != nil else { return }
                            self.onEvent?(.failed(generation: generation, message: "Game audio was interrupted. Check the capture card and reconnect audio. Video capture is independent."))
                        }
                    })
                }
                self.lastSample = ProcessInfo.processInfo.systemUptime
                self.lastPublished = 0
                session.startRunning()
                guard session.isRunning, preview.connection(with: .audio)?.isActive == true else {
                    throw AudioSetupError.inactiveOutput
                }
                let timer = DispatchSource.makeTimerSource(queue: self.queue)
                timer.schedule(deadline: .now() + 1, repeating: 1)
                timer.setEventHandler { [weak self] in
                    guard let self, self.session != nil else { return }
                    if ProcessInfo.processInfo.systemUptime - self.lastSample > 4 {
                        self.onEvent?(.failed(generation: generation, message: "No recent audio samples. Check console audio, HDMI, and USB, then reconnect audio."))
                        self.stopOnQueue()
                    }
                }
                self.timer = timer
                timer.resume()
            } catch {
                self.stopOnQueue()
                self.onEvent?(.failed(generation: generation, message: error.localizedDescription))
            }
        }
    }

    func stop() { queue.async { self.stopOnQueue() } }

    func setMuted(_ value: Bool, generation: Int) {
        queue.async {
            guard generation == self.generation else { return }
            self.preview?.volume = value ? 0 : 0.5
        }
    }

    private func stopOnQueue() {
        timer?.cancel()
        timer = nil
        sessionObservers.forEach(NotificationCenter.default.removeObserver)
        sessionObservers.removeAll()
        preview?.volume = 0
        samples?.setSampleBufferDelegate(nil, queue: nil)
        session?.stopRunning()
        session = nil
        preview = nil
        samples = nil
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard output === samples, CMSampleBufferDataIsReady(sampleBuffer), CMSampleBufferGetNumSamples(sampleBuffer) > 0 else { return }
        lastSample = ProcessInfo.processInfo.systemUptime
        guard lastPublished == 0 || lastSample - lastPublished >= 1 else { return }
        lastPublished = lastSample
        var description = "Receiving audio samples"
        if let format = CMSampleBufferGetFormatDescription(sampleBuffer), let basic = CMAudioFormatDescriptionGetStreamBasicDescription(format) {
            description = "\(basic.pointee.mSampleRate) Hz · \(basic.pointee.mChannelsPerFrame) channels"
        }
        // Metadata only: no copying, retaining, recording, or custom playback of samples.
        onEvent?(.samples(generation: generation, description: description))
    }

    private func installDeviceObserversIfNeeded() {
        guard deviceObservers.isEmpty else { return }
        for name in [AVCaptureDevice.wasConnectedNotification, AVCaptureDevice.wasDisconnectedNotification] {
            deviceObservers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in
                guard let self else { return }
                self.queue.async { self.onEvent?(.hardwareChanged) }
            })
        }
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.onEvent?(.hardwareChanged) }
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        if AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, queue, listener) == noErr {
            outputListener = listener
        }
    }

    deinit {
        timer?.cancel()
        (deviceObservers + sessionObservers).forEach(NotificationCenter.default.removeObserver)
        if let outputListener {
            var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
            AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, queue, outputListener)
        }
    }

    private enum AudioSetupError: LocalizedError {
        case unsupportedInput, unsupportedPreview, unsupportedSamples, inactiveOutput
        var errorDescription: String? {
            switch self {
            case .unsupportedInput: "This USB audio input could not be added to a capture session."
            case .unsupportedPreview: "Native audio preview is not supported by this input configuration."
            case .unsupportedSamples: "The device cannot provide audio monitoring and sample-delivery diagnostics together."
            case .inactiveOutput: "The native audio preview did not become active. Check the Mac output and reconnect audio."
            }
        }
    }
}

@MainActor
final class NativeGameAudioPermissions: GameAudioPermissions {
    var status: GameAudioPermission {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: .authorized
        case .notDetermined: .notDetermined
        default: .denied
        }
    }
    func request(_ completion: @escaping @Sendable (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: completion)
    }
}
