import Foundation
import UserNotifications

/// Schedules the weekly "time for your check-in" notification for a condition.
enum ReminderScheduler {
    struct Reminder: Sendable {
        let id: UUID
        let conditionName: String
        let instrumentName: String
        let enabled: Bool
        let weekday: Int
        let hour: Int
        let minute: Int
    }

    static func update(for condition: TrackedCondition) {
        let reminder = Reminder(
            id: condition.id,
            conditionName: condition.name,
            instrumentName: condition.instrument?.shortName ?? "check-in",
            enabled: condition.reminderEnabled,
            weekday: condition.reminderWeekday,
            hour: condition.reminderHour,
            minute: condition.reminderMinute
        )
        Task { await schedule(reminder) }
    }

    static func cancel(conditionID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [conditionID.uuidString])
    }

    private static func schedule(_ reminder: Reminder) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        guard reminder.enabled else { return }

        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(reminder.conditionName) check-in"
        content.body = "Take a minute to fill in your \(reminder.instrumentName) so you can see how things are changing."
        content.sound = .default

        var components = DateComponents()
        components.weekday = reminder.weekday
        components.hour = reminder.hour
        components.minute = reminder.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        try? await center.add(UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger))
    }
}
