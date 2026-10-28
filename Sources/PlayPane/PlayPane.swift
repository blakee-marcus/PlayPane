import SwiftUI

@main
struct PlayPaneApp: App {
    @StateObject private var capture = CaptureCoordinator()

    var body: some Scene {
        Window("PlayPane", id: "main") {
            CaptureStageView(coordinator: capture)
                .frame(minWidth: 480, minHeight: 320)
        }
        .defaultSize(width: 960, height: 600)
        .commands {
            CommandMenu("Device") {
                ForEach(capture.devices) { device in
                    Button(device.name) { capture.connect(to: device.id) }
                }
                Divider()
                Button("Scan Again") { capture.refresh() }
                Button("Reconnect") { capture.reconnect() }
                    .disabled(capture.devices.isEmpty)
            }
        }
    }
}
