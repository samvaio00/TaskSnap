import CoreData
import Foundation
import CloudKit

class PersistenceController: ObservableObject {
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

    let container: NSPersistentCloudKitContainer
    private let cloudKitContainerIdentifier = "iCloud.com.warnergears.TaskSnap"
    private var cloudKitEnabled = false

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "TaskSnap")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            setupStoreDescription()
        }
        
        container.loadPersistentStores(completionHandler: { [weak self] (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            // Setup CloudKit sync notifications
            self?.setupCloudKitNotifications()
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Use a merge policy that prefers the most recent change
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
    }
    
    // MARK: - CloudKit Notifications
    
    private func setupCloudKitNotifications() {
        // Listen for remote changes from CloudKit
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
    }
    
    @objc private func handleRemoteChange(_ notification: Notification) {
        print("CloudKit remote change received")
        
        // Process history changes to update UI
        container.viewContext.perform { [weak self] in
            // Refresh all objects to get latest CloudKit data
            self?.container.viewContext.refreshAllObjects()
            
            // Post notification to refresh UI
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .cloudKitSyncCompleted, object: nil)
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupStoreDescription() {
        guard let description = container.persistentStoreDescriptions.first else { return }
        
        // Enable history tracking (needed for both local and CloudKit)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        
        // Check if CloudKit was previously enabled
        if SyncManager.shared.isSyncEnabled {
            enableCloudKitSync(in: description)
        }
    }
    
    // MARK: - CloudKit Toggle
    
    func enableCloudKit(completion: @escaping (Bool) -> Void) {
        guard !cloudKitEnabled else {
            completion(true)
            return
        }
        
        guard let description = container.persistentStoreDescriptions.first else {
            completion(false)
            return
        }
        
        enableCloudKitSync(in: description)
        
        // Reload store with CloudKit
        reloadStore { success in
            self.cloudKitEnabled = success
            completion(success)
        }
    }
    
    func disableCloudKit() {
        guard cloudKitEnabled,
              let description = container.persistentStoreDescriptions.first else { return }
        
        // Remove CloudKit options
        description.cloudKitContainerOptions = nil
        
        // Reload without CloudKit
        reloadStore { _ in
            self.cloudKitEnabled = false
        }
    }
    
    private func enableCloudKitSync(in description: NSPersistentStoreDescription) {
        let cloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudKitContainerIdentifier)
        description.cloudKitContainerOptions = cloudKitOptions
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    }
    
    private func reloadStore(completion: @escaping (Bool) -> Void) {
        let storeURL = container.persistentStoreDescriptions.first?.url
        
        // Remove existing store
        if let coordinator = container.persistentStoreCoordinator.persistentStores.first {
            do {
                try container.persistentStoreCoordinator.remove(coordinator)
            } catch {
                print("Error removing store: \(error)")
                completion(false)
                return
            }
        }
        
        // Reload with new configuration
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error reloading store: \(error)")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    // MARK: - Sync Status
    
    var isCloudKitEnabled: Bool {
        cloudKitEnabled
    }
    
    // MARK: - Save
    
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
