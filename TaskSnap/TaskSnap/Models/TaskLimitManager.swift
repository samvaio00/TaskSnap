import Foundation

// MARK: - Task Limit Manager
class TaskLimitManager {
    static let shared = TaskLimitManager()
    
    let freeTierLimit = 15
    
    var isProUser: Bool {
        // For MVP, always return false (free tier)
        // In production, this would check UserDefaults or receipt
        return false
    }
    
    func canCreateTask(currentTaskCount: Int) -> Bool {
        if isProUser {
            return true
        }
        return currentTaskCount < freeTierLimit
    }
    
    func remainingTasks(currentTaskCount: Int) -> Int {
        if isProUser {
            return Int.max
        }
        return max(0, freeTierLimit - currentTaskCount)
    }
    
    var limitMessage: String {
        return "Free tier: \(freeTierLimit) tasks max"
    }
}
