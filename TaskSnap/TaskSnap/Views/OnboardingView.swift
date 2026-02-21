import SwiftUI
import AVFoundation
import UserNotifications

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showPermissionRequest = false
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    let totalPages = 5
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    }
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    CapturePage()
                        .tag(1)
                    
                    ClarifyPage()
                        .tag(2)
                    
                    CompletePage()
                        .tag(3)
                    
                    PermissionsPage()
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(accessibilitySettings.pageTransitionAnimation, value: currentPage)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? HighContrastColors.accent : HighContrastColors.secondaryText.opacity(0.3))
                            .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                            .scaleEffect(currentPage == index ? (accessibilitySettings.shouldShowCelebrations ? 1.2 : 1.0) : 1.0)
                            .animation(accessibilitySettings.pageTransitionAnimation, value: currentPage)
                            .highContrastBorder(cornerRadius: currentPage == index ? 5 : 4, lineWidth: accessibilitySettings.highContrast && currentPage == index ? 1 : 0)
                    }
                }
                .padding(.vertical, 20)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Page indicator")
                .accessibilityValue("Page \(currentPage + 1) of \(totalPages)")
                
                // Next/Get Started button
                Button {
                    if currentPage < totalPages - 1 {
                        withAnimation(accessibilitySettings.pageTransitionAnimation) {
                            currentPage += 1
                        }
                    } else {
                        requestPermissions()
                    }
                } label: {
                    HStack {
                        Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .accessibleText(lineLimit: 1)
                        Image(systemName: currentPage < totalPages - 1 ? "arrow.right" : "checkmark")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(HighContrastColors.accent)
                    .cornerRadius(16)
                    .highContrastButton(isPrimary: true)
                }
                .accessibleTouchTarget()
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .alert("Enable Notifications?", isPresented: $showPermissionRequest) {
            Button("Not Now", role: .cancel) {
                completeOnboarding()
            }
            Button("Enable") {
                requestNotificationPermission()
            }
        } message: {
            Text("TaskSnap can remind you of overdue tasks and help maintain your streak. Would you like to enable notifications?")
        }
    }
    
    private func requestPermissions() {
        // Request camera permission
        AVCaptureDevice.requestAccess(for: .video) { _ in
            // Permission handled, continue
        }
        
        // Show notification permission dialog
        showPermissionRequest = true
    }
    
    private func requestNotificationPermission() {
        NotificationManager.shared.requestAuthorization { granted in
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                
                // App Icon Placeholder
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient.highContrast(
                                colors: [.accentColor, .accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 16) {
                    Text("Welcome to TaskSnap")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .accessibleText()
                    
                    Text("Capture Your Chaos. See Your Success.")
                        .font(.title3)
                        .foregroundColor(HighContrastColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .accessibleText()
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("Designed for ADHD brains", systemImage: "brain.head.profile")
                        .accessibleLabel(icon: "brain.head.profile", label: "Designed for ADHD brains")
                    Label("Visual task management", systemImage: "eye.fill")
                        .accessibleLabel(icon: "eye.fill", label: "Visual task management")
                    Label("Build lasting habits", systemImage: "flame.fill")
                        .accessibleLabel(icon: "flame.fill", label: "Build lasting habits")
                }
                .font(.subheadline)
                .foregroundColor(HighContrastColors.secondaryText)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Capture Page
struct CapturePage: View {
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(HighContrastColors.accent.opacity(accessibilitySettings.highContrast ? 0.3 : 0.2))
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "camera.fill")
                        .font(.system(size: 80))
                        .foregroundColor(HighContrastColors.accent)
                }
                
                VStack(spacing: 16) {
                    Text("1. Capture")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(HighContrastColors.accent)
                        .accessibleText()
                    
                    Text("Snap a photo of anything that needs your attention")
                        .font(.title3)
                        .foregroundColor(HighContrastColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .accessibleText()
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Label("Messy desk? Capture it.", systemImage: "checkmark.circle.fill")
                        .foregroundColor(HighContrastColors.accent)
                        .accessibleLabel(icon: "checkmark.circle.fill", label: "Messy desk? Capture it.")
                    
                    Label("Broken item? Snap it.", systemImage: "checkmark.circle.fill")
                        .foregroundColor(HighContrastColors.accent)
                        .accessibleLabel(icon: "checkmark.circle.fill", label: "Broken item? Snap it.")
                    
                    Label("Grocery list? Photograph it.", systemImage: "checkmark.circle.fill")
                        .foregroundColor(HighContrastColors.accent)
                        .accessibleLabel(icon: "checkmark.circle.fill", label: "Grocery list? Photograph it.")
                }
                .font(.subheadline)
                .foregroundColor(HighContrastColors.secondaryText)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Clarify Page
struct ClarifyPage: View {
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(accessibilitySettings.highContrast ? 0.3 : 0.2))
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 80))
                        .foregroundColor(accessibilitySettings.highContrast ? HighContrastColors.warning : .orange)
                }
                
                VStack(spacing: 16) {
                    Text("2. Clarify")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(accessibilitySettings.highContrast ? HighContrastColors.warning : .orange)
                        .accessibleText()
                    
                    Text("AI suggests a title, or pick a quick category")
                        .font(.title3)
                        .foregroundColor(HighContrastColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .accessibleText()
                        .padding(.horizontal)
                }
                
                HStack(spacing: 12) {
                    CategoryBadge(icon: "sparkles", label: "Clean", color: .blue)
                    CategoryBadge(icon: "wrench.fill", label: "Fix", color: .orange)
                    CategoryBadge(icon: "cart.fill", label: "Buy", color: .green)
                }
                .padding(.top, 20)
                
                Text("Reduce decision fatigue with one-tap categorization")
                    .font(.caption)
                    .foregroundColor(HighContrastColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .accessibleText()
                    .padding(.top, 8)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Complete Page
struct CompletePage: View {
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color("doneColor").opacity(accessibilitySettings.highContrast ? 0.3 : 0.2))
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 80))
                        .foregroundColor(HighContrastColors.success)
                }
                
                VStack(spacing: 16) {
                    Text("3. Complete")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(HighContrastColors.success)
                        .accessibleText()
                    
                    Text("Take an after photo and celebrate your win!")
                        .font(.title3)
                        .foregroundColor(HighContrastColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .accessibleText()
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Label("See before & after comparison", systemImage: "photo.stack.fill")
                        .foregroundColor(HighContrastColors.success)
                        .accessibleLabel(icon: "photo.stack.fill", label: "See before & after comparison")
                    
                    Label("Enjoy celebration animations", systemImage: "sparkles")
                        .foregroundColor(HighContrastColors.success)
                        .accessibleLabel(icon: "sparkles", label: "Enjoy celebration animations")
                    
                    Label("Build your daily streak", systemImage: "flame.fill")
                        .foregroundColor(HighContrastColors.success)
                        .accessibleLabel(icon: "flame.fill", label: "Build your daily streak")
                }
                .font(.subheadline)
                .foregroundColor(HighContrastColors.secondaryText)
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Permissions Page
struct PermissionsPage: View {
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(accessibilitySettings.highContrast ? 0.3 : 0.2))
                        .frame(width: 200, height: 200)
                    
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 80))
                        .foregroundColor(accessibilitySettings.highContrast ? HighContrastColors.info : .purple)
                }
                
                VStack(spacing: 16) {
                    Text("One More Thing")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .accessibleText()
                    
                    Text("TaskSnap needs a couple permissions to work best")
                        .font(.title3)
                        .foregroundColor(HighContrastColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .accessibleText()
                        .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    PermissionRow(
                        icon: "camera.fill",
                        title: "Camera",
                        description: "To capture task photos"
                    )
                    
                    PermissionRow(
                        icon: "photo.on.rectangle",
                        title: "Photo Library",
                        description: "To save and view task photos"
                    )
                    
                    PermissionRow(
                        icon: "bell.fill",
                        title: "Notifications (Optional)",
                        description: "Reminders for overdue tasks"
                    )
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Permission Row
struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(HighContrastColors.accent)
                .frame(width: 40)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .accessibleText(lineLimit: 1)
                Text(description)
                    .font(.caption)
                    .foregroundColor(HighContrastColors.secondaryText)
                    .accessibleText(lineLimit: 2)
            }
        }
    }
}

// MARK: - Category Badge
struct CategoryBadge: View {
    let icon: String
    let label: String
    let color: Color
    
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(accessibilitySettings.highContrast ? color.opacity(1.0) : color)
                .accessibilityHidden(true)
            
            Text(label)
                .font(.caption)
                .foregroundColor(HighContrastColors.secondaryText)
                .accessibleText(lineLimit: 1)
        }
        .frame(width: 80, height: 80)
        .background(color.opacity(accessibilitySettings.highContrast ? 0.2 : 0.1))
        .cornerRadius(12)
        .highContrastBorder(cornerRadius: 12, lineWidth: accessibilitySettings.highContrast ? 1 : 0, color: color.opacity(0.5))
    }
}

#Preview {
    OnboardingView()
}
