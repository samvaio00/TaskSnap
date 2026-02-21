import Foundation
import CoreData
import NaturalLanguage

// MARK: - Task Suggestion
struct TaskSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let category: TaskCategory
    let confidence: Double
    let reason: String
    let basedOn: String // The task this is based on
}

// MARK: - Task Suggestion Service
class TaskSuggestionService: ObservableObject {
    static let shared = TaskSuggestionService()
    
    @Published var suggestions: [TaskSuggestion] = []
    @Published var isLoading = false
    
    private let context: NSManagedObjectContext
    
    private init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    // MARK: - Generate Suggestions
    func generateSuggestions(for currentTask: TaskEntity? = nil, limit: Int = 5) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var allSuggestions: [TaskSuggestion] = []
            
            // 1. Suggest recurring tasks
            let recurringSuggestions = self.suggestRecurringTasks()
            allSuggestions.append(contentsOf: recurringSuggestions)
            
            // 2. Suggest based on patterns
            let patternSuggestions = self.suggestBasedOnPatterns()
            allSuggestions.append(contentsOf: patternSuggestions)
            
            // 3. Suggest based on time
            let timeSuggestions = self.suggestBasedOnTime()
            allSuggestions.append(contentsOf: timeSuggestions)
            
            // 4. Suggest based on current task (if provided)
            if let currentTask = currentTask {
                let similarSuggestions = self.suggestSimilarTasks(to: currentTask)
                allSuggestions.append(contentsOf: similarSuggestions)
            }
            
            // Remove duplicates and sort by confidence
            let uniqueSuggestions = self.removeDuplicates(allSuggestions)
            let sortedSuggestions = uniqueSuggestions.sorted { $0.confidence > $1.confidence }
            
            DispatchQueue.main.async {
                self.suggestions = Array(sortedSuggestions.prefix(limit))
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Recurring Task Suggestions
    private func suggestRecurringTasks() -> [TaskSuggestion] {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == 'done'")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.completedAt, ascending: false)]
        
        guard let completedTasks = try? context.fetch(request) else { return [] }
        
        // Group tasks by normalized title
        var taskGroups: [String: [TaskEntity]] = [:]
        
        for task in completedTasks {
            guard let title = task.title?.lowercased() else { continue }
            let normalizedTitle = normalizeTitle(title)
            taskGroups[normalizedTitle, default: []].append(task)
        }
        
        var suggestions: [TaskSuggestion] = []
        let calendar = Calendar.current
        let now = Date()
        
        for (normalizedTitle, tasks) in taskGroups {
            guard tasks.count >= 2 else { continue } // Need at least 2 occurrences
            
            // Check if it's been a while since last completion
            guard let lastCompleted = tasks.first?.completedAt else { continue }
            
            let daysSinceLastCompletion = calendar.dateComponents([.day], from: lastCompleted, to: now).day ?? 0
            
            // Calculate average interval between completions
            let intervals = calculateIntervals(tasks)
            guard let averageInterval = intervals.average(), averageInterval > 0 else { continue }
            
            // If it's been longer than average interval, suggest it
            if Double(daysSinceLastCompletion) > averageInterval * 0.8 {
                let confidence = min(1.0, Double(daysSinceLastCompletion) / averageInterval)
                
                if let mostRecent = tasks.first,
                   let originalTitle = mostRecent.title {
                    suggestions.append(TaskSuggestion(
                        title: originalTitle,
                        category: mostRecent.taskCategory,
                        confidence: confidence,
                        reason: "Done \(tasks.count) times, usually every \(Int(averageInterval)) days",
                        basedOn: "Recurring pattern"
                    ))
                }
            }
        }
        
        return suggestions
    }
    
    // MARK: - Pattern-Based Suggestions
    private func suggestBasedOnPatterns() -> [TaskSuggestion] {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == 'done'")
        
        guard let completedTasks = try? context.fetch(request) else { return [] }
        
        var suggestions: [TaskSuggestion] = []
        
        // Find tasks commonly done on this day of week
        let weekdayTasks = completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return calendar.component(.weekday, from: completedAt) == weekday
        }
        
        // Group by title and count
        var weekdayTaskCounts: [String: Int] = [:]
        for task in weekdayTasks {
            guard let title = task.title else { continue }
            weekdayTaskCounts[title, default: 0] += 1
        }
        
        // Suggest top tasks for this day
        let topWeekdayTasks = weekdayTaskCounts.sorted { $0.value > $1.value }.prefix(2)
        for (title, count) in topWeekdayTasks {
            if count >= 2 {
                // Find the category from one of these tasks
                if let task = weekdayTasks.first(where: { $0.title == title }) {
                    suggestions.append(TaskSuggestion(
                        title: title,
                        category: task.taskCategory,
                        confidence: min(0.8, Double(count) * 0.2),
                        reason: "Often done on \(dayName(weekday))s",
                        basedOn: "Day pattern"
                    ))
                }
            }
        }
        
        // Find tasks commonly done at this time of day
        let timeOfDay = getTimeOfDay(hour: hour)
        let timeTasks = completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            let taskHour = calendar.component(.hour, from: completedAt)
            return getTimeOfDay(hour: taskHour) == timeOfDay
        }
        
        var timeTaskCounts: [String: Int] = [:]
        for task in timeTasks {
            guard let title = task.title else { continue }
            timeTaskCounts[title, default: 0] += 1
        }
        
        let topTimeTasks = timeTaskCounts.sorted { $0.value > $1.value }.prefix(2)
        for (title, count) in topTimeTasks {
            if count >= 2 {
                if let task = timeTasks.first(where: { $0.title == title }) {
                    suggestions.append(TaskSuggestion(
                        title: title,
                        category: task.taskCategory,
                        confidence: min(0.7, Double(count) * 0.2),
                        reason: "Often done in the \(timeOfDay.rawValue)",
                        basedOn: "Time pattern"
                    ))
                }
            }
        }
        
        return suggestions
    }
    
    // MARK: - Time-Based Suggestions
    private func suggestBasedOnTime() -> [TaskSuggestion] {
        let hour = Calendar.current.component(.hour, from: Date())
        var suggestions: [TaskSuggestion] = []
        
        // Morning routine suggestions
        if hour >= 6 && hour < 10 {
            suggestions.append(contentsOf: [
                TaskSuggestion(title: "Make bed", category: .organize, confidence: 0.5, reason: "Morning routine", basedOn: "Time of day"),
                TaskSuggestion(title: "Unload dishwasher", category: .clean, confidence: 0.4, reason: "Morning routine", basedOn: "Time of day"),
                TaskSuggestion(title: "Check emails", category: .work, confidence: 0.5, reason: "Start of workday", basedOn: "Time of day")
            ])
        }
        
        // Evening suggestions
        if hour >= 18 && hour < 22 {
            suggestions.append(contentsOf: [
                TaskSuggestion(title: "Tidy living room", category: .clean, confidence: 0.4, reason: "Evening wind-down", basedOn: "Time of day"),
                TaskSuggestion(title: "Prep tomorrow's lunch", category: .health, confidence: 0.4, reason: "Evening prep", basedOn: "Time of day"),
                TaskSuggestion(title: "Load dishwasher", category: .clean, confidence: 0.5, reason: "End of day cleanup", basedOn: "Time of day")
            ])
        }
        
        // Weekend suggestions
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 { // Sunday or Saturday
            suggestions.append(contentsOf: [
                TaskSuggestion(title: "Weekly laundry", category: .clean, confidence: 0.6, reason: "Weekend chore", basedOn: "Day of week"),
                TaskSuggestion(title: "Meal prep", category: .health, confidence: 0.5, reason: "Weekend prep", basedOn: "Day of week"),
                TaskSuggestion(title: "Organize closet", category: .organize, confidence: 0.4, reason: "Weekend project", basedOn: "Day of week")
            ])
        }
        
        return suggestions
    }
    
    // MARK: - Similar Task Suggestions
    private func suggestSimilarTasks(to currentTask: TaskEntity) -> [TaskSuggestion] {
        guard let currentTitle = currentTask.title?.lowercased() else { return [] }
        
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == 'done' AND title != %@", currentTask.title ?? "")
        request.fetchLimit = 20
        
        guard let completedTasks = try? context.fetch(request) else { return [] }
        
        var suggestions: [TaskSuggestion] = []
        let currentEmbedding = generateEmbedding(for: currentTitle)
        
        for task in completedTasks {
            guard let taskTitle = task.title?.lowercased() else { continue }
            
            let similarity = calculateSimilarity(currentEmbedding, generateEmbedding(for: taskTitle))
            
            if similarity > 0.7 { // High similarity threshold
                suggestions.append(TaskSuggestion(
                    title: task.title ?? taskTitle,
                    category: task.taskCategory,
                    confidence: similarity,
                    reason: "Similar to '\(currentTask.title ?? "current task")'",
                    basedOn: "Task similarity"
                ))
            }
        }
        
        return suggestions.sorted { $0.confidence > $1.confidence }.prefix(3).map { $0 }
    }
    
    // MARK: - Helpers
    private func normalizeTitle(_ title: String) -> String {
        // Remove numbers and common variations
        var normalized = title
        
        // Remove numbers
        normalized = normalized.components(separatedBy: CharacterSet.decimalDigits).joined()
        
        // Remove common prefixes/suffixes
        let wordsToRemove = ["the", "a", "an", "my", "your"]
        let words = normalized.split(separator: " ")
        let filteredWords = words.filter { !wordsToRemove.contains(String($0)) }
        
        return filteredWords.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }
    
    private func calculateIntervals(_ tasks: [TaskEntity]) -> [Double] {
        let calendar = Calendar.current
        var intervals: [Double] = []
        
        let sortedTasks = tasks.sorted { 
            ($0.completedAt ?? Date()) < ($1.completedAt ?? Date()) 
        }
        
        for i in 1..<sortedTasks.count {
            guard let current = sortedTasks[i].completedAt,
                  let previous = sortedTasks[i-1].completedAt else { continue }
            
            let days = calendar.dateComponents([.day], from: previous, to: current).day ?? 0
            intervals.append(Double(days))
        }
        
        return intervals
    }
    
    private func removeDuplicates(_ suggestions: [TaskSuggestion]) -> [TaskSuggestion] {
        var seenTitles: Set<String> = []
        var unique: [TaskSuggestion] = []
        
        for suggestion in suggestions {
            let normalizedTitle = suggestion.title.lowercased()
            if !seenTitles.contains(normalizedTitle) {
                seenTitles.insert(normalizedTitle)
                unique.append(suggestion)
            }
        }
        
        return unique
    }
    
    private func dayName(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let date = Calendar.current.date(from: DateComponents(weekday: weekday))!
        return formatter.string(from: date)
    }
    
    private func getTimeOfDay(hour: Int) -> TimeOfDay {
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
    
    enum TimeOfDay: String {
        case morning = "morning"
        case afternoon = "afternoon"
        case evening = "evening"
        case night = "night"
    }
    
    // Simple embedding using word frequency
    private func generateEmbedding(for text: String) -> [Double] {
        let words = text.split(separator: " ").map { String($0) }
        var embedding = Array(repeating: 0.0, count: 100)
        
        for (index, word) in words.enumerated() {
            let hash = abs(word.hashValue % 100)
            embedding[hash] += 1.0
            
            // Position weighting
            if index < embedding.count {
                embedding[index] += 0.5
            }
        }
        
        // Normalize
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }
        
        return embedding
    }
    
    private func calculateSimilarity(_ embedding1: [Double], _ embedding2: [Double]) -> Double {
        guard embedding1.count == embedding2.count else { return 0 }
        
        let dotProduct = zip(embedding1, embedding2).map(*).reduce(0, +)
        return max(0, min(1, (dotProduct + 1) / 2)) // Normalize to 0-1
    }
}

// MARK: - Array Extension
extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}

// MARK: - Task Suggestions View
struct TaskSuggestionsView: View {
    @StateObject private var service = TaskSuggestionService.shared
    let currentTask: TaskEntity?
    let onSelect: (TaskSuggestion) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Suggested Tasks")
                    .font(.headline)
                
                Spacer()
                
                if service.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        service.generateSuggestions(for: currentTask)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                }
            }
            
            if service.suggestions.isEmpty && !service.isLoading {
                Text("Complete more tasks to get personalized suggestions!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(service.suggestions) { suggestion in
                        Button {
                            onSelect(suggestion)
                        } label: {
                            HStack {
                                Image(systemName: suggestion.category.icon)
                                    .foregroundColor(Color(suggestion.category.color))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    
                                    Text(suggestion.reason)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                // Confidence indicator
                                Circle()
                                    .fill(confidenceColor(suggestion.confidence))
                                    .frame(width: 8, height: 8)
                            }
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .onAppear {
            service.generateSuggestions(for: currentTask)
        }
    }
    
    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence > 0.7 { return .green }
        if confidence > 0.4 { return .orange }
        return .gray
    }
}

// MARK: - Quick Add Suggestion Button
struct QuickAddSuggestionButton: View {
    let suggestion: TaskSuggestion
    let onAdd: () -> Void
    
    var body: some View {
        Button {
            onAdd()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: suggestion.category.icon)
                    .font(.caption)
                    .foregroundColor(Color(suggestion.category.color))
                
                Text(suggestion.title)
                    .font(.caption)
                    .lineLimit(1)
                
                Image(systemName: "plus.circle.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
