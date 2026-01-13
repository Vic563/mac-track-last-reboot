import Foundation
import SwiftUI

final class UptimeManager: ObservableObject {
    @Published var uptime: TimeInterval = 0
    @Published var lastRebootDate: Date = Date()

    private var timer: Timer?

    init() {
        updateUptime()
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateUptime()
        }
    }

    private func updateUptime() {
        var boottime = timeval()
        var size = MemoryLayout<timeval>.stride
        var mib: [Int32] = [CTL_KERN, KERN_BOOTTIME]

        if sysctl(&mib, 2, &boottime, &size, nil, 0) != -1 {
            let bootDate = Date(timeIntervalSince1970: TimeInterval(boottime.tv_sec))
            lastRebootDate = bootDate
            uptime = Date().timeIntervalSince(bootDate)
        }
    }

    var components: (months: Int, days: Int, hours: Int, minutes: Int, seconds: Int) {
        let totalSeconds = Int(uptime)

        let months = totalSeconds / (30 * 24 * 3600)
        let remainingAfterMonths = totalSeconds % (30 * 24 * 3600)

        let days = remainingAfterMonths / (24 * 3600)
        let remainingAfterDays = remainingAfterMonths % (24 * 3600)

        let hours = remainingAfterDays / 3600
        let remainingAfterHours = remainingAfterDays % 3600

        let minutes = remainingAfterHours / 60
        let seconds = remainingAfterHours % 60

        return (months, days, hours, minutes, seconds)
    }

    var shortDisplayString: String {
        let c = components
        if c.months > 0 {
            return "\(c.months)mo \(c.days)d"
        } else if c.days > 0 {
            return "\(c.days)d \(c.hours)h"
        } else if c.hours > 0 {
            return "\(c.hours)h \(c.minutes)m"
        } else {
            return "\(c.minutes)m \(c.seconds)s"
        }
    }

    var fullDisplayString: String {
        let c = components
        var parts: [String] = []

        if c.months > 0 {
            parts.append("\(c.months) month\(c.months == 1 ? "" : "s")")
        }
        if c.days > 0 || c.months > 0 {
            parts.append("\(c.days) day\(c.days == 1 ? "" : "s")")
        }
        parts.append("\(c.hours) hour\(c.hours == 1 ? "" : "s")")
        parts.append("\(c.minutes) minute\(c.minutes == 1 ? "" : "s")")
        parts.append("\(c.seconds) second\(c.seconds == 1 ? "" : "s")")

        return parts.joined(separator: ", ")
    }

    // Color based on uptime duration
    var uptimeColor: Color {
        let totalHours = uptime / 3600

        if totalHours < 24 {
            // Less than 1 day - green (fresh reboot)
            return .green
        } else if totalHours < 24 * 7 {
            // Less than 1 week - blue (healthy)
            return .blue
        } else if totalHours < 24 * 30 {
            // Less than 1 month - yellow/orange (consider rebooting)
            return .orange
        } else {
            // More than 1 month - red (should reboot)
            return .red
        }
    }

    var uptimeStatus: String {
        let totalHours = uptime / 3600

        if totalHours < 24 {
            return "Recently rebooted"
        } else if totalHours < 24 * 7 {
            return "System running smoothly"
        } else if totalHours < 24 * 30 {
            return "Consider rebooting soon"
        } else {
            return "Reboot recommended"
        }
    }
}
