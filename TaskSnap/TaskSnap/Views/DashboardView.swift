import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var gamificationViewModel: GamificationViewModel
    @StateObject private var syncManager = SyncManager.shared
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    let onCaptureTap: () -> Void
    
    @State private var selectedTask: TaskEntity?
    @State private var showingTaskDetail = false
    @State private var showingVictoryView = false
    @State private var completedTask: TaskEntity?
    @State private var showingLimitAlert = false
    @State private var showingSyncError = false
    @State private var syncErrorMessage = ""
    
    // Drag and drop state
    @State private var draggedTask: TaskEntity?
    @State private var dragOverColumn: TaskStatus?
    
    // Mini celebration state
    @State private var showMiniCelebration = false
    @State private var miniCelebrationPosition: CGPoint = .zero
    
    // Toast state
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastIcon = ""
    @State private var toastColor: Color = .accentColor
    
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
            ZStack {
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
                
                // Mini celebration overlay
                if showMiniCelebration {
                    MiniConfettiBurst(position: miniCelebrationPosition)
                        .transition(.opacity)
                }
                
                // Toast overlay
                if showToast {
                    ToastView(message: toastMessage, icon: toastIcon, color: toastColor)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(100)
                }
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .openTaskDetail)) { notification in
            if let taskId = notification.userInfo?["taskId"] as? String,
               let task = taskViewModel.tasks.first(where: { $0.id?.uuidString == taskId }) {
                selectedTask = task
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitSyncCompleted)) { _ in
            // Refresh tasks when CloudKit sync completes
            taskViewModel.fetchTasks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudKitSyncFailed)) { notification in
            // Show sync error
            if let error = notification.userInfo?["error"] as? Error {
                syncErrorMessage = error.localizedDescription
                showingSyncError = true
            }
        }
        .errorBanner(
            isPresented: $showingSyncError,
            message: syncErrorMessage,
            icon: "exclamationmark.icloud",
            iconColor: .orange,
            autoDismiss: true,
            onDismiss: { showingSyncError = false },
            onAction: {
                syncManager.triggerManualSync()
                showingSyncError = false
            },
            actionTitle: "Retry"
        )
    }
    
    // MARK: - Toast Helper
    private func showToast(message: String, icon: String, color: Color) {
        toastMessage = message
        toastIcon = icon
        toastColor = color
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                showToast = false
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
                            .accessibilityHidden(true)
                        Text("\(gamificationViewModel.streakManager.currentStreak)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                    Text("day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current streak")
                .accessibilityValue("\(gamificationViewModel.streakManager.currentStreak) days")
                
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Tasks completed today")
                .accessibilityValue("\(gamificationViewModel.todayTasks.count)")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .accessibilityAddTraits(.isHeader)
            
            // Task Limit Warning
            if !canCreateTask {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)
                    Text("Task limit reached (\(TaskLimitManager.shared.freeTierLimit) active tasks)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .accessibilityLabel("Task limit reached")
                .accessibilityValue("\(TaskLimitManager.shared.freeTierLimit) active tasks maximum on free tier")
            } else if remainingTasks <= 3 {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                    Text("\(remainingTasks) task slots remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
                .accessibilityLabel("Task slots remaining")
                .accessibilityValue("\(remainingTasks) out of \(TaskLimitManager.shared.freeTierLimit)")
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
                        .accessibilityHidden(true)
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
            .accessibilityLabel(canCreateTask ? "Capture a new task" : "Task limit reached")
            .accessibilityHint(canCreateTask ? "Opens camera to capture a new task" : "Complete existing tasks or upgrade to add more")
            .accessibilityAddTraits(.isButton)
            
            // AI Task Suggestions
            TaskSuggestionsView(currentTask: nil) { suggestion in
                // Could pre-fill a new task with this suggestion
                print("Selected suggestion: \(suggestion.title)")
            }
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
    
    // MARK: - Column Empty State
    @ViewBuilder
    private func columnEmptyState(status: TaskStatus, title: String) -> some View {
        switch status {
        case .todo:
            // To Do column - encourage capturing first task
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color("todoColor").opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "camera.viewfinder")
                        .font(.title2)
                        .foregroundColor(Color("todoColor"))
                }
                
                VStack(spacing: 4) {
                    Text("Ready to start!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Capture your first task")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("No tasks in \(title). Capture your first task to get started.")
            
        case .doing:
            // Doing column - encourage dragging tasks
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color("doingColor").opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "hand.tap")
                        .font(.title2)
                        .foregroundColor(Color("doingColor"))
                }
                
                VStack(spacing: 4) {
                    Text("Start something!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Drag tasks here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("No tasks currently in progress. Drag tasks here from To Do to start working on them.")
            
        case .done:
            // Done column - celebrate empty state
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color("doneColor").opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(Color("doneColor"))
                }
                
                VStack(spacing: 4) {
                    Text("Nothing done yet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Complete tasks to see them here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("No completed tasks yet. Finish tasks to see your accomplishments here.")
        }
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
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                    .accessibleText(lineLimit: 1)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                    .accessibilityLabel("\(count) tasks in \(title)")
                    .highContrastBorder(cornerRadius: 12, lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title) column")
            .accessibilityValue("\(count) tasks")
            .accessibilityAddTraits(.isHeader)
            
            // Drop Zone
            ZStack {
                // Background that changes when dragging over
                RoundedRectangle(cornerRadius: 12)
                    .fill(dragOverColumn == status ? color.opacity(accessibilitySettings.highContrast ? 0.25 : 0.15) : Color(.tertiarySystemBackground))
                    .animation(accessibilitySettings.dragAnimation, value: dragOverColumn)
                
                VStack {
                    if tasks.isEmpty && dragOverColumn != status {
                        // Empty state - using custom view based on column
                        columnEmptyState(status: status, title: title)
                    } else {
                        // Task Grid
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                                if status == .done {
                                    // Done tasks show after image capture if needed
                                    SwipeableDoneCard(
                                        task: task,
                                        onTap: { selectedTask = task },
                                        onAddAfterImage: { selectedTask = task },
                                        onReopen: {
                                            reopenTask(task)
                                        },
                                        onDelete: {
                                            deleteTask(task)
                                        }
                                    )
                                } else {
                                    SwipeableTaskCard(
                                        task: task,
                                        onTap: { selectedTask = task },
                                        index: index,
                                        onDropInDone: { position in
                                            triggerMiniCelebration(at: position)
                                        },
                                        onComplete: {
                                            completeTask(task)
                                        },
                                        onStart: {
                                            startTask(task)
                                        },
                                        onEdit: {
                                            selectedTask = task
                                        },
                                        onDelete: {
                                            deleteTask(task)
                                        },
                                        onMoveTo: { newStatus in
                                            moveTask(task, to: newStatus)
                                        },
                                        onToggleUrgent: {
                                            toggleTaskUrgent(task)
                                        }
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
        .background(HighContrastColors.secondaryBackground)
        .cornerRadius(16)
        .if(accessibilitySettings.highContrast) { view in
            view.overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(HighContrastColors.border, lineWidth: 2)
            )
        }
        .dropDestination(
            for: TaskDraggable.self,
            action: { items, location in
                guard let taskID = items.first?.id,
                      let task = taskViewModel.tasks.first(where: { $0.id?.uuidString == taskID }) else {
                    return false
                }
                
                let wasMovedToDone = status == .done && task.taskStatus != .done
                
                // Update task status with drop animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    taskViewModel.updateTaskStatus(task, to: status)
                }
                
                // Haptic feedback on successful drop
                Haptics.shared.success()
                
                // If moved to done, trigger mini celebration
                if wasMovedToDone {
                    // Trigger mini celebration at drop location
                    let dropPosition = CGPoint(x: location.x, y: location.y)
                    triggerMiniCelebration(at: dropPosition)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        completedTask = task
                        showingVictoryView = true
                    }
                }
                
                return true
            },
            isTargeted: { isTargeted in
                withAnimation(.easeInOut(duration: 0.2)) {
                    dragOverColumn = isTargeted ? status : nil
                }
            }
        )
    }
    
    // MARK: - Task Actions
    private func completeTask(_ task: TaskEntity) {
        // Haptic feedback
        Haptics.shared.success()
        
        // Sound feedback
        SoundEffectManager.shared.play(.taskComplete)
        
        // Update status
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            taskViewModel.updateTaskStatus(task, to: .done)
        }
        
        // Show toast
        showToast(message: "Task completed!", icon: "checkmark.circle.fill", color: Color("doneColor"))
        
        // Trigger celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completedTask = task
            showingVictoryView = true
        }
    }
    
    private func startTask(_ task: TaskEntity) {
        // Haptic feedback
        Haptics.shared.medium()
        
        // Sound feedback
        SoundEffectManager.shared.play(.buttonTap)
        
        // Update status
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            taskViewModel.updateTaskStatus(task, to: .doing)
        }
        
        // Show toast
        showToast(message: "Started task", icon: "play.circle.fill", color: Color("doingColor"))
    }
    
    private func reopenTask(_ task: TaskEntity) {
        // Haptic feedback
        Haptics.shared.medium()
        
        // Sound feedback
        SoundManager.shared.play(.tap)
        
        // Update status
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            taskViewModel.updateTaskStatus(task, to: .todo)
        }
        
        // Show toast
        showToast(message: "Task reopened", icon: "arrow.uturn.backward.circle.fill", color: Color("todoColor"))
    }
    
    private func moveTask(_ task: TaskEntity, to status: TaskStatus) {
        // Haptic feedback
        Haptics.shared.light()
        
        // Sound feedback
        SoundManager.shared.play(.tap)
        
        // Update status
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            taskViewModel.updateTaskStatus(task, to: status)
        }
        
        // Show toast
        let message = status == .done ? "Task completed!" : "Moved to \(status.displayName)"
        let icon = status == .done ? "checkmark.circle.fill" : "arrow.right.circle.fill"
        let color = status == .done ? Color("doneColor") : (status == .doing ? Color("doingColor") : Color("todoColor"))
        showToast(message: message, icon: icon, color: color)
        
        // If moved to done, trigger celebration
        if status == .done {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completedTask = task
                showingVictoryView = true
            }
        }
    }
    
    private func deleteTask(_ task: TaskEntity) {
        // Haptic feedback
        Haptics.shared.notification(type: .warning)
        
        // Sound feedback
        SoundEffectManager.shared.play(.error)
        
        // Delete task
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            taskViewModel.deleteTask(task)
        }
        
        // Show toast
        showToast(message: "Task deleted", icon: "trash.circle.fill", color: .red)
    }
    
    private func toggleTaskUrgent(_ task: TaskEntity) {
        // Haptic feedback
        Haptics.shared.light()
        
        // Toggle urgent status using updateTask
        let newUrgentState = !task.isUrgent
        taskViewModel.updateTask(task, isUrgent: newUrgentState)
        
        // Show toast
        let message = newUrgentState ? "Marked as urgent" : "Removed urgent mark"
        let icon = newUrgentState ? "exclamationmark.circle.fill" : "checkmark.circle.fill"
        let color = newUrgentState ? Color("urgencyHigh") : .accentColor
        showToast(message: message, icon: icon, color: color)
    }
    
    // MARK: - Mini Celebration
    private func triggerMiniCelebration(at position: CGPoint) {
        miniCelebrationPosition = position
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showMiniCelebration = true
        }
        
        // Hide mini celebration after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showMiniCelebration = false
            }
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .padding(.top, 8)
    }
}

// MARK: - Swipeable Task Card
struct SwipeableTaskCard: View {
    let task: TaskEntity
    let onTap: () -> Void
    let index: Int
    let onDropInDone: (CGPoint) -> Void
    let onComplete: () -> Void
    let onStart: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveTo: (TaskStatus) -> Void
    let onToggleUrgent: () -> Void
    
    @State private var isPressed = false
    @State private var isDragging = false
    @State private var appeared = false
    @State private var dropScale: CGFloat = 1.0
    @State private var dragRotation: Double = 0
    @State private var showDeleteConfirmation = false
    
    @Environment(\.reducedMotion) var reducedMotion
    
    var body: some View {
        TaskCardContent(
            task: task,
            isPressed: isPressed,
            isDragging: isDragging,
            dragRotation: dragRotation
        )
        .scaleEffect(dropScale)
        .draggable(
            TaskDraggable(id: task.id?.uuidString ?? "", title: task.title ?? "")
        ) {
            // Preview while dragging
            TaskCardContent(
                task: task,
                isPressed: true,
                isDragging: true,
                dragRotation: 0
            )
            .frame(width: 140)
            .scaleEffect(1.05)
            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
            .rotationEffect(.degrees(reducedMotion ? 0 : 2))
            .opacity(0.9)
        }
        // Swipe Actions - Leading Edge (Right swipe)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            // Quick Complete
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onComplete()
                }
            } label: {
                Label("Complete", systemImage: "checkmark")
            }
            .tint(Color("doneColor"))
        }
        // Swipe Actions - Trailing Edge (Left swipe)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Start (Move to Doing)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onStart()
                }
            } label: {
                Label("Start", systemImage: "play.fill")
            }
            .tint(Color("doingColor"))
            
            // Edit
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.gray)
            
            // Delete
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            ContextMenuContent(
                task: task,
                onMoveTo: onMoveTo,
                onEdit: onEdit,
                onDelete: { showDeleteConfirmation = true },
                onToggleUrgent: onToggleUrgent
            )
        }
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
                isDragging = pressing
                
                if pressing {
                    // Add slight rotation for "picked up" feel
                    dragRotation = reducedMotion ? 0 : Double.random(in: -3...3)
                    Haptics.shared.light()
                } else {
                    // Reset rotation
                    dragRotation = 0
                }
            }
        }, perform: {})
        .accessibilityLabel(taskAccessibilityLabel)
        .accessibilityHint("Double-tap to open task details. Swipe right to complete, swipe left for more actions. Long press and drag to move to another column.")
        .accessibilityValue(taskAccessibilityValue)
        .accessibilityAddTraits(.isButton)
        // Entrance animation
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            // Staggered entrance animation
            let delay = Double(index) * 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
        .onDisappear {
            appeared = false
        }
        .alert("Delete Task?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \"\(task.title ?? "this task")\"? This action cannot be undone.")
        }
    }
    
    private var taskAccessibilityLabel: String {
        let title = task.title ?? "Untitled task"
        let status = task.taskStatus.displayName
        return "\(title), \(status)"
    }
    
    private var taskAccessibilityValue: String {
        var values: [String] = []
        
        if task.isUrgent {
            values.append("Urgent")
        }
        
        if let dueDate = task.dueDate {
            let dateString = dueDate.formattedString(style: .short)
            if task.isOverdue {
                values.append("Overdue, due \(dateString)")
            } else {
                values.append("Due \(dateString)")
            }
        }
        
        return values.isEmpty ? "No urgency set" : values.joined(separator: ". ")
    }
    
    // MARK: - Drop Animation
    func playDropAnimation() {
        guard !reducedMotion else { return }
        
        // Bounce effect: scale down to 0.95 then back to 1.0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            dropScale = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                dropScale = 1.0
            }
        }
    }
}

// MARK: - Context Menu Content
struct ContextMenuContent: View {
    let task: TaskEntity
    let onMoveTo: (TaskStatus) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleUrgent: () -> Void
    
    var body: some View {
        // Move Actions
        Section("Move to") {
            Button {
                onMoveTo(.todo)
            } label: {
                Label("To Do", systemImage: "circle")
            }
            .disabled(task.taskStatus == .todo)
            
            Button {
                onMoveTo(.doing)
            } label: {
                Label("Doing", systemImage: "play.circle")
            }
            .disabled(task.taskStatus == .doing)
            
            Button {
                onMoveTo(.done)
            } label: {
                Label("Done", systemImage: "checkmark.circle")
            }
            .disabled(task.taskStatus == .done)
        }
        
        // Task Actions
        Section {
            Button {
                onEdit()
            } label: {
                Label("Edit Task", systemImage: "pencil")
            }
            
            Button {
                onToggleUrgent()
            } label: {
                Label(task.isUrgent ? "Remove Urgent" : "Mark Urgent", 
                      systemImage: task.isUrgent ? "minus.circle" : "exclamationmark.circle")
            }
            
            // Share Task (only if shared spaces enabled)
            // Note: Enable when SyncManager.shared.isSharedSpacesEnabled is available
            // if SyncManager.shared.isSharedSpacesEnabled {
            //     Button {
            //         // Share action would go here
            //     } label: {
            //         Label("Share Task", systemImage: "square.and.arrow.up")
            //     }
            // }
        }
        
        // Delete Action
        Section {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }
}

// MARK: - Swipeable Done Task Card
struct SwipeableDoneCard: View {
    let task: TaskEntity
    let onTap: () -> Void
    let onAddAfterImage: () -> Void
    let onReopen: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    @State private var appeared = false
    @State private var completionPulse: CGFloat = 1.0
    @State private var showDeleteConfirmation = false
    
    @Environment(\.reducedMotion) var reducedMotion
    
    var body: some View {
        DoneTaskCardContent(
            task: task,
            isPressed: isPressed,
            onAddAfterImage: onAddAfterImage,
            completionPulse: completionPulse
        )
        // Swipe Actions - Leading Edge (Right swipe)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            // Reopen (Move back to To Do)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onReopen()
                }
            } label: {
                Label("Reopen", systemImage: "arrow.uturn.backward")
            }
            .tint(Color("todoColor"))
        }
        // Swipe Actions - Trailing Edge (Left swipe)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // Delete
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            // Reopen Action
            Button {
                onReopen()
            } label: {
                Label("Reopen Task", systemImage: "arrow.uturn.backward")
            }
            
            // View Action
            Button {
                onTap()
            } label: {
                Label("View Details", systemImage: "eye")
            }
            
            // Delete Action
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
            }
            if pressing {
                Haptics.shared.light()
            }
        }, perform: {})
        // Entrance animation
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
            
            // Completion celebration pulse
            guard !reducedMotion else { return }
            
            // Quick scale pulse: 1.0 → 1.2 → 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    completionPulse = 1.15
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        completionPulse = 1.0
                    }
                }
            }
        }
        .onDisappear {
            appeared = false
        }
        .alert("Delete Task?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \"\(task.title ?? "this task")\"? This action cannot be undone.")
        }
    }
}

// MARK: - Task Card Content
struct TaskCardContent: View {
    let task: TaskEntity
    let isPressed: Bool
    var isDragging: Bool = false
    var dragRotation: Double = 0
    
    @Environment(\.reducedMotion) var reducedMotion
    
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
                        .accessibilityHidden(true)
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
                                .accessibilityHidden(true)
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
                        .accessibilityHidden(true)
                    Text(dueDate.formattedString(style: .short))
                        .font(.caption2)
                }
                .foregroundColor(task.isOverdue ? Color("urgencyHigh") : .secondary)
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(isDragging ? 0.2 : 0.05),
            radius: isDragging ? 12 : 4,
            x: 0,
            y: isDragging ? 8 : 2
        )
        .scaleEffect(isPressed ? 0.95 : (isDragging ? 1.05 : 1.0))
        .rotationEffect(.degrees(reducedMotion ? 0 : dragRotation))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragRotation)
        .withUrgencyGlow(task.urgencyLevel)
    }
}

// MARK: - Done Task Card Content
struct DoneTaskCardContent: View {
    let task: TaskEntity
    let isPressed: Bool
    let onAddAfterImage: () -> Void
    let completionPulse: CGFloat
    
    @Environment(\.reducedMotion) var reducedMotion
    
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
        .scaleEffect(isPressed ? 0.95 : completionPulse)
    }
}

// MARK: - Draggable Task Card (Legacy - kept for compatibility)
struct DraggableTaskCard: View {
    let task: TaskEntity
    let onTap: () -> Void
    let index: Int
    let onDropInDone: (CGPoint) -> Void
    
    @State private var isPressed = false
    @State private var isDragging = false
    @State private var appeared = false
    @State private var dropScale: CGFloat = 1.0
    @State private var dragRotation: Double = 0
    
    @Environment(\.reducedMotion) var reducedMotion
    
    var body: some View {
        TaskCardContent(
            task: task,
            isPressed: isPressed,
            isDragging: isDragging,
            dragRotation: dragRotation
        )
        .scaleEffect(dropScale)
        .draggable(
            TaskDraggable(id: task.id?.uuidString ?? "", title: task.title ?? "")
        ) {
            // Preview while dragging
            TaskCardContent(
                task: task,
                isPressed: true,
                isDragging: true,
                dragRotation: 0
            )
            .frame(width: 140)
            .scaleEffect(1.05)
            .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
            .rotationEffect(.degrees(reducedMotion ? 0 : 2))
            .opacity(0.9)
        }
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
                isDragging = pressing
                
                if pressing {
                    // Add slight rotation for "picked up" feel
                    dragRotation = reducedMotion ? 0 : Double.random(in: -3...3)
                    Haptics.shared.light()
                } else {
                    // Reset rotation
                    dragRotation = 0
                }
            }
        }, perform: {})
        .accessibilityLabel(taskAccessibilityLabel)
        .accessibilityHint("Double-tap to open task details. Long press and drag to move to another column.")
        .accessibilityValue(taskAccessibilityValue)
        .accessibilityAddTraits(.isButton)
        // Entrance animation
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            // Staggered entrance animation
            let delay = Double(index) * 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
        .onDisappear {
            appeared = false
        }
    }
    
    private var taskAccessibilityLabel: String {
        let title = task.title ?? "Untitled task"
        let status = task.taskStatus.displayName
        return "\(title), \(status)"
    }
    
    private var taskAccessibilityValue: String {
        var values: [String] = []
        
        if task.isUrgent {
            values.append("Urgent")
        }
        
        if let dueDate = task.dueDate {
            let dateString = dueDate.formattedString(style: .short)
            if task.isOverdue {
                values.append("Overdue, due \(dateString)")
            } else {
                values.append("Due \(dateString)")
            }
        }
        
        return values.isEmpty ? "No urgency set" : values.joined(separator: ". ")
    }
    
    // MARK: - Drop Animation
    func playDropAnimation() {
        guard !reducedMotion else { return }
        
        // Bounce effect: scale down to 0.95 then back to 1.0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            dropScale = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                dropScale = 1.0
            }
        }
    }
}

// MARK: - Done Task Card (Legacy - kept for compatibility)
struct DoneTaskCard: View {
    let task: TaskEntity
    let onTap: () -> Void
    let onAddAfterImage: () -> Void
    
    @State private var isPressed = false
    @State private var appeared = false
    @State private var completionPulse: CGFloat = 1.0
    
    @Environment(\.reducedMotion) var reducedMotion
    
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
        .scaleEffect(isPressed ? 0.95 : completionPulse)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPressed = pressing
            }
            if pressing {
                Haptics.shared.light()
            }
        }, perform: {})
        // Entrance animation
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
            
            // Completion celebration pulse
            guard !reducedMotion else { return }
            
            // Quick scale pulse: 1.0 → 1.2 → 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    completionPulse = 1.15
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        completionPulse = 1.0
                    }
                }
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

// MARK: - Mini Confetti Burst
struct MiniConfettiBurst: View {
    let position: CGPoint
    
    @State private var particles: [MiniParticle] = []
    @Environment(\.reducedMotion) var reducedMotion
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    var path = Path()
                    
                    switch particle.shape {
                    case .circle:
                        path.addEllipse(in: CGRect(
                            x: particle.x,
                            y: particle.y,
                            width: particle.size,
                            height: particle.size
                        ))
                    case .square:
                        path.addRect(CGRect(
                            x: particle.x,
                            y: particle.y,
                            width: particle.size,
                            height: particle.size
                        ))
                    case .triangle:
                        path.move(to: CGPoint(x: particle.x + particle.size/2, y: particle.y))
                        path.addLine(to: CGPoint(x: particle.x + particle.size, y: particle.y + particle.size))
                        path.addLine(to: CGPoint(x: particle.x, y: particle.y + particle.size))
                        path.closeSubpath()
                    }
                    
                    context.translateBy(x: particle.x + particle.size/2, y: particle.y + particle.size/2)
                    context.rotate(by: .degrees(particle.rotation))
                    context.translateBy(x: -(particle.x + particle.size/2), y: -(particle.y + particle.size/2))
                    
                    context.fill(path, with: .color(particle.color.opacity(particle.opacity)))
                }
            }
            .onChange(of: timeline.date) { _, _ in
                updateParticles()
            }
        }
        .onAppear {
            if !reducedMotion {
                createParticles()
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange, .cyan]
        let shapes: [MiniParticleShape] = [.circle, .square, .triangle]
        
        particles = (0..<25).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let velocity = CGFloat.random(in: 3...8)
            
            return MiniParticle(
                x: position.x,
                y: position.y,
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -10...10),
                velocityX: cos(angle) * velocity,
                velocityY: sin(angle) * velocity - 3, // Slight upward bias
                shape: shapes.randomElement()!,
                opacity: 1.0
            )
        }
    }
    
    private func updateParticles() {
        for index in particles.indices {
            particles[index].x += particles[index].velocityX
            particles[index].y += particles[index].velocityY
            particles[index].velocityY += 0.3 // Gravity
            particles[index].rotation += particles[index].rotationSpeed
            particles[index].opacity -= 0.015 // Fade out
        }
        
        // Remove invisible particles
        particles.removeAll { $0.opacity <= 0 }
    }
}

// MARK: - Mini Particle Model
struct MiniParticle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var rotation: Double
    var rotationSpeed: Double
    var velocityX: CGFloat
    var velocityY: CGFloat
    var shape: MiniParticleShape
    var opacity: Double
}

enum MiniParticleShape {
    case circle, square, triangle
}

// MARK: - Drop Placeholder
struct DropPlaceholder: View {
    let color: Color
    
    @State private var isAnimating = false
    
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
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            )
            .onAppear {
                isAnimating = true
            }
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
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? accessibilitySettings.pressedScaleEffect : 1.0)
            .animation(accessibilitySettings.gentleSpringAnimation, value: configuration.isPressed)
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
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    var glowColor: Color {
        accessibilitySettings.highContrast ? HighContrastColors.urgencyHigh : Color(level.color)
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(glowColor, lineWidth: level.shouldGlow ? (accessibilitySettings.highContrast ? 3 : 2) : 0)
                    .shadow(
                        color: glowColor.opacity(level.shouldGlow && accessibilitySettings.shouldShowCelebrations ? 0.6 : 0),
                        radius: level.shouldGlow ? (isAnimating && accessibilitySettings.shouldShowCelebrations ? 8 : 4) : 0
                    )
                    .opacity(level.shouldGlow ? 1 : 0)
                    .animation(
                        level.shouldGlow && accessibilitySettings.shouldShowCelebrations ?
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true) :
                        .default,
                        value: isAnimating
                    )
            )
            .onAppear {
                if level.shouldGlow && accessibilitySettings.shouldShowCelebrations {
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
