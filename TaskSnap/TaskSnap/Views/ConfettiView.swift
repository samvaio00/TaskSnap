import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange, .doneColor]
    
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
                    case .rectangle:
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
                    }
                    
                    context.translateBy(x: particle.x + particle.size/2, y: particle.y + particle.size/2)
                    context.rotate(by: .degrees(particle.rotation))
                    context.translateBy(x: -(particle.x + particle.size/2), y: -(particle.y + particle.size/2))
                    
                    context.fill(path, with: .color(particle.color))
                }
            }
            .onChange(of: timeline.date) { _ in
                updateParticles(in: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        particles = (0..<80).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: -100...0),
                size: CGFloat.random(in: 8...16),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -5...5),
                speedY: CGFloat.random(in: 2...6),
                speedX: CGFloat.random(in: -2...2),
                shape: ConfettiShape.allCases.randomElement()!
            )
        }
    }
    
    private func updateParticles(in size: CGSize) {
        for index in particles.indices {
            particles[index].y += particles[index].speedY
            particles[index].x += particles[index].speedX + sin(particles[index].y / 50) * 2
            particles[index].rotation += particles[index].rotationSpeed
            
            // Reset particle if it falls off screen
            if particles[index].y > size.height {
                particles[index].y = -20
                particles[index].x = CGFloat.random(in: 0...size.width)
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
}

enum ConfettiShape: CaseIterable {
    case circle, rectangle, triangle
}

// MARK: - Celebration View
struct CelebrationView: View {
    let message: String
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            if showConfetti {
                ConfettiView()
            }
            
            VStack {
                Spacer()
                
                Text(message)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.doneColor)
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

#Preview {
    CelebrationView(message: "Task Complete!")
}
