import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for preview
        for i in 0..<5 {
            let newTask = TaskEntity(context: viewContext)
            newTask.id = UUID()
            newTask.title = "Sample Task \(i + 1)"
            newTask.taskDescription = "Description for task \(i + 1)"
            newTask.status = ["todo", "doing", "done"][i % 3]
            newTask.category = ["clean", "fix", "buy", "work"][i % 4]
            newTask.createdAt = Date()
            newTask.dueDate = i < 2 ? Date().addingTimeInterval(86400) : nil
            newTask.isUrgent = i == 0
            newTask.beforeImagePath = nil
            newTask.afterImagePath = nil
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TaskSnap")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
