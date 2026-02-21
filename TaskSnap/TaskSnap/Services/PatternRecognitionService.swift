import Foundation
import CoreData
import Combine

// MARK: - Insight Types
enum InsightType: String, CaseIterable {
    case productivityPattern = "productivity_pattern"
    case timeOfDay = "time_of_day"
    case categoryTrend = "category_trend"
    case focusModeImpact = "focus_mode_impact"
    case streakCorrelation = "streak_correlation"
    case completionSpeed = "completion_speed"
    case urgentTaskPattern = "urgent_task_pattern"
    case weekendVsWeekday = "weekend_vs_weekday"
    
    var displayName: String {
        switch self {
        case .productivityPattern: return "Productivity Pattern"
        case .timeOfDay: return "Best Time to Work"
        case .categoryTrend: return "Category Insights"
        case .focusModeImpact: return "Focus Mode Impact"
        case .streakCorrelation: return "Streak Power"
        case .completionSpeed: return "Completion Speed"
        case .urgentTaskPattern: return "Urgency Response"
        case .weekendVsWeekday: return "Weekend vs Weekday"
        }
    }
    
    var icon: String {
        switch self {
        case .productivityPattern: return "chart.line.uptrend.xyaxis"
        case .timeOfDay: return "clock.fill"
        case .categoryTrend: return "folder.fill"
        case .focusModeImpact: return "target"
        case .streakCorrelation: return "flame.fill"
        case .completionSpeed: return "bolt.fill"
        case .urgentTaskPattern: return "exclamationmark.triangle.fill"
        case .weekendVsWeekday: return "calendar"
        }
    }
    
    var color: String {
        switch self {
        case .productivityPattern: return "blue"
        case .timeOfDay: return "orange"
        case .categoryTrend: return "green"
        case .focusModeImpact: return "purple"
        case .streakCorrelation: return "red"
        case .completionSpeed: return "yellow"
        case .urgentTaskPattern: return "orange"
        case .weekendVsWeekday: return "indigo"
        }
    }
}

// MARK: - Pattern Insight
struct PatternInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let detail: String
    let confidence: Double // 0.0 to 1.0
    let metric: String?
    let trend: TrendDirection?
    let recommendation: String?
    let generatedAt: Date
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .orange
            }
        }
    }
}

// MARK: - Productivity Metrics
struct ProductivityMetrics {
    let totalTasks: Int
    let completedTasks: Int
    let completionRate: Double
    let averageCompletionTime: TimeInterval?
    let tasksByDayOfWeek: [Int: Int] // 1 = Sunday, 7 = Saturday
    let tasksByHour: [Int: Int] // 0-23
    let tasksByCategory: [String: Int]
    let focusModeTasks: Int
    let focusModeCompleted: Int
    let averageStreakWhenCompleted: Double
    let urgentTaskCompletionRate: Double
    let weekendCompletionRate: Double
    let weekdayCompletionRate: Double
}

// MARK: - Pattern Recognition Service
class PatternRecognitionService: ObservableObject {
    static let shared = PatternRecognitionService()
    
    @Published var insights: [PatternInsight] = []
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    private init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadCachedInsights()
    }
    
    // MARK: - Analysis
    
    func analyzePatterns(force: Bool = false) {
        // Only analyze once per day unless forced
        if !force,
           let lastDate = lastAnalysisDate,
           Calendar.current.isDateInToday(lastDate) {
            return
        }
        
        isAnalyzing = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let metrics = self.calculateMetrics()
            var newInsights: [PatternInsight] = []
            
            // Generate insights based on metrics
            if let insight = self.analyzeProductivityPattern(metrics: metrics) {
                newInsights.append(insight)
            }
            
            if let insight = self.analyzeBestTimeOfDay(metrics: metrics) {
                newInsights.append(insight)
            }
            
            if let insight = self.analyzeCategoryTrends(metrics: metrics) {
                newInsights.append(insight)
            }
            
            if let insight = self.analyzeFocusModeImpact(metrics: metrics) {
                newInsights.append(insight)
            }
            
            if let insight = self.analyzeStreakCorrelation(metrics: metrics) {
                newInsights.append(insight)
            }
            
            if let insight = self.analyzeCompletionSpeed(metrics: metrics) {
                newInsights.append(insight)
            }
            
            if let insight = self.analyzeUrgentTaskPattern(metrics: metrics) {
                newInsights.append(insight)
            }
            
            if let insight = self.analyzeWeekendVsWeekday(metrics: metrics) {
                newInsights.append(insight)
            }
            
            // Sort by confidence
            newInsights.sort { $0.confidence > $1.confidence }
            
            DispatchQueue.main.async {
                self.insights = newInsights
                self.lastAnalysisDate = Date()
                self.isAnalyzing = false
                self.cacheInsights()
            }
        }
    }
    
    // MARK: - Metric Calculation
    
    private func calculateMetrics() -> ProductivityMetrics {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        
        // Fetch all tasks from last 90 days
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        request.predicate = NSPredicate(format: "createdAt >= %@", ninetyDaysAgo as NSDate)
        
        guard let tasks = try? context.fetch(request) else {
            return ProductivityMetrics(
                totalTasks: 0,
                completedTasks: 0,
                completionRate: 0,
                averageCompletionTime: nil,
                tasksByDayOfWeek: [:],
                tasksByHour: [:],
                tasksByCategory: [:],
                focusModeTasks: 0,
                focusModeCompleted: 0,
                averageStreakWhenCompleted: 0,
                urgentTaskCompletionRate: 0,
                weekendCompletionRate: 0,
                weekdayCompletionRate: 0
            )
        }
        
        let completedTasks = tasks.filter { $0.taskStatus == .done }
        let completionRate = tasks.isEmpty ? 0 : Double(completedTasks.count) / Double(tasks.count)
        
        // Tasks by day of week
        var tasksByDayOfWeek: [Int: Int] = [:]
        for task in completedTasks {
            guard let completedAt = task.completedAt else { continue }
            let weekday = Calendar.current.component(.weekday, from: completedAt)
            tasksByDayOfWeek[weekday, default: 0] += 1
        }
        
        // Tasks by hour
        var tasksByHour: [Int: Int] = [:]
        for task in completedTasks {
            guard let completedAt = task.completedAt else { continue }
            let hour = Calendar.current.component(.hour, from: completedAt)
            tasksByHour[hour, default: 0] += 1
        }
        
        // Tasks by category
        var tasksByCategory: [String: Int] = [:]
        for task in completedTasks {
            tasksByCategory[task.taskCategory.rawValue, default: 0] += 1
        }
        
        // Focus mode tasks (we'll track this via FocusSessionEntity)
        let focusRequest: NSFetchRequest<FocusSessionEntity> = FocusSessionEntity.fetchRequest()
        let focusSessions = (try? context.fetch(focusRequest)) ?? []
        let focusModeTasks = focusSessions.count
        let focusModeCompleted = focusSessions.filter { $0.duration > 0 }.count
        
        // Average completion time
        var totalCompletionTime: TimeInterval = 0
        var completionTimeCount = 0
        for task in completedTasks {
            guard let createdAt = task.createdAt,
                  let completedAt = task.completedAt else { continue }
            let duration = completedAt.timeIntervalSince(createdAt)
            // Only count reasonable durations (less than 30 days)
            if duration > 0 && duration < 30 * 24 * 3600 {
                totalCompletionTime += duration
                completionTimeCount += 1
            }
        }
        let averageCompletionTime = completionTimeCount > 0 ? totalCompletionTime / Double(completionTimeCount) : nil
        
        // Weekend vs weekday
        let weekendTasks = completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            let weekday = Calendar.current.component(.weekday, from: completedAt)
            return weekday == 1 || weekday == 7 // Sunday or Saturday
        }
        let weekdayTasks = completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            let weekday = Calendar.current.component(.weekday, from: completedAt)
            return weekday != 1 && weekday != 7
        }
        
        let weekendCompletionRate = completedTasks.isEmpty ? 0 : Double(weekendTasks.count) / Double(completedTasks.count)
        let weekdayCompletionRate = completedTasks.isEmpty ? 0 : Double(weekdayTasks.count) / Double(completedTasks.count)
        
        // Urgent task completion rate
        let urgentTasks = tasks.filter { $0.isUrgent }
        let completedUrgentTasks = urgentTasks.filter { $0.taskStatus == .done }
        let urgentTaskCompletionRate = urgentTasks.isEmpty ? 0 : Double(completedUrgentTasks.count) / Double(urgentTasks.count)
        
        // Average streak when completing (simplified - would need historical streak data)
        let currentStreak = StreakManager.shared.currentStreak
        let averageStreakWhenCompleted = Double(currentStreak)
        
        return ProductivityMetrics(
            totalTasks: tasks.count,
            completedTasks: completedTasks.count,
            completionRate: completionRate,
            averageCompletionTime: averageCompletionTime,
            tasksByDayOfWeek: tasksByDayOfWeek,
            tasksByHour: tasksByHour,
            tasksByCategory: tasksByCategory,
            focusModeTasks: focusModeTasks,
            focusModeCompleted: focusModeCompleted,
            averageStreakWhenCompleted: averageStreakWhenCompleted,
            urgentTaskCompletionRate: urgentTaskCompletionRate,
            weekendCompletionRate: weekendCompletionRate,
            weekdayCompletionRate: weekdayCompletionRate
        )
    }
    
    // MARK: - Individual Insight Analyzers
    
    private func analyzeProductivityPattern(metrics: ProductivityMetrics) -> PatternInsight? {
        guard metrics.completedTasks >= 5 else { return nil }
        
        // Find best day
        let bestDay = metrics.tasksByDayOfWeek.max { $0.value < $1.value }
        guard let (day, count) = bestDay else { return nil }
        
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let dayName = dayNames[day]
        
        // Calculate if it's significantly better (>30% more than average)
        let averagePerDay = Double(metrics.completedTasks) / 7.0
        let isSignificant = Double(count) > averagePerDay * 1.3
        
        let confidence = min(0.9, Double(metrics.completedTasks) / 50.0 + (isSignificant ? 0.2 : 0))
        
        let trend: PatternInsight.TrendDirection = metrics.completionRate > 0.7 ? .up : (metrics.completionRate < 0.4 ? .down : .stable)
        
        return PatternInsight(
            type: .productivityPattern,
            title: "Your Peak Day is \(dayName)",
            description: "You complete most tasks on \(dayName)s. Use this day for your most important work.",
            detail: "You've completed \(count) tasks on \(dayName)s in the last 90 days.",
            confidence: confidence,
            metric: "\(count) tasks",
            trend: trend,
            recommendation: "Schedule challenging tasks for \(dayName)s when you're most productive.",
            generatedAt: Date()
        )
    }
    
    private func analyzeBestTimeOfDay(metrics: ProductivityMetrics) -> PatternInsight? {
        guard metrics.completedTasks >= 5 else { return nil }
        
        // Group hours into time periods
        let morning = (6...11).compactMap { metrics.tasksByHour[$0] }.reduce(0, +)
        let afternoon = (12...17).compactMap { metrics.tasksByHour[$0] }.reduce(0, +)
        let evening = (18...21).compactMap { metrics.tasksByHour[$0] }.reduce(0, +)
        let night = Array(22...23) + Array(0...5)
        let nightCount = night.compactMap { metrics.tasksByHour[$0] }.reduce(0, +)
        
        let periods = [
            ("Morning (6AM-12PM)", morning),
            ("Afternoon (12PM-6PM)", afternoon),
            ("Evening (6PM-10PM)", evening),
            ("Night (10PM-6AM)", nightCount)
        ]
        
        let bestPeriod = periods.max { $0.1 < $1.1 }
        guard let (periodName, count) = bestPeriod, count > 0 else { return nil }
        
        let confidence = min(0.85, Double(metrics.completedTasks) / 60.0)
        
        // Determine if user is early bird or night owl
        var archetype = ""
        if morning > afternoon && morning > evening {
            archetype = "Early Bird"
        } else if nightCount > morning && nightCount > afternoon {
            archetype = "Night Owl"
        } else if afternoon > morning && afternoon > evening {
            archetype = "Afternoon Achiever"
        }
        
        return PatternInsight(
            type: .timeOfDay,
            title: archetype.isEmpty ? "Best Time: \(periodName)" : "You're a \(archetype)!",
            description: "You complete \(count) tasks during \(periodName.lowercased()).",
            detail: "Your brain is most active during \(periodName.lowercased()).",
            confidence: confidence,
            metric: "\(count) tasks",
            trend: nil,
            recommendation: "Use \(periodName.lowercased()) for your hardest tasks.",
            generatedAt: Date()
        )
    }
    
    private func analyzeCategoryTrends(metrics: ProductivityMetrics) -> PatternInsight? {
        guard metrics.completedTasks >= 5 else { return nil }
        
        let bestCategory = metrics.tasksByCategory.max { $0.value < $1.value }
        guard let (categoryRaw, count) = bestCategory else { return nil }
        
        // Map raw category to display name
        let categoryDisplayNames: [String: String] = [
            "clean": "Cleaning",
            "fix": "Fixing",
            "buy": "Shopping",
            "organize": "Organizing",
            "health": "Health",
            "work": "Work",
            "other": "Other"
        ]
        
        let categoryName = categoryDisplayNames[categoryRaw] ?? categoryRaw.capitalized
        
        let confidence = min(0.8, Double(metrics.completedTasks) / 40.0)
        
        return PatternInsight(
            type: .categoryTrend,
            title: "\(categoryName) Champion",
            description: "You excel at \(categoryName.lowercased()) tasks! This is your strength zone.",
            detail: "You've completed \(count) \(categoryName.lowercased()) tasks.",
            confidence: confidence,
            metric: "\(count) tasks",
            trend: .up,
            recommendation: "Leverage this strength when planning your week.",
            generatedAt: Date()
        )
    }
    
    private func analyzeFocusModeImpact(metrics: ProductivityMetrics) -> PatternInsight? {
        guard metrics.focusModeTasks >= 3 else { return nil }
        
        let focusRate = Double(metrics.focusModeCompleted) / Double(metrics.focusModeTasks)
        let regularRate = metrics.completionRate
        
        let improvement = ((focusRate - regularRate) / regularRate) * 100
        let isBetter = improvement > 0
        
        let confidence = min(0.9, Double(metrics.focusModeTasks) / 20.0)
        
        let title = isBetter ? "Focus Mode Boosts You!" : "Focus Mode Needs Practice"
        let description = isBetter 
            ? "You're \(Int(improvement))% more likely to complete tasks using Focus Mode."
            : "Your completion rate is similar with or without Focus Mode. Try longer sessions."
        
        return PatternInsight(
            type: .focusModeImpact,
            title: title,
            description: description,
            detail: "Focus Mode completion rate: \(Int(focusRate * 100))%",
            confidence: confidence,
            metric: "\(Int(focusRate * 100))% success",
            trend: isBetter ? .up : .stable,
            recommendation: isBetter ? "Use Focus Mode for important tasks!" : "Try 25-minute Pomodoro sessions.",
            generatedAt: Date()
        )
    }
    
    private func analyzeStreakCorrelation(metrics: ProductivityMetrics) -> PatternInsight? {
        let currentStreak = StreakManager.shared.currentStreak
        guard currentStreak >= 3 || metrics.completedTasks >= 10 else { return nil }
        
        // Simplified analysis - in real implementation would correlate streak with completion rate
        let confidence = min(0.85, Double(currentStreak) / 14.0)
        
        var title = ""
        var description = ""
        var trend: PatternInsight.TrendDirection = .stable
        
        if currentStreak >= 7 {
            title = "🔥 Momentum Master"
            description = "Your \(currentStreak)-day streak is powering you forward! Streaks build habits."
            trend = .up
        } else if currentStreak >= 3 {
            title = "Building Momentum"
            description = "You're on a \(currentStreak)-day streak. Keep it going!"
            trend = .up
        } else {
            title = "Start Your Streak"
            description = "Complete a task today to start building momentum!"
            trend = .down
        }
        
        return PatternInsight(
            type: .streakCorrelation,
            title: title,
            description: description,
            detail: "Current streak: \(currentStreak) days",
            confidence: confidence,
            metric: "\(currentStreak) days",
            trend: trend,
            recommendation: "Don't break the chain! Complete one task today.",
            generatedAt: Date()
        )
    }
    
    private func analyzeCompletionSpeed(metrics: ProductivityMetrics) -> PatternInsight? {
        guard let avgTime = metrics.averageCompletionTime, metrics.completedTasks >= 5 else { return nil }
        
        let hours = Int(avgTime) / 3600
        let minutes = (Int(avgTime) % 3600) / 60
        
        let timeString = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        
        var speedCategory = ""
        if avgTime < 3600 { // Less than 1 hour
            speedCategory = "Lightning Fast"
        } else if avgTime < 24 * 3600 { // Less than 1 day
            speedCategory = "Same-Day Finisher"
        } else if avgTime < 3 * 24 * 3600 { // Less than 3 days
            speedCategory = "Steady Progress"
        } else {
            speedCategory = "Deep Thinker"
        }
        
        let confidence = min(0.8, Double(metrics.completedTasks) / 30.0)
        
        return PatternInsight(
            type: .completionSpeed,
            title: "\(speedCategory)",
            description: "You typically complete tasks in \(timeString).",
            detail: "Average from \(metrics.completedTasks) completed tasks.",
            confidence: confidence,
            metric: timeString,
            trend: nil,
            recommendation: avgTime > 24 * 3600 ? "Try breaking large tasks into smaller chunks." : nil,
            generatedAt: Date()
        )
    }
    
    private func analyzeUrgentTaskPattern(metrics: ProductivityMetrics) -> PatternInsight? {
        // Need some urgent tasks to analyze
        guard metrics.urgentTaskCompletionRate > 0 else { return nil }
        
        let rate = metrics.urgentTaskCompletionRate
        let confidence = 0.75
        
        var title = ""
        var description = ""
        var trend: PatternInsight.TrendDirection = .stable
        
        if rate >= 0.9 {
            title = "Urgency Handler Pro"
            description = "You crush urgent tasks with a \(Int(rate * 100))% completion rate!"
            trend = .up
        } else if rate >= 0.7 {
            title = "Good Under Pressure"
            description = "You handle \(Int(rate * 100))% of urgent tasks well."
            trend = .stable
        } else {
            title = "Urgent Tasks Need Attention"
            description = "Only \(Int(rate * 100))% of urgent tasks get completed. Try marking fewer as urgent."
            trend = .down
        }
        
        return PatternInsight(
            type: .urgentTaskPattern,
            title: title,
            description: description,
            detail: "\(Int(rate * 100))% completion rate for urgent tasks",
            confidence: confidence,
            metric: "\(Int(rate * 100))%",
            trend: trend,
            recommendation: rate < 0.7 ? "Consider if all marked-urgent tasks truly are urgent." : "Keep up the great prioritization!",
            generatedAt: Date()
        )
    }
    
    private func analyzeWeekendVsWeekday(metrics: ProductivityMetrics) -> PatternInsight? {
        guard metrics.completedTasks >= 10 else { return nil }
        
        let weekendRate = metrics.weekendCompletionRate
        let weekdayRate = metrics.weekdayCompletionRate
        
        let ratio = weekendRate > 0 ? weekdayRate / weekendRate : 1
        
        let confidence = min(0.8, Double(metrics.completedTasks) / 40.0)
        
        var title = ""
        var description = ""
        
        if ratio > 1.5 {
            title = "Weekday Warrior"
            description = "You're \(Int((ratio - 1) * 100))% more productive on weekdays."
        } else if ratio < 0.7 {
            title = "Weekend Achiever"
            description = "You shine on weekends! Consider protecting weekend time for tasks."
        } else {
            title = "Consistent Every Day"
            description = "You maintain steady productivity all week long."
        }
        
        return PatternInsight(
            type: .weekendVsWeekday,
            title: title,
            description: description,
            detail: "Weekday: \(Int(weekdayRate * 100))% vs Weekend: \(Int(weekendRate * 100))%",
            confidence: confidence,
            metric: nil,
            trend: nil,
            recommendation: ratio > 1.5 ? "Use weekdays for big tasks, weekends for rest." : nil,
            generatedAt: Date()
        )
    }
    
    // MARK: - Caching
    
    private func cacheInsights() {
        if let encoded = try? JSONEncoder().encode(insights) {
            UserDefaults.standard.set(encoded, forKey: "tasksnap.pattern_insights")
            UserDefaults.standard.set(Date(), forKey: "tasksnap.pattern_insights_date")
        }
    }
    
    private func loadCachedInsights() {
        guard let data = UserDefaults.standard.data(forKey: "tasksnap.pattern_insights"),
              let decoded = try? JSONDecoder().decode([PatternInsight].self, from: data) else {
            return
        }
        
        insights = decoded
        lastAnalysisDate = UserDefaults.standard.object(forKey: "tasksnap.pattern_insights_date") as? Date
    }
}

// MARK: - PatternInsight Codable Extension
extension PatternInsight: Codable {
    enum CodingKeys: String, CodingKey {
        case id, type, title, description, detail, confidence, metric, trend, recommendation, generatedAt
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(detail, forKey: .detail)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(metric, forKey: .metric)
        try container.encode(trend?.rawValue, forKey: .trend)
        try container.encode(recommendation, forKey: .recommendation)
        try container.encode(generatedAt, forKey: .generatedAt)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let typeRaw = try container.decode(String.self, forKey: .type)
        type = InsightType(rawValue: typeRaw)!
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        detail = try container.decode(String.self, forKey: .detail)
        confidence = try container.decode(Double.self, forKey: .confidence)
        metric = try container.decodeIfPresent(String.self, forKey: .metric)
        if let trendRaw = try container.decodeIfPresent(String.self, forKey: .trend) {
            trend = TrendDirection(rawValue: trendRaw)
        } else {
            trend = nil
        }
        recommendation = try container.decodeIfPresent(String.self, forKey: .recommendation)
        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
    }
}

extension PatternInsight.TrendDirection: RawRepresentable {
    var rawValue: String {
        switch self {
        case .up: return "up"
        case .down: return "down"
        case .stable: return "stable"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "up": self = .up
        case "down": self = .down
        case "stable": self = .stable
        default: return nil
        }
    }
}
