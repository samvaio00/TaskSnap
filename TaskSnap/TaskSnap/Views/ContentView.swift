import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var gamificationViewModel = GamificationViewModel()
    
    @State private var showingCaptureView = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView(
                taskViewModel: taskViewModel,
                gamificationViewModel: gamificationViewModel,
                onCaptureTap: { showingCaptureView = true }
            )
            .tabItem {
                Label("Tasks", systemImage: "square.grid.2x2")
            }
            .tag(0)
            
            // Streak Tab
            StreakView(gamificationViewModel: gamificationViewModel)
                .tabItem {
                    Label("Streak", systemImage: "flame.fill")
                }
                .tag(1)
            
            // Achievements Tab
            AchievementView()
                .tabItem {
                    Label("Awards", systemImage: "trophy.fill")
                }
                .tag(2)
        }
        .accentColor(.accentColor)
        .sheet(isPresented: $showingCaptureView) {
            CaptureView(taskViewModel: taskViewModel, isPresented: $showingCaptureView)
        }
        .onAppear {
            // Check streak status when app appears
            StreakManager.shared.checkAndResetStreakIfNeeded()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
