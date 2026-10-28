import AppKit
@preconcurrency import AVFoundation
import SwiftUI

@MainActor
private func check(_ value: @autoclosure () -> Bool, _ message: String) {
    guard value() else { print("FAIL: \(message)"); exit(1) }
    print("PASS: \(message)")
}

@MainActor
private func findPreview(in view: NSView) -> PreviewNSView? {
    if let preview = view as? PreviewNSView { return preview }
    for child in view.subviews {
        if let found = findPreview(in: child) { return found }
    }
    return nil
}

@main
struct CaptureStageTests {
    @MainActor
    static func main() async throws {
        let presentation = CaptureStagePresentation()
        check(!presentation.controlsVisible(isPlaying: true, audioNeedsAttention: false), "gameplay hides unrequested controls")
        check(presentation.controlsVisible(isPlaying: false, audioNeedsAttention: false), "setup and video recovery keep controls reachable")
        check(presentation.controlsVisible(isPlaying: true, audioNeedsAttention: true), "audio failure reveals controls without covering video")
        presentation.controlsRequested = true
        check(presentation.controlsVisible(isPlaying: true, audioNeedsAttention: false), "menu preference reveals gameplay controls")
        presentation.controlsRequested = false

        _ = NSApplication.shared
        let capture = CaptureCoordinator()
        let session = capture.session
        let preview = PreviewNSView(session: session)
        let layer = preview.preview
        for size in [CGSize(width: 960, height: 540), CGSize(width: 1280, height: 800),
                     CGSize(width: 1920, height: 1080), CGSize(width: 2560, height: 1080),
                     CGSize(width: 480, height: 700)] {
            preview.setFrameSize(size)
            preview.layout()
            check(preview.preview === layer && layer.session === session && layer.frame == preview.bounds && layer.videoGravity == .resizeAspect,
                  "aspect-fit preview preserves layer and session at \(Int(size.width))×\(Int(size.height))")
        }

        // Mount the real SwiftUI stage with production owners, but do not open any
        // capture input or request OS permission. Real fullscreen is tested in-app.
        let audio = GameAudioCoordinator()
        let host = NSHostingView(rootView: CaptureStageView(coordinator: capture, audio: audio, presentation: presentation))
        host.setFrameSize(CGSize(width: 960, height: 600))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 960, height: 600),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(150))
        guard let mounted = findPreview(in: host) else { check(false, "real SwiftUI stage mounts native preview"); return }
        check(mounted.preview.session === session, "real SwiftUI stage mounts the owned capture session")
        let videoGeneration = capture.model.generation
        let audioGeneration = audio.model.generation
        for index in 1...3 {
            presentation.controlsRequested.toggle()
            host.rootView = CaptureStageView(coordinator: capture, audio: audio, presentation: presentation)
            host.layoutSubtreeIfNeeded()
            try await Task.sleep(for: .milliseconds(30))
            check(findPreview(in: host) === mounted && mounted.preview.session === session,
                  "stage recomposition \(index) preserves native preview and capture owner")
        }
        check(capture.model.generation == videoGeneration && audio.model.generation == audioGeneration,
              "control-only redraws do not reconnect video or reassociate audio")
        check(!session.isRunning && session.inputs.isEmpty && session.outputs.isEmpty,
              "layout and controls never open capture input or start playback")
    }
}
