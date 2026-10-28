import SwiftUI

@main
struct PlayPaneApp: App {
    @StateObject private var capture = CaptureCoordinator()
    @StateObject private var audio = GameAudioCoordinator()
    @StateObject private var presentation = CaptureStagePresentation()

    var body: some Scene {
        Window("PlayPane", id: "main") {
            CaptureStageView(coordinator: capture, audio: audio, presentation: presentation)
                .frame(minWidth: 480, minHeight: 320)
        }
        .defaultSize(width: 960, height: 600)
        .windowStyle(.titleBar)
        .commands {
            // macOS supplies Enter/Exit Full Screen and Control-Command-F for
            // this standard resizable window. Do not add a duplicate command.
            CommandGroup(replacing: .toolbar) {
                Toggle("Show Controls During Gameplay", isOn: $presentation.controlsRequested)
                    .keyboardShortcut("t", modifiers: [.command, .option])
            }
            CommandGroup(replacing: .help) {
                Button("Connection Help") { presentation.showConnectionHelp = true }
                Button("Audio Status and Help…") { audio.showHelp = true }
            }
            CommandMenu("Device") {
                ForEach(capture.devices) { device in
                    Button(device.name) { capture.connect(to: device.id) }
                }
                Divider()
                Button("Scan Again") { capture.refresh() }
                Button("Reconnect") { capture.reconnect() }
                    .disabled(capture.devices.isEmpty)
            }
            CommandMenu("Audio") {
                Text(audio.statusText)
                Picker("Capture Audio Input", selection: Binding(get: { audio.model.selectedInputID ?? "" }, set: { audio.selectInput($0) })) {
                    Text("Choose USB audio input…").tag("")
                    ForEach(audio.inputs) { input in Text(input.name).tag(input.id) }
                }.disabled(audio.model.videoID == nil)
                Text("Playback: System Default")
                Text(audio.outputName)
                Divider()
                if audio.model.state == .permissionRequired {
                    Button("Allow Capture Audio…") { audio.requestPermission() }
                } else {
                    Button("Start Game Audio") { audio.start() }
                        .disabled(audio.model.selectedInputID == nil || audio.isActive)
                }
                Button("Stop Audio") { audio.stop() }.disabled(!audio.isActive)
                Toggle("Mute Game Audio", isOn: Binding(get: { audio.model.isMuted }, set: { audio.setMuted($0) }))
                Button("Scan Audio Inputs") { audio.refresh() }
                Divider()
                Button("Audio Status and Help…") { audio.showHelp = true }
            }
        }
    }
}
