import SwiftUI

struct CaptureStageView: View {
    @ObservedObject var coordinator: CaptureCoordinator
    @State private var showHelp = false

    var body: some View {
        ZStack {
            Color.black
            CapturePreviewView(session: coordinator.session)
                .opacity(coordinator.state.isPlaying ? 1 : 0)
                .accessibilityHidden(!coordinator.state.isPlaying)
            if !coordinator.state.isPlaying {
                VStack(spacing: 14) {
                    Image(systemName: symbol).font(.largeTitle).accessibilityHidden(true)
                    Text(title).font(.title2)
                    Text(detail).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    if case .connecting = coordinator.state { ProgressView().controlSize(.small) }
                    action
                    Button("Connection Help") { showHelp = true }
                }
                .padding(28)
                .frame(maxWidth: 480)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(24)
            }
        }
        .toolbar {
            ToolbarItem {
                Picker("Capture device", selection: Binding(get: { coordinator.selectedID }, set: { coordinator.connect(to: $0) })) {
                    if coordinator.devices.isEmpty { Text("No capture device").tag("") }
                    ForEach(coordinator.devices) { device in Text(device.name).tag(device.id) }
                }
                .disabled(coordinator.devices.isEmpty)
                .help("Choose an external USB video capture device")
            }
            ToolbarItem { Button("Connection Help", systemImage: "questionmark.circle") { showHelp = true } }
        }
        .task { coordinator.bootstrap() }
        .sheet(isPresented: $showHelp) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Connect your console").font(.title2)
                Text("Connect PS5 HDMI output to the capture card's HDMI input, then connect USB to the Mac. Select the USB capture device from the Device menu.")
                Text("For blocked gameplay capture, check PS5 Settings → System → HDMI → Enable HDCP. Protected media may not be capturable.")
                Text("Frames indicate device output, not verified HDMI signal. Some cards produce black, blue, or no-signal images when HDMI is absent.").foregroundStyle(.secondary)
                if !coordinator.frameDescription.isEmpty { Text(coordinator.frameDescription).font(.body.monospaced()) }
                Text("Game audio is not implemented in this milestone.").foregroundStyle(.secondary)
                Button("Done") { showHelp = false }.keyboardShortcut(.defaultAction)
            }.padding(24).frame(width: 460)
        }
    }

    private var title: String {
        switch coordinator.state {
        case .noDevice: "Connect a capture card"
        case .permissionRequired: "Allow camera access"
        case .permissionDenied: "Camera access is off"
        case .ready: "Ready to connect"
        case .connecting: "Connecting to capture device…"
        case .playing: "Receiving video"
        case .noSignal: "No video frames received"
        case .disconnected: "Capture card disconnected"
        case .failed: "Couldn’t start video capture"
        }
    }

    private var symbol: String {
        switch coordinator.state {
        case .permissionRequired, .permissionDenied: "lock.shield"
        case .failed, .noSignal, .disconnected: "exclamationmark.triangle"
        default: "display"
        }
    }

    private var detail: String {
        switch coordinator.state {
        case .noDevice: "Connect your console through a USB HDMI capture device. Built-in and virtual cameras are not console sources."
        case .permissionRequired: "PlayPane needs camera access to show video from your selected HDMI capture device."
        case .permissionDenied: "Enable PlayPane in System Settings → Privacy & Security → Camera, then try again."
        case .ready: "Choose Connect to display video from the selected USB capture device."
        case .connecting: "Waiting for the selected device to deliver video frames."
        case .playing: ""
        case .noSignal: "Check HDMI, console power, and USB connections. The device has not delivered a recent frame."
        case .disconnected: "Reconnect the USB capture device, scan again, and choose Reconnect."
        case .failed(let reason): reason
        }
    }

    @ViewBuilder private var action: some View {
        switch coordinator.state {
        case .permissionRequired:
            Button("Continue") { coordinator.requestPermission() }.buttonStyle(.borderedProminent)
        case .permissionDenied:
            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") { NSWorkspace.shared.open(url) }
            }
            Button("Check Permission Again") { coordinator.connect() }
        case .noDevice:
            Button("Scan Again") { coordinator.refresh() }
        case .ready:
            Button("Connect") { coordinator.connect() }.buttonStyle(.borderedProminent)
        case .failed, .disconnected, .noSignal:
            Button("Reconnect") { coordinator.reconnect() }.disabled(coordinator.devices.isEmpty)
            Button("Scan Again") { coordinator.refresh() }
        default: EmptyView()
        }
    }
}
