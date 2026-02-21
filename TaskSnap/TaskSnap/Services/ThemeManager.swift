import Foundation
import Combine
import CoreData

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var selectedTheme: CelebrationTheme = .classic
    @Published var unlockedThemes: Set<String> = [CelebrationTheme.classic.rawValue]
    @Published var themeProgress: [CelebrationTheme: Double] = [:]
    
    private let selectedThemeKey = "tasksnap.selectedTheme"
    private let unlockedThemesKey = "tasksnap.unlockedThemes"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSavedData()
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func loadSavedData() {
        // Load selected theme
        if let savedTheme = UserDefaults.standard.string(forKey: selectedThemeKey),
           let theme = CelebrationTheme(rawValue: savedTheme) {
            selectedTheme = theme
        }
        
        // Load unlocked themes
        if let savedUnlocked = UserDefaults.standard.array(forKey: unlockedThemesKey) as? [String] {
            unlockedThemes = Set(savedUnlocked)
        } else {
            // Default: only classic is unlocked
            unlockedThemes = [CelebrationTheme.classic.rawValue]
        }
        
        // Initialize progress
        updateThemeProgress()
    }
    
    private func setupObservers() {
        // Listen for streak updates
        NotificationCenter.default.publisher(for: .streakUpdated)
            .sink { [weak self] _ in
                self?.checkThemeUnlocks()
            }
            .store(in: &cancellables)
        
        // Listen for achievement unlocks
        NotificationCenter.default.publisher(for: .achievementUnlocked)
            .sink { [weak self] notification in
                if let achievementName = notification.userInfo?["name"] as? String {
                    self?.checkAchievementBasedUnlocks(achievementName: achievementName)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Theme Selection
    
    func selectTheme(_ theme: CelebrationTheme) {
        guard isThemeUnlocked(theme) else { return }
        
        selectedTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: selectedThemeKey)
        
        Haptics.shared.success()
    }
    
    func isThemeUnlocked(_ theme: CelebrationTheme) -> Bool {
        // Pro themes are always unlocked for Pro users
        if theme.isProOnly {
            return isProUser
        }
        
        return unlockedThemes.contains(theme.rawValue)
    }
    
    // MARK: - Theme Unlocking
    
    func checkThemeUnlocks() {
        let currentStreak = StreakManager.shared.currentStreak
        let totalCompleted = getTotalCompletedTasks()
        
        for theme in CelebrationTheme.allCases {
            // Skip if already unlocked or Pro-only
            guard !isThemeUnlocked(theme) else { continue }
            guard !theme.isProOnly else { continue }
            
            let shouldUnlock: Bool
            let progress: Double
            
            switch theme.unlockRequirement {
            case .default:
                shouldUnlock = true
                progress = 1.0
                
            case .streak(let requiredDays):
                shouldUnlock = currentStreak >= requiredDays
                progress = min(Double(currentStreak) / Double(requiredDays), 1.0)
                
            case .tasksCompleted(let requiredCount):
                shouldUnlock = totalCompleted >= requiredCount
                progress = min(Double(totalCompleted) / Double(requiredCount), 1.0)
                
            case .achievement, .proOnly:
                continue // Handled separately
            }
            
            themeProgress[theme] = progress
            
            if shouldUnlock {
                unlockTheme(theme)
            }
        }
    }
    
    private func checkAchievementBasedUnlocks(achievementName: String) {
        for theme in CelebrationTheme.allCases {
            guard !isThemeUnlocked(theme) else { continue }
            
            if case .achievement(let requiredAchievement) = theme.unlockRequirement,
               requiredAchievement == achievementName {
                unlockTheme(theme)
            }
        }
    }
    
    private func unlockTheme(_ theme: CelebrationTheme) {
        unlockedThemes.insert(theme.rawValue)
        saveUnlockedThemes()
        
        // Post notification
        NotificationCenter.default.post(
            name: .themeUnlocked,
            object: nil,
            userInfo: ["theme": theme.rawValue]
        )
        
        // Show toast notification
        DispatchQueue.main.async {
            AchievementToastManager.shared.showToast(
                title: "Theme Unlocked!",
                subtitle: theme.displayName,
                icon: theme.icon,
                color: "achievementGold"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTotalCompletedTasks() -> Int {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == 'done'")
        
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    private func updateThemeProgress() {
        let currentStreak = StreakManager.shared.currentStreak
        let totalCompleted = getTotalCompletedTasks()
        
        for theme in CelebrationTheme.allCases {
            switch theme.unlockRequirement {
            case .streak(let requiredDays):
                themeProgress[theme] = min(Double(currentStreak) / Double(requiredDays), 1.0)
            case .tasksCompleted(let requiredCount):
                themeProgress[theme] = min(Double(totalCompleted) / Double(requiredCount), 1.0)
            default:
                themeProgress[theme] = isThemeUnlocked(theme) ? 1.0 : 0.0
            }
        }
    }
    
    private func saveUnlockedThemes() {
        UserDefaults.standard.set(Array(unlockedThemes), forKey: unlockedThemesKey)
    }
    
    // MARK: - Pro Status
    
    var isProUser: Bool {
        // TODO: Integrate with actual purchase verification
        // For now, check UserDefaults
        UserDefaults.standard.bool(forKey: "tasksnap.isProUser")
    }
    
    func unlockAllThemesForPro() {
        for theme in CelebrationTheme.allCases where theme.isProOnly {
            unlockedThemes.insert(theme.rawValue)
        }
        saveUnlockedThemes()
    }
    
    // MARK: - Preview Helper
    
    func unlockAllThemesForPreview() {
        for theme in CelebrationTheme.allCases {
            unlockedThemes.insert(theme.rawValue)
        }
        saveUnlockedThemes()
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let themeUnlocked = Notification.Name("tasksnap.themeUnlocked")
    static let streakUpdated = Notification.Name("tasksnap.streakUpdated")
}
