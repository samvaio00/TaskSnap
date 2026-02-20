import Foundation
import CoreData
import SwiftUI
import Combine

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskEntity] = []
    @Published var todoTasks: [TaskEntity] = []
    @Published var doingTasks: [TaskEntity] = []
    @Published var doneTasks: [TaskEntity] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        fetchTasks()
    }
    
    func fetchTasks() {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)]
        
        do {
            tasks = try viewContext.fetch(request)
            categorizeTasks()
        } catch {
            print("Error fetching tasks: \(error)")
        }
    }
    
    private func categorizeTasks() {
        todoTasks = tasks.filter { $0.taskStatus == .todo }
        doingTasks = tasks.filter { $0.taskStatus == .doing }
        doneTasks = tasks.filter { $0.taskStatus == .done }
    }
    
    func createTask(title: String, description: String = "", category: TaskCategory, beforeImage: UIImage?, dueDate: Date? = nil, isUrgent: Bool = false) -> TaskEntity {
        let task = TaskEntity(context: viewContext)
        task.id = UUID()
        task.title = title
        task.taskDescription = description
        task.taskCategory = category
        task.taskStatus = .todo
        task.createdAt = Date()
        task.dueDate = dueDate
        task.isUrgent = isUrgent
        
        if let image = beforeImage {
            task.beforeImagePath = ImageStorage.shared.saveImage(image)
        }
        
        saveContext()
        fetchTasks()
        
        // Provide haptic feedback
        Haptics.shared.success()
        
        return task
    }
    
    func updateTaskStatus(_ task: TaskEntity, to status: TaskStatus) {
        task.taskStatus = status
        
        if status == .doing && task.startedAt == nil {
            task.startedAt = Date()
        }
        
        if status == .done && task.completedAt == nil {
            task.completedAt = Date()
            StreakManager.shared.recordTaskCompletion()
        }
        
        saveContext()
        fetchTasks()
    }
    
    func completeTask(_ task: TaskEntity, afterImage: UIImage?) {
        task.taskStatus = .done
        task.completedAt = Date()
        
        if let image = afterImage {
            task.afterImagePath = ImageStorage.shared.saveImage(image)
        }
        
        saveContext()
        fetchTasks()
        
        // Update streak and achievements
        StreakManager.shared.recordTaskCompletion()
        AchievementManager.shared.checkAchievements(
            streak: StreakManager.shared.currentStreak,
            tasksCompleted: doneTasks.count,
            tasks: tasks
        )
    }
    
    func updateTask(_ task: TaskEntity, title: String? = nil, description: String? = nil, dueDate: Date? = nil, isUrgent: Bool? = nil) {
        if let title = title {
            task.title = title
        }
        if let description = description {
            task.taskDescription = description
        }
        if let dueDate = dueDate {
            task.dueDate = dueDate
        }
        if let isUrgent = isUrgent {
            task.isUrgent = isUrgent
        }
        
        saveContext()
        fetchTasks()
    }
    
    func deleteTask(_ task: TaskEntity) {
        // Delete associated images
        if let beforePath = task.beforeImagePath {
            ImageStorage.shared.deleteImage(filename: beforePath)
        }
        if let afterPath = task.afterImagePath {
            ImageStorage.shared.deleteImage(filename: afterPath)
        }
        
        viewContext.delete(task)
        saveContext()
        fetchTasks()
    }
    
    func moveTask(_ task: TaskEntity, to status: TaskStatus) {
        updateTaskStatus(task, to: status)
    }
    
    func getTasksForToday() -> [TaskEntity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return doneTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= today && completedAt < tomorrow
        }
    }
    
    var totalCompletedCount: Int {
        doneTasks.count
    }
    
    var tasksCompletedToday: Int {
        getTasksForToday().count
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
