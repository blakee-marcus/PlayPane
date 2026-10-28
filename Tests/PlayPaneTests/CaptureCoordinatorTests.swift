import Foundation

// Standalone assertions also run under Command Line Tools (no XCTest installed).
@main
struct CaptureCoordinatorTests {
    static func main() throws {
        var model = CaptureModel()
        let generation = model.connect(to: "usb")
        precondition(model.state == .connecting("usb"), "Session startup is not evidence of frames")
        model.receivedFrame(generation: generation)
        precondition(model.state == .playing("usb"), "The first actual frame must enable playback")
        print("PASS: playback requires a frame from the active connection")
        let sameGeneration = model.connect(to: "usb")
        precondition(sameGeneration == generation, "Repeated connect must not restart a live session")
        print("PASS: repeated connect preserves the active session")
        model.reset(to: .disconnected)
        model.receivedFrame(generation: generation)
        precondition(model.state == .disconnected, "Late frames must not resurrect a disconnected device")
        print("PASS: disconnect rejects late frames")
        let next = model.connect(to: "second-usb")
        model.receivedFrame(generation: generation)
        precondition(model.state == .connecting("second-usb"), "Old source cannot satisfy new source readiness")
        print("PASS: switching devices rejects old callbacks")
        model.stalled(generation: next)
        precondition(model.state == .noSignal("second-usb"), "Missing frames must hide stale preview")
        print("PASS: missing frames produce a persistent recovery state")
        model.receivedFrame(generation: next)
        precondition(model.state == .playing("second-usb"), "Frames can recover the same stream")
        print("PASS: resumed frames recover playback")
        model.reset(to: .permissionDenied)
        model.receivedFrame(generation: next)
        precondition(model.state == .permissionDenied, "Permission denial cannot be bypassed by an old callback")
        print("PASS: permission denial invalidates pending capture")
    }
}
