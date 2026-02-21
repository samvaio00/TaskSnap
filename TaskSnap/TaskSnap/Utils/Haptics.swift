import Foundation
import UIKit

@MainActor
class Haptics {
    static let shared = Haptics()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    private init() {
        // Prepare generators
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        selection.prepare()
        notification.prepare()
    }
    
    func light() {
        lightImpact.impactOccurred()
    }
    
    func medium() {
        mediumImpact.impactOccurred()
    }
    
    func heavy() {
        heavyImpact.impactOccurred()
    }
    
    func selectionChanged() {
        selection.selectionChanged()
    }
    
    func success() {
        notification.notificationOccurred(.success)
    }
    
    func error() {
        notification.notificationOccurred(.error)
    }
    
    func warning() {
        notification.notificationOccurred(.warning)
    }
    
    // MARK: - Custom patterns for specific interactions with sound effects
    
    /// Task completion: Success haptic + task complete sound
    func taskCompleted() {
        // Success followed by a light impact
        notification.notificationOccurred(.success)
        
        // Play sound effect
        SoundEffectManager.shared.play(.taskComplete)
        
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            self.lightImpact.impactOccurred()
        }
    }
    
    /// Task moved: Medium impact haptic + optional swipe sound
    func taskMoved() {
        mediumImpact.impactOccurred()
        SoundEffectManager.shared.play(.swipe)
    }
    
    /// Camera shutter: Heavy impact haptic + camera shutter sound
    func cameraShutter() {
        heavyImpact.impactOccurred()
        SoundEffectManager.shared.play(.cameraShutter)
    }
    
    /// Button tap: Light impact haptic + button tap sound
    func buttonTap() {
        lightImpact.impactOccurred()
        SoundEffectManager.shared.play(.buttonTap)
    }
    
    /// Achievement unlocked: Celebration pattern + achievement sound
    func achievementUnlocked() {
        // Celebration pattern: success + medium + success
        notification.notificationOccurred(.success)
        
        // Play achievement sound
        SoundEffectManager.shared.play(.achievement)
        
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            self.mediumImpact.impactOccurred()
            try? await Task.sleep(for: .milliseconds(150))
            self.notification.notificationOccurred(.success)
        }
    }
    
    /// Streak milestone: Success haptic + streak milestone sound
    func streakMilestone() {
        notification.notificationOccurred(.success)
        SoundEffectManager.shared.play(.streakMilestone)
    }
    
    /// Generic success with sound
    func successWithSound() {
        notification.notificationOccurred(.success)
        SoundEffectManager.shared.play(.success)
    }
    
    /// Error with sound
    func errorWithSound() {
        notification.notificationOccurred(.error)
        SoundEffectManager.shared.play(.error)
    }
    
    /// Pop animation with sound
    func pop() {
        lightImpact.impactOccurred()
        SoundEffectManager.shared.play(.pop)
    }
    
    /// Swipe gesture with sound
    func swipe() {
        lightImpact.impactOccurred()
        SoundEffectManager.shared.play(.swipe)
    }
}
