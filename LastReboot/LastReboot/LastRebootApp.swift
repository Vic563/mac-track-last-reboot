import SwiftUI
import ServiceManagement

@main
struct LastRebootApp: App {
    @StateObject private var uptimeManager = UptimeManager()
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(uptimeManager: uptimeManager, launchAtLogin: $launchAtLogin)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                Text(uptimeManager.shortDisplayString)
                    .monospacedDigit()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
