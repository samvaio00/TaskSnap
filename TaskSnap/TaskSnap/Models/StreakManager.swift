import Foundation

class StreakManager: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var lastCompletionDate: Date?
    @Published var plantGrowthStage: Int = 0
    
    static let shared = StreakManager()
    
    private let streakKey = "tasksnap.currentStreak"
    private let longestStreakKey = "tasksnap.longestStreak"
    private let lastCompletionKey = "tasksnap.lastCompletion"
    
    init() {
        loadStreakData()
    }
    
    private func loadStreakData() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
        lastCompletionDate = UserDefaults.standard.object(forKey: lastCompletionKey) as? Date
        updatePlantGrowthStage()
    }
    
    func recordTaskCompletion() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streakIncreased = false
        
        if let lastDate = lastCompletionDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            
            if calendar.isDate(today, inSameDayAs: lastDay) {
                // Already completed today, no streak change
                return
            } else if let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day {
                if daysBetween == 1 {
                    // Consecutive day - increase streak
                    currentStreak += 1
                    streakIncreased = true
                } else {
                    // Streak broken - reset
                    currentStreak = 1
                }
            }
        } else {
            // First completion ever
            currentStreak = 1
        }
        
        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        // Play streak grow animation if streak increased (and not first completion)
        if streakIncreased && currentStreak > 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                AnimationManager.shared.play(.streakGrow)
            }
        }
        
        lastCompletionDate = Date()
        updatePlantGrowthStage()
        saveStreakData()
    }
    
    func checkAndResetStreakIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lastDate = lastCompletionDate else { return }
        let lastDay = calendar.startOfDay(for: lastDate)
        
        if let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day {
            if daysBetween > 1 && currentStreak > 0 {
                // More than one day missed - streak broken
                let hadStreak = currentStreak > 1
                currentStreak = 0
                updatePlantGrowthStage()
                saveStreakData()
                
                // Play streak break animation if user had an active streak
                if hadStreak {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        AnimationManager.shared.play(.streakBreak)
                    }
                }
            }
        }
    }
    
    private func updatePlantGrowthStage() {
        // Plant grows based on streak and maxes out at stage 10
        plantGrowthStage = min(currentStreak, 10)
    }
    
    private func saveStreakData() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        UserDefaults.standard.set(lastCompletionDate, forKey: lastCompletionKey)
    }
    
    var plantImageName: String {
        if currentStreak == 0 {
            return "plant_wilted"
        }
        return "plant_stage_\(plantGrowthStage)"
    }
    
    var plantDescription: String {
        switch plantGrowthStage {
        case 0:
            return "Your plant needs care. Complete a task to help it grow!"
        case 1...3:
            return "Your sprout is growing! Keep going!"
        case 4...6:
            return "Your plant is thriving! Great work!"
        case 7...9:
            return "Your plant is flourishing! You're amazing!"
        case 10:
            return "Your plant is fully grown! You're a TaskSnap master!"
        default:
            return ""
        }
    }
    
    var isStreakAtRisk: Bool {
        guard let lastDate = lastCompletionDate else { return false }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastDate)
        
        if let daysBetween = calendar.dateComponents([.day], from: lastDay, to: today).day {
            return daysBetween == 1 && currentStreak > 0
        }
        return false
    }
}
