import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.reducedMotion) private var reducedMotion
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var gamificationViewModel: GamificationViewModel
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    @State private var showingCaptureView = false
    @State private var selectedTab = 0
    @State private var previousTab = 0
    
    // Animation namespace for matched geometry effects
    @Namespace private var animation
    
    // Tab configuration
    private let tabs: [TabItem] = [
        TabItem(index: 0, title: "Tasks", icon: "square.grid.2x2", accessibilityLabel: "Tasks Dashboard", accessibilityHint: "View and manage your tasks in kanban board view"),
        TabItem(index: 1, title: "Streak", icon: "flame.fill", accessibilityLabel: "Streak Tracker", accessibilityHint: "View your daily completion streak and plant growth"),
        TabItem(index: 2, title: "Awards", icon: "trophy.fill", accessibilityLabel: "Achievements", accessibilityHint: "View your earned badges and awards"),
        TabItem(index: 3, title: "Stats", icon: "chart.bar.fill", accessibilityLabel: "Statistics", accessibilityHint: "View your productivity analytics and insights"),
        TabItem(index: 4, title: "Focus", icon: "person.2.fill", accessibilityLabel: "Focus Room", accessibilityHint: "Join virtual body doubling sessions for accountability"),
        TabItem(index: 5, title: "Shared", icon: "person.3.fill", accessibilityLabel: "Shared Spaces", accessibilityHint: "View and collaborate on shared task spaces"),
        TabItem(index: 6, title: "Settings", icon: "gear", accessibilityLabel: "Settings", accessibilityHint: "Configure app preferences, sync, and themes")
    ]
    
    init() {
        // Initialize gamificationViewModel with shared context
        let context = PersistenceController.shared.container.viewContext
        _gamificationViewModel = StateObject(wrappedValue: GamificationViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Content area with transitions
                contentView
                    .padding(.bottom, 90) // Space for custom tab bar
                
                // Custom Tab Bar
                customTabBar
            }
            .ignoresSafeArea(.keyboard)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingCaptureView) {
            CaptureView(taskViewModel: taskViewModel, isPresented: $showingCaptureView)
        }
        .overlay(
            AchievementToastContainer()
        )
        .animationOverlay()
        .onAppear {
            // Check streak status when app appears
            StreakManager.shared.checkAndResetStreakIfNeeded()
        }
        .environmentObject(accessibilitySettings)
        .onReceive(NotificationCenter.default.publisher(for: .resetToDashboard)) { _ in
            // Reset to first tab when app becomes active
            withAnimation(accessibilitySettings.pageTransitionAnimation) {
                previousTab = selectedTab
                selectedTab = 0
            }
        }
    }
    
    // MARK: - Content View with Transitions
    private var contentView: some View {
        ZStack {
            // Dashboard Tab
            DashboardView(
                taskViewModel: taskViewModel,
                gamificationViewModel: gamificationViewModel,
                onCaptureTap: { showingCaptureView = true }
            )
            .opacity(selectedTab == 0 ? 1 : 0)
            .offset(x: tabOffset(for: 0))
            .zIndex(selectedTab == 0 ? 1 : 0)
            
            // Streak Tab
            StreakView(gamificationViewModel: gamificationViewModel)
                .opacity(selectedTab == 1 ? 1 : 0)
                .offset(x: tabOffset(for: 1))
                .zIndex(selectedTab == 1 ? 1 : 0)
            
            // Achievements Tab
            AchievementView()
                .opacity(selectedTab == 2 ? 1 : 0)
                .offset(x: tabOffset(for: 2))
                .zIndex(selectedTab == 2 ? 1 : 0)
            
            // Analytics Tab
            AnalyticsView()
                .opacity(selectedTab == 3 ? 1 : 0)
                .offset(x: tabOffset(for: 3))
                .zIndex(selectedTab == 3 ? 1 : 0)
            
            // Body Doubling Tab
            BodyDoublingRoomView()
                .opacity(selectedTab == 4 ? 1 : 0)
                .offset(x: tabOffset(for: 4))
                .zIndex(selectedTab == 4 ? 1 : 0)
            
            // Shared Spaces Tab
            SharedSpacesListView()
                .opacity(selectedTab == 5 ? 1 : 0)
                .offset(x: tabOffset(for: 5))
                .zIndex(selectedTab == 5 ? 1 : 0)
            
            // Settings Tab
            SettingsView()
                .opacity(selectedTab == 6 ? 1 : 0)
                .offset(x: tabOffset(for: 6))
                .zIndex(selectedTab == 6 ? 1 : 0)
        }
        .animation(accessibilitySettings.pageTransitionAnimation, value: selectedTab)
    }
    
    private func tabOffset(for tab: Int) -> CGFloat {
        guard selectedTab != tab else { return 0 }
        
        // Create a slide effect based on tab direction (disabled in reduced motion)
        guard !accessibilitySettings.reduceMotion else { return 0 }
        let direction = tab > selectedTab ? 1 : -1
        return CGFloat(direction) * 30
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(tabs) { tab in
                        tabButton(for: tab)
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 70)
            .background(
                Color(.systemBackground)
                    .opacity(0.95)
                    .background(.ultraThinMaterial)
            )
        }
    }
    
    private func tabButton(for tab: TabItem) -> some View {
        let isSelected = selectedTab == tab.index
        
        return Button {
            withAnimation(accessibilitySettings.pageTransitionAnimation) {
                previousTab = selectedTab
                selectedTab = tab.index
            }
            Haptics.shared.light()
        } label: {
            AccessibleTabLabel(
                tab: tab,
                isSelected: isSelected,
                namespace: animation
            )
        }
        .buttonStyle(AccessibleTabButtonStyle(accessibilitySettings: accessibilitySettings))
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityHint(tab.accessibilityHint)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Tab Item Model
struct TabItem: Identifiable {
    let id = UUID()
    let index: Int
    let title: String
    let icon: String
    let accessibilityLabel: String
    let accessibilityHint: String
}

// MARK: - Accessible Tab Label
struct AccessibleTabLabel: View {
    let tab: TabItem
    let isSelected: Bool
    var namespace: Namespace.ID
    
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    @Environment(\.sizeCategory) var sizeCategory
    
    var body: some View {
        VStack(spacing: spacing) {
            ZStack {
                // Active indicator background with high contrast support
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(HighContrastColors.accent.opacity(accessibilitySettings.highContrast ? 0.25 : 0.15))
                        .frame(width: 44, height: 36)
                        .highContrastBorder(cornerRadius: 12, lineWidth: 1, color: isSelected ? HighContrastColors.accent.opacity(0.5) : Color.clear)
                        .matchedGeometryEffect(id: "activeTab", in: namespace)
                }
                
                // Icon with morphing effect
                Image(systemName: tab.icon)
                    .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? HighContrastColors.accent : HighContrastColors.secondaryText)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(accessibilitySettings.gentleSpringAnimation, value: isSelected)
            }
            .frame(height: 36)
            
            // Tab title with Dynamic Type support
            Text(tab.title)
                .font(.caption2)
                .fontWeight(isSelected ? .medium : .regular)
                .foregroundColor(isSelected ? HighContrastColors.accent : HighContrastColors.secondaryText)
                .accessibleText(lineLimit: 1)
        }
        .frame(width: 60)
        .contentShape(Rectangle())
    }
    
    private var spacing: CGFloat {
        accessibilitySettings.isAccessibilitySize(sizeCategory) ? 6 : 4
    }
}

// MARK: - Tab Button Style
struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Accessible Tab Button Style
struct AccessibleTabButtonStyle: ButtonStyle {
    let accessibilitySettings: AccessibilitySettings
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? accessibilitySettings.pressedScaleEffect : 1.0)
            .animation(accessibilitySettings.quickAnimationDuration > 0 ? .easeInOut(duration: 0.1) : .none, value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
