import Foundation
import UserNotifications
import CoreData

// MARK: - Notification Manager
@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Notification identifiers
    private let streakReminderIdentifier = "tasksnap.streak.reminder"
    private let taskReminderPrefix = "tasksnap.task."
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            Task { @MainActor in
                self.isAuthorized = granted
                if granted {
                    self.scheduleStreakReminder()
                    self.rescheduleAllTaskReminders()
                }
                completion(granted)
            }
        }
    }
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Task Reminders
    
    func scheduleTaskReminder(for task: TaskEntity) {
        guard isAuthorized,
              let dueDate = task.dueDate,
              task.taskStatus != .done else { return }
        
        // Remove any existing reminder for this task
        cancelTaskReminder(for: task)
        
        let identifier = taskReminderIdentifier(for: task)
        
        // Schedule reminder based on urgency
        let reminderDates = calculateReminderDates(for: dueDate, isUrgent: task.isUrgent)
        
        for (index, reminderDate) in reminderDates.enumerated() {
            guard reminderDate > Date() else { continue }
            
            let content = createTaskReminderContent(for: task, reminderIndex: index, totalReminders: reminderDates.count)
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "\(identifier).\(index)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error scheduling task reminder: \(error)")
                }
            }
        }
    }
    
    func cancelTaskReminder(for task: TaskEntity) {
        let identifier = taskReminderIdentifier(for: task)
        
        // Cancel all possible reminder indices (we schedule up to 3)
        let identifiers = (0..<3).map { "\(identifier).\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func rescheduleAllTaskReminders() {
        guard isAuthorized else { return }
        
        // Clear all existing task reminders
        notificationCenter.getPendingNotificationRequests { requests in
            let taskIdentifiers = requests.compactMap { request -> String? in
                request.identifier.hasPrefix(self.taskReminderPrefix) ? request.identifier : nil
            }
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: taskIdentifiers)
        }
        
        // Reschedule for all incomplete tasks with due dates
        Task { @MainActor in
            let context = PersistenceController.shared.container.viewContext
            let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            request.predicate = NSPredicate(format: "status != 'done' AND dueDate != nil")
            
            do {
                let tasks = try context.fetch(request)
                tasks.forEach { self.scheduleTaskReminder(for: $0) }
            } catch {
                print("Error fetching tasks for reminder scheduling: \(error)")
            }
        }
    }
    
    // MARK: - Streak Reminders
    
    func scheduleStreakReminder() {
        guard isAuthorized else { return }
        
        // Cancel existing streak reminder
        cancelStreakReminder()
        
        // Check if user has already completed a task today
        let tasksCompletedToday = StreakManager.shared.lastCompletionDate.map {
            Calendar.current.isDateInToday($0)
        } ?? false
        
        guard !tasksCompletedToday else { return }
        
        let content = createStreakReminderContent()
        
        // Schedule for 8 PM today (or tomorrow if already past 8 PM)
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        var triggerDate = Calendar.current.date(from: dateComponents)!
        if triggerDate < Date() {
            triggerDate = Calendar.current.date(byAdding: .day, value: 1, to: triggerDate)!
        }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: streakReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling streak reminder: \(error)")
            }
        }
    }
    
    func cancelStreakReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [streakReminderIdentifier])
    }
    
    func updateStreakReminder() {
        // Called when a task is completed - cancel current and reschedule for tomorrow
        cancelStreakReminder()
        scheduleStreakReminder()
    }
    
    // MARK: - Helper Methods
    
    private func taskReminderIdentifier(for task: TaskEntity) -> String {
        guard let id = task.id?.uuidString else { return "\(taskReminderPrefix)unknown" }
        return "\(taskReminderPrefix)\(id)"
    }
    
    private func calculateReminderDates(for dueDate: Date, isUrgent: Bool) -> [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        let now = Date()
        
        // Always add reminder at due date (if in future)
        if dueDate > now {
            dates.append(dueDate)
        }
        
        // For urgent tasks or tasks due within 24 hours, add earlier reminder
        let hoursUntilDue = calendar.dateComponents([.hour], from: now, to: dueDate).hour ?? 0
        
        if isUrgent || hoursUntilDue <= 24 {
            // Reminder 2 hours before
            if let twoHoursBefore = calendar.date(byAdding: .hour, value: -2, to: dueDate),
               twoHoursBefore > now {
                dates.insert(twoHoursBefore, at: 0)
            }
        }
        
        if hoursUntilDue > 24 {
            // Reminder 24 hours before for tasks further out
            if let dayBefore = calendar.date(byAdding: .day, value: -1, to: dueDate),
               dayBefore > now {
                dates.insert(dayBefore, at: 0)
            }
        }
        
        return dates
    }
    
    private func createTaskReminderContent(for task: TaskEntity, reminderIndex: Int, totalReminders: Int) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        
        // Title varies based on urgency and reminder sequence
        if task.isUrgent || task.isOverdue {
            content.title = "🔥 Urgent Task Reminder"
        } else if reminderIndex == totalReminders - 1 {
            content.title = "⏰ Task Due Soon"
        } else {
            content.title = "📸 Upcoming Task"
        }
        
        content.body = "\"\(task.title ?? "Task")\" is due \(formatDueDate(task.dueDate!))"
        content.sound = .default
        content.badge = 1
        
        // Add custom data for deep linking
        if let taskId = task.id?.uuidString {
            content.userInfo = ["taskId": taskId, "type": "taskReminder"]
        }
        
        return content
    }
    
    private func createStreakReminderContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        let streak = StreakManager.shared.currentStreak
        
        if streak > 0 {
            content.title = "🔥 Keep Your Streak Alive!"
            content.body = "You have a \(streak)-day streak going! Complete a task today to keep it growing. 🌱"
        } else {
            content.title = "🌱 Start Your Streak Today!"
            content.body = "Your plant is wilting. Complete a task to help it grow!"
        }
        
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "streakReminder"]
        
        return content
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "today at \(formatter.string(from: date))"
        } else if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: date, relativeTo: now)
        }
    }
    
    // MARK: - Debug
    
    func printScheduledNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            print("=== Scheduled Notifications (\(requests.count)) ===")
            for request in requests {
                print("- \(request.identifier)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("  Next: \(trigger.nextTriggerDate()?.description ?? "unknown")")
                }
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle deep linking from notification
        if let type = userInfo["type"] as? String {
            switch type {
            case "taskReminder":
                if let taskId = userInfo["taskId"] as? String {
                    NotificationCenter.default.post(
                        name: .openTaskDetail,
                        object: nil,
                        userInfo: ["taskId": taskId]
                    )
                }
            case "streakReminder":
                NotificationCenter.default.post(name: .openCapture, object: nil)
            default:
                break
            }
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let openTaskDetail = Notification.Name("tasksnap.openTaskDetail")
    static let openCapture = Notification.Name("tasksnap.openCapture")
}
