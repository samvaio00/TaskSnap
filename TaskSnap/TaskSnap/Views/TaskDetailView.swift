import SwiftUI

struct TaskDetailView: View {
    let task: TaskEntity
    @ObservedObject var taskViewModel: TaskViewModel
    let onComplete: (TaskEntity) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingCompleteConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingImagePicker = false
    @State private var showingPhotoLibrary = false
    @State private var showingCompletionOptions = false
    @State private var showingFocusTimer = false
    @State private var afterImage: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Task Image Section
                    taskImageSection
                    
                    // Task Info
                    taskInfoSection
                    
                    // Action Buttons
                    actionButtonsSection
                    
                    // Task Metadata
                    metadataSection
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Task", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                CameraImagePicker(image: $afterImage, isPresented: $showingImagePicker)
            }
            .sheet(isPresented: $showingPhotoLibrary) {
                PhotoLibraryPicker(image: $afterImage, isPresented: $showingPhotoLibrary)
            }
            .sheet(isPresented: $showingFocusTimer) {
                FocusTimerView(
                    task: task,
                    taskViewModel: taskViewModel,
                    onComplete: { completedTask in
                        showingFocusTimer = false
                        onComplete(completedTask)
                    }
                )
            }
            .confirmationDialog("Complete Task", isPresented: $showingCompletionOptions, titleVisibility: .visible) {
                Button("Take Photo") {
                    showingImagePicker = true
                }
                Button("Choose from Library") {
                    showingPhotoLibrary = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Take an after photo to celebrate your accomplishment!")
            }
            .alert("Complete Task?", isPresented: $showingCompleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Complete", role: .none) {
                    completeTask()
                }
            } message: {
                Text("Take an after photo to celebrate your accomplishment!")
            }
            .alert("Delete Task?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteTask()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .onChange(of: afterImage) { newImage in
                if newImage != nil {
                    showingCompleteConfirmation = true
                }
            }
            .overlay(
                AchievementToastContainer()
            )
        }
    }
    
    // MARK: - Task Image Section
    private var taskImageSection: some View {
        VStack(spacing: 16) {
            // Before Image
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("BEFORE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                if let image = task.beforeImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .shadow(radius: 4)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(task.taskCategory.color).opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: task.taskCategory.icon)
                                .font(.system(size: 60))
                                .foregroundColor(Color(task.taskCategory.color))
                        )
                }
            }
            
            // After Image (if completed)
            if task.taskStatus == .done {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("AFTER")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color("doneColor"))
                        Spacer()
                    }
                    
                    if let image = task.afterImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(16)
                            .shadow(radius: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color("doneColor"), lineWidth: 3)
                            )
                    } else {
                        // No after image - show capture options
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("doneColor").opacity(0.1))
                                .frame(height: 120)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(Color("doneColor"))
                                        Text("Add After Photo")
                                            .font(.headline)
                                            .foregroundColor(Color("doneColor"))
                                    }
                                )
                            
                            // Camera button
                            Button {
                                showingImagePicker = true
                            } label: {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Take Photo")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("doneColor"))
                                .cornerRadius(12)
                            }
                            
                            // Photo Library button
                            Button {
                                showingPhotoLibrary = true
                            } label: {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Choose from Library")
                                }
                                .font(.headline)
                                .foregroundColor(Color("doneColor"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("doneColor").opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Task Info Section
    private var taskInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(task.title ?? "Untitled Task")
                .font(.title)
                .fontWeight(.bold)
            
            // Category Badge
            HStack {
                Image(systemName: task.taskCategory.icon)
                Text(task.taskCategory.displayName)
            }
            .font(.subheadline)
            .foregroundColor(Color(task.taskCategory.color))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(task.taskCategory.color).opacity(0.15))
            .cornerRadius(20)
            
            // Description
            if let description = task.taskDescription, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Urgent Badge
            if task.isUrgent && task.taskStatus != .done {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color("urgencyHigh"))
                    Text("Urgent")
                        .fontWeight(.semibold)
                }
                .foregroundColor(Color("urgencyHigh"))
                .padding()
                .background(Color("urgencyHigh").opacity(0.1))
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if task.taskStatus == .todo {
                Button {
                    Haptics.shared.taskMoved()
                    taskViewModel.updateTaskStatus(task, to: .doing)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Start Task")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("doingColor"))
                    .cornerRadius(16)
                }
                
                Button {
                    Haptics.shared.cameraShutter()
                    showingCompletionOptions = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Task")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("doneColor"))
                    .cornerRadius(16)
                }
            } else if task.taskStatus == .doing {
                // Focus Timer Button
                Button {
                    Haptics.shared.buttonTap()
                    showingFocusTimer = true
                } label: {
                    HStack {
                        Image(systemName: "timer.circle.fill")
                        Text("Start Focus Timer")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(16)
                }
                
                Button {
                    Haptics.shared.cameraShutter()
                    showingCompletionOptions = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Task")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("doneColor"))
                    .cornerRadius(16)
                }
                
                Button {
                    Haptics.shared.taskMoved()
                    taskViewModel.updateTaskStatus(task, to: .todo)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle")
                        Text("Move Back to To Do")
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
            } else {
                // Task is done
                Button {
                    Haptics.shared.taskMoved()
                    taskViewModel.updateTaskStatus(task, to: .todo)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise.circle")
                        Text("Reopen Task")
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
            }
        }
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Created Date
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(.secondary)
                    Text("Created")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(task.createdAt?.formattedString() ?? "Unknown")
                }
                
                Divider()
                
                // Due Date (if set)
                if let dueDate = task.dueDate {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(task.isOverdue ? Color("urgencyHigh") : .secondary)
                        Text("Due")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(dueDate.formattedString())
                            .foregroundColor(task.isOverdue ? Color("urgencyHigh") : .primary)
                        
                        if task.isOverdue {
                            Text("Overdue")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color("urgencyHigh"))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Completed Date (if done)
                if let completedAt = task.completedAt {
                    Divider()
                    
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Color("doneColor"))
                        Text("Completed")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(completedAt.formattedString())
                            .foregroundColor(Color("doneColor"))
                    }
                }
                
                // Status
                Divider()
                
                HStack {
                    Image(systemName: "flag.fill")
                        .foregroundColor(Color(task.taskStatus.color))
                    Text("Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(task.taskStatus.displayName)
                        .fontWeight(.medium)
                        .foregroundColor(Color(task.taskStatus.color))
                }
            }
            .font(.subheadline)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func completeTask() {
        Haptics.shared.taskCompleted()
        taskViewModel.completeTask(task, afterImage: afterImage)
        dismiss()
        onComplete(task)
    }
    
    private func deleteTask() {
        Haptics.shared.error()
        taskViewModel.deleteTask(task)
        dismiss()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let task = TaskEntity(context: context)
    task.id = UUID()
    task.title = "Clean the Kitchen"
    task.taskDescription = "The dishes have piled up and need cleaning"
    task.taskCategory = .clean
    task.taskStatus = .todo
    task.createdAt = Date()
    task.isUrgent = true
    
    return TaskDetailView(
        task: task,
        taskViewModel: TaskViewModel(context: context),
        onComplete: { _ in }
    )
}
