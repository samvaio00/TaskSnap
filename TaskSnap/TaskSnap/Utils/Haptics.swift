import Foundation
import UIKit

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
    
    // Custom patterns for specific interactions
    func taskCompleted() {
        // Success followed by a light impact
        notification.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact.impactOccurred()
        }
    }
    
    func taskMoved() {
        mediumImpact.impactOccurred()
    }
    
    func cameraShutter() {
        heavyImpact.impactOccurred()
    }
    
    func buttonTap() {
        lightImpact.impactOccurred()
    }
}
