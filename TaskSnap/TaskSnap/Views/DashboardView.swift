import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var gamificationViewModel: GamificationViewModel
    let onCaptureTap: () -> Void
    
    @State private var selectedTask: TaskEntity?
    @State private var showingTaskDetail = false
    @State private var showingVictoryView = false
    @State private var completedTask: TaskEntity?
    @State private var showingLimitAlert = false
    
    // Drag and drop state
    @State private var draggedTask: TaskEntity?
    @State private var dragOverColumn: TaskStatus?
    
    private var activeTaskCount: Int {
        taskViewModel.todoTasks.count + taskViewModel.doingTasks.count
    }
    
    private var canCreateTask: Bool {
        TaskLimitManager.shared.canCreateTask(currentTaskCount: activeTaskCount)
    }
    
    private var remainingTasks: Int {
        TaskLimitManager.shared.remainingTasks(currentTaskCount: activeTaskCount)
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with streak and capture button
                    headerSection
                    
                    // Kanban Board with Drag & Drop
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
        .alert("Task Limit Reached", isPresented: $showingLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've reached the free tier limit of \(TaskLimitManager.shared.freeTierLimit) active tasks. Complete some tasks or upgrade to Pro for unlimited tasks.")
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
            
            // Task Limit Warning
            if !canCreateTask {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Task limit reached (\(TaskLimitManager.shared.freeTierLimit) active tasks)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            } else if remainingTasks <= 3 {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("\(remainingTasks) task slots remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Capture Button
            Button {
                if canCreateTask {
                    onCaptureTap()
                } else {
                    showingLimitAlert = true
                }
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                    Text(canCreateTask ? "Capture a Task" : "Limit Reached")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: canCreateTask ? 
                            [.accentColor, .accentColor.opacity(0.8)] :
                            [.gray, .gray.opacity(0.8)],
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
            draggableTaskColumn(
                title: "To Do",
                status: .todo,
                color: Color("todoColor"),
                count: taskViewModel.todoTasks.count,
                tasks: taskViewModel.todoTasks
            )
            
            // Doing Column
            draggableTaskColumn(
                title: "Doing",
                status: .doing,
                color: Color("doingColor"),
                count: taskViewModel.doingTasks.count,
                tasks: taskViewModel.doingTasks
            )
            
            // Done Column
            draggableTaskColumn(
                title: "Done",
                status: .done,
                color: Color("doneColor"),
                count: taskViewModel.doneTasks.count,
                tasks: taskViewModel.doneTasks.prefix(6).map { $0 }
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Draggable Task Column
    private func draggableTaskColumn(
        title: String,
        status: TaskStatus,
        color: Color,
        count: Int,
        tasks: [TaskEntity]
    ) -> some View {
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
            
            // Drop Zone
            ZStack {
                // Background that changes when dragging over
                RoundedRectangle(cornerRadius: 12)
                    .fill(dragOverColumn == status ? color.opacity(0.15) : Color(.tertiarySystemBackground))
                    .animation(.easeInOut(duration: 0.2), value: dragOverColumn)
                
                VStack {
                    if tasks.isEmpty && dragOverColumn != status {
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
                                Text("Drag tasks here")
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            .padding(.vertical, 30)
                            Spacer()
                        }
                    } else {
                        // Task Grid
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(tasks) { task in
                                if status == .done {
                                    // Done tasks show after image capture if needed
                                    DoneTaskCard(
                                        task: task,
                                        onTap: { selectedTask = task },
                                        onAddAfterImage: { selectedTask = task }
                                    )
                                } else {
                                    DraggableTaskCard(
                                        task: task,
                                        onTap: { selectedTask = task }
                                    )
                                }
                            }
                            
                            // Drop placeholder
                            if dragOverColumn == status {
                                DropPlaceholder(color: color)
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .frame(minHeight: 100)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .dropDestination(
            for: TaskDraggable.self,
            action: { items, location in
                guard let taskID = items.first?.id,
                      let task = taskViewModel.tasks.first(where: { $0.id?.uuidString == taskID }) else {
                    return false
                }
                
                // Update task status
                withAnimation(.spring()) {
                    taskViewModel.updateTaskStatus(task, to: status)
                    Haptics.shared.success()
                }
                
                // If moved to done, show victory
                if status == .done && task.taskStatus != .done {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        completedTask = task
                        showingVictoryView = true
                    }
                }
                
                return true
            },
            isTargeted: { isTargeted in
                dragOverColumn = isTargeted ? status : nil
            }
        )
    }
}

// MARK: - Draggable Task Card
struct DraggableTaskCard: View {
    let task: TaskEntity
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        TaskCardContent(task: task, isPressed: isPressed)
            .draggable(
                TaskDraggable(id: task.id?.uuidString ?? "", title: task.title ?? "")
            ) {
                // Preview while dragging
                TaskCardContent(task: task, isPressed: true)
                    .frame(width: 140)
                    .opacity(0.8)
            }
            .onTapGesture {
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
                isPressed = pressing
                if pressing {
                    Haptics.shared.light()
                }
            }, perform: {})
    }
}

// MARK: - Task Card Content
struct TaskCardContent: View {
    let task: TaskEntity
    let isPressed: Bool
    
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
                                .foregroundColor(Color("urgencyHigh"))
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
                .foregroundColor(task.isOverdue ? Color("urgencyHigh") : .secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.gentleSpring(), value: isPressed)
        .withUrgencyGlow(task.urgencyLevel)
    }
}

// MARK: - Done Task Card (with After Image support)
struct DoneTaskCard: View {
    let task: TaskEntity
    let onTap: () -> Void
    let onAddAfterImage: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image Section - Shows after image if available, before image as fallback
            ZStack {
                if let afterImage = task.afterImage {
                    // Show after image
                    Image(uiImage: afterImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // Done badge overlay
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(Color("doneColor"))
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(4)
                    
                } else if let beforeImage = task.beforeImage {
                    // Show before image with "Add After Photo" overlay
                    Image(uiImage: beforeImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .opacity(0.6)
                    
                    // Add after photo button
                    Button {
                        onAddAfterImage()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Add After Photo")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("doneColor"))
                        .cornerRadius(8)
                    }
                } else {
                    // No image at all - show category icon with add button
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(task.taskCategory.color).opacity(0.2))
                        .frame(height: 100)
                    
                    VStack(spacing: 4) {
                        Image(systemName: task.taskCategory.icon)
                            .font(.system(size: 32))
                            .foregroundColor(Color(task.taskCategory.color))
                        
                        Button {
                            onAddAfterImage()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                Text("Add Photo")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color("doneColor"))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Title
            Text(task.title ?? "Untitled")
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            // Completed date
            if let completedAt = task.completedAt {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(Color("doneColor"))
                    Text("Done \(completedAt.formattedString(style: .short))")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.gentleSpring(), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            isPressed = pressing
            if pressing {
                Haptics.shared.light()
            }
        }, perform: {})
    }
}

// MARK: - Drop Placeholder
struct DropPlaceholder: View {
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .frame(height: 140)
            .overlay(
                Image(systemName: "arrow.down.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(color)
            )
    }
}

// MARK: - Draggable Item
struct TaskDraggable: Transferable, Codable {
    let id: String
    let title: String
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .taskItem)
    }
}

// Custom UTType for task items
extension UTType {
    static var taskItem: UTType {
        UTType(exportedAs: "com.warnergears.TaskSnap.task")
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
