import WidgetKit
import SwiftUI
import Intents
import CoreData

// MARK: - Timeline Entry
struct TaskSnapWidgetEntry: TimelineEntry {
    let date: Date
    let tasksCount: Int
    let streakCount: Int
    let urgentTasks: Int
}

// MARK: - Timeline Provider
struct TaskSnapWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskSnapWidgetEntry {
        TaskSnapWidgetEntry(date: Date(), tasksCount: 3, streakCount: 5, urgentTasks: 1)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TaskSnapWidgetEntry) -> Void) {
        let entry = fetchWidgetData()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskSnapWidgetEntry>) -> Void) {
        let entry = fetchWidgetData()
        
        // Update every 15 minutes
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    private func fetchWidgetData() -> TaskSnapWidgetEntry {
        // Try to fetch from Core Data via shared container
        // For now, use UserDefaults as fallback
        let sharedDefaults = UserDefaults(suiteName: "group.com.warnergears.TaskSnap")
        let tasksCount = sharedDefaults?.integer(forKey: "widgetTasksCount") ?? 0
        let streakCount = sharedDefaults?.integer(forKey: "widgetStreakCount") ?? 0
        let urgentTasks = sharedDefaults?.integer(forKey: "widgetUrgentTasks") ?? 0
        
        return TaskSnapWidgetEntry(
            date: Date(),
            tasksCount: tasksCount,
            streakCount: streakCount,
            urgentTasks: urgentTasks
        )
    }
}

// MARK: - Small Widget (Streak Focus)
struct TaskSnapSmallWidgetView: View {
    let entry: TaskSnapWidgetEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            VStack(spacing: 8) {
                // Streak with flame
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text("\(entry.streakCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("day streak")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .padding(.horizontal, 8)
                
                // Tasks count
                HStack(spacing: 4) {
                    Image(systemName: entry.urgentTasks > 0 ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(entry.urgentTasks > 0 ? .red : .green)
                    Text("\(entry.tasksCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding()
        }
    }
}

// MARK: - Medium Widget (Quick Capture)
struct TaskSnapMediumWidgetView: View {
    let entry: TaskSnapWidgetEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            HStack(spacing: 16) {
                // Left side - Stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                        Text("TaskSnap")
                            .font(.headline)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(entry.streakCount) day streak")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(entry.urgentTasks > 0 ? .red : .green)
                        Text(entry.urgentTasks > 0 ? "\(entry.urgentTasks) urgent" : "\(entry.tasksCount) tasks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Right side - Quick Capture Button
                Link(destination: URL(string: "tasksnap://capture")!) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        Text("Capture")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Large Widget (Task List Preview)
struct TaskSnapLargeWidgetView: View {
    let entry: TaskSnapWidgetEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "camera.viewfinder")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    Text("TaskSnap")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Streak badge
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(entry.streakCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(12)
                }
                
                Divider()
                
                // Quick stats
                HStack(spacing: 16) {
                    StatBadge(icon: "circle", count: entry.tasksCount, label: "To Do", color: .blue)
                    StatBadge(icon: "exclamationmark.circle", count: entry.urgentTasks, label: "Urgent", color: .red)
                }
                
                Spacer()
                
                // Quick capture button
                Link(destination: URL(string: "tasksnap://capture")!) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Capture New Task")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}

struct StatBadge: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(count)")
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Lock Screen Widgets
struct TaskSnapLockScreenCircularWidgetView: View {
    let entry: TaskSnapWidgetEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 2) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("\(entry.streakCount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }
}

struct TaskSnapLockScreenInlineWidgetView: View {
    let entry: TaskSnapWidgetEntry
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            Text("\(entry.streakCount) day streak")
        }
    }
}

struct TaskSnapLockScreenRectangularWidgetView: View {
    let entry: TaskSnapWidgetEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(entry.streakCount)")
                    .fontWeight(.bold)
            }
            
            Divider()
            
            // Tasks
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle")
                Text("\(entry.tasksCount)")
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            // Camera icon
            Image(systemName: "camera.fill")
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Widget Bundle
@main
struct TaskSnapWidgets: WidgetBundle {
    var body: some Widget {
        TaskSnapHomeScreenWidget()
        TaskSnapLockScreenWidget()
    }
}

// MARK: - Home Screen Widget
struct TaskSnapHomeScreenWidget: Widget {
    let kind: String = "TaskSnapHomeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskSnapWidgetProvider()) { entry in
            TaskSnapHomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TaskSnap")
        .description("View your streak and quick capture tasks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TaskSnapHomeWidgetEntryView: View {
    let entry: TaskSnapWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            TaskSnapSmallWidgetView(entry: entry)
        case .systemMedium:
            TaskSnapMediumWidgetView(entry: entry)
        case .systemLarge:
            TaskSnapLargeWidgetView(entry: entry)
        default:
            TaskSnapSmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Lock Screen Widget
struct TaskSnapLockScreenWidget: Widget {
    let kind: String = "TaskSnapLockWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskSnapWidgetProvider()) { entry in
            TaskSnapLockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TaskSnap Streak")
        .description("Track your daily streak on the lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

struct TaskSnapLockScreenWidgetEntryView: View {
    let entry: TaskSnapWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            TaskSnapLockScreenCircularWidgetView(entry: entry)
        case .accessoryInline:
            TaskSnapLockScreenInlineWidgetView(entry: entry)
        case .accessoryRectangular:
            TaskSnapLockScreenRectangularWidgetView(entry: entry)
        default:
            TaskSnapLockScreenCircularWidgetView(entry: entry)
        }
    }
}

// MARK: - Previews (iOS 17+)
@available(iOS 17.0, *)
#Preview(as: .systemSmall) {
    TaskSnapHomeScreenWidget()
} timeline: {
    TaskSnapWidgetEntry(date: .now, tasksCount: 3, streakCount: 5, urgentTasks: 1)
}

@available(iOS 17.0, *)
#Preview(as: .systemMedium) {
    TaskSnapHomeScreenWidget()
} timeline: {
    TaskSnapWidgetEntry(date: .now, tasksCount: 3, streakCount: 5, urgentTasks: 1)
}

@available(iOS 17.0, *)
#Preview(as: .accessoryCircular) {
    TaskSnapLockScreenWidget()
} timeline: {
    TaskSnapWidgetEntry(date: .now, tasksCount: 3, streakCount: 5, urgentTasks: 1)
}
