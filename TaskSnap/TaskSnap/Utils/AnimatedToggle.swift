import SwiftUI

// MARK: - Toggle Size
enum AnimatedToggleSize {
    case small
    case regular
    case large
    
    var width: CGFloat {
        switch self {
        case .small: return 40
        case .regular: return 52
        case .large: return 68
        }
    }
    
    var height: CGFloat {
        switch self {
        case .small: return 24
        case .regular: return 32
        case .large: return 40
        }
    }
    
    var knobSize: CGFloat {
        switch self {
        case .small: return 18
        case .regular: return 26
        case .large: return 34
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 8
        case .regular: return 12
        case .large: return 16
        }
    }
}

// MARK: - Animated Toggle Style
struct AnimatedToggleStyle: ToggleStyle {
    let size: AnimatedToggleSize
    let showIcons: Bool
    let onColor: Color
    let offColor: Color
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(
        size: AnimatedToggleSize = .regular,
        showIcons: Bool = true,
        onColor: Color = .green,
        offColor: Color = Color(.systemGray4)
    ) {
        self.size = size
        self.showIcons = showIcons
        self.onColor = onColor
        self.offColor = offColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ToggleShape(
                isOn: configuration.isOn,
                size: size,
                showIcons: showIcons,
                onColor: onColor,
                offColor: offColor,
                reduceMotion: reduceMotion
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
                // Haptic feedback
                Haptics.shared.selectionChanged()
            }
        }
    }
}

// MARK: - Toggle Shape
private struct ToggleShape: View {
    let isOn: Bool
    let size: AnimatedToggleSize
    let showIcons: Bool
    let onColor: Color
    let offColor: Color
    let reduceMotion: Bool
    
    @State private var knobScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background track
            RoundedRectangle(cornerRadius: size.height / 2)
                .fill(isOn ? onColor : offColor)
                .frame(width: size.width, height: size.height)
            
            // Knob
            HStack {
                if isOn {
                    Spacer()
                }
                
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: size.knobSize, height: size.knobSize)
                        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                    
                    // Icons inside knob
                    if showIcons {
                        Image(systemName: isOn ? "checkmark" : "xmark")
                            .font(.system(size: size.iconSize, weight: .bold))
                            .foregroundColor(isOn ? onColor : offColor)
                            .opacity(0.8)
                    }
                }
                .scaleEffect(knobScale)
                .padding(3)
                
                if !isOn {
                    Spacer()
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: isOn) { _, _ in
            guard !reduceMotion else { return }
            // Bounce effect on toggle
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                knobScale = 0.85
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    knobScale = 1.0
                }
            }
        }
    }
}

// MARK: - Standalone Animated Toggle View
struct AnimatedToggle: View {
    @Binding var isOn: Bool
    let title: String?
    let description: String?
    let size: AnimatedToggleSize
    let showIcons: Bool
    let onColor: Color
    let offColor: Color
    let hapticEnabled: Bool
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(
        isOn: Binding<Bool>,
        title: String? = nil,
        description: String? = nil,
        size: AnimatedToggleSize = .regular,
        showIcons: Bool = true,
        onColor: Color = .green,
        offColor: Color? = nil,
        hapticEnabled: Bool = true
    ) {
        self._isOn = isOn
        self.title = title
        self.description = description
        self.size = size
        self.showIcons = showIcons
        self.onColor = onColor
        self.offColor = offColor ?? Color(.systemGray4)
        self.hapticEnabled = hapticEnabled
    }
    
    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
                isOn.toggle()
            }
            if hapticEnabled {
                Haptics.shared.selectionChanged()
            }
        } label: {
            HStack(spacing: 12) {
                if let title = title {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        if let description = description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                ToggleShape(
                    isOn: isOn,
                    size: size,
                    showIcons: showIcons,
                    onColor: onColor,
                    offColor: offColor,
                    reduceMotion: reduceMotion
                )
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
    }
    
    private var accessibilityLabel: String {
        title ?? "Toggle"
    }
    
    private var accessibilityHint: String {
        description ?? "Double tap to toggle \(isOn ? "off" : "on")"
    }
}

// MARK: - Settings Toggle Row View
struct SettingsToggleRow: View {
    let icon: String?
    let iconColor: Color
    let title: String
    let description: String?
    @Binding var isOn: Bool
    let size: AnimatedToggleSize
    let showIcons: Bool
    let onColor: Color
    let hapticEnabled: Bool
    let onToggle: ((Bool) -> Void)?
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    init(
        icon: String? = nil,
        iconColor: Color = .accentColor,
        title: String,
        description: String? = nil,
        isOn: Binding<Bool>,
        size: AnimatedToggleSize = .regular,
        showIcons: Bool = true,
        onColor: Color = .green,
        hapticEnabled: Bool = true,
        onToggle: ((Bool) -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.description = description
        self._isOn = isOn
        self.size = size
        self.showIcons = showIcons
        self.onColor = onColor
        self.hapticEnabled = hapticEnabled
        self.onToggle = onToggle
    }
    
    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
                isOn.toggle()
            }
            if hapticEnabled {
                Haptics.shared.selectionChanged()
            }
            onToggle?(isOn)
        } label: {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .frame(width: 32)
                        .foregroundColor(iconColor)
                        .accessibilityHidden(true)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                ToggleShape(
                    isOn: isOn,
                    size: size,
                    showIcons: showIcons,
                    onColor: onColor,
                    offColor: Color(.systemGray4),
                    reduceMotion: reduceMotion
                )
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description ?? "Double tap to toggle \(isOn ? "off" : "on")")
        .accessibilityValue(isOn ? "Enabled" : "Disabled")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - View Extensions
extension View {
    func animatedToggleStyle(
        size: AnimatedToggleSize = .regular,
        showIcons: Bool = true,
        onColor: Color = .green,
        offColor: Color = Color(.systemGray4)
    ) -> some View {
        self.toggleStyle(AnimatedToggleStyle(
            size: size,
            showIcons: showIcons,
            onColor: onColor,
            offColor: offColor
        ))
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var isOn1 = true
        @State private var isOn2 = false
        @State private var isOn3 = true
        @State private var isOn4 = false
        
        var body: some View {
            List {
                Section("Sizes") {
                    SettingsToggleRow(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: "Small Toggle",
                        description: "Compact size for dense UIs",
                        isOn: $isOn1,
                        size: .small
                    )
                    
                    SettingsToggleRow(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: "Regular Toggle",
                        description: "Standard size (default)",
                        isOn: $isOn2,
                        size: .regular
                    )
                    
                    SettingsToggleRow(
                        icon: "bell.fill",
                        iconColor: .orange,
                        title: "Large Toggle",
                        description: "Easy to tap for accessibility",
                        isOn: $isOn3,
                        size: .large
                    )
                }
                
                Section("Colors & Icons") {
                    SettingsToggleRow(
                        icon: "icloud",
                        iconColor: .blue,
                        title: "iCloud Sync",
                        description: "Sync across all devices",
                        isOn: $isOn4,
                        onColor: .blue
                    )
                    
                    Toggle("Standard Toggle", isOn: $isOn1)
                        .animatedToggleStyle(onColor: .purple)
                }
                
                Section("Without Icons") {
                    SettingsToggleRow(
                        icon: "moon.fill",
                        iconColor: .indigo,
                        title: "Dark Mode",
                        isOn: $isOn2,
                        showIcons: false
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}
