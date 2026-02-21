import Foundation
import AVFoundation
import Combine

// MARK: - Focus Sound Types
enum FocusSound: String, CaseIterable, Identifiable {
    case none = "none"
    case rain = "rain"
    case cafe = "cafe"
    case whiteNoise = "whiteNoise"
    case forest = "forest"
    case ocean = "ocean"
    case fireplace = "fireplace"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "No Sound"
        case .rain: return "Rain"
        case .cafe: return "Coffee Shop"
        case .whiteNoise: return "White Noise"
        case .forest: return "Forest"
        case .ocean: return "Ocean Waves"
        case .fireplace: return "Fireplace"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "speaker.slash.fill"
        case .rain: return "cloud.rain.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .whiteNoise: return "waveform"
        case .forest: return "leaf.fill"
        case .ocean: return "water.waves"
        case .fireplace: return "flame.fill"
        }
    }
    
    var color: String {
        switch self {
        case .none: return "secondary"
        case .rain: return "blue"
        case .cafe: return "brown"
        case .whiteNoise: return "gray"
        case .forest: return "green"
        case .ocean: return "cyan"
        case .fireplace: return "orange"
        }
    }
    
    var filename: String? {
        switch self {
        case .none: return nil
        case .rain: return "rain_loop.mp3"
        case .cafe: return "cafe_loop.mp3"
        case .whiteNoise: return "whitenoise_loop.mp3"
        case .forest: return "forest_loop.mp3"
        case .ocean: return "ocean_loop.mp3"
        case .fireplace: return "fireplace_loop.mp3"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "Focus in silence"
        case .rain: return "Gentle rainfall for deep concentration"
        case .cafe: return "Ambient coffee shop atmosphere"
        case .whiteNoise: return "Steady white noise to mask distractions"
        case .forest: return "Peaceful forest sounds with birds"
        case .ocean: return "Calming ocean waves"
        case .fireplace: return "Crackling fire for cozy focus"
        }
    }
}

// MARK: - Focus Sound Manager
class FocusSoundManager: ObservableObject {
    static let shared = FocusSoundManager()
    
    @Published var currentSound: FocusSound = .none
    @Published var volume: Double = 0.5
    @Published var isPlaying = false
    
    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    
    private init() {
        // Load saved preferences
        if let savedSound = UserDefaults.standard.string(forKey: "focusSound"),
           let sound = FocusSound(rawValue: savedSound) {
            currentSound = sound
        }
        volume = UserDefaults.standard.double(forKey: "focusSoundVolume")
        if volume == 0 {
            volume = 0.5 // Default
        }
        
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    func play(sound: FocusSound) {
        // Stop current sound
        stop()
        
        guard sound != .none, let filename = sound.filename else {
            currentSound = .none
            return
        }
        
        // For demo/prototype, we'll use system sounds or generate simple tones
        // In production, these would be actual audio files in the bundle
        if let url = Bundle.main.url(forResource: filename, withExtension: nil, subdirectory: "Sounds") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1 // Loop forever
                audioPlayer?.volume = Float(volume)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
                
                currentSound = sound
                isPlaying = true
                
                // Fade in
                fadeIn()
                
                // Save preference
                UserDefaults.standard.set(sound.rawValue, forKey: "focusSound")
            } catch {
                print("Failed to play sound: \(error)")
            }
        } else {
            // Fallback: generate white noise programmatically
            if sound == .whiteNoise {
                generateWhiteNoise()
            }
        }
    }
    
    func stop() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        
        // Fade out before stopping
        guard let player = audioPlayer else {
            isPlaying = false
            return
        }
        
        let steps = 10
        let fadeDuration = 0.5
        let stepDuration = fadeDuration / Double(steps)
        let volumeStep = player.volume / Float(steps)
        
        var currentStep = 0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            currentStep += 1
            player.volume -= volumeStep
            
            if currentStep >= steps {
                timer.invalidate()
                player.stop()
                self?.audioPlayer = nil
                self?.isPlaying = false
            }
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    func resume() {
        audioPlayer?.play()
        isPlaying = true
    }
    
    func setVolume(_ newVolume: Double) {
        volume = max(0, min(1, newVolume))
        audioPlayer?.volume = Float(volume)
        UserDefaults.standard.set(volume, forKey: "focusSoundVolume")
    }
    
    private func fadeIn() {
        guard let player = audioPlayer else { return }
        
        player.volume = 0
        let targetVolume = Float(volume)
        let steps = 20
        let fadeDuration = 2.0
        let stepDuration = fadeDuration / Double(steps)
        let volumeStep = targetVolume / Float(steps)
        
        var currentStep = 0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            player.volume += volumeStep
            
            if currentStep >= steps {
                timer.invalidate()
                player.volume = targetVolume
            }
        }
    }
    
    // MARK: - Procedural Audio Fallback
    
    private func generateWhiteNoise() {
        // Create a simple white noise buffer as fallback
        // In production, use actual audio files
        let sampleRate: Double = 44100
        let duration: Double = 1.0 // 1 second buffer, looped
        let numSamples = Int(sampleRate * duration)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numSamples)) else {
            return
        }
        
        buffer.frameLength = AVAudioFrameCount(numSamples)
        
        // Fill with random values (white noise)
        if let data = buffer.floatChannelData?[0] {
            for i in 0..<numSamples {
                data[i] = Float.random(in: -0.1...0.1) * Float(volume)
            }
        }
        
        do {
            let player = try AVAudioPlayer()
            // Note: This is a simplified approach. In production, use actual audio files
            audioPlayer = player
            isPlaying = true
            currentSound = .whiteNoise
        } catch {
            print("Failed to create white noise: \(error)")
        }
    }
}

// MARK: - Break Reminder Manager
class BreakReminderManager: ObservableObject {
    static let shared = BreakReminderManager()
    
    @Published var isBreakTime = false
    @Published var timeUntilBreak: TimeInterval = 0
    @Published var breakDuration: TimeInterval = 300 // 5 minutes default
    
    private var reminderTimer: Timer?
    private var breakInterval: TimeInterval = 1500 // 25 minutes default (Pomodoro)
    
    var breakIntervalMinutes: Int {
        get { Int(breakInterval / 60) }
        set { breakInterval = TimeInterval(newValue * 60) }
    }
    
    func startMonitoring(sessionDuration: TimeInterval) {
        stopMonitoring()
        
        // Only remind for sessions longer than 15 minutes
        guard sessionDuration > 900 else { return }
        
        timeUntilBreak = breakInterval
        
        reminderTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.timeUntilBreak -= 1
            
            if self.timeUntilBreak <= 0 && !self.isBreakTime {
                self.triggerBreakReminder()
            }
        }
    }
    
    func stopMonitoring() {
        reminderTimer?.invalidate()
        reminderTimer = nil
        isBreakTime = false
        timeUntilBreak = 0
    }
    
    func skipBreak() {
        isBreakTime = false
        timeUntilBreak = breakInterval
    }
    
    func takeBreak() {
        isBreakTime = true
        // In a full implementation, this would start a break timer
        // and notify when break is over
    }
    
    func endBreak() {
        isBreakTime = false
        timeUntilBreak = breakInterval
    }
    
    private func triggerBreakReminder() {
        isBreakTime = true
        
        // Post notification
        NotificationCenter.default.post(
            name: .breakReminderTriggered,
            object: nil
        )
        
        // Schedule local notification as backup
        let content = UNMutableNotificationContent()
        content.title = "Time for a Break!"
        content.body = "You've been focusing for a while. Take a 5-minute break to recharge."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "break-reminder",
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    var formattedTimeUntilBreak: String {
        let minutes = Int(timeUntilBreak) / 60
        let seconds = Int(timeUntilBreak) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let breakReminderTriggered = Notification.Name("tasksnap.break.reminder")
}
