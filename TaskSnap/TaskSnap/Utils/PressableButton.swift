import SwiftUI

// MARK: - Button Type
enum PressableButtonType {
    case primary
    case secondary
    case ghost
    case destructive
}

// MARK: - Pressable Button Style
struct PressableButtonStyle: ButtonStyle {
    let type: PressableButtonType
    let hapticEnabled: Bool
    let cornerRadius: CGFloat
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(
        type: PressableButtonType = .primary,
        hapticEnabled: Bool = true,
        cornerRadius: CGFloat = 12
    ) {
        self.type = type
        self.hapticEnabled = hapticEnabled
        self.cornerRadius = cornerRadius
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor(for: configuration))
            .foregroundColor(foregroundColor(for: configuration))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor(for: configuration), lineWidth: borderWidth)
            )
            .scaleEffect(scale(for: configuration))
            .opacity(opacity(for: configuration))
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && hapticEnabled {
                    Haptics.shared.buttonTap()
                }
            }
    }
    
    // MARK: - Style Helpers
    
    private func backgroundColor(for configuration: Configuration) -> Color {
        switch type {
        case .primary:
            return configuration.isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor
        case .secondary:
            return configuration.isPressed ? Color.accentColor.opacity(0.1) : Color.clear
        case .ghost:
            return configuration.isPressed ? Color.primary.opacity(0.1) : Color.clear
        case .destructive:
            return configuration.isPressed ? Color.red.opacity(0.8) : Color.red
        }
    }
    
    private func foregroundColor(for configuration: Configuration) -> Color {
        switch type {
        case .primary, .destructive:
            return .white
        case .secondary:
            return Color.accentColor
        case .ghost:
            return Color.primary
        }
    }
    
    private func borderColor(for configuration: Configuration) -> Color {
        switch type {
        case .primary, .destructive:
            return .clear
        case .secondary:
            return configuration.isPressed ? Color.accentColor.opacity(0.5) : Color.accentColor
        case .ghost:
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch type {
        case .secondary:
            return 1.5
        default:
            return 0
        }
    }
    
    // MARK: - Animation Helpers
    
    private func scale(for configuration: Configuration) -> CGFloat {
        guard !reduceMotion else { return 1.0 }
        return configuration.isPressed ? 0.95 : 1.0
    }
    
    private func opacity(for configuration: Configuration) -> Double {
        return configuration.isPressed ? 0.9 : 1.0
    }
}

// MARK: - Long Press Button Style
struct LongPressableButtonStyle: ButtonStyle {
    let type: PressableButtonType
    let hapticEnabled: Bool
    let cornerRadius: CGFloat
    let onLongPress: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isLongPressing = false
    @State private var longPressWorkItem: DispatchWorkItem?
    
    init(
        type: PressableButtonType = .primary,
        hapticEnabled: Bool = true,
        cornerRadius: CGFloat = 12,
        onLongPress: @escaping () -> Void
    ) {
        self.type = type
        self.hapticEnabled = hapticEnabled
        self.cornerRadius = cornerRadius
        self.onLongPress = onLongPress
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(backgroundColor(for: configuration))
            .foregroundColor(foregroundColor(for: configuration))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor(for: configuration), lineWidth: borderWidth)
            )
            .scaleEffect(scale(for: configuration))
            .opacity(opacity(for: configuration))
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isLongPressing)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    if hapticEnabled {
                        Haptics.shared.buttonTap()
                    }
                    startLongPressTimer()
                } else {
                    cancelLongPressTimer()
                }
            }
    }
    
    private func startLongPressTimer() {
        isLongPressing = false
        let workItem = DispatchWorkItem {
            isLongPressing = true
            if hapticEnabled {
                Haptics.shared.medium()
            }
            onLongPress()
        }
        longPressWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    private func cancelLongPressTimer() {
        longPressWorkItem?.cancel()
        longPressWorkItem = nil
        isLongPressing = false
    }
    
    // MARK: - Style Helpers (same as PressableButtonStyle)
    
    private func backgroundColor(for configuration: Configuration) -> Color {
        switch type {
        case .primary:
            return configuration.isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor
        case .secondary:
            return configuration.isPressed ? Color.accentColor.opacity(0.1) : Color.clear
        case .ghost:
            return configuration.isPressed ? Color.primary.opacity(0.1) : Color.clear
        case .destructive:
            return configuration.isPressed ? Color.red.opacity(0.8) : Color.red
        }
    }
    
    private func foregroundColor(for configuration: Configuration) -> Color {
        switch type {
        case .primary, .destructive:
            return .white
        case .secondary:
            return Color.accentColor
        case .ghost:
            return Color.primary
        }
    }
    
    private func borderColor(for configuration: Configuration) -> Color {
        switch type {
        case .primary, .destructive:
            return .clear
        case .secondary:
            return configuration.isPressed ? Color.accentColor.opacity(0.5) : Color.accentColor
        case .ghost:
            return .clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch type {
        case .secondary:
            return 1.5
        default:
            return 0
        }
    }
    
    private func scale(for configuration: Configuration) -> CGFloat {
        guard !reduceMotion else { return 1.0 }
        if isLongPressing {
            return 1.02
        }
        return configuration.isPressed ? 0.95 : 1.0
    }
    
    private func opacity(for configuration: Configuration) -> Double {
        return configuration.isPressed ? 0.9 : 1.0
    }
}

// MARK: - View Extension
extension View {
    func pressableButton(
        type: PressableButtonType = .primary,
        hapticEnabled: Bool = true,
        cornerRadius: CGFloat = 12
    ) -> some View {
        self.buttonStyle(PressableButtonStyle(
            type: type,
            hapticEnabled: hapticEnabled,
            cornerRadius: cornerRadius
        ))
    }
    
    func longPressableButton(
        type: PressableButtonType = .primary,
        hapticEnabled: Bool = true,
        cornerRadius: CGFloat = 12,
        onLongPress: @escaping () -> Void
    ) -> some View {
        self.buttonStyle(LongPressableButtonStyle(
            type: type,
            hapticEnabled: hapticEnabled,
            cornerRadius: cornerRadius,
            onLongPress: onLongPress
        ))
    }
}

// MARK: - Convenience Button View
struct PressableButton: View {
    let title: String
    let icon: String?
    let type: PressableButtonType
    let hapticEnabled: Bool
    let action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        type: PressableButtonType = .primary,
        hapticEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.type = type
        self.hapticEnabled = hapticEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
            }
        }
        .pressableButton(type: type, hapticEnabled: hapticEnabled)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        PressableButton(title: "Primary Button", icon: "star.fill", type: .primary) {}
        PressableButton(title: "Secondary Button", icon: "gear", type: .secondary) {}
        PressableButton(title: "Ghost Button", type: .ghost) {}
        PressableButton(title: "Destructive Button", icon: "trash", type: .destructive) {}
    }
    .padding()
}
