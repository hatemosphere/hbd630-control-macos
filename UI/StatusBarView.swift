import SwiftUI

// MARK: - Tooltip (NSView-backed, works in NSPopover)

private class PassthroughTooltipView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

private struct Tooltip: NSViewRepresentable {
    let text: String
    func makeNSView(context: Context) -> NSView {
        let view = PassthroughTooltipView()
        view.toolTip = text
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.toolTip = text
    }
}

private extension View {
    func tooltip(_ text: String) -> some View {
        overlay(Tooltip(text: text))
    }
}

struct StatusBarView: View {
    @ObservedObject var controller: HeadphoneController
    @ObservedObject var bluetooth: BluetoothManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch bluetooth.state {
            case .connected:
                ConnectedView(controller: controller, bluetooth: bluetooth)
            case .error(let message):
                ErrorView(message: message) {
                    bluetooth.scanForDevices()
                }
            default:
                DeviceListView(bluetooth: bluetooth) { device in
                    bluetooth.connect(to: device)
                }
            }
        }
        .frame(width: 300)
        .padding(.vertical, 8)
        .tint(.blue)
    }
}

// MARK: - Connected View

private struct ConnectedView: View {
    @ObservedObject var controller: HeadphoneController
    let bluetooth: BluetoothManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "headphones")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 1) {
                    Text(controller.deviceInfo.name.isEmpty ? "HDB 630" : controller.deviceInfo.name)
                        .font(.headline)
                    if !controller.deviceInfo.codec.isEmpty {
                        Text("Codec: \(controller.deviceInfo.codec)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                BatteryBadge(
                    level: controller.batteryLevel,
                    chargingStatus: controller.deviceInfo.chargingStatus
                )
            }
            .padding(.horizontal, 16)

            Divider()

            // ANC Section
            ANCSection(controller: controller)

            // Transparent Hearing (requires ANC on, Adaptive off)
            if controller.ancEnabled && !controller.ancState.adaptive {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Transparent Hearing")
                            .font(.callout)
                        Spacer()
                        Text("\(controller.transparencyLevel)%")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(controller.transparencyLevel) },
                            set: { val in
                                let level = Int(val)
                                controller.transparencyLevel = level
                                controller.setTransparency(level)
                            }
                        ),
                        in: 0...100,
                        step: 1
                    )
                }
                .tooltip("Lets outside sounds through while ANC is active")
                .padding(.horizontal, 16)
            }

            // EQ, Bass Boost & Crossfeed
            EQSection(controller: controller)

            // Call Transparency (sidetone)
            HStack {
                Text("Call Transparency")
                    .font(.callout)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { controller.sidetoneLevel > 0 },
                    set: { on in
                        let level = on ? 2 : 0
                        controller.sidetoneLevel = level
                        controller.setSidetone(level)
                    }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .tooltip("Hear your own voice during phone calls (sidetone)")
            .padding(.horizontal, 16)

            if controller.sidetoneLevel > 0 {
                Picker("", selection: Binding(
                    get: { controller.sidetoneLevel },
                    set: { level in
                        controller.sidetoneLevel = level
                        controller.setSidetone(level)
                    }
                )) {
                    Text("1").tag(1)
                    Text("2").tag(2)
                    Text("3").tag(3)
                    Text("4").tag(4)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                HStack {
                    Text("Auto-Pause")
                        .font(.callout)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { controller.autoPauseEnabled },
                        set: { on in Task { await controller.setAutoPause(on) } }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
                .tooltip("Pause audio when Call Transparency is enabled")
                .padding(.horizontal, 16)
            }

            Divider()

            // Settings toggles
            SettingsSection(controller: controller)

            // Connection management
            if !controller.pairedDevices.isEmpty {
                Divider()
                ConnectionSection(controller: controller)
            }

            Divider()

            // Footer
            FooterView(controller: controller, bluetooth: bluetooth)
        }
    }
}

// MARK: - ANC Section

private struct ANCSection: View {
    @ObservedObject var controller: HeadphoneController

    var body: some View {
        HStack {
            Text("Active Noise Cancelling")
                .font(.callout)
            Spacer()
            Toggle("", isOn: Binding(
                get: { controller.ancEnabled },
                set: { on in Task { await controller.setANCEnabled(on) } }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .tooltip("Reduces ambient noise using built-in microphones")
        .padding(.horizontal, 16)

        if controller.ancEnabled {
            VStack(alignment: .leading, spacing: 4) {
                Text("Anti-Wind")
                    .font(.callout)
                Picker("", selection: Binding(
                    get: { controller.ancState.antiWind },
                    set: { val in Task { await controller.setAntiWind(val) } }
                )) {
                    Text("Off").tag(0)
                    Text("Auto").tag(2)
                    Text("Max").tag(1)
                }
                .pickerStyle(.segmented)
            }
            .tooltip("Reduces wind noise — Auto adjusts based on conditions")
            .padding(.horizontal, 16)

            HStack {
                Text("Comfort")
                    .font(.callout)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { controller.ancState.comfort },
                    set: { on in Task { await controller.setComfort(on) } }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .tooltip("Reduced ANC strength for less ear pressure")
            .padding(.horizontal, 16)

            HStack {
                Text("Adaptive ANC")
                    .font(.callout)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { controller.ancState.adaptive },
                    set: { on in Task { await controller.setAdaptive(on) } }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .tooltip("Automatically adjusts ANC level based on environment")
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - EQ Section

private struct EQSection: View {
    @ObservedObject var controller: HeadphoneController

    var body: some View {
        HStack {
            Text("Podcast Mode")
                .font(.callout)
            Spacer()
            Toggle("", isOn: Binding(
                get: { controller.podcastModeEnabled },
                set: { on in Task {
                    await controller.setPodcastMode(on)
                    if !on {
                        controller.lockEQ(preset: controller.eqPreset)
                        await controller.sendEQBands(controller.eqPreset)
                    }
                }}
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .tooltip("Audio processing optimized for speech and podcasts")
        .padding(.horizontal, 16)

        if !controller.podcastModeEnabled {
            VStack(alignment: .leading, spacing: 4) {
                Text("Equalizer")
                    .font(.callout)
                Picker("", selection: Binding(
                    get: { controller.eqPreset },
                    set: { preset in
                        guard preset != .custom else { return }
                        controller.lockEQ(preset: preset)
                        Task { await controller.sendEQBands(preset) }
                    }
                )) {
                    if controller.eqPreset == .custom {
                        Text("Custom").tag(EQPreset.custom)
                    }
                    ForEach(EQPreset.builtIn) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            .padding(.horizontal, 16)

            HStack {
                Text("Bass Boost")
                    .font(.callout)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { controller.bassBoostEnabled },
                    set: { on in Task { await controller.setBassBoost(on) } }
                ))
                .toggleStyle(.switch)
                .controlSize(.small)
            }
            .tooltip("Enhanced low-frequency response")
            .padding(.horizontal, 16)
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("Crossfeed")
                .font(.callout)
            Picker("", selection: Binding(
                get: { controller.crossfeedLevel },
                set: { level in Task { await controller.setCrossfeed(level) } }
            )) {
                Text("Off").tag(2)
                Text("Low").tag(0)
                Text("High").tag(1)
            }
            .pickerStyle(.segmented)
        }
        .tooltip("Blends stereo channels for more natural, speaker-like sound")
        .padding(.horizontal, 16)
    }
}

// MARK: - Settings Section

private struct SettingsSection: View {
    @ObservedObject var controller: HeadphoneController

    var body: some View {
        HStack {
            Text("On-Head Detection")
                .font(.callout)
            Spacer()
            Toggle("", isOn: Binding(
                get: { controller.onHeadDetectionEnabled },
                set: { on in Task { await controller.setOnHeadDetection(on) } }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .tooltip("Detects when headphones are worn or removed")
        .padding(.horizontal, 16)

        HStack {
            Text("Smart Pause")
                .font(.callout)
            Spacer()
            Toggle("", isOn: Binding(
                get: { controller.smartPauseEnabled },
                set: { on in Task { await controller.setSmartPause(on) } }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .disabled(!controller.onHeadDetectionEnabled)
        }
        .opacity(controller.onHeadDetectionEnabled ? 1 : 0.5)
        .tooltip(controller.onHeadDetectionEnabled
            ? "Pauses audio when headphones are removed"
            : "Requires On-Head Detection to be enabled")
        .padding(.horizontal, 16)

        HStack {
            Text("Auto-Answer Calls")
                .font(.callout)
            Spacer()
            Toggle("", isOn: Binding(
                get: { controller.autoCallEnabled },
                set: { on in Task { await controller.setAutoCall(on) } }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .disabled(!controller.onHeadDetectionEnabled)
        }
        .opacity(controller.onHeadDetectionEnabled ? 1 : 0.5)
        .tooltip(controller.onHeadDetectionEnabled
            ? "Automatically answers incoming calls after a delay"
            : "Requires On-Head Detection to be enabled")
        .padding(.horizontal, 16)

        HStack {
            Text("Comfort Call")
                .font(.callout)
            Spacer()
            Toggle("", isOn: Binding(
                get: { controller.comfortCallEnabled },
                set: { on in Task { await controller.setComfortCall(on) } }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .tooltip("Automatically adjusts audio when a phone call starts")
        .padding(.horizontal, 16)

        HStack {
            Text("Auto Power Off")
                .font(.callout)
            Spacer()
            Picker("", selection: Binding(
                get: { controller.autoPowerOffMinutes },
                set: { mins in Task { await controller.setAutoPowerOff(minutes: mins) } }
            )) {
                Text("Off").tag(0)
                Text("15 min").tag(15)
                Text("30 min").tag(30)
                Text("60 min").tag(60)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 90)
            .disabled(!controller.onHeadDetectionEnabled)
        }
        .opacity(controller.onHeadDetectionEnabled ? 1 : 0.5)
        .tooltip(controller.onHeadDetectionEnabled
            ? "Turns off headphones after idle time to save battery"
            : "Requires On-Head Detection to be enabled")
        .padding(.horizontal, 16)
    }
}

// MARK: - Connection Section

private struct ConnectionSection: View {
    @ObservedObject var controller: HeadphoneController

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Connections")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if controller.maxBTConnections > 1 {
                    Text("Multipoint")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)

            ForEach(controller.pairedDevices) { device in
                HStack(spacing: 6) {
                    Image(systemName: device.index == controller.ownDeviceIndex
                          ? "desktopcomputer" : "iphone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                    Text(device.name.isEmpty ? "Device \(device.index)" : device.name)
                        .font(.caption)
                    if device.index == controller.ownDeviceIndex {
                        Text("This device")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    if device.isConnected {
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 1)
            }
        }
    }
}

// MARK: - Footer

private struct FooterView: View {
    @ObservedObject var controller: HeadphoneController
    let bluetooth: BluetoothManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                if !controller.deviceInfo.serial.isEmpty {
                    Text("S/N \(controller.deviceInfo.serial)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                if !controller.deviceInfo.firmwareVersion.isEmpty {
                    Text("FW \(controller.deviceInfo.firmwareVersion)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Button("Disconnect") {
                bluetooth.disconnect()
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .foregroundStyle(.secondary)
            QuitButton()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Battery Badge

private struct BatteryBadge: View {
    let level: Int
    let chargingStatus: ChargingStatus

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: batteryIcon)
                .foregroundStyle(level <= 15 ? .red : .primary)
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(level)%")
                    .font(.caption)
                    .monospacedDigit()
                if !chargingStatus.label.isEmpty {
                    Text(chargingStatus.label)
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var batteryIcon: String {
        if chargingStatus == .charging {
            return "battery.100percent.bolt"
        }
        switch level {
        case 0..<13: return "battery.0percent"
        case 13..<38: return "battery.25percent"
        case 38..<63: return "battery.50percent"
        case 63..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
}

// MARK: - Device List View

private struct DeviceListView: View {
    @ObservedObject var bluetooth: BluetoothManager
    let onSelect: (IOBluetoothDevice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Select Device")
                    .font(.headline)
                Spacer()
                Button {
                    bluetooth.scanForDevices()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)

            if bluetooth.state == .scanning {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if bluetooth.pairedDevices.isEmpty {
                Text("No paired Bluetooth devices found.\nPair your HDB 630 in System Settings first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(bluetooth.pairedDevices, id: \.addressString) { device in
                    Button {
                        onSelect(device)
                    } label: {
                        HStack {
                            Image(systemName: "headphones")
                            Text(device.name ?? device.addressString ?? "Unknown")
                            Spacer()
                            if bluetooth.state == .connecting {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
            HStack {
                Spacer()
                QuitButton()
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
            Button("Retry", action: onRetry)
                .buttonStyle(.bordered)
            QuitButton()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quit Button

private struct QuitButton: View {
    @EnvironmentObject var bluetooth: BluetoothManager

    var body: some View {
        Button("Quit") {
            bluetooth.disconnect()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                NSApp.terminate(nil)
            }
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .foregroundStyle(.secondary)
    }
}