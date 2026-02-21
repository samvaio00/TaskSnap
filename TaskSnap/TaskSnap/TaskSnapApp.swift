import SwiftUI
import CoreData
import WidgetKit

@main
struct TaskSnapApp: App {
    let persistenceController = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showCaptureView = false
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    // MARK: - Launch Screen State
    @State private var showLaunchScreen = true
    @State private var launchScreenOpacity = 1.0

    var body: some Scene {
        WindowGroup {
            ZStack {
                // MARK: - Main App Content
                mainContent
                    .opacity(showLaunchScreen ? 0 : 1)
                    .animation(.easeIn(duration: 0.3), value: showLaunchScreen)
                
                // MARK: - Launch Screen Overlay
                if showLaunchScreen {
                    LaunchScreen()
                        .opacity(launchScreenOpacity)
                        .transition(.opacity)
                        .onAppear {
                            dismissLaunchScreen()
                        }
                }
            }
        }
    }
    
    // MARK: - Main Content View
    @ViewBuilder
    private var mainContent: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(accessibilitySettings)
                    .sheet(isPresented: $showCaptureView) {
                        CaptureView(
                            taskViewModel: TaskViewModel(context: persistenceController.container.viewContext),
                            isPresented: $showCaptureView
                        )
                    }
                    .onOpenURL { url in
                        handleURL(url)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .openCapture)) { _ in
                        showCaptureView = true
                    }
            } else {
                OnboardingView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(accessibilitySettings)
            }
        }
    }
    
    // MARK: - Launch Screen Dismissal
    private func dismissLaunchScreen() {
        // Wait 2.5 seconds then fade out launch screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                launchScreenOpacity = 0
            }
            
            // Remove from view hierarchy after fade completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showLaunchScreen = false
            }
        }
    }
    
    // MARK: - URL Handling
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

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure appearance
        UINavigationBar.appearance().tintColor = UIColor(named: "AccentColor")
        
        // Initialize achievement notification manager
        AchievementNotificationManager.initialize()
        
        // Initialize notification manager
        NotificationManager.shared.checkAuthorizationStatus()
        
        // Update widget data on launch
        WidgetDataManager.shared.updateWidgetData()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Update widget data when app becomes active
        WidgetDataManager.shared.updateWidgetData()
        
        // Check and update streak reminder when app becomes active
        NotificationManager.shared.scheduleStreakReminder()
        
        // Check if streak needs to be reset (user missed a day)
        StreakManager.shared.checkAndResetStreakIfNeeded()
        
        // Post notification to reset app to first tab
        NotificationCenter.default.post(name: .resetToDashboard, object: nil)
    }
}

// MARK: - Widget Data Manager
@MainActor
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
