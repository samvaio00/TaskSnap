import Foundation
import CoreData
import UIKit

enum TaskStatus: String, CaseIterable {
    case todo = "todo"
    case doing = "doing"
    case done = "done"
    
    var displayName: String {
        switch self {
        case .todo: return "To Do"
        case .doing: return "Doing"
        case .done: return "Done"
        }
    }
    
    var color: String {
        switch self {
        case .todo: return "todoColor"
        case .doing: return "doingColor"
        case .done: return "doneColor"
        }
    }
}

enum TaskCategory: String, CaseIterable {
    case clean = "clean"
    case fix = "fix"
    case buy = "buy"
    case work = "work"
    case organize = "organize"
    case health = "health"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .clean: return "Clean"
        case .fix: return "Fix"
        case .buy: return "Buy"
        case .work: return "Work"
        case .organize: return "Organize"
        case .health: return "Health"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .clean: return "sparkles"
        case .fix: return "wrench.fill"
        case .buy: return "cart.fill"
        case .work: return "briefcase.fill"
        case .organize: return "folder.fill"
        case .health: return "heart.fill"
        case .other: return "tag.fill"
        }
    }
    
    var color: String {
        switch self {
        case .clean: return "categoryClean"
        case .fix: return "categoryFix"
        case .buy: return "categoryBuy"
        case .work: return "categoryWork"
        case .organize: return "categoryOrganize"
        case .health: return "categoryHealth"
        case .other: return "categoryOther"
        }
    }
}

// MARK: - Task Entity Extension
extension TaskEntity {
    var taskStatus: TaskStatus {
        get {
            TaskStatus(rawValue: status ?? "todo") ?? .todo
        }
        set {
            status = newValue.rawValue
        }
    }
    
    var taskCategory: TaskCategory {
        get {
            TaskCategory(rawValue: category ?? "other") ?? .other
        }
        set {
            category = newValue.rawValue
        }
    }
    
    var beforeImage: UIImage? {
        guard let path = beforeImagePath else { return nil }
        return ImageStorage.shared.loadImage(from: path)
    }
    
    var afterImage: UIImage? {
        guard let path = afterImagePath else { return nil }
        return ImageStorage.shared.loadImage(from: path)
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return dueDate < Date() && taskStatus != .done
    }
    
    var urgencyLevel: UrgencyLevel {
        if taskStatus == .done { return .none }
        if isUrgent { return .high }
        guard let dueDate = dueDate else { return .none }
        
        let hoursUntilDue = Calendar.current.dateComponents([.hour], from: Date(), to: dueDate).hour ?? 0
        
        if hoursUntilDue < 0 {
            return .high
        } else if hoursUntilDue < 24 {
            return .medium
        } else if hoursUntilDue < 72 {
            return .low
        }
        return .none
    }
}

enum UrgencyLevel {
    case none, low, medium, high
    
    var color: String {
        switch self {
        case .none: return ""
        case .low: return "urgencyLow"
        case .medium: return "urgencyMedium"
        case .high: return "urgencyHigh"
        }
    }
    
    var shouldGlow: Bool {
        self == .medium || self == .high
    }
}

// MARK: - Image Storage
class ImageStorage {
    static let shared = ImageStorage()
    
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TaskImages")
    }
    
    init() {
        try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
    }
    
    func saveImage(_ image: UIImage) -> String? {
        let filename = UUID().uuidString + ".jpg"
        let filepath = documentsDirectory.appendingPathComponent(filename)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        do {
            try data.write(to: filepath)
            return filename
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func loadImage(from filename: String) -> UIImage? {
        let filepath = documentsDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: filepath) else { return nil }
        return UIImage(data: data)
    }
    
    func deleteImage(filename: String) {
        let filepath = documentsDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: filepath)
    }
}
