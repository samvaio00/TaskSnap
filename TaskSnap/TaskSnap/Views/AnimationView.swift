import SwiftUI
import AVKit

enum TaskSnapAnimation: String, CaseIterable {
    case captureSuccess = "capture_success"
    case taskComplete = "task_complete"
    case streakGrow = "streak_grow"
    case streakBreak = "streak_break"
    case badgeUnlock = "badge_unlock"
    case focusStart = "focus_start"
    case dailyGoalComplete = "daily_goal_complete"
    case organizeTaskComplete = "organize_task_complete"
    
    var filename: String { "\(rawValue).mp4" }
    
    var duration: Double {
        switch self {
        case .dailyGoalComplete, .organizeTaskComplete:
            return 8.0
        default:
            return 4.0
        }
    }
    
    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .taskComplete, .badgeUnlock, .dailyGoalComplete:
            return .heavy
        case .captureSuccess, .streakGrow:
            return .medium
        case .focusStart, .streakBreak, .organizeTaskComplete:
            return .light
        }
    }
    
    var hapticDelay: Double {
        switch self {
        case .captureSuccess:
            return 0.5
        case .taskComplete, .badgeUnlock, .focusStart, .organizeTaskComplete:
            return 1.5
        case .streakGrow, .streakBreak:
            return 2.5
        case .dailyGoalComplete:
            return 1.0
        }
    }
    
    var canSkip: Bool {
        switch self {
        case .taskComplete, .dailyGoalComplete, .organizeTaskComplete:
            return false
        default:
            return true
        }
    }
}

struct AnimationView: View {
    let animation: TaskSnapAnimation
    let onComplete: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            if reduceMotion {
                // Reduced motion fallback
                VStack(spacing: 20) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                    
                    Text(animationTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .onAppear {
                    triggerHaptic()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onComplete()
                    }
                }
            } else if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        setupPlayer()
                    }
            }
            
            // Skip button for skippable animations
            if animation.canSkip {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            player?.pause()
                            onComplete()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            if !reduceMotion {
                loadAndPlay()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private var animationTitle: String {
        switch animation {
        case .captureSuccess: return "Photo Captured!"
        case .taskComplete: return "Task Complete!"
        case .streakGrow: return "Streak Growing!"
        case .streakBreak: return "New Beginning!"
        case .badgeUnlock: return "Achievement Unlocked!"
        case .focusStart: return "Focus Mode"
        case .dailyGoalComplete: return "Daily Goal Complete!"
        case .organizeTaskComplete: return "Organized!"
        }
    }
    
    private func loadAndPlay() {
        guard let url = Bundle.main.url(forResource: animation.rawValue, withExtension: "mp4", subdirectory: "Animations") else {
            print("Animation file not found: \(animation.filename)")
            onComplete()
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        
        // Check for reduced speed setting
        let intensity = UserDefaults.standard.string(forKey: "animationIntensity") ?? "full"
        if intensity == "reduced" {
            newPlayer.rate = 2.0 // Play at 2x speed
        }
        
        // Observe playback completion
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            onComplete()
        }
        
        // Trigger haptic at specific time (adjusted for reduced speed)
        let hapticDelay = intensity == "reduced" ? animation.hapticDelay / 2 : animation.hapticDelay
        DispatchQueue.main.asyncAfter(deadline: .now() + hapticDelay) {
            triggerHaptic()
        }
        
        newPlayer.play()
        player = newPlayer
        isPlaying = true
    }
    
    private func setupPlayer() {
        // Already handled in loadAndPlay
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: animation.hapticStyle)
        generator.impactOccurred()
    }
}

// MARK: - Animation Manager
class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    
    @Published var currentAnimation: TaskSnapAnimation?
    @Published var isShowingAnimation = false
    
    private var completionHandler: (() -> Void)?
    
    func play(_ animation: TaskSnapAnimation, completion: @escaping () -> Void = {}) {
        // Check user preferences
        let intensity = UserDefaults.standard.string(forKey: "animationIntensity") ?? "full"
        
        if intensity == "minimal" {
            // Just trigger haptic and completion
            let generator = UIImpactFeedbackGenerator(style: animation.hapticStyle)
            generator.impactOccurred()
            completion()
            return
        }
        
        completionHandler = completion
        currentAnimation = animation
        isShowingAnimation = true
    }
    
    func onAnimationComplete() {
        isShowingAnimation = false
        completionHandler?()
        completionHandler = nil
        currentAnimation = nil
    }
}

// MARK: - Animation Modifier
struct AnimationOverlay: ViewModifier {
    @StateObject private var manager = AnimationManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if manager.isShowingAnimation, let animation = manager.currentAnimation {
                AnimationView(animation: animation) {
                    manager.onAnimationComplete()
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
}

extension View {
    func animationOverlay() -> some View {
        modifier(AnimationOverlay())
    }
}

// MARK: - Preview
#Preview {
    AnimationView(animation: .badgeUnlock) {}
}
