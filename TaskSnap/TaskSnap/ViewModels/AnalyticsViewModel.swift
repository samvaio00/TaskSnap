import Foundation
import CoreData
import SwiftUI

// MARK: - Analytics ViewModel
class AnalyticsViewModel: ObservableObject {
    @Published var completionByDayOfWeek: [DayOfWeekData] = []
    @Published var completionByHour: [HourData] = []
    @Published var completionByCategory: [CategoryData] = []
    @Published var weeklyTrend: [WeeklyData] = []
    @Published var totalStats: TaskStats = TaskStats()
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadAnalytics()
    }
    
    func loadAnalytics() {
        loadCompletionByDayOfWeek()
        loadCompletionByHour()
        loadCompletionByCategory()
        loadWeeklyTrend()
        loadTotalStats()
    }
    
    // MARK: - Completion by Day of Week
    private func loadCompletionByDayOfWeek() {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == 'done' AND completedAt != nil")
        
        do {
            let tasks = try context.fetch(request)
            var dayCounts: [Int: Int] = [:]
            
            for task in tasks {
                guard let completedAt = task.completedAt else { continue }
                let weekday = Calendar.current.component(.weekday, from: completedAt)
                dayCounts[weekday, default: 0] += 1
            }
            
            let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            completionByDayOfWeek = (1...7).map { day in
                DayOfWeekData(
                    day: dayNames[day - 1],
                    count: dayCounts[day] ?? 0
                )
            }
        } catch {
            print("Error loading day of week data: \(error)")
        }
    }
    
    // MARK: - Completion by Hour
    private func loadCompletionByHour() {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == 'done' AND completedAt != nil")
        
        do {
            let tasks = try context.fetch(request)
            var hourCounts: [Int: Int] = [:]
            
            for task in tasks {
                guard let completedAt = task.completedAt else { continue }
                let hour = Calendar.current.component(.hour, from: completedAt)
                hourCounts[hour, default: 0] += 1
            }
            
            // Group into time periods
            let timePeriods = [
                ("Morning", 6..<12),
                ("Afternoon", 12..<18),
                ("Evening", 18..<22),
                ("Night", 22..<24),
                ("Late Night", 0..<6)
            ]
            
            completionByHour = timePeriods.map { name, range in
                let count = range.reduce(0) { $0 + (hourCounts[$1] ?? 0) }
                return HourData(period: name, count: count)
            }
        } catch {
            print("Error loading hour data: \(error)")
        }
    }
    
    // MARK: - Completion by Category
    private func loadCompletionByCategory() {
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        request.predicate = NSPredicate(format: "status == 'done'")
        
        do {
            let tasks = try context.fetch(request)
            var categoryCounts: [String: Int] = [:]
            
            for task in tasks {
                let category = task.category ?? "other"
                categoryCounts[category, default: 0] += 1
            }
            
            completionByCategory = categoryCounts.map { key, count in
                CategoryData(
                    category: TaskCategory(rawValue: key)?.displayName ?? key.capitalized,
                    count: count,
                    color: TaskCategory(rawValue: key)?.color ?? "categoryOther"
                )
            }.sorted { $0.count > $1.count }
        } catch {
            print("Error loading category data: \(error)")
        }
    }
    
    // MARK: - Weekly Trend (Last 4 Weeks)
    private func loadWeeklyTrend() {
        let calendar = Calendar.current
        let now = Date()
        
        var weeklyData: [WeeklyData] = []
        
        for weekOffset in (0..<4).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                  let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) else {
                continue
            }
            
            let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "status == 'done' AND completedAt >= %@ AND completedAt < %@",
                weekStart as NSDate,
                weekEnd as NSDate
            )
            
            do {
                let count = try context.count(for: request)
                let weekLabel = weekOffset == 0 ? "This Week" : "\(weekOffset)w ago"
                weeklyData.append(WeeklyData(week: weekLabel, count: count))
            } catch {
                print("Error loading weekly trend: \(error)")
            }
        }
        
        weeklyTrend = weeklyData
    }
    
    // MARK: - Total Stats
    private func loadTotalStats() {
        let totalRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        let completedRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        completedRequest.predicate = NSPredicate(format: "status == 'done'")
        
        do {
            let total = try context.count(for: totalRequest)
            let completed = try context.count(for: completedRequest)
            
            // Calculate completion rate for last 30 days
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let recentRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            recentRequest.predicate = NSPredicate(format: "createdAt >= %@", thirtyDaysAgo as NSDate)
            
            let recentTotal = try context.count(for: recentRequest)
            
            let recentCompletedRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            recentCompletedRequest.predicate = NSPredicate(
                format: "status == 'done' AND completedAt >= %@",
                thirtyDaysAgo as NSDate
            )
            let recentCompleted = try context.count(for: recentCompletedRequest)
            
            let completionRate = recentTotal > 0 ? Double(recentCompleted) / Double(recentTotal) : 0
            
            totalStats = TaskStats(
                totalTasks: total,
                completedTasks: completed,
                completionRate: completionRate,
                currentStreak: StreakManager.shared.currentStreak,
                longestStreak: StreakManager.shared.longestStreak
            )
        } catch {
            print("Error loading total stats: \(error)")
        }
    }
}

// MARK: - Data Models
struct DayOfWeekData: Identifiable {
    let id = UUID()
    let day: String
    let count: Int
}

struct HourData: Identifiable {
    let id = UUID()
    let period: String
    let count: Int
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
    let color: String
}

struct WeeklyData: Identifiable {
    let id = UUID()
    let week: String
    let count: Int
}

struct TaskStats {
    let totalTasks: Int
    let completedTasks: Int
    let completionRate: Double
    let currentStreak: Int
    let longestStreak: Int
    
    init(totalTasks: Int = 0, completedTasks: Int = 0, completionRate: Double = 0, currentStreak: Int = 0, longestStreak: Int = 0) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.completionRate = completionRate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
    }
    
    var completionPercentage: Int {
        Int(completionRate * 100)
    }
}
