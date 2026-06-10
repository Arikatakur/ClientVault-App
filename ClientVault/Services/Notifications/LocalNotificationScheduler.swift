import Foundation
import UserNotifications

/// Local notifications for payment-due reminders and project deadlines. These
/// stay on-device (no server needed) — the blueprint keeps them local.
protocol LocalNotificationScheduling: Sendable {
    func requestAuthorization() async -> Bool
    func schedule(id: String, title: String, body: String, at date: Date) async throws
    func cancel(id: String)
}

final class LocalNotificationScheduler: LocalNotificationScheduling, @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func schedule(id: String, title: String, body: String, at date: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await center.add(request)
    }

    func cancel(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
}
