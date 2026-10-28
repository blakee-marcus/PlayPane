import SwiftUI

struct GameAudioHelpView: View {
    @ObservedObject var audio: GameAudioCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Game Audio").font(.title2)
            Text(audio.statusText).textSelection(.enabled)
            Picker("USB audio input", selection: Binding(get: { audio.model.selectedInputID ?? "" }, set: { audio.selectInput($0) })) {
                Text("Choose capture-card audio…").tag("")
                ForEach(audio.inputs) { input in Text(input.name).tag(input.id) }
            }
            .disabled(audio.model.videoID == nil)
            Text("Playback: System Default — \(audio.outputName)").foregroundStyle(.secondary)
            HStack {
                if audio.model.state == .permissionRequired {
                    Button("Allow Capture Audio…") { audio.requestPermission() }.buttonStyle(.borderedProminent)
                } else {
                    Button("Start Game Audio") { audio.start() }
                        .disabled(audio.model.selectedInputID == nil || audio.isActive)
                }
                Button("Stop Audio") { audio.stop() }.disabled(!audio.isActive)
                Button("Scan Again") { audio.refresh() }
            }
            Toggle("Mute game audio", isOn: Binding(get: { audio.model.isMuted }, set: { audio.setMuted($0) }))
            if audio.model.state == .permissionDenied {
                Button("Open Microphone Privacy Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") { NSWorkspace.shared.open(url) }
                }
            }
            if !audio.sampleDescription.isEmpty { Text(audio.sampleDescription).font(.body.monospaced()) }
            Text("The microphone permission covers capture-card audio input. PlayPane never substitutes the built-in microphone or changes the system input/output selection.").font(.callout).foregroundStyle(.secondary)
            Text("Confirm the PS5 sends sound over HDMI. Close or mute other monitoring apps to avoid duplicate audio. Initial monitoring gain is 50%; use your normal Mac output volume. Receiving samples does not verify audible sound or A/V sync.").font(.callout).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 500)
    }
}
