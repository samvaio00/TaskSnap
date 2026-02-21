import SwiftUI
import Combine

/// Manages accessibility preferences for TaskSnap
/// Respects system settings by default but allows app-specific overrides
@MainActor
class AccessibilitySettings: ObservableObject {
    static let shared = AccessibilitySettings()
    
    // MARK: - Published Properties
    
    /// Reduces motion animations throughout the app
    @Published var reduceMotion: Bool {
        didSet {
            UserDefaults.standard.set(reduceMotion, forKey: "reduceMotion")
            UserDefaults.standard.set(true, forKey: "reduceMotionOverridden")
        }
    }
    
    /// Enables high contrast mode for better visibility
    @Published var highContrast: Bool {
        didSet {
            UserDefaults.standard.set(highContrast, forKey: "highContrast")
        }
    }
    
    /// Shows button shapes for clearer boundaries
    @Published var buttonShapes: Bool {
        didSet {
            UserDefaults.standard.set(buttonShapes, forKey: "buttonShapes")
        }
    }
    
    /// Whether reduce motion has been manually overridden from system setting
    @Published private(set) var reduceMotionOverridden: Bool
    
    // MARK: - Animation Properties
    
    /// Standard animation duration (0 for reduced motion)
    var standardAnimationDuration: Double {
        reduceMotion ? 0 : 0.3
    }
    
    /// Quick animation duration for small UI changes
    var quickAnimationDuration: Double {
        reduceMotion ? 0 : 0.2
    }
    
    /// Spring animation that respects reduce motion preference
    var springAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.7)
    }
    
    /// Bouncy animation that respects reduce motion preference
    var bouncyAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.6)
    }
    
    /// Gentle spring for subtle interactions
    var gentleSpringAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .gentleSpring()
    }
    
    /// Page transition animation
    var pageTransitionAnimation: Animation {
        reduceMotion ? .none : .easeInOut(duration: 0.3)
    }
    
    /// Card entrance animation
    var cardEntranceAnimation: Animation? {
        reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7).delay(0.1)
    }
    
    /// Drag animation
    var dragAnimation: Animation {
        reduceMotion ? .linear(duration: 0.1) : .spring(response: 0.3, dampingFraction: 0.8)
    }
    
    /// Scale effect for pressed state (less reduction in reduced motion)
    var pressedScaleEffect: CGFloat {
        reduceMotion ? 0.98 : 0.95
    }
    
    /// Whether to show celebratory animations
    var shouldShowCelebrations: Bool {
        !reduceMotion
    }
    
    // MARK: - Dynamic Type Support
    
    /// Minimum scale factor for dynamic type support
    var minimumScaleFactor: CGFloat {
        0.5
    }
    
    /// Maximum line limit for accessibility text
    var maximumLineLimit: Int? {
        nil // No limit for accessibility
    }
    
    // MARK: - Touch Target Sizes
    
    /// Minimum touch target size for accessibility (44pt is iOS standard)
    var minimumTouchTargetSize: CGFloat {
        44
    }
    
    /// Larger touch target size for high accessibility sizes
    var largeTouchTargetSize: CGFloat {
        56
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter: NotificationCenter
    
    // MARK: - Initialization
    
    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        
        // Check if user has overridden reduce motion setting
        let overridden = UserDefaults.standard.bool(forKey: "reduceMotionOverridden")
        self.reduceMotionOverridden = overridden
        
        if overridden {
            // Use user's explicit preference
            self.reduceMotion = UserDefaults.standard.bool(forKey: "reduceMotion")
        } else {
            // Default to system setting
            self.reduceMotion = UIAccessibility.isReduceMotionEnabled
        }
        
        self.highContrast = UserDefaults.standard.bool(forKey: "highContrast")
        self.buttonShapes = UserDefaults.standard.bool(forKey: "buttonShapes")
        
        setupSystemSettingObserver()
    }
    
    // MARK: - System Setting Observation
    
    private func setupSystemSettingObserver() {
        // Listen for system accessibility setting changes
        notificationCenter.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Only update if user hasn't manually overridden
                if !self.reduceMotionOverridden {
                    self.reduceMotion = UIAccessibility.isReduceMotionEnabled
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Reset reduce motion to system default
    func resetReduceMotionToSystemDefault() {
        reduceMotionOverridden = false
        UserDefaults.standard.set(false, forKey: "reduceMotionOverridden")
        reduceMotion = UIAccessibility.isReduceMotionEnabled
    }
    
    /// Reset all accessibility settings to defaults
    func resetToDefaults() {
        resetReduceMotionToSystemDefault()
        highContrast = false
        buttonShapes = false
    }
    
    /// Check if the current dynamic type size is an accessibility size
    func isAccessibilitySize(_ sizeCategory: ContentSizeCategory) -> Bool {
        sizeCategory >= .accessibilityMedium
    }
}

// MARK: - Environment Key

private struct AccessibilitySettingsKey: EnvironmentKey {
    static let defaultValue = AccessibilitySettings.shared
}

extension EnvironmentValues {
    var accessibilitySettings: AccessibilitySettings {
        get { self[AccessibilitySettingsKey.self] }
        set { self[AccessibilitySettingsKey.self] = newValue }
    }
}

// MARK: - View Modifiers

/// View modifier that applies button shape styling based on accessibility settings
struct AccessibleButtonShapeModifier: ViewModifier {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    func body(content: Content) -> some View {
        content
            .if(accessibilitySettings.buttonShapes) { view in
                view.overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                )
            }
    }
}

/// View modifier for accessible touch targets
struct AccessibleTouchTargetModifier: ViewModifier {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    @Environment(\.sizeCategory) var sizeCategory
    
    func body(content: Content) -> some View {
        content
            .frame(minHeight: accessibilitySettings.isAccessibilitySize(sizeCategory) 
                   ? accessibilitySettings.largeTouchTargetSize 
                   : accessibilitySettings.minimumTouchTargetSize)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies button shapes when the setting is enabled
    func accessibleButtonShape() -> some View {
        self.modifier(AccessibleButtonShapeModifier())
    }
    
    /// Ensures minimum touch target size for accessibility
    func accessibleTouchTarget() -> some View {
        self.modifier(AccessibleTouchTargetModifier())
    }
    
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview Helpers

extension AccessibilitySettings {
    static var preview: AccessibilitySettings {
        let settings = AccessibilitySettings()
        settings.reduceMotion = false
        settings.highContrast = false
        settings.buttonShapes = false
        return settings
    }
    
    static var previewReducedMotion: AccessibilitySettings {
        let settings = AccessibilitySettings()
        settings.reduceMotion = true
        settings.highContrast = false
        settings.buttonShapes = false
        return settings
    }
    
    static var previewHighContrast: AccessibilitySettings {
        let settings = AccessibilitySettings()
        settings.reduceMotion = false
        settings.highContrast = true
        settings.buttonShapes = true
        return settings
    }
}
