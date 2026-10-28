import SwiftUI
@preconcurrency import AVFoundation

struct CapturePreviewView: NSViewRepresentable {
    let session: AVCaptureSession

    func makeNSView(context: Context) -> PreviewNSView {
        PreviewNSView(session: session)
    }

    func updateNSView(_ view: PreviewNSView, context: Context) {
        // Session lifetime belongs to CaptureCoordinator, never to SwiftUI redraws.
        if view.preview.session !== session { view.preview.session = session }
    }

    static func dismantleNSView(_ view: PreviewNSView, coordinator: ()) {
        view.preview.session = nil
    }
}

final class PreviewNSView: NSView {
    let preview: AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession) {
        preview = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        preview.videoGravity = .resizeAspect
        layer?.addSublayer(preview)
        setAccessibilityElement(true)
        setAccessibilityLabel("Console video preview")
    }

    required init?(coder: NSCoder) { nil }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        preview.frame = bounds
        CATransaction.commit()
    }
}
