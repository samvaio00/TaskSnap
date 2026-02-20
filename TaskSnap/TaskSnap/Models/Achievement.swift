import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: String
    let criteria: AchievementCriteria
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progress: Double
}

enum AchievementCriteria: Codable {
    case streak(days: Int)
    case tasksCompleted(count: Int)
    case tasksInCategory(category: String, count: Int)
    case morningTasks(count: Int) // Before 10 AM
    case eveningTasks(count: Int) // After 8 PM
    case quickCompleter(count: Int) // Complete within 1 hour of creation
}

class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    
    static let shared = AchievementManager()
    
    private let achievementsKey = "tasksnap.achievements"
    
    init() {
        loadAchievements()
        if achievements.isEmpty {
            setupDefaultAchievements()
        }
    }
    
    private func setupDefaultAchievements() {
        achievements = [
            Achievement(
                id: "first_task",
                title: "First Capture",
                description: "Create your first task",
                icon: "camera.fill",
                color: "achievementBronze",
                criteria: .tasksCompleted(count: 1),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "streak_3",
                title: "Getting Started",
                description: "Complete tasks 3 days in a row",
                icon: "flame.fill",
                color: "achievementBronze",
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
                criteria: .streak(days: 7),
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
                criteria: .streak(days: 30),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "morning_warrior",
                title: "Morning Warrior",
                description: "Complete 5 tasks before 10 AM",
                icon: "sun.max.fill",
                color: "achievementGold",
                criteria: .morningTasks(count: 5),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "clutter_buster",
                title: "Clutter Buster",
                description: "Complete 10 cleaning tasks",
                icon: "sparkles",
                color: "achievementSilver",
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
                criteria: .tasksInCategory(category: "fix", count: 5),
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
                criteria: .quickCompleter(count: 5),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            ),
            Achievement(
                id: "task_master",
                title: "Task Master",
                description: "Complete 50 tasks total",
                icon: "checkmark.seal.fill",
                color: "achievementGold",
                criteria: .tasksCompleted(count: 50),
                isUnlocked: false,
                unlockedAt: nil,
                progress: 0
            )
        ]
        saveAchievements()
    }
    
    func checkAchievements(streak: Int, tasksCompleted: Int, tasks: [TaskEntity]) {
        var updated = false
        
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
                    let hour = Calendar.current.component(.hour, from: completedAt)
                    return task.taskStatus == .done && hour < 10
                }.count
                progress = min(Double(morningCount) / Double(count), 1.0)
                shouldUnlock = morningCount >= count
                
            case .eveningTasks(let count):
                let eveningCount = tasks.filter { task in
                    guard let completedAt = task.completedAt else { return false }
                    let hour = Calendar.current.component(.hour, from: completedAt)
                    return task.taskStatus == .done && hour >= 20
                }.count
                progress = min(Double(eveningCount) / Double(count), 1.0)
                shouldUnlock = eveningCount >= count
                
            case .quickCompleter(let count):
                // This would need tracking of creation vs completion time
                progress = 0
                shouldUnlock = false
            }
            
            achievements[index].progress = progress
            
            if shouldUnlock && !achievements[index].isUnlocked {
                achievements[index].isUnlocked = true
                achievements[index].unlockedAt = Date()
                updated = true
                
                // Post notification for achievement unlock
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .achievementUnlocked,
                        object: nil,
                        userInfo: ["achievement": self.achievements[index]]
                    )
                }
            }
        }
        
        if updated {
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
    
    var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }
    
    var totalCount: Int {
        achievements.count
    }
}
