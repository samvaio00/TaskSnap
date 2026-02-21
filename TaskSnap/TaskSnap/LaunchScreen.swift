import SwiftUI

// MARK: - Launch Screen
/// Professional launch screen with animated app icon, branding, and loading indicator
struct LaunchScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // Animation states
    @State private var isVisible = false
    @State private var iconScale = 0.8
    @State private var iconRotation = -30.0
    @State private var textOpacity = 0.0
    @State private var taglineOffset: CGFloat = 20
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var pulseScale = 1.0
    
    var body: some View {
        ZStack {
            // MARK: - Background
            backgroundGradient
            
            // MARK: - Content
            VStack(spacing: 32) {
                Spacer()
                
                // MARK: - App Icon
                appIconView
                
                // MARK: - App Name
                appNameView
                
                Spacer()
                
                // MARK: - Tagline
                taglineView
                
                // MARK: - Loading Indicator
                loadingIndicator
            }
            .padding(.vertical, 60)
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: backgroundColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(
            // Subtle animated shimmer overlay
            GeometryReader { geometry in
                if !reduceMotion {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(colorScheme == .dark ? 0.03 : 0.08),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.4)
                    .offset(x: geometry.size.width * shimmerOffset)
                    .blur(radius: 20)
                }
            }
        )
    }
    
    private var backgroundColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.05, green: 0.08, blue: 0.15),
                Color(red: 0.08, green: 0.12, blue: 0.20),
                Color(red: 0.06, green: 0.10, blue: 0.16)
            ]
        } else {
            return [
                Color(red: 0.95, green: 0.98, blue: 1.0),
                Color(red: 0.90, green: 0.95, blue: 1.0),
                Color(red: 0.85, green: 0.92, blue: 1.0)
            ]
        }
    }
    
    // MARK: - App Icon View
    private var appIconView: some View {
        ZStack {
            // Outer glow ring (pulsing)
            if !reduceMotion {
                Circle()
                    .stroke(
                        accentGradient,
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulseScale)
                    .opacity(0.3)
            }
            
            // Main icon background
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: iconBackgroundColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(
                    color: accentColor.opacity(0.4),
                    radius: 20,
                    x: 0,
                    y: 10
                )
            
            // Camera with checkmark icon
            ZStack {
                // Camera body
                Image(systemName: "camera.fill")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundColor(.white)
                
                // Checkmark badge
                Circle()
                    .fill(Color.green)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 32, y: 32)
                    .shadow(radius: 4)
            }
        }
        .scaleEffect(iconScale)
        .rotationEffect(.degrees(iconRotation))
    }
    
    // MARK: - App Name View
    private var appNameView: some View {
        VStack(spacing: 8) {
            Text("TaskSnap")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.15, blue: 0.25))
                .tracking(0.5)
                .overlay(
                    // Subtle gradient text effect
                    accentGradient
                        .mask(
                            Text("TaskSnap")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .tracking(0.5)
                        )
                        .opacity(0.8)
                )
        }
        .opacity(textOpacity)
    }
    
    // MARK: - Tagline View
    private var taglineView: some View {
        Text("Capture Your Chaos. See Your Success.")
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(0.6))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .offset(y: taglineOffset)
            .opacity(textOpacity)
    }
    
    // MARK: - Loading Indicator
    private var loadingIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                LoadingDot(index: index)
            }
        }
        .opacity(textOpacity)
    }
    
    // MARK: - Colors
    private var accentColor: Color {
        Color(red: 0.2, green: 0.6, blue: 1.0)
    }
    
    private var accentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.2, green: 0.6, blue: 1.0),
                Color(red: 0.4, green: 0.7, blue: 1.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var iconBackgroundColors: [Color] {
        [
            Color(red: 0.2, green: 0.6, blue: 1.0),
            Color(red: 0.1, green: 0.45, blue: 0.9)
        ]
    }
    
    // MARK: - Animation
    private func startAnimations() {
        // Fade in entire view
        withAnimation(.easeIn(duration: 0.3)) {
            isVisible = true
        }
        
        // Icon entrance animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            iconScale = 1.0
            iconRotation = 0
        }
        
        // Text fade in
        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            textOpacity = 1.0
        }
        
        // Tagline slide up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
            taglineOffset = 0
        }
        
        // Start pulsing animation for glow effect
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.8)) {
                pulseScale = 1.15
            }
            
            // Shimmer animation
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false).delay(1)) {
                shimmerOffset = 1.5
            }
        }
    }
}

// MARK: - Loading Dot
private struct LoadingDot: View {
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.6, blue: 1.0),
                        Color(red: 0.4, green: 0.7, blue: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                    )
            )
            .frame(width: 10, height: 10)
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .opacity(isAnimating ? 1.0 : 0.4)
            .onAppear {
                if !reduceMotion {
                    withAnimation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15)
                    ) {
                        isAnimating = true
                    }
                } else {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Preview
#Preview("Light Mode") {
    LaunchScreen()
}

#Preview("Dark Mode") {
    LaunchScreen()
        .preferredColorScheme(.dark)
}

#Preview("Reduced Motion") {
    LaunchScreen()
        .environment(\.accessibilityReduceMotion, true)
}
