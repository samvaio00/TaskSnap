//
//  A_AchievementNotification.swift
//  TaskSnap
//
//  Achievement notification manager
//  Named with A_ prefix to ensure early compilation
//

import Foundation

class AchievementNotificationManager {
    static let shared = AchievementNotificationManager()
    
    private init() {
        // Listen for achievement unlock notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAchievementUnlocked(_:)),
            name: .achievementUnlocked,
            object: nil
        )
    }
    
    @objc private func handleAchievementUnlocked(_ notification: Notification) {
        guard let achievement = notification.userInfo?["achievement"] as? Achievement else { return }
        showAchievement(achievement)
    }
    
    func showAchievement(_ achievement: Achievement) {
        DispatchQueue.main.async {
            AchievementToastManager.shared.showToast(achievement: achievement)
        }
    }
    
    // Call this to ensure the singleton is initialized
    static func initialize() {
        _ = shared
    }
}
