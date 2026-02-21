//
//  A_SharedAchievementUI.swift
//  TaskSnap
//
//  Shared achievement UI components with cartoonish animations
//  Named with A_ prefix to ensure early compilation
//

import SwiftUI

// MARK: - Achievement Toast
struct AchievementToast: Identifiable {
    let id = UUID()
    let achievement: Achievement
}

class AchievementToastManager: ObservableObject {
    static let shared = AchievementToastManager()
    
    @Published var currentToast: AchievementToast?
    @Published var showParticles = false
    private var queue: [AchievementToast] = []
    
    func showToast(achievement: Achievement) {
        let toast = AchievementToast(achievement: achievement)
        queue.append(toast)
        
        if currentToast == nil {
            displayNext()
        }
    }
    
    func showToast(title: String, subtitle: String, icon: String, color: String) {
        // Create a temporary achievement-like toast
        let tempAchievement = Achievement(
            id: UUID().uuidString,
            title: title,
            description: subtitle,
            icon: icon,
            color: color,
            category: .starter,
            criteria: .tasksCompleted(count: 1),
            isUnlocked: true,
            unlockedAt: Date(),
            progress: 1.0
        )
        let toast = AchievementToast(achievement: tempAchievement)
        queue.append(toast)
        
        if currentToast == nil {
            displayNext()
        }
    }
    
    private func displayNext() {
        guard !queue.isEmpty else {
            currentToast = nil
            return
        }
        
        currentToast = queue.removeFirst()
        
        // Trigger particle explosion
        withAnimation(.easeOut(duration: 0.1)) {
            showParticles = true
        }
        
        // Play haptic feedback
        Haptics.shared.achievementUnlocked()
        
        // Auto-dismiss after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.easeIn(duration: 0.3)) {
                self.currentToast = nil
                self.showParticles = false
            }
            
            // Show next toast after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.displayNext()
            }
        }
    }
}

// MARK: - Achievement Toast View with Cartoonish Animation
struct AchievementToastView: View {
    let achievement: Achievement
    @State private var scale: CGFloat = 0.1
    @State private var rotation: Double = -15
    @State private var offsetY: CGFloat = -200
    @State private var iconBounce: CGFloat = 0
    @State private var glowScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    @State private var ribbonOffset: CGFloat = -100
    
    var body: some View {
        ZStack {
            // Animated glow background
            ZStack {
                // Outer glow
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                colorFromString(achievement.color).opacity(0.3),
                                colorFromString(achievement.color).opacity(0.1),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 360, height: 120)
                    .blur(radius: 20)
                    .scaleEffect(glowScale)
                
                // Inner glow
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorFromString(achievement.color).opacity(0.15))
                    .frame(width: 340, height: 100)
                    .blur(radius: 10)
                    .scaleEffect(glowScale)
            }
            
            // Main card
            HStack(spacing: 16) {
                // Animated icon container
                ZStack {
                    // Pulsing rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(colorFromString(achievement.color).opacity(0.3), lineWidth: 2)
                            .frame(width: 70 + CGFloat(i * 15), height: 70 + CGFloat(i * 15))
                            .scaleEffect(1 + iconBounce * (0.1 + CGFloat(i) * 0.05))
                            .opacity(1 - iconBounce * CGFloat(i) * 0.3)
                    }
                    
                    // Background circle with gradient
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    colorFromString(achievement.color).opacity(0.6),
                                    colorFromString(achievement.color).opacity(0.3)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(
                            color: colorFromString(achievement.color).opacity(0.5),
                            radius: 10 + iconBounce * 10,
                            x: 0,
                            y: 5
                        )
                    
                    // Icon with bounce
                    Image(systemName: achievement.icon)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        .scaleEffect(1 + iconBounce * 0.2)
                        .rotationEffect(.degrees(iconBounce * 10))
                }
                .frame(width: 80, height: 80)
                
                // Text content
                VStack(alignment: .leading, spacing: 6) {
                    // "Achievement Unlocked!" banner
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        
                        Text("Achievement Unlocked!")
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(colorFromString(achievement.color))
                            .textCase(.uppercase)
                            .tracking(1)
                        
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                    .opacity(textOpacity)
                    
                    // Achievement name
                    Text(achievement.title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        .opacity(textOpacity)
                    
                    // Description
                    Text(achievement.description)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .opacity(textOpacity)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Glassmorphism background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                    
                    // Top shine
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .white.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.6),
                                    colorFromString(achievement.color).opacity(0.3),
                                    colorFromString(achievement.color).opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .shadow(
                color: colorFromString(achievement.color).opacity(0.4),
                radius: 20,
                x: 0,
                y: 10
            )
            .shadow(
                color: .black.opacity(0.15),
                radius: 10,
                x: 0,
                y: 5
            )
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .offset(y: offsetY)
        .onAppear {
            // Cartoonish elastic entrance animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0)) {
                scale = 1.0
                rotation = 0
                offsetY = 0
            }
            
            // Glow expands
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                glowScale = 1.0
            }
            
            // Text fades in
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                textOpacity = 1.0
            }
            
            // Continuous icon bounce animation
            withAnimation(
                .spring(response: 0.4, dampingFraction: 0.4)
                .repeatForever(autoreverses: true)
            ) {
                iconBounce = 1.0
            }
        }
    }
}

// MARK: - Particle Effect for Celebration
struct AchievementParticles: View {
    let color: Color
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var rotation: Double
        var opacity: Double
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: ["star.fill", "sparkle", "circle.fill"].randomElement()!)
                    .foregroundColor(color)
                    .scaleEffect(particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        particles = (0..<15).map { _ in
            Particle(
                x: 200 + CGFloat.random(in: -100...100),
                y: 100,
                scale: CGFloat.random(in: 0.3...0.8),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
        }
    }
    
    private func animateParticles() {
        for index in particles.indices {
            withAnimation(
                .easeOut(duration: 1.0)
                .delay(Double.random(in: 0...0.3))
            ) {
                particles[index].y += CGFloat.random(in: -150...(-50))
                particles[index].x += CGFloat.random(in: -100...100)
                particles[index].opacity = 0
                particles[index].rotation += Double.random(in: 180...360)
            }
        }
    }
}

// MARK: - Toast Container
struct AchievementToastContainer: View {
    @StateObject private var manager = AchievementToastManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Particles layer
                if manager.showParticles, let toast = manager.currentToast {
                    AchievementParticles(color: colorFromString(toast.achievement.color))
                        .frame(width: geometry.size.width, height: 200)
                        .position(x: geometry.size.width / 2, y: 120)
                }
                
                // Toast
                VStack {
                    if let toast = manager.currentToast {
                        AchievementToastView(achievement: toast.achievement)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
                .padding(.top, geometry.safeAreaInsets.top + 10)
            }
        }
        .ignoresSafeArea()
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: manager.currentToast != nil)
    }
}

// Helper function to convert string color names to SwiftUI Color
func colorFromString(_ colorName: String) -> Color {
    switch colorName {
    case "achievementBronze":
        return Color(red: 0.8, green: 0.5, blue: 0.2)
    case "achievementSilver":
        return Color(red: 0.6, green: 0.6, blue: 0.65)
    case "achievementGold":
        return Color(red: 1.0, green: 0.84, blue: 0.0)
    default:
        return Color.accentColor
    }
}
