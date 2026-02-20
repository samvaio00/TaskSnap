import Foundation
import Combine
import CoreData

class GamificationViewModel: NSObject, ObservableObject {
    @Published var streakManager = StreakManager.shared
    @Published var achievementManager = AchievementManager.shared
    @Published var todayTasks: [TaskEntity] = []
    
    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    private var fetchController: NSFetchedResultsController<TaskEntity>?
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        super.init()
        
        // Check streak status on init
        streakManager.checkAndResetStreakIfNeeded()
        
        // Setup fetch controller to monitor Core Data changes
        setupFetchController()
        
        // Initial fetch
        fetchTodayTasks()
    }
    
    private func setupFetchController() {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.completedAt, ascending: false)]
        
        fetchController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        fetchController?.delegate = self
        
        do {
            try fetchController?.performFetch()
            fetchTodayTasks()
        } catch {
            print("Error setting up fetch controller: \(error)")
        }
    }
    
    private func fetchTodayTasks() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "status == 'done' AND completedAt >= %@ AND completedAt < %@",
            today as NSDate,
            tomorrow as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.completedAt, ascending: false)]
        
        do {
            todayTasks = try viewContext.fetch(request)
            print("Fetched \(todayTasks.count) tasks for today")
        } catch {
            print("Error fetching today's tasks: \(error)")
            todayTasks = []
        }
    }
    
    func hasTasksFor(date: Date) -> Bool {
        return getTasksFor(date: date).count > 0
    }
    
    func getTasksFor(date: Date) -> [TaskEntity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "status == 'done' AND completedAt >= %@ AND completedAt < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching tasks for date: \(error)")
            return []
        }
    }
    
    var todayProgress: Double {
        let target = 3.0 // Target 3 tasks per day
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
        let count = todayTasks.count
        
        if streakManager.currentStreak == 0 {
            return "Start your streak today!"
        }
        
        if streakManager.isStreakAtRisk {
            return "Don't break your \(streakManager.currentStreak)-day streak!"
        }
        
        if count == 0 {
            return "Complete a task to keep your streak!"
        } else if count < 3 {
            return "Great start! Keep going!"
        } else {
            return "Amazing productivity today! 🔥"
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension GamificationViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        DispatchQueue.main.async {
            self.fetchTodayTasks()
        }
    }
}
