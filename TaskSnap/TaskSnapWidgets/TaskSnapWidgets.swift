import WidgetKit
import SwiftUI
import Intents

struct TaskSnapWidgetEntry: TimelineEntry {
    let date: Date
    let tasksCount: Int
    let streakCount: Int
}

struct TaskSnapWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaskSnapWidgetEntry {
        TaskSnapWidgetEntry(date: Date(), tasksCount: 3, streakCount: 5)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TaskSnapWidgetEntry) -> Void) {
        let entry = TaskSnapWidgetEntry(date: Date(), tasksCount: 3, streakCount: 5)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskSnapWidgetEntry>) -> Void) {
        // Get actual data from shared UserDefaults or Core Data
        let tasksCount = UserDefaults.standard.integer(forKey: "widgetTasksCount")
        let streakCount = StreakManager.shared.currentStreak
        
        let entry = TaskSnapWidgetEntry(
            date: Date(),
            tasksCount: tasksCount,
            streakCount: streakCount
        )
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Small Widget
struct TaskSnapSmallWidgetView: View {
    let entry: TaskSnapWidgetEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            VStack(spacing: 12) {
                // Streak
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    Text("\(entry.streakCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
                
                // Tasks
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("\(entry.tasksCount) today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Medium Widget
struct TaskSnapMediumWidgetView: View {
    let entry: TaskSnapWidgetEntry
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color(.systemBackground))
            
            HStack(spacing: 20) {
                // Left side - Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("TaskSnap")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(entry.streakCount) day streak")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(entry.tasksCount) tasks today")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Right side - Quick Capture Button
                Link(destination: URL(string: "tasksnap://capture")!) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("Capture")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.accentColor)
                    .cornerRadius(16)
                }
            }
            .padding()
        }
    }
}

// MARK: - Lock Screen Widget
struct TaskSnapLockScreenWidgetView: View {
    let entry: TaskSnapWidgetEntry
    @Environment(\.widgetFamily) var family
    
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

// MARK: - Widget Configuration
@main
struct TaskSnapWidgets: WidgetBundle {
    var body: some Widget {
        TaskSnapHomeScreenWidget()
        TaskSnapLockScreenWidget()
    }
}

struct TaskSnapHomeScreenWidget: Widget {
    let kind: String = "TaskSnapHomeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskSnapWidgetProvider()) { entry in
            TaskSnapHomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TaskSnap")
        .description("View your streak and tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
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
        default:
            TaskSnapSmallWidgetView(entry: entry)
        }
    }
}

struct TaskSnapLockScreenWidget: Widget {
    let kind: String = "TaskSnapLockWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskSnapWidgetProvider()) { entry in
            TaskSnapLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("TaskSnap Streak")
        .description("View your current streak on the lock screen.")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

#Preview(as: .systemSmall) {
    TaskSnapHomeScreenWidget()
} timeline: {
    TaskSnapWidgetEntry(date: .now, tasksCount: 3, streakCount: 5)
}
