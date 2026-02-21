import SwiftUI

// MARK: - Reaction-Based Confetti Styles
enum ConfettiStyle {
    case celebration      // 🎉 Party popper - colorful, fast, energetic
    case powerful         // 💪 Strong - bold, heavy, impactful
    case sparkle          // ✨ Magic - slow, glittery, ethereal
    case fire             // 🔥 Intense - red/orange, explosive, fast
    case praise           // 🙌 Praise - gold, upward burst, celebratory
    case happy            // 😊 Gentle - soft colors, slow falling, calm
    
    static func from(reaction: String) -> ConfettiStyle {
        switch reaction {
        case "🎉": return .celebration
        case "💪": return .powerful
        case "✨": return .sparkle
        case "🔥": return .fire
        case "🙌": return .praise
        case "😊": return .happy
        default: return .celebration
        }
    }
}

struct ConfettiView: View {
    let reaction: String?
    let theme: CelebrationTheme?
    @State private var particles: [ConfettiParticle] = []
    
    init(reaction: String? = nil, theme: CelebrationTheme? = nil) {
        self.reaction = reaction
        self.theme = theme
    }
    
    private var style: ConfettiStyle {
        if let reaction = reaction {
            return ConfettiStyle.from(reaction: reaction)
        }
        return .celebration
    }
    
    private var currentTheme: CelebrationTheme {
        theme ?? ThemeManager.shared.selectedTheme
    }
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Update and draw particles
                for particle in particles {
                    var path = Path()
                    
                    // Different shapes for variety
                    switch particle.shape {
                    case .circle:
                        path.addEllipse(in: CGRect(
                            x: particle.x,
                            y: particle.y,
                            width: particle.size,
                            height: particle.size
                        ))
                    case .square:
                        path.addRect(CGRect(
                            x: particle.x,
                            y: particle.y,
                            width: particle.size,
                            height: particle.size * 0.6
                        ))
                    case .triangle:
                        path.move(to: CGPoint(x: particle.x + particle.size/2, y: particle.y))
                        path.addLine(to: CGPoint(x: particle.x + particle.size, y: particle.y + particle.size))
                        path.addLine(to: CGPoint(x: particle.x, y: particle.y + particle.size))
                        path.closeSubpath()
                    case .star:
                        path = starPath(in: CGRect(
                            x: particle.x,
                            y: particle.y,
                            width: particle.size,
                            height: particle.size
                        ))
                    case .heart:
                        path = heartPath(in: CGRect(
                            x: particle.x,
                            y: particle.y,
                            width: particle.size,
                            height: particle.size
                        ))
                    case .diamond:
                        path.move(to: CGPoint(x: particle.x + particle.size/2, y: particle.y))
                        path.addLine(to: CGPoint(x: particle.x + particle.size, y: particle.y + particle.size/2))
                        path.addLine(to: CGPoint(x: particle.x + particle.size/2, y: particle.y + particle.size))
                        path.addLine(to: CGPoint(x: particle.x, y: particle.y + particle.size/2))
                        path.closeSubpath()
                    case .square:
                        path.addRect(CGRect(
                            x: particle.x,
                            y: particle.y,
                            width: particle.size,
                            height: particle.size
                        ))
                    case .ribbon:
                        // Simplified ribbon as wavy line
                        path.move(to: CGPoint(x: particle.x, y: particle.y))
                        path.addQuadCurve(
                            to: CGPoint(x: particle.x + particle.size, y: particle.y + particle.size),
                            control: CGPoint(x: particle.x + particle.size/2, y: particle.y - particle.size/2)
                        )
                    case .flame:
                        path.move(to: CGPoint(x: particle.x + particle.size/2, y: particle.y + particle.size))
                        path.addQuadCurve(
                            to: CGPoint(x: particle.x + particle.size/2, y: particle.y),
                            control: CGPoint(x: particle.x, y: particle.y + particle.size/2)
                        )
                        path.addQuadCurve(
                            to: CGPoint(x: particle.x + particle.size/2, y: particle.y + particle.size),
                            control: CGPoint(x: particle.x + particle.size, y: particle.y + particle.size/2)
                        )
                    case .leaf:
                        path.move(to: CGPoint(x: particle.x + particle.size/2, y: particle.y + particle.size))
                        path.addQuadCurve(
                            to: CGPoint(x: particle.x + particle.size/2, y: particle.y),
                            control: CGPoint(x: particle.x, y: particle.y + particle.size/2)
                        )
                        path.addQuadCurve(
                            to: CGPoint(x: particle.x + particle.size/2, y: particle.y + particle.size),
                            control: CGPoint(x: particle.x + particle.size, y: particle.y + particle.size/2)
                        )
                    case .flower:
                        // Simple flower as circle with petals
                        path.addEllipse(in: CGRect(
                            x: particle.x + particle.size/4,
                            y: particle.y + particle.size/4,
                            width: particle.size/2,
                            height: particle.size/2
                        ))
                    case .bolt:
                        path.move(to: CGPoint(x: particle.x + particle.size/2, y: particle.y))
                        path.addLine(to: CGPoint(x: particle.x + particle.size/3, y: particle.y + particle.size/2))
                        path.addLine(to: CGPoint(x: particle.x + particle.size*2/3, y: particle.y + particle.size/2))
                        path.addLine(to: CGPoint(x: particle.x + particle.size/2, y: particle.y + particle.size))
                        path.addLine(to: CGPoint(x: particle.x + particle.size*2/3, y: particle.y + particle.size/2))
                        path.addLine(to: CGPoint(x: particle.x + particle.size/3, y: particle.y + particle.size/2))
                        path.closeSubpath()
                    case .crown:
                        path.move(to: CGPoint(x: particle.x, y: particle.y + particle.size))
                        path.addLine(to: CGPoint(x: particle.x, y: particle.y + particle.size/2))
                        path.addLine(to: CGPoint(x: particle.x + particle.size/3, y: particle.y + particle.size/3))
                        path.addLine(to: CGPoint(x: particle.x + particle.size/2, y: particle.y))
                        path.addLine(to: CGPoint(x: particle.x + particle.size*2/3, y: particle.y + particle.size/3))
                        path.addLine(to: CGPoint(x: particle.x + particle.size, y: particle.y + particle.size/2))
                        path.addLine(to: CGPoint(x: particle.x + particle.size, y: particle.y + particle.size))
                        path.closeSubpath()
                    }
                    
                    context.translateBy(x: particle.x + particle.size/2, y: particle.y + particle.size/2)
                    context.rotate(by: .degrees(particle.rotation))
                    context.translateBy(x: -(particle.x + particle.size/2), y: -(particle.y + particle.size/2))
                    
                    context.fill(path, with: .color(particle.color.opacity(particle.opacity)))
                }
            }
            .onChange(of: timeline.date) { _, _ in
                updateParticles(in: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    // MARK: - Style Configuration
    private var colors: [Color] {
        // If theme is explicitly provided or no reaction, use theme colors
        if theme != nil || reaction == nil {
            return Array(currentTheme.confettiColors)
        }
        
        // Otherwise use reaction-based colors
        switch style {
        case .celebration:
            return [.red, .blue, .green, .yellow, .pink, .purple, .orange]
        case .powerful:
            return [.blue, .indigo, .purple, Color(hex: "1a237e")]
        case .sparkle:
            return [.white, .yellow.opacity(0.8), .cyan.opacity(0.6), .purple.opacity(0.4)]
        case .fire:
            return [.red, .orange, .yellow, Color(hex: "ff5722")]
        case .praise:
            return [.yellow, .orange, Color(hex: "ffd700"), Color(hex: "ffaa00")]
        case .happy:
            return [.pink.opacity(0.7), .mint.opacity(0.7), .yellow.opacity(0.6), .cyan.opacity(0.5)]
        }
    }
    
    private var particleCount: Int {
        switch style {
        case .celebration: return 100
        case .powerful: return 60
        case .sparkle: return 120
        case .fire: return 150
        case .praise: return 80
        case .happy: return 70
        }
    }
    
    private var particleSize: ClosedRange<CGFloat> {
        switch style {
        case .celebration: return 8...16
        case .powerful: return 12...24
        case .sparkle: return 4...10
        case .fire: return 6...18
        case .praise: return 10...20
        case .happy: return 8...14
        }
    }
    
    private func createParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                x: style.initialXPosition(screenWidth: screenWidth),
                y: style.initialYPosition(),
                size: CGFloat.random(in: particleSize),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                rotationSpeed: style.rotationSpeed,
                speedY: style.speedY,
                speedX: style.speedX,
                shape: style.shape,
                opacity: 1.0,
                fadeSpeed: style.fadeSpeed
            )
        }
    }
    
    private func updateParticles(in size: CGSize) {
        for index in particles.indices {
            // Apply physics based on style
            style.updatePhysics(particle: &particles[index], screenSize: size)
            
            // Reset or fade particle
            if particles[index].y > size.height || particles[index].opacity <= 0 {
                particles[index].reset(
                    screenWidth: size.width,
                    style: style
                )
            }
        }
    }
}

// MARK: - Confetti Particle Model
struct ConfettiParticle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var rotation: Double
    var rotationSpeed: Double
    var speedY: CGFloat
    var speedX: CGFloat
    var shape: ConfettiShape
    var opacity: Double
    var fadeSpeed: Double
    
    mutating func reset(screenWidth: CGFloat, style: ConfettiStyle) {
        self.x = style.initialXPosition(screenWidth: screenWidth)
        self.y = style.initialYPosition()
        self.opacity = 1.0
        self.speedY = style.speedY
        self.speedX = style.speedX
    }
}

// MARK: - Confetti Style Extensions
extension ConfettiStyle {
    var shape: ConfettiShape {
        switch self {
        case .celebration: return [.circle, .square, .triangle].randomElement()!
        case .powerful: return .square
        case .sparkle: return .star
        case .fire: return [.triangle, .circle].randomElement()!
        case .praise: return [.star, .circle].randomElement()!
        case .happy: return [.circle, .heart].randomElement()!
        }
    }
    
    var rotationSpeed: Double {
        switch self {
        case .celebration: return Double.random(in: -8...8)
        case .powerful: return Double.random(in: -3...3)
        case .sparkle: return Double.random(in: -2...2)
        case .fire: return Double.random(in: -10...10)
        case .praise: return Double.random(in: -5...5)
        case .happy: return Double.random(in: -4...4)
        }
    }
    
    var speedY: CGFloat {
        switch self {
        case .celebration: return CGFloat.random(in: 3...7)
        case .powerful: return CGFloat.random(in: 5...9)
        case .sparkle: return CGFloat.random(in: 0.5...2)
        case .fire: return CGFloat.random(in: 4...10)
        case .praise: return CGFloat.random(in: -3...(-1)) // Floats upward
        case .happy: return CGFloat.random(in: 1...3)
        }
    }
    
    var speedX: CGFloat {
        switch self {
        case .celebration: return CGFloat.random(in: -3...3)
        case .powerful: return CGFloat.random(in: -1...1)
        case .sparkle: return CGFloat.random(in: -0.5...0.5)
        case .fire: return CGFloat.random(in: -2...2)
        case .praise: return CGFloat.random(in: -4...4)
        case .happy: return CGFloat.random(in: -1...1)
        }
    }
    
    var fadeSpeed: Double {
        switch self {
        case .celebration: return 0
        case .powerful: return 0
        case .sparkle: return 0.005
        case .fire: return 0.008
        case .praise: return 0.003
        case .happy: return 0
        }
    }
    
    func initialXPosition(screenWidth: CGFloat) -> CGFloat {
        switch self {
        case .celebration, .sparkle, .happy:
            return CGFloat.random(in: 0...screenWidth)
        case .powerful:
            return screenWidth / 2 + CGFloat.random(in: -50...50)
        case .fire:
            return screenWidth / 2 + CGFloat.random(in: -100...100)
        case .praise:
            return screenWidth / 2 + CGFloat.random(in: -150...150)
        }
    }
    
    func initialYPosition() -> CGFloat {
        switch self {
        case .celebration, .sparkle, .happy, .fire, .powerful:
            return CGFloat.random(in: -100...0)
        case .praise:
            return UIScreen.main.bounds.height + 50 // Start from bottom
        }
    }
    
    func updatePhysics(particle: inout ConfettiParticle, screenSize: CGSize) {
        switch self {
        case .celebration:
            particle.y += particle.speedY
            particle.x += particle.speedX + sin(particle.y / 50) * 3
            particle.rotation += particle.rotationSpeed
            
        case .powerful:
            particle.y += particle.speedY
            particle.x += particle.speedX
            particle.rotation += particle.rotationSpeed
            // Heavy gravity effect
            particle.speedY += 0.1
            
        case .sparkle:
            particle.y += particle.speedY
            particle.x += particle.speedX + sin(particle.y / 30) * 0.5
            particle.rotation += particle.rotationSpeed
            particle.opacity -= particle.fadeSpeed
            
        case .fire:
            particle.y -= particle.speedY // Fire rises
            particle.x += particle.speedX + CGFloat.random(in: -1...1)
            particle.rotation += particle.rotationSpeed * 2
            particle.opacity -= particle.fadeSpeed
            particle.size *= 0.99 // Shrink as it burns
            
        case .praise:
            particle.y += particle.speedY // Float upward
            particle.x += particle.speedX + sin(particle.y / 40) * 2
            particle.rotation += particle.rotationSpeed
            particle.opacity -= particle.fadeSpeed
            
        case .happy:
            particle.y += particle.speedY
            particle.x += particle.speedX + sin(particle.y / 80) * 2
            particle.rotation += particle.rotationSpeed * 0.5
        }
    }
}

// ConfettiShape is defined in CelebrationTheme.swift

// MARK: - Celebration View
struct CelebrationView: View {
    let message: String
    let reaction: String?
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            if showConfetti {
                ConfettiView(reaction: reaction)
            }
            
            VStack {
                Spacer()
                
                Text(message)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(Color("doneColor"))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 10)
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
            }
        }
    }
}

// MARK: - Shape Path Helpers
func starPath(in rect: CGRect) -> Path {
    var path = Path()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let points = 5
    let outerRadius = rect.width / 2
    let innerRadius = rect.width / 5
    
    for i in 0..<points * 2 {
        let angle = Double(i) * .pi / Double(points) - .pi / 2
        let radius = i % 2 == 0 ? outerRadius : innerRadius
        let x = center.x + CGFloat(cos(angle)) * radius
        let y = center.y + CGFloat(sin(angle)) * radius
        
        if i == 0 {
            path.move(to: CGPoint(x: x, y: y))
        } else {
            path.addLine(to: CGPoint(x: x, y: y))
        }
    }
    path.closeSubpath()
    return path
}

func heartPath(in rect: CGRect) -> Path {
    var path = Path()
    let scale = rect.width / 100
    let offsetX = rect.minX
    let offsetY = rect.minY
    
    path.move(to: CGPoint(x: offsetX + 50 * scale, y: offsetY + 30 * scale))
    
    path.addCurve(
        to: CGPoint(x: offsetX + 10 * scale, y: offsetY + 30 * scale),
        control1: CGPoint(x: offsetX + 50 * scale, y: offsetY - 10 * scale),
        control2: CGPoint(x: offsetX + 10 * scale, y: offsetY - 10 * scale)
    )
    
    path.addCurve(
        to: CGPoint(x: offsetX + 50 * scale, y: offsetY + 90 * scale),
        control1: CGPoint(x: offsetX + 10 * scale, y: offsetY + 60 * scale),
        control2: CGPoint(x: offsetX + 50 * scale, y: offsetY + 70 * scale)
    )
    
    path.addCurve(
        to: CGPoint(x: offsetX + 90 * scale, y: offsetY + 30 * scale),
        control1: CGPoint(x: offsetX + 50 * scale, y: offsetY + 70 * scale),
        control2: CGPoint(x: offsetX + 90 * scale, y: offsetY + 60 * scale)
    )
    
    path.addCurve(
        to: CGPoint(x: offsetX + 50 * scale, y: offsetY + 30 * scale),
        control1: CGPoint(x: offsetX + 90 * scale, y: offsetY - 10 * scale),
        control2: CGPoint(x: offsetX + 50 * scale, y: offsetY - 10 * scale)
    )
    
    return path
}

// MARK: - Color Hex Helper
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    CelebrationView(message: "Task Complete!", reaction: "🎉")
}
