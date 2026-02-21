import Foundation
import CoreData

// MARK: - Achievement
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: String
    let category: AchievementCategory
    let criteria: AchievementCriteria
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progress: Double
}

enum AchievementCategory: String, Codable, CaseIterable {
    case starter = "Getting Started"
    case streak = "Streaks"
    case productivity = "Productivity"
    case explorer = "Explorer"
    case master = "Master"
    
    var icon: String {
        switch self {
        case .starter: return "star.fill"
        case .streak: return "flame.fill"
        case .productivity: return "bolt.fill"
        case .explorer: return "compass.fill"
        case .master: return "crown.fill"
        }
    }
}

enum AchievementCriteria: Codable {
    case streak(days: Int)
    case tasksCompleted(count: Int)
    case tasksInCategory(category: String, count: Int)
    case morningTasks(count: Int) // Before 10 AM
    case eveningTasks(count: Int) // After 8 PM
    case quickCompleter(count: Int) // Complete within 1 hour of creation
    case consecutiveDays(count: Int) // Active on app for X days
    case photosTaken(count: Int) // Take before/after photos
    case urgentTasks(count: Int) // Complete urgent tasks
    case weekendWarrior // Complete tasks on weekends
    case perfectWeek // Complete at least 1 task every day for a week
    case categoryVariety(count: Int) // Use X different categories
    case longTask(hours: Int) // Tasks that take longer than X hours
    case earlyBird // Complete task before 7 AM
    case nightOwl // Complete task after 11 PM
    case bulkComplete(count: Int) // Complete X tasks in one day
}

class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    
    static let shared = AchievementManager()
    
    private let achievementsKey = "tasksnap.achievements"
    
    init() {
        loadAchievements()
        if achievements.isEmpty || achievements.count < 20 {
            setupAllAchievements()
        }
    }
    
    private func setupAllAchievements() {
        achievements = [
            // MARK: - Getting Started (5)
            Achievement(
                id: "first_task",
                title: "First Capture",
                description: "Create your first task",
                icon: "camera.fill",
                color: "achievementBronze",
                category: .starter,
                criteria: .tasksCompleted(count: 1),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "first_complete",
                title: "First Win",
                description: "Complete your first task",
                icon: "checkmark.circle.fill",
                color: "achievementBronze",
                category: .starter,
                criteria: .tasksCompleted(count: 1),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "photo_journalist",
                title: "Photo Journalist",
                description: "Take 5 before/after photo pairs",
                icon: "photo.fill",
                color: "achievementBronze",
                category: .starter,
                criteria: .photosTaken(count: 5),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "category_explorer",
                title: "Category Explorer",
                description: "Use 3 different task categories",
                icon: "folder.fill",
                color: "achievementBronze",
                category: .starter,
                criteria: .categoryVariety(count: 3),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "daily_user",
                title: "Daily User",
                description: "Open the app for 3 consecutive days",
                icon: "calendar",
                color: "achievementBronze",
                category: .starter,
                criteria: .consecutiveDays(count: 3),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            
            // MARK: - Streaks (5)
            Achievement(
                id: "streak_3",
                title: "Getting Started",
                description: "Complete tasks 3 days in a row",
                icon: "flame.fill",
                color: "achievementBronze",
                category: .streak,
                criteria: .streak(days: 3),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "streak_7",
                title: "Week Warrior",
                description: "Complete tasks 7 days in a row",
                icon: "flame.fill",
                color: "achievementSilver",
                category: .streak,
                criteria: .streak(days: 7),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "streak_14",
                title: "Two Week Titan",
                description: "Complete tasks 14 days in a row",
                icon: "flame.fill",
                color: "achievementSilver",
                category: .streak,
                criteria: .streak(days: 14),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "streak_30",
                title: "Momentum Master",
                description: "Complete tasks 30 days in a row",
                icon: "flame.fill",
                color: "achievementGold",
                category: .streak,
                criteria: .streak(days: 30),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "streak_100",
                title: "Century Club",
                description: "Complete tasks 100 days in a row",
                icon: "flame.fill",
                color: "achievementGold",
                category: .streak,
                criteria: .streak(days: 100),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            
            // MARK: - Productivity (5)
            Achievement(
                id: "morning_warrior",
                title: "Morning Warrior",
                description: "Complete 5 tasks before 10 AM",
                icon: "sun.max.fill",
                color: "achievementGold",
                category: .productivity,
                criteria: .morningTasks(count: 5),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "early_bird",
                title: "Early Bird",
                description: "Complete a task before 7 AM",
                icon: "sunrise.fill",
                color: "achievementSilver",
                category: .productivity,
                criteria: .earlyBird,
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "night_owl",
                title: "Night Owl",
                description: "Complete a task after 11 PM",
                icon: "moon.fill",
                color: "achievementSilver",
                category: .productivity,
                criteria: .nightOwl,
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "quick_winner",
                title: "Quick Winner",
                description: "Complete 5 tasks within an hour of creating them",
                icon: "bolt.fill",
                color: "achievementSilver",
                category: .productivity,
                criteria: .quickCompleter(count: 5),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "bulk_day",
                title: "Power Day",
                description: "Complete 5 tasks in a single day",
                icon: "checkmark.circle.badge.fill",
                color: "achievementGold",
                category: .productivity,
                criteria: .bulkComplete(count: 5),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            
            // MARK: - Explorer (5)
            Achievement(
                id: "clutter_buster",
                title: "Clutter Buster",
                description: "Complete 10 cleaning tasks",
                icon: "sparkles",
                color: "achievementSilver",
                category: .explorer,
                criteria: .tasksInCategory(category: "clean", count: 10),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "handyman",
                title: "Handy Person",
                description: "Complete 5 fix-it tasks",
                icon: "wrench.fill",
                color: "achievementBronze",
                category: .explorer,
                criteria: .tasksInCategory(category: "fix", count: 5),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "shopper",
                title: "Smart Shopper",
                description: "Complete 10 buy tasks",
                icon: "cart.fill",
                color: "achievementBronze",
                category: .explorer,
                criteria: .tasksInCategory(category: "buy", count: 10),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "category_master",
                title: "Category Master",
                description: "Use all 7 task categories",
                icon: "square.grid.2x2.fill",
                color: "achievementSilver",
                category: .explorer,
                criteria: .categoryVariety(count: 7),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "weekend_warrior",
                title: "Weekend Warrior",
                description: "Complete tasks on 4 different weekends",
                icon: "calendar.badge.clock",
                color: "achievementSilver",
                category: .explorer,
                criteria: .weekendWarrior,
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            
            // MARK: - Master (6)
            Achievement(
                id: "task_master",
                title: "Task Master",
                description: "Complete 50 tasks total",
                icon: "checkmark.seal.fill",
                color: "achievementGold",
                category: .master,
                criteria: .tasksCompleted(count: 50),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "task_legend",
                title: "Task Legend",
                description: "Complete 100 tasks total",
                icon: "crown.fill",
                color: "achievementGold",
                category: .master,
                criteria: .tasksCompleted(count: 100),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "urgent_handler",
                title: "Urgent Handler",
                description: "Complete 10 urgent tasks",
                icon: "exclamationmark.triangle.fill",
                color: "achievementSilver",
                category: .master,
                criteria: .urgentTasks(count: 10),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "perfect_week",
                title: "Perfect Week",
                description: "Complete at least 1 task every day for 7 days",
                icon: "calendar.badge.checkmark",
                color: "achievementGold",
                category: .master,
                criteria: .perfectWeek,
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "marathon_task",
                title: "Marathon Task",
                description: "Have a task in progress for over 24 hours before completing",
                icon: "timer",
                color: "achievementSilver",
                category: .master,
                criteria: .longTask(hours: 24),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "dedicated_user",
                title: "Dedicated User",
                description: "Open the app for 30 consecutive days",
                icon: "app.badge.fill",
                color: "achievementGold",
                category: .master,
                criteria: .consecutiveDays(count: 30),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            )
        ]
        saveAchievements()
    }
    
    func checkAchievements(streak: Int, tasksCompleted: Int, tasks: [TaskEntity]) {
        var updated = false
        let calendar = Calendar.current
        let now = Date()
        
        for index in achievements.indices where !achievements[index].isUnlocked {
            var shouldUnlock = false
            var progress: Double = 0
            
            switch achievements[index].criteria {
            case .streak(let days):
                progress = min(Double(streak) / Double(days), 1.0)
                shouldUnlock = streak >= days
                
            case .tasksCompleted(let count):
                progress = min(Double(tasksCompleted) / Double(count), 1.0)
                shouldUnlock = tasksCompleted >= count
                
            case .tasksInCategory(let category, let count):
                let categoryCount = tasks.filter { $0.taskCategory.rawValue == category && $0.taskStatus == .done }.count
                progress = min(Double(categoryCount) / Double(count), 1.0)
                shouldUnlock = categoryCount >= count
                
            case .morningTasks(let count):
                let morningCount = tasks.filter { task in
                    guard let completedAt = task.completedAt else { return false }
                    let hour = calendar.component(.hour, from: completedAt)
                    return task.taskStatus == .done && hour < 10
                }.count
                progress = min(Double(morningCount) / Double(count), 1.0)
                shouldUnlock = morningCount >= count
                
            case .eveningTasks(let count):
                let eveningCount = tasks.filter { task in
                    guard let completedAt = task.completedAt else { return false }
                    let hour = calendar.component(.hour, from: completedAt)
                    return task.taskStatus == .done && hour >= 20
                }.count
                progress = min(Double(eveningCount) / Double(count), 1.0)
                shouldUnlock = eveningCount >= count
                
            case .quickCompleter(let count):
                // Track in future version
                progress = 0
                shouldUnlock = false
                
            case .consecutiveDays, .photosTaken, .urgentTasks, .weekendWarrior, .perfectWeek, 
                 .categoryVariety, .longTask, .earlyBird, .nightOwl, .bulkComplete:
                // These need more complex tracking - implement incrementally
                progress = 0
                shouldUnlock = false
            }
            
            achievements[index].progress = progress
            
            if shouldUnlock && !achievements[index].isUnlocked {
                unlockAchievement(at: index)
                updated = true
            }
        }
        
        if updated {
            saveAchievements()
        }
    }
    
    func unlockAchievement(at index: Int) {
        achievements[index].isUnlocked = true
        achievements[index].unlockedAt = Date()
        
        // Play badge unlock animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AnimationManager.shared.play(.badgeUnlock)
        }
        
        // Post notification
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .achievementUnlocked,
                object: nil,
                userInfo: [
                    "achievement": self.achievements[index],
                    "name": self.achievements[index].title
                ]
            )
        }
    }
    
    // Helper to check specific achievement by ID
    func checkSpecificAchievement(id: String, tasks: [TaskEntity]) {
        guard let index = achievements.firstIndex(where: { $0.id == id && !$0.isUnlocked }) else { return }
        
        var shouldUnlock = false
        let calendar = Calendar.current
        
        switch achievements[index].criteria {
        case .earlyBird:
            shouldUnlock = tasks.contains { task in
                guard let completedAt = task.completedAt else { return false }
                return calendar.component(.hour, from: completedAt) < 7
            }
            
        case .nightOwl:
            shouldUnlock = tasks.contains { task in
                guard let completedAt = task.completedAt else { return false }
                return calendar.component(.hour, from: completedAt) >= 23
            }
            
        case .urgentTasks(let count):
            let urgentCount = tasks.filter { $0.isUrgent && $0.taskStatus == .done }.count
            shouldUnlock = urgentCount >= count
            achievements[index].progress = min(Double(urgentCount) / Double(count), 1.0)
            
        case .categoryVariety(let count):
            let categories = Set(tasks.filter { $0.taskStatus == .done }.map { $0.taskCategory.rawValue })
            shouldUnlock = categories.count >= count
            achievements[index].progress = min(Double(categories.count) / Double(count), 1.0)
            
        default:
            break
        }
        
        if shouldUnlock {
            unlockAchievement(at: index)
            saveAchievements()
        }
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: achievementsKey)
        }
    }
    
    private func loadAchievements() {
        guard let data = UserDefaults.standard.data(forKey: achievementsKey),
              let decoded = try? JSONDecoder().decode([Achievement].self, from: data) else {
            return
        }
        achievements = decoded
    }
    
    // MARK: - Stats
    
    var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }
    
    var totalCount: Int {
        achievements.count
    }
    
    var unlockedByCategory: [AchievementCategory: Int] {
        Dictionary(grouping: achievements.filter(\.isUnlocked), by: { $0.category })
            .mapValues { $0.count }
    }
    
    func achievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }
}

// MARK: - Achievement Notification
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("tasksnap.achievement.unlocked")
}
