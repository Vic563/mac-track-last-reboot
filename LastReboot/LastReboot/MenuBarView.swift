import SwiftUI
import ServiceManagement

struct MenuBarView: View {
    @ObservedObject var uptimeManager: UptimeManager
    @Binding var launchAtLogin: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundColor(uptimeManager.uptimeColor)
                Text("Last Reboot")
                    .font(.headline)
            }
            .padding(.bottom, 4)

            Divider()

            // Last reboot date
            VStack(alignment: .leading, spacing: 4) {
                Text("Rebooted on:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(uptimeManager.lastRebootDate, style: .date)
                    .font(.subheadline)
                Text(uptimeManager.lastRebootDate, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Uptime breakdown with colors
            VStack(alignment: .leading, spacing: 8) {
                Text("Time since reboot:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                UptimeGridView(components: uptimeManager.components, color: uptimeManager.uptimeColor)
            }

            Divider()

            // Status message
            HStack {
                Circle()
                    .fill(uptimeManager.uptimeColor)
                    .frame(width: 8, height: 8)
                Text(uptimeManager.uptimeStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Launch at Login toggle
            Toggle(isOn: $launchAtLogin) {
                Label("Launch at Login", systemImage: "power")
            }
            .toggleStyle(.switch)
            .controlSize(.small)
            .onChange(of: launchAtLogin) { newValue in
                setLaunchAtLogin(newValue)
            }

            Divider()

            // Reboot button
            Button(action: {
                confirmReboot()
            }) {
                Label("Reboot Now", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .foregroundColor(.orange)

            Divider()

            // Quit button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit LastReboot", systemImage: "xmark.circle")
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
        .padding()
        .frame(width: 220)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }

    private func confirmReboot() {
        let alert = NSAlert()
        alert.messageText = "Reboot Your Mac"
        alert.informativeText = "Are you sure you want to reboot now? All unsaved work will be lost."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reboot")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            executeReboot()
        }
    }

    private func executeReboot() {
        let script = NSAppleScript(source: "do shell script \"shutdown -r now\" with administrator privileges")
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        if let error = error {
            print("Failed to execute reboot: \(error)")
        }
    }
}

struct UptimeGridView: View {
    let components: (months: Int, days: Int, hours: Int, minutes: Int, seconds: Int)
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            if components.months > 0 {
                TimeUnitRow(value: components.months, unit: "Months", color: color)
            }
            TimeUnitRow(value: components.days, unit: "Days", color: color)
            TimeUnitRow(value: components.hours, unit: "Hours", color: color)
            TimeUnitRow(value: components.minutes, unit: "Minutes", color: color)
            TimeUnitRow(value: components.seconds, unit: "Seconds", color: color)
        }
    }
}

struct TimeUnitRow: View {
    let value: Int
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            Text(String(format: "%02d", value))
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .cornerRadius(4)
        }
    }
}
