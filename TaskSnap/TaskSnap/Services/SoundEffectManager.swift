import Foundation
import AVFoundation
import AudioToolbox

// MARK: - Sound Effect Manager
@MainActor
class SoundEffectManager: ObservableObject {
    static let shared = SoundEffectManager()
    
    // MARK: - Published Properties
    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: soundEnabledKey)
        }
    }
    
    @Published var volume: Float {
        didSet {
            UserDefaults.standard.set(volume, forKey: soundVolumeKey)
            updateVolume()
        }
    }
    
    // MARK: - Private Properties
    private let soundEnabledKey = "tasksnap.soundEffects.enabled"
    private let soundVolumeKey = "tasksnap.soundEffects.volume"
    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var systemSoundIDs: [SoundEffect: SystemSoundID] = [:]
    
    // MARK: - Sound Effect Types
    enum SoundEffect: String, CaseIterable, Identifiable {
        case buttonTap       = "button_tap"
        case taskComplete    = "task_complete"
        case success         = "success"
        case error           = "error"
        case cameraShutter   = "camera_shutter"
        case achievement     = "achievement"
        case streakMilestone = "streak_milestone"
        case swipe           = "swipe"
        case pop             = "pop"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .buttonTap: return "Button Tap"
            case .taskComplete: return "Task Complete"
            case .success: return "Success"
            case .error: return "Error"
            case .cameraShutter: return "Camera Shutter"
            case .achievement: return "Achievement"
            case .streakMilestone: return "Streak Milestone"
            case .swipe: return "Swipe"
            case .pop: return "Pop"
            }
        }
        
        var description: String {
            switch self {
            case .buttonTap: return "Standard button press feedback"
            case .taskComplete: return "When a task is completed"
            case .success: return "General success actions"
            case .error: return "Error or warning states"
            case .cameraShutter: return "Taking a photo"
            case .achievement: return "Unlocking achievements"
            case .streakMilestone: return "Reaching streak milestones"
            case .swipe: return "Swipe actions"
            case .pop: return "UI elements appearing"
            }
        }
        
        var systemSoundID: SystemSoundID {
            switch self {
            case .buttonTap:
                return 1104 // Standard click
            case .taskComplete, .success:
                return 1394 // Success
            case .error:
                return 1053 // Error
            case .cameraShutter:
                return 1108 // Camera shutter
            case .achievement, .streakMilestone:
                return 1395 // Fanfare
            case .swipe, .pop:
                return 1106 // Swipe
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        self.isSoundEnabled = UserDefaults.standard.object(forKey: soundEnabledKey) as? Bool ?? true
        self.volume = UserDefaults.standard.object(forKey: soundVolumeKey) as? Float ?? 0.7
        
        preloadSounds()
        setupAudioSession()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Sound Loading
    func preloadSounds() {
        // Try to load custom sounds from bundle
        for effect in SoundEffect.allCases {
            if let player = loadSound(for: effect) {
                audioPlayers[effect] = player
            } else {
                // Fall back to system sound
                systemSoundIDs[effect] = effect.systemSoundID
            }
        }
    }
    
    private func loadSound(for effect: SoundEffect) -> AVAudioPlayer? {
        // Check for custom sound file
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") ??
                        Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") ??
                        Bundle.main.url(forResource: effect.rawValue, withExtension: "caf") else {
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = volume
            return player
        } catch {
            print("Failed to load sound \(effect.rawValue): \(error)")
            return nil
        }
    }
    
    // MARK: - Playback
    func play(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }
        
        // Try custom sound first
        if let player = audioPlayers[effect] {
            player.currentTime = 0
            player.volume = volume
            player.play()
        } else if let soundID = systemSoundIDs[effect] {
            // Fall back to system sound
            AudioServicesPlaySystemSound(soundID)
        }
    }
    
    func play(_ effect: SoundEffect, withHaptic: Bool = true) {
        play(effect)
        
        if withHaptic {
            triggerHaptic(for: effect)
        }
    }
    
    private func triggerHaptic(for effect: SoundEffect) {
        switch effect {
        case .buttonTap, .swipe, .pop:
            Haptics.shared.light()
        case .taskComplete, .success:
            Haptics.shared.success()
        case .error:
            Haptics.shared.error()
        case .achievement, .streakMilestone:
            Haptics.shared.achievementUnlocked()
        case .cameraShutter:
            Haptics.shared.cameraShutter()
        }
    }
    
    // MARK: - Volume Control
    private func updateVolume() {
        for player in audioPlayers.values {
            player.volume = volume
        }
    }
    
    // MARK: - Test Method
    func testSound(_ effect: SoundEffect) {
        play(effect, withHaptic: true)
    }
    
    // MARK: - Reset
    func resetToDefaults() {
        isSoundEnabled = true
        volume = 0.7
        preloadSounds()
    }
}

// MARK: - View Extension for Easy Access
extension View {
    func withSoundEffects() -> some View {
        self.environmentObject(SoundEffectManager.shared)
    }
}
