import Foundation
import SwiftUI

// MARK: - Celebration Theme
enum CelebrationTheme: String, CaseIterable, Identifiable {
    case classic = "classic"
    case party = "party"
    case fire = "fire"
    case diamond = "diamond"
    case rainbow = "rainbow"
    case nature = "nature"
    case neon = "neon"
    case gold = "gold"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .party: return "Party Time"
        case .fire: return "On Fire"
        case .diamond: return "Diamond"
        case .rainbow: return "Rainbow"
        case .nature: return "Nature"
        case .neon: return "Neon Nights"
        case .gold: return "Golden Hour"
        }
    }
    
    var icon: String {
        switch self {
        case .classic: return "sparkles"
        case .party: return "party.popper"
        case .fire: return "flame.fill"
        case .diamond: return "diamond.fill"
        case .rainbow: return "rainbow"
        case .nature: return "leaf.fill"
        case .neon: return "bolt.fill"
        case .gold: return "crown.fill"
        }
    }
    
    var description: String {
        switch self {
        case .classic: return "The original TaskSnap celebration"
        case .party: return "Confetti and streamers galore"
        case .fire: return "Hot streak celebration"
        case .diamond: return "Premium sparkle effects"
        case .rainbow: return "Colorful pride celebration"
        case .nature: return "Organic leaf and flower petals"
        case .neon: return "Electric glow effects"
        case .gold: return "Luxury golden celebration"
        }
    }
    
    // MARK: - Confetti Colors
    var confettiColors: [Color] {
        switch self {
        case .classic:
            return [.red, .blue, .green, .yellow, .purple, .orange]
        case .party:
            return [.pink, .cyan, .yellow, .purple, .orange, .mint]
        case .fire:
            return [.red, .orange, .yellow, .red.opacity(0.8), .orange.opacity(0.8)]
        case .diamond:
            return [.cyan, .white, .blue.opacity(0.5), .cyan.opacity(0.7), .white.opacity(0.9)]
        case .rainbow:
            return [.red, .orange, .yellow, .green, .blue, .purple]
        case .nature:
            return [.green, .mint, .yellow.opacity(0.8), .brown.opacity(0.6), .green.opacity(0.7)]
        case .neon:
            return [.pink, .cyan, .green, .yellow, .purple, .orange]
        case .gold:
            return [.yellow, .orange, .yellow.opacity(0.8), .orange.opacity(0.7), .white]
        }
    }
    
    // MARK: - Confetti Shapes
    var confettiShapes: [ConfettiShape] {
        switch self {
        case .classic:
            return [.circle, .square, .triangle]
        case .party:
            return [.circle, .square, .star, .ribbon]
        case .fire:
            return [.circle, .triangle, .flame]
        case .diamond:
            return [.diamond, .square, .circle]
        case .rainbow:
            return [.circle, .star, .heart]
        case .nature:
            return [.leaf, .flower, .circle]
        case .neon:
            return [.square, .triangle, .bolt]
        case .gold:
            return [.crown, .star, .circle, .diamond]
        }
    }
    
    // MARK: - Animation Style
    var animationStyle: AnimationStyle {
        switch self {
        case .classic: return .gentle
        case .party: return .explosive
        case .fire: return .rising
        case .diamond: return .sparkle
        case .rainbow: return .wave
        case .nature: return .floating
        case .neon: return .electric
        case .gold: return .royal
        }
    }
    
    // MARK: - Sound Effect (placeholder for now)
    var soundEffect: String? {
        switch self {
        case .classic: return "success"
        case .party: return "party_horn"
        case .fire: return "fireworks"
        case .diamond: return "chime"
        case .rainbow: return "celebration"
        case .nature: return "birds"
        case .neon: return "electric"
        case .gold: return "triumph"
        }
    }
    
    // MARK: - Unlock Requirements
    var unlockRequirement: UnlockRequirement {
        switch self {
        case .classic:
            return .default
        case .party:
            return .streak(days: 3)
        case .fire:
            return .achievement(name: "Morning Warrior")
        case .diamond:
            return .proOnly
        case .rainbow:
            return .tasksCompleted(count: 25)
        case .nature:
            return .achievement(name: "Clutter Buster")
        case .neon:
            return .proOnly
        case .gold:
            return .streak(days: 14)
        }
    }
    
    var isProOnly: Bool {
        if case .proOnly = unlockRequirement {
            return true
        }
        return false
    }
}

// MARK: - Confetti Shape (Shared)
enum ConfettiShape {
    case circle, square, triangle, star, heart, diamond
    case ribbon, flame, leaf, flower, bolt, crown
}

// MARK: - Animation Style
enum AnimationStyle {
    case gentle      // Slow fall, soft bounce
    case explosive   // Fast burst out
    case rising      // Floats upward like fire
    case sparkle     // Twinkles and fades
    case wave        // Swaying motion
    case floating    // Slow drift like leaves
    case electric    // Quick zigzag
    case royal       // Graceful descent
}

// MARK: - Unlock Requirement
enum UnlockRequirement: Equatable {
    case `default`           // Unlocked from start
    case streak(days: Int)   // Unlock after X day streak
    case tasksCompleted(count: Int)  // Unlock after X tasks
    case achievement(name: String)   // Unlock specific achievement
    case proOnly             // Pro subscription only
    
    var displayText: String {
        switch self {
        case .default:
            return "Unlocked"
        case .streak(let days):
            return "Reach a \(days)-day streak"
        case .tasksCompleted(let count):
            return "Complete \(count) tasks"
        case .achievement(let name):
            return "Unlock '\(name)'"
        case .proOnly:
            return "Pro Feature"
        }
    }
}

// MARK: - Theme Progress
struct ThemeProgress {
    let theme: CelebrationTheme
    let isUnlocked: Bool
    let progress: Double  // 0.0 to 1.0
    let requirement: UnlockRequirement
}
