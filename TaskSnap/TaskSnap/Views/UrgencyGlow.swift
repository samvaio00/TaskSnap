import SwiftUI

struct UrgencyGlow: View {
    let level: UrgencyLevel
    @State private var isAnimating = false
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1, paused: !level.shouldGlow)) { timeline in
            Canvas { context, size in
                if level.shouldGlow {
                    let rect = CGRect(origin: .zero, size: size)
                    let path = RoundedRectangle(cornerRadius: 16).path(in: rect)
                    
                    // Animated glow effect
                    let animationOffset = sin(timeline.date.timeIntervalSinceReferenceDate * 4) * 0.5 + 0.5
                    let glowIntensity = 0.4 + (animationOffset * 0.4)
                    
                    // Outer glow
                    for i in 0..<3 {
                        let offset = CGFloat(i + 1) * 4
                        let opacity = glowIntensity / CGFloat(i + 2)
                        
                        context.addFilter(.alphaThreshold(min: 0.01))
                        context.addFilter(.blur(radius: offset))
                        
                        context.stroke(
                            path,
                            with: .color(Color(level.color).opacity(opacity)),
                            lineWidth: 3
                        )
                    }
                    
                    // Inner stroke
                    context.stroke(
                        path,
                        with: .color(Color(level.color)),
                        lineWidth: 2
                    )
                }
            }
        }
    }
}

// MARK: - Animated Border View
struct AnimatedBorder: ViewModifier {
    let color: Color
    let lineWidth: CGFloat
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        AngularGradient(
                            colors: [color.opacity(0), color, color.opacity(0)],
                            center: .center,
                            angle: .degrees(phase)
                        ),
                        lineWidth: lineWidth
                    )
                    .opacity(isActive ? 1 : 0)
            )
            .onAppear {
                if isActive {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        phase = 360
                    }
                }
            }
    }
}

extension View {
    func animatedBorder(color: Color, lineWidth: CGFloat = 3, isActive: Bool) -> some View {
        modifier(AnimatedBorder(color: color, lineWidth: lineWidth, isActive: isActive))
    }
}

#Preview {
    VStack(spacing: 20) {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .frame(width: 200, height: 100)
            .overlay(
                UrgencyGlow(level: .high)
            )
            .overlay(
                Text("High Urgency")
            )
        
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.systemBackground))
            .frame(width: 200, height: 100)
            .overlay(
                UrgencyGlow(level: .medium)
            )
            .overlay(
                Text("Medium Urgency")
            )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
