import SwiftUI

struct DashboardView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var gamificationViewModel: GamificationViewModel
    let onCaptureTap: () -> Void
    
    @State private var selectedTask: TaskEntity?
    @State private var showingTaskDetail = false
    @State private var showingVictoryView = false
    @State private var completedTask: TaskEntity?
    
    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with streak and capture button
                    headerSection
                    
                    // Kanban Board
                    kanbanBoard
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("TaskSnap")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(
                task: task,
                taskViewModel: taskViewModel,
                onComplete: { completedTask in
                    self.completedTask = completedTask
                    showingVictoryView = true
                }
            )
        }
        .sheet(isPresented: $showingVictoryView) {
            if let task = completedTask {
                VictoryView(task: task) {
                    showingVictoryView = false
                    completedTask = nil
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Streak and Progress Card
            HStack(spacing: 16) {
                // Streak indicator
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: gamificationViewModel.plantSystemImage)
                            .font(.title2)
                            .foregroundColor(Color(gamificationViewModel.plantColor))
                        Text("\(gamificationViewModel.streakManager.currentStreak)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                    Text("day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Today's progress
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(gamificationViewModel.todayTasks.count)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                    Text("done today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            // Capture Button
            Button(action: onCaptureTap) {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    Text("Capture a Task")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal)
    }
    
    // MARK: - Kanban Board
    private var kanbanBoard: some View {
        VStack(spacing: 20) {
            // To Do Column
            taskColumn(
                title: "To Do",
                color: .todoColor,
                count: taskViewModel.todoTasks.count,
                tasks: taskViewModel.todoTasks
            )
            
            // Doing Column
            taskColumn(
                title: "Doing",
                color: .doingColor,
                count: taskViewModel.doingTasks.count,
                tasks: taskViewModel.doingTasks
            )
            
            // Done Column
            taskColumn(
                title: "Done",
                color: .doneColor,
                count: taskViewModel.doneTasks.count,
                tasks: taskViewModel.doneTasks.prefix(6).map { $0 } // Show recent 6
            )
        }
        .padding(.horizontal)
    }
    
    private func taskColumn(title: String, color: Color, count: Int, tasks: [TaskEntity]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column Header
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
            }
            
            if tasks.isEmpty {
                // Empty state
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 30)
                    Spacer()
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                // Task Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(tasks) { task in
                        TaskCard(task: task)
                            .onTapGesture {
                                selectedTask = task
                            }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Task Card
struct TaskCard: View {
    let task: TaskEntity
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image or Placeholder
            ZStack {
                if let image = task.beforeImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(task.taskCategory.color).opacity(0.2))
                        .frame(height: 100)
                    
                    Image(systemName: task.taskCategory.icon)
                        .font(.system(size: 32))
                        .foregroundColor(Color(task.taskCategory.color))
                }
                
                // Urgency Glow Overlay
                if task.urgencyLevel.shouldGlow {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(task.urgencyLevel.color), lineWidth: 2)
                        .shadow(color: Color(task.urgencyLevel.color), radius: 4)
                }
                
                // Urgent Badge
                if task.isUrgent {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.urgencyHigh)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }
            
            // Title
            Text(task.title ?? "Untitled")
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            // Due date if exists
            if let dueDate = task.dueDate {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(dueDate.formattedString(style: .short))
                        .font(.caption2)
                }
                .foregroundColor(task.isOverdue ? .urgencyHigh : .secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.gentleSpring(), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
            if pressing {
                Haptics.shared.light()
            }
        }, perform: {})
        .withUrgencyGlow(task.urgencyLevel)
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.gentleSpring(), value: configuration.isPressed)
    }
}

// MARK: - Urgency Glow Modifier
extension View {
    func withUrgencyGlow(_ level: UrgencyLevel) -> some View {
        self.modifier(UrgencyGlowModifier(level: level))
    }
}

struct UrgencyGlowModifier: ViewModifier {
    let level: UrgencyLevel
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(level.color), lineWidth: level.shouldGlow ? 2 : 0)
                    .shadow(color: Color(level.color).opacity(level.shouldGlow ? 0.6 : 0), radius: level.shouldGlow ? (isAnimating ? 8 : 4) : 0)
                    .opacity(level.shouldGlow ? 1 : 0)
                    .animation(
                        level.shouldGlow ?
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true) :
                        .default,
                        value: isAnimating
                    )
            )
            .onAppear {
                if level.shouldGlow {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    DashboardView(
        taskViewModel: TaskViewModel(context: PersistenceController.preview.container.viewContext),
        gamificationViewModel: GamificationViewModel(),
        onCaptureTap: {}
    )
}
