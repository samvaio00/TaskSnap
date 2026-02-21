import Foundation
import CloudKit

// MARK: - Focus Session
struct FocusSession: Identifiable, Codable {
    let id: UUID
    let userId: String
    let userName: String
    let avatar: String
    let startTime: Date
    let taskName: String?
    let isActive: Bool
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        } else {
            return String(format: "%d min", minutes)
        }
    }
}

// MARK: - Session Participant
struct SessionParticipant: Identifiable, Codable {
    let id: String
    let name: String
    let avatar: String
    let joinedAt: Date
    let currentTask: String?
    let isActive: Bool
    let lastHeartbeat: Date
    
    var isOnline: Bool {
        // Consider online if heartbeat within last 2 minutes
        Date().timeIntervalSince(lastHeartbeat) < 120
    }
}

// MARK: - Room Status
enum RoomStatus: String {
    case available = "Available"
    case full = "Full"
    case premiumRequired = "Pro Feature"
}
