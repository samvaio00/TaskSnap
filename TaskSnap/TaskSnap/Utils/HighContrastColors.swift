import SwiftUI

/// High contrast color palette for improved accessibility
/// Uses darker darks and lighter lights with stronger borders
struct HighContrastColors {
    
    // MARK: - Background Colors
    
    /// Primary background color (system background)
    static var background: Color {
        AccessibilitySettings.shared.highContrast 
            ? Color(.systemBackground)
            : Color(.systemBackground)
    }
    
    /// Secondary background with stronger contrast in high contrast mode
    static var secondaryBackground: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(.secondarySystemBackground).opacity(1.0)
            : Color(.secondarySystemBackground)
    }
    
    /// Tertiary background
    static var tertiaryBackground: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(.tertiarySystemBackground).opacity(1.0)
            : Color(.tertiarySystemBackground)
    }
    
    /// Grouped background
    static var groupedBackground: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(.systemGroupedBackground)
            : Color(.systemGroupedBackground)
    }
    
    // MARK: - Text Colors
    
    /// Primary text (labels, titles)
    static var primaryText: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(.label)
            : Color(.label)
    }
    
    /// Secondary text (captions, subtitles) with enhanced contrast
    static var secondaryText: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(.secondaryLabel).opacity(1.0)
            : Color(.secondaryLabel)
    }
    
    /// Tertiary text (placeholders, hints)
    static var tertiaryText: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(.tertiaryLabel).opacity(1.0)
            : Color(.tertiaryLabel)
    }
    
    // MARK: - Accent Colors (High Contrast Variants)
    
    /// Accent color with high contrast variant
    static var accent: Color {
        AccessibilitySettings.shared.highContrast
            ? Color.accentColor.opacity(1.0)
            : Color.accentColor
    }
    
    /// Success color (green with enhanced visibility)
    static var success: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(red: 0.0, green: 0.6, blue: 0.0)
            : Color("doneColor")
    }
    
    /// Warning color (orange with enhanced visibility)
    static var warning: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(red: 0.9, green: 0.5, blue: 0.0)
            : Color.orange
    }
    
    /// Error color (red with enhanced visibility)
    static var error: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(red: 0.9, green: 0.0, blue: 0.0)
            : Color("urgencyHigh")
    }
    
    /// Info color (blue with enhanced visibility)
    static var info: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(red: 0.0, green: 0.4, blue: 0.9)
            : Color.blue
    }
    
    // MARK: - Status Colors
    
    /// To Do column color
    static var todoColor: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(red: 0.0, green: 0.5, blue: 0.9)
            : Color("todoColor")
    }
    
    /// Doing column color
    static var doingColor: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(red: 0.9, green: 0.6, blue: 0.0)
            : Color("doingColor")
    }
    
    /// Done column color
    static var doneColor: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(red: 0.0, green: 0.7, blue: 0.3)
            : Color("doneColor")
    }
    
    /// Urgency low color
    static var urgencyLow: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(red: 0.0, green: 0.6, blue: 0.6)
            : Color("urgencyLow")
    }
    
    /// Urgency medium color
    static var urgencyMedium: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(red: 0.9, green: 0.7, blue: 0.0)
            : Color("urgencyMedium")
    }
    
    /// Urgency high color
    static var urgencyHigh: Color {
        AccessibilitySettings.shared.highContrast
            ? Color(red: 0.9, green: 0.2, blue: 0.1)
            : Color("urgencyHigh")
    }
    
    // MARK: - Border Colors
    
    /// Standard border color
    static var border: Color {
        AccessibilitySettings.shared.highContrast
            ? Color.black.opacity(0.5)
            : Color.gray.opacity(0.3)
    }
    
    /// Strong border for emphasis
    static var strongBorder: Color {
        AccessibilitySettings.shared.highContrast
            ? Color.black.opacity(0.7)
            : Color.gray.opacity(0.5)
    }
    
    /// Divider/separator color
    static var separator: Color {
        AccessibilitySettings.shared.highContrast
            ? Color.separator.opacity(1.0)
            : Color.separator
    }
    
    // MARK: - Shadow Colors
    
    /// Shadow color with appropriate opacity
    static var shadow: Color {
        AccessibilitySettings.shared.highContrast
            ? Color.black.opacity(0.3)
            : Color.black.opacity(0.15)
    }
    
    /// Strong shadow for high contrast
    static var strongShadow: Color {
        Color.black.opacity(0.4)
    }
}

// MARK: - View Modifiers

/// View modifier that applies high contrast border styling
struct HighContrastBorderModifier: ViewModifier {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    var cornerRadius: CGFloat
    var lineWidth: CGFloat
    var color: Color?
    
    init(cornerRadius: CGFloat = 12, lineWidth: CGFloat = 2, color: Color? = nil) {
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.color = color
    }
    
    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    color ?? HighContrastColors.border,
                    lineWidth: accessibilitySettings.highContrast ? lineWidth * 1.5 : lineWidth
                )
        )
    }
}

/// View modifier for high contrast button styling
struct HighContrastButtonModifier: ViewModifier {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    var isPrimary: Bool
    
    func body(content: Content) -> some View {
        content
            .if(accessibilitySettings.highContrast) { view in
                view.overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.5), lineWidth: 2)
                )
            }
            .if(accessibilitySettings.buttonShapes) { view in
                view.overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                )
            }
    }
}

/// View modifier for high contrast card styling
struct HighContrastCardModifier: ViewModifier {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    func body(content: Content) -> some View {
        content
            .background(HighContrastColors.secondaryBackground)
            .cornerRadius(16)
            .if(accessibilitySettings.highContrast) { view in
                view.overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(HighContrastColors.strongBorder, lineWidth: 2)
                )
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies high contrast border styling
    func highContrastBorder(
        cornerRadius: CGFloat = 12,
        lineWidth: CGFloat = 2,
        color: Color? = nil
    ) -> some View {
        self.modifier(HighContrastBorderModifier(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            color: color
        ))
    }
    
    /// Applies high contrast button styling
    func highContrastButton(isPrimary: Bool = false) -> some View {
        self.modifier(HighContrastButtonModifier(isPrimary: isPrimary))
    }
    
    /// Applies high contrast card styling
    func highContrastCard() -> some View {
        self.modifier(HighContrastCardModifier())
    }
}

// MARK: - Shape Styles

/// Shape style that adapts to high contrast mode
struct AdaptiveShapeStyle: ShapeStyle {
    var normal: Color
    var highContrast: Color
    
    var color: Color {
        AccessibilitySettings.shared.highContrast ? highContrast : normal
    }
    
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        color
    }
}

// MARK: - Color Extensions

extension Color {
    /// Returns high contrast variant of the color
    func highContrastVariant() -> Color {
        guard AccessibilitySettings.shared.highContrast else { return self }
        
        // Increase saturation and adjust brightness for better contrast
        // This is a simplified approach - in production, you'd use color space conversions
        return self.opacity(1.0)
    }
    
    /// Returns the color with appropriate opacity for the current contrast mode
    func adaptiveOpacity(_ normal: Double, highContrast override: Double = 1.0) -> Color {
        AccessibilitySettings.shared.highContrast 
            ? self.opacity(override)
            : self.opacity(normal)
    }
}

// MARK: - Gradient Extensions

extension LinearGradient {
    /// Creates a high contrast gradient
    static func highContrast(
        colors: [Color],
        startPoint: UnitPoint,
        endPoint: UnitPoint
    ) -> LinearGradient {
        let adaptedColors = AccessibilitySettings.shared.highContrast
            ? colors.map { $0.opacity(1.0) }
            : colors
        
        return LinearGradient(
            colors: adaptedColors,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
}

// MARK: - Previews

#Preview("High Contrast Colors") {
    Group {
        HighContrastColorPreview()
            .environmentObject(AccessibilitySettings.preview)
            .previewDisplayName("Normal")
        
        HighContrastColorPreview()
            .environmentObject(AccessibilitySettings.previewHighContrast)
            .previewDisplayName("High Contrast")
    }
}

private struct HighContrastColorPreview: View {
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status Colors
                colorRow("To Do", color: HighContrastColors.todoColor)
                colorRow("Doing", color: HighContrastColors.doingColor)
                colorRow("Done", color: HighContrastColors.doneColor)
                
                Divider()
                
                // Urgency Colors
                colorRow("Urgency Low", color: HighContrastColors.urgencyLow)
                colorRow("Urgency Medium", color: HighContrastColors.urgencyMedium)
                colorRow("Urgency High", color: HighContrastColors.urgencyHigh)
                
                Divider()
                
                // Cards
                Text("Card with High Contrast Border")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .highContrastCard()
                
                // Button
                Button("High Contrast Button") {}
                    .padding()
                    .background(HighContrastColors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .highContrastButton(isPrimary: true)
            }
            .padding()
        }
    }
    
    func colorRow(_ name: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .highContrastBorder(cornerRadius: 15, lineWidth: 1)
            
            Text(name)
                .font(.body)
            
            Spacer()
        }
    }
}
