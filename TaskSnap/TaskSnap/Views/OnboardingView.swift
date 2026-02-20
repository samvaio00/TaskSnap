import SwiftUI
import AVFoundation
import UserNotifications

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showPermissionRequest = false
    
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
                .animation(.easeInOut, value: currentPage)
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.vertical, 20)
                
                // Next/Get Started button
                Button {
                    if currentPage < totalPages - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        requestPermissions()
                    }
                } label: {
                    HStack {
                        Text(currentPage < totalPages - 1 ? "Next" : "Get Started")
                            .font(.headline)
                        Image(systemName: currentPage < totalPages - 1 ? "arrow.right" : "checkmark")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(16)
                }
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completeOnboarding()
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

// MARK: - Welcome Page
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Icon Placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
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
                
                Text("Capture Your Chaos. See Your Success.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Label("Designed for ADHD brains", systemImage: "brain.head.profile")
                Label("Visual task management", systemImage: "eye.fill")
                Label("Build lasting habits", systemImage: "flame.fill")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Capture Page
struct CapturePage: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 16) {
                Text("1. Capture")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                
                Text("Snap a photo of anything that needs your attention")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Messy desk? Capture it.")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Broken item? Snap it.")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Grocery list? Photograph it.")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Clarify Page
struct ClarifyPage: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 16) {
                Text("2. Clarify")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                
                Text("AI suggests a title, or pick a quick category")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
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
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Complete Page
struct CompletePage: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color("doneColor").opacity(0.2))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color("doneColor"))
            }
            
            VStack(spacing: 16) {
                Text("3. Complete")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color("doneColor"))
                
                Text("Take an after photo and celebrate your win!")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "photo.stack.fill")
                        .foregroundColor(Color("doneColor"))
                    Text("See before & after comparison")
                }
                
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(Color("doneColor"))
                    Text("Enjoy celebration animations")
                }
                
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(Color("doneColor"))
                    Text("Build your daily streak")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Permissions Page
struct PermissionsPage: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 16) {
                Text("One More Thing")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                
                Text("TaskSnap needs a couple permissions to work best")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading) {
                        Text("Camera")
                            .font(.headline)
                        Text("To capture task photos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading) {
                        Text("Photo Library")
                            .font(.headline)
                        Text("To save and view task photos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 16) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading) {
                        Text("Notifications (Optional)")
                            .font(.headline)
                        Text("Reminders for overdue tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Category Badge
struct CategoryBadge: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 80)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView()
}
