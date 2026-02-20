import SwiftUI
import CoreData
import WidgetKit

@main
struct TaskSnapApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showCaptureView = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .sheet(isPresented: $showCaptureView) {
                            CaptureView(
                                taskViewModel: TaskViewModel(context: persistenceController.container.viewContext),
                                isPresented: $showCaptureView
                            )
                        }
                        .onOpenURL { url in
                            handleURL(url)
                        }
                } else {
                    OnboardingView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
            }
        }
    }
    
    private func handleURL(_ url: URL) {
        guard url.scheme == "tasksnap" else { return }
        
        switch url.host {
        case "capture":
            showCaptureView = true
        default:
            break
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure appearance
        UINavigationBar.appearance().tintColor = UIColor(named: "AccentColor")
        
        // Initialize achievement notification manager
        AchievementNotificationManager.initialize()
        
        // Update widget data on launch
        WidgetDataManager.shared.updateWidgetData()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Update widget data when app becomes active
        WidgetDataManager.shared.updateWidgetData()
    }
}

// MARK: - Widget Data Manager
class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let sharedDefaults = UserDefaults(suiteName: "group.com.warnergears.TaskSnap")
    private let context = PersistenceController.shared.container.viewContext
    
    func updateWidgetData() {
        // Get task counts
        let taskCount = getTaskCount(status: "todo") + getTaskCount(status: "doing")
        let urgentCount = getUrgentTaskCount()
        let streak = StreakManager.shared.currentStreak
        
        // Save to shared UserDefaults
        sharedDefaults?.set(taskCount, forKey: "widgetTasksCount")
        sharedDefaults?.set(urgentCount, forKey: "widgetUrgentTasks")
        sharedDefaults?.set(streak, forKey: "widgetStreakCount")
        
        // Trigger widget reload
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func getTaskCount(status: String) -> Int {
        let request = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", status)
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting tasks: \(error)")
            return 0
        }
    }
    
    private func getUrgentTaskCount() -> Int {
        let request = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isUrgent == YES AND status != 'done'")
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting urgent tasks: \(error)")
            return 0
        }
    }
}
