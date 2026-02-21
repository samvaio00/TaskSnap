import SwiftUI
import Combine

// MARK: - Error State View
/// Comprehensive error state view with illustration, message, and retry action
struct ErrorStateView: View {
    let icon: String
    let title: String
    let message: String
    var iconColor: Color = .accentColor
    var showRetryButton: Bool = true
    var retryButtonText: String = "Try Again"
    var showSupportButton: Bool = false
    var onRetry: (() -> Void)?
    var onContactSupport: (() -> Void)?
    
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var isAnimating = false
    @State private var iconScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundColor(iconColor)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
            }
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.2)) {
                        iconScale = 1.1
                    }
                }
            }
            .accessibilityHidden(true)
            
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
            // Retry button
            if showRetryButton, let onRetry = onRetry {
                Button(action: onRetry) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text(retryButtonText)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel("\(retryButtonText): \(title)")
                .padding(.horizontal, 40)
            }
            
            // Contact support button
            if showSupportButton, let onContactSupport = onContactSupport {
                Button(action: onContactSupport) {
                    Text("Contact Support")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(PressableButtonStyle(scale: 0.98))
                .accessibilityLabel("Contact support for help with: \(title)")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Empty State View
/// Enhanced empty state with animated illustration and encouraging language
struct EmptyStateView: View {
    var icon: String = "camera.viewfinder"
    var title: String = "No Tasks Yet"
    var message: String = "Capture your first task by taking a photo of something that needs your attention."
    var buttonTitle: String = "Capture a Task"
    var showButton: Bool = true
    var onAction: (() -> Void)?
    
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var floatOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated floating illustration
            ZStack {
                // Background circles
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(pulseScale)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 180, height: 180)
                    .scaleEffect(pulseScale * 0.9)
                
                // Main icon
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundColor(.accentColor)
                    .offset(y: floatOffset)
            }
            .onAppear {
                if !reduceMotion {
                    // Floating animation
                    withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                        floatOffset = -10
                    }
                    
                    // Subtle pulse
                    withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                        pulseScale = 1.05
                    }
                }
            }
            .accessibilityHidden(true)
            
            // Title with encouraging language
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            // Optimistic message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            
            // Action button
            if showButton, let onAction = onAction {
                Button(action: onAction) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                        Text(buttonTitle)
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(buttonTitle)
                .accessibilityHint("Opens camera to capture a new task")
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Network Error View
/// Specialized view for connection issues with auto-retry
struct NetworkErrorView: View {
    var onRetry: (() -> Void)?
    var onOfflineMode: (() -> Void)?
    
    @StateObject private var viewModel = NetworkErrorViewModel()
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // WiFi icon with animation
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "wifi.slash")
                    .font(.system(size: 44))
                    .foregroundColor(.orange)
                    .rotationEffect(.degrees(isAnimating ? 5 : -5))
            }
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
                viewModel.startCountdown(retryAction: onRetry)
            }
            .accessibilityHidden(true)
            
            Text("Connection Lost")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Text("We're having trouble connecting to the server. Your tasks are safely stored on your device.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Countdown indicator
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .rotationEffect(.degrees(viewModel.isRetrying ? 360 : 0))
                    .animation(viewModel.isRetrying ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isRetrying)
                
                Text(viewModel.isRetrying ? "Retrying..." : "Retrying in \(viewModel.countdown)s")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(20)
            
            // Action buttons
            VStack(spacing: 12) {
                Button {
                    viewModel.retryNow(retryAction: onRetry)
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry Now")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(16)
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(viewModel.isRetrying)
                .opacity(viewModel.isRetrying ? 0.6 : 1.0)
                
                if let onOfflineMode = onOfflineMode {
                    Button(action: onOfflineMode) {
                        HStack {
                            Image(systemName: "icloud.slash")
                            Text("Continue Offline")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.98))
                }
            }
            .padding(.horizontal, 40)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onDisappear {
            viewModel.cancelCountdown()
        }
    }
}

// MARK: - Network Error View Model
@MainActor
class NetworkErrorViewModel: ObservableObject {
    @Published var countdown: Int = 5
    @Published var isRetrying: Bool = false
    
    private var cancellable: AnyCancellable?
    private var countdownCancellable: AnyCancellable?
    
    func startCountdown(retryAction: (() -> Void)?) {
        guard !isRetrying else { return }
        
        countdown = 5
        
        countdownCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.countdown > 1 {
                    self.countdown -= 1
                } else {
                    self.countdownCancellable?.cancel()
                    self.retryNow(retryAction: retryAction)
                }
            }
    }
    
    func cancelCountdown() {
        countdownCancellable?.cancel()
        cancellable?.cancel()
        isRetrying = false
    }
    
    func retryNow(retryAction: (() -> Void)?) {
        countdownCancellable?.cancel()
        isRetrying = true
        
        // Simulate retry delay
        cancellable = Just(())
            .delay(for: .seconds(1.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isRetrying = false
                retryAction?()
            }
    }
}

// MARK: - Generic Error Banner
/// Top banner that slides in with auto-dismiss
struct GenericErrorBanner: View {
    let message: String
    var icon: String = "exclamationmark.triangle.fill"
    var iconColor: Color = .orange
    var autoDismiss: Bool = true
    var dismissAfter: TimeInterval = 5
    var onDismiss: (() -> Void)?
    var onAction: (() -> Void)?
    var actionTitle: String?
    
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var isVisible = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let actionTitle = actionTitle, let onAction = onAction {
                Button(action: onAction) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(6)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Dismiss error message")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
        .offset(y: isVisible ? 0 : -100)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.y < 0 {
                        dragOffset = value.translation.y
                    }
                }
                .onEnded { value in
                    if value.translation.y < -50 {
                        dismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            // Slide in
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
            
            // Auto dismiss
            if autoDismiss {
                DispatchQueue.main.asyncAfter(deadline: .now() + dismissAfter) {
                    if isVisible {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
        .accessibilityHint("Swipe up to dismiss")
    }
    
    private func dismiss() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8)) {
            isVisible = false
            dragOffset = -100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss?()
        }
    }
}

// MARK: - Sync Error Banner
/// Specialized banner for sync failures
struct SyncErrorBanner: View {
    let error: SyncError
    var onRetry: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        GenericErrorBanner(
            message: error.localizedDescription,
            icon: error.icon,
            iconColor: error.color,
            onDismiss: onDismiss,
            onAction: onRetry,
            actionTitle: "Retry"
        )
    }
}

// MARK: - Sync Error
enum SyncError: Error, LocalizedError {
    case networkUnavailable
    case iCloudNotAvailable
    case syncFailed(String)
    case quotaExceeded
    
    var errorDescription: String? {
        localizedDescription
    }
    
    var localizedDescription: String {
        switch self {
        case .networkUnavailable:
            return "Unable to sync. Check your internet connection."
        case .iCloudNotAvailable:
            return "iCloud is not available. Please sign in to iCloud."
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .quotaExceeded:
            return "iCloud storage full. Upgrade your storage plan."
        }
    }
    
    var icon: String {
        switch self {
        case .networkUnavailable:
            return "wifi.slash"
        case .iCloudNotAvailable:
            return "icloud.slash"
        case .syncFailed:
            return "exclamationmark.icloud"
        case .quotaExceeded:
            return "externaldrive.badge.xmark"
        }
    }
    
    var color: Color {
        switch self {
        case .networkUnavailable:
            return .orange
        case .iCloudNotAvailable:
            return .red
        case .syncFailed:
            return .orange
        case .quotaExceeded:
            return .red
        }
    }
}

// MARK: - No Results View
/// Empty state for search/filter with no results
struct NoResultsView: View {
    var searchTerm: String = ""
    var onClearSearch: (() -> Void)?
    
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isAnimating ? 15 : -15))
            }
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        isAnimating = true
                    }
                }
            }
            .accessibilityHidden(true)
            
            Text("No Results Found")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if !searchTerm.isEmpty {
                Text("We couldn't find any tasks matching \"\(searchTerm)\".")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Try adjusting your filters to see more tasks.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let onClearSearch = onClearSearch {
                Button(action: onClearSearch) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Clear Search")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(PressableButtonStyle(scale: 0.98))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error Banner Modifier
/// View modifier for showing error banners
struct ErrorBannerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    var icon: String = "exclamationmark.triangle.fill"
    var iconColor: Color = .orange
    var autoDismiss: Bool = true
    var onDismiss: (() -> Void)?
    var onAction: (() -> Void)?
    var actionTitle: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                VStack {
                    GenericErrorBanner(
                        message: message,
                        icon: icon,
                        iconColor: iconColor,
                        autoDismiss: autoDismiss,
                        onDismiss: {
                            isPresented = false
                            onDismiss?()
                        },
                        onAction: onAction,
                        actionTitle: actionTitle
                    )
                    
                    Spacer()
                }
                .transition(.move(edge: .top))
                .zIndex(100)
            }
        }
    }
}

// MARK: - View Extension
extension View {
    func errorBanner(
        isPresented: Binding<Bool>,
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        iconColor: Color = .orange,
        autoDismiss: Bool = true,
        onDismiss: (() -> Void)? = nil,
        onAction: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) -> some View {
        modifier(ErrorBannerModifier(
            isPresented: isPresented,
            message: message,
            icon: icon,
            iconColor: iconColor,
            autoDismiss: autoDismiss,
            onDismiss: onDismiss,
            onAction: onAction,
            actionTitle: actionTitle
        ))
    }
}

// MARK: - Preview
#Preview("Error States") {
    ScrollView {
        VStack(spacing: 30) {
            // Error State
            ErrorStateView(
                icon: "exclamationmark.triangle",
                title: "Something Went Wrong",
                message: "We couldn't load your tasks. Please try again.",
                iconColor: .orange,
                onRetry: {}
            )
            .frame(height: 400)
            
            // Empty State
            EmptyStateView(
                onAction: {}
            )
            .frame(height: 400)
            
            // Network Error
            NetworkErrorView(
                onRetry: {},
                onOfflineMode: {}
            )
            .frame(height: 400)
            
            // No Results
            NoResultsView(
                searchTerm: "clean",
                onClearSearch: {}
            )
            .frame(height: 300)
        }
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Error Banners") {
    VStack(spacing: 20) {
        GenericErrorBanner(
            message: "Failed to save task. Please try again.",
            onDismiss: {},
            onAction: {},
            actionTitle: "Retry"
        )
        
        SyncErrorBanner(
            error: .networkUnavailable,
            onRetry: {},
            onDismiss: {}
        )
        
        GenericErrorBanner(
            message: "iCloud sync failed. Using offline mode.",
            icon: "icloud.slash",
            iconColor: .secondary
        )
        
        Spacer()
    }
    .padding(.top)
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty State Variations") {
    VStack(spacing: 20) {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "All Caught Up!",
            message: "You've completed all your tasks. Great job!",
            buttonTitle: "Add New Task",
            onAction: {}
        )
        .frame(height: 300)
        
        EmptyStateView(
            icon: "sparkles",
            title: "No Achievements Yet",
            message: "Complete tasks to unlock achievements and build your streak!",
            buttonTitle: "Start a Task",
            onAction: {}
        )
        .frame(height: 300)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
