import Foundation
import Combine

class GamificationViewModel: ObservableObject {
    @Published var streakManager = StreakManager.shared
    @Published var achievementManager = AchievementManager.shared
    @Published var todayTasks: [TaskEntity] = []
    
    private let taskViewModel: TaskViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(taskViewModel: TaskViewModel = TaskViewModel()) {
        self.taskViewModel = taskViewModel
        
        // Check streak status on init
        streakManager.checkAndResetStreakIfNeeded()
        
        // Subscribe to task changes
        taskViewModel.$tasks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTodayTasks()
            }
            .store(in: &cancellables)
        
        updateTodayTasks()
    }
    
    private func updateTodayTasks() {
        todayTasks = taskViewModel.getTasksForToday()
    }
    
    var todayProgress: Double {
        let target = 5.0 // Target 5 tasks per day
        return min(Double(todayTasks.count) / target, 1.0)
    }
    
    var todayProgressPercentage: Int {
        Int(todayProgress * 100)
    }
    
    var plantSystemImage: String {
        // Return SF Symbol based on growth stage
        switch streakManager.plantGrowthStage {
        case 0:
            return "leaf.fill" // Wilted/small
        case 1...3:
            return "leaf.arrow.triangle.circlepath" // Sprouting
        case 4...6:
            return "tree" // Growing
        case 7...9:
            return "tree.fill" // Flourishing
        case 10:
            return "flower.fill" // Fully bloomed
        default:
            return "leaf.fill"
        }
    }
    
    var plantColor: String {
        switch streakManager.plantGrowthStage {
        case 0:
            return "plantWilted"
        case 1...3:
            return "plantSprout"
        case 4...6:
            return "plantGrowing"
        case 7...9:
            return "plantFlourishing"
        case 10:
            return "plantMature"
        default:
            return "plantSprout"
        }
    }
    
    var motivationalMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if streakManager.currentStreak == 0 {
            return "Start your streak today!"
        }
        
        if streakManager.isStreakAtRisk {
            return "Don't break your \(streakManager.currentStreak)-day streak!"
        }
        
        if hour < 12 {
            return "Good morning! Let's crush some tasks!"
        } else if hour < 17 {
            return "Keep the momentum going!"
        } else {
            return "Finish strong today!"
        }
    }
}
