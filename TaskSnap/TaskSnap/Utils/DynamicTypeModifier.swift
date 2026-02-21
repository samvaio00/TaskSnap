import SwiftUI

/// View modifier for Dynamic Type support with proper scaling and line limits
struct DynamicTypeModifier: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    /// The text style being used (determines scaling behavior)
    var textStyle: UIFont.TextStyle?
    
    /// Whether to allow unlimited lines (default) or limit to a specific number
    var lineLimit: Int?
    
    /// Whether this text should expand vertically for larger sizes
    var expandsVertically: Bool
    
    /// Minimum scale factor for the text
    var minimumScaleFactor: CGFloat?
    
    init(
        textStyle: UIFont.TextStyle? = nil,
        lineLimit: Int? = nil,
        expandsVertically: Bool = true,
        minimumScaleFactor: CGFloat? = nil
    ) {
        self.textStyle = textStyle
        self.lineLimit = lineLimit
        self.expandsVertically = expandsVertically
        self.minimumScaleFactor = minimumScaleFactor
    }
    
    func body(content: Content) -> some View {
        content
            .lineLimit(lineLimit)
            .minimumScaleFactor(minimumScaleFactor ?? accessibilitySettings.minimumScaleFactor)
            .if(expandsVertically && isAccessibilitySize) { view in
                view.fixedSize(horizontal: false, vertical: true)
            }
    }
    
    private var isAccessibilitySize: Bool {
        accessibilitySettings.isAccessibilitySize(sizeCategory)
    }
}

/// View modifier for accessible labels with icon and text
struct AccessibleLabelModifier: ViewModifier {
    let icon: String
    let label: String
    
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    func body(content: Content) -> some View {
        HStack(spacing: accessibilitySettings.isAccessibilitySize(sizeCategory) ? 12 : 8) {
            Image(systemName: icon)
                .imageScale(accessibilitySettings.isAccessibilitySize(sizeCategory) ? .large : .medium)
                .accessibilityHidden(true)
            
            Text(label)
                .accessibleText()
            
            Spacer()
            
            content
        }
    }
}

/// View modifier for accessible value display
struct AccessibleValueModifier: ViewModifier {
    let label: String
    let value: String
    let icon: String?
    
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: accessibilitySettings.isAccessibilitySize(sizeCategory) ? 12 : 8) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .accessibilityHidden(true)
                }
                
                Text(label)
                    .font(.headline)
                    .accessibleText()
                
                Spacer()
            }
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
                .accessibleText()
            
            content
        }
        .padding(.vertical, accessibilitySettings.isAccessibilitySize(sizeCategory) ? 8 : 4)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies Dynamic Type support with proper scaling
    /// - Parameters:
    ///   - lineLimit: Maximum number of lines (nil for unlimited)
    ///   - expandsVertically: Whether text should expand vertically for larger sizes
    ///   - minimumScaleFactor: Minimum scale factor (defaults to 0.5)
    func accessibleText(
        lineLimit: Int? = nil,
        expandsVertically: Bool = true,
        minimumScaleFactor: CGFloat? = nil
    ) -> some View {
        self.modifier(DynamicTypeModifier(
            lineLimit: lineLimit,
            expandsVertically: expandsVertically,
            minimumScaleFactor: minimumScaleFactor
        ))
    }
    
    /// Applies Dynamic Type with a specific text style
    /// - Parameters:
    ///   - style: The UIFont.TextStyle to use
    ///   - lineLimit: Maximum number of lines
    func accessibleTextStyle(
        _ style: UIFont.TextStyle,
        lineLimit: Int? = nil
    ) -> some View {
        self.modifier(DynamicTypeModifier(
            textStyle: style,
            lineLimit: lineLimit
        ))
    }
    
    /// Wraps content in an accessible label with icon and text
    func accessibleLabel(icon: String, label: String) -> some View {
        self.modifier(AccessibleLabelModifier(icon: icon, label: label))
    }
    
    /// Wraps content in an accessible value display
    func accessibleValue(label: String, value: String, icon: String? = nil) -> some View {
        self.modifier(AccessibleValueModifier(label: label, value: value, icon: icon))
    }
}

// MARK: - Accessible Text Styles

extension Text {
    /// Creates a Text view with accessible Dynamic Type support
    static func accessible(_ content: String, lineLimit: Int? = nil) -> some View {
        Text(content)
            .accessibleText(lineLimit: lineLimit)
    }
    
    /// Creates a Text view with accessible headline styling
    static func accessibleHeadline(_ content: String) -> some View {
        Text(content)
            .font(.headline)
            .accessibleText()
    }
    
    /// Creates a Text view with accessible body styling
    static func accessibleBody(_ content: String) -> some View {
        Text(content)
            .font(.body)
            .accessibleText()
    }
}

// MARK: - Accessible Stack Layouts

/// A VStack that adapts spacing for accessibility sizes
struct AccessibleVStack<Content: View>: View {
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    let alignment: HorizontalAlignment
    let baseSpacing: CGFloat
    let content: Content
    
    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.baseSpacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: actualSpacing) {
            content
        }
    }
    
    private var actualSpacing: CGFloat {
        accessibilitySettings.isAccessibilitySize(sizeCategory) ? baseSpacing * 1.5 : baseSpacing
    }
}

/// An HStack that adapts spacing for accessibility sizes
struct AccessibleHStack<Content: View>: View {
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    let alignment: VerticalAlignment
    let baseSpacing: CGFloat
    let content: Content
    
    init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.baseSpacing = spacing
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: alignment, spacing: actualSpacing) {
            content
        }
    }
    
    private var actualSpacing: CGFloat {
        accessibilitySettings.isAccessibilitySize(sizeCategory) ? baseSpacing * 1.5 : baseSpacing
    }
}

// MARK: - Accessible Padding

extension View {
    /// Applies padding that scales with Dynamic Type
    func accessiblePadding(_ edges: Edge.Set = .all, base: CGFloat) -> some View {
        self.modifier(AccessiblePaddingModifier(edges: edges, basePadding: base))
    }
}

struct AccessiblePaddingModifier: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    let edges: Edge.Set
    let basePadding: CGFloat
    
    func body(content: Content) -> some View {
        content.padding(edges, actualPadding)
    }
    
    private var actualPadding: CGFloat {
        accessibilitySettings.isAccessibilitySize(sizeCategory) ? basePadding * 1.5 : basePadding
    }
}

// MARK: - Previews

#Preview("Dynamic Type Variations") {
    Group {
        DynamicTypePreviewContent()
            .environment(\.sizeCategory, .medium)
            .previewDisplayName("Medium")
        
        DynamicTypePreviewContent()
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .previewDisplayName("Accessibility XL")
    }
}

private struct DynamicTypePreviewContent: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Headline Text")
                .font(.headline)
                .accessibleText()
            
            Text("This is body text that should scale properly with Dynamic Type and wrap to multiple lines when needed.")
                .font(.body)
                .accessibleText()
            
            AccessibleVStack(alignment: .leading, spacing: 16) {
                Label("Item 1", systemImage: "checkmark.circle")
                Label("Item 2", systemImage: "checkmark.circle")
                Label("Item 3", systemImage: "checkmark.circle")
            }
        }
        .padding()
    }
}
