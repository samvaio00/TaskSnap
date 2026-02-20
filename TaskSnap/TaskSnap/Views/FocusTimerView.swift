import SwiftUI

struct FocusTimerView: View {
    let task: TaskEntity
    @ObservedObject var taskViewModel: TaskViewModel
    let onComplete: (TaskEntity) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var timerModel = FocusTimerModel()
    @State private var showingCompleteConfirmation = false
    @State private var showingImagePicker = false
    @State private var afterImage: UIImage?
    
    let timerDurations: [TimeInterval] = [5 * 60, 10 * 60, 15 * 60, 25 * 60, 45 * 60, 60 * 60] // 5, 10, 15, 25, 45, 60 minutes
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Task Info Card
                    taskInfoCard
                    
                    // Timer Selection (when not running)
                    if !timerModel.isRunning && !timerModel.isPaused {
                        timerSelectionView
                    }
                    
                    // Timer Display
                    if timerModel.isRunning || timerModel.isPaused {
                        timerDisplayView
                    }
                    
                    Spacer()
                    
                    // Control Buttons
                    controlButtons
                }
                .padding()
            }
            .navigationTitle("Focus Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        timerModel.stopTimer()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            CameraImagePicker(image: $afterImage, isPresented: $showingImagePicker)
        }
        .alert("Complete Task?", isPresented: $showingCompleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Complete", role: .none) {
                completeTask()
            }
        } message: {
            Text("Take an after photo to celebrate your accomplishment!")
        }
        .onChange(of: afterImage) { newImage in
            if newImage != nil {
                showingCompleteConfirmation = true
            }
        }
        .onReceive(timerModel.$timeRemaining) { time in
            if time == 0 && timerModel.isRunning {
                timerModel.timerFinished()
                Haptics.shared.success()
            }
        }
    }
    
    // MARK: - Task Info Card
    private var taskInfoCard: some View {
        HStack(spacing: 16) {
            // Task Image
            ZStack {
                if let image = task.beforeImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(task.taskCategory.color).opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: task.taskCategory.icon)
                        .font(.title)
                        .foregroundColor(Color(task.taskCategory.color))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled")
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: task.taskCategory.icon)
                        .font(.caption)
                    Text(task.taskCategory.displayName)
                        .font(.caption)
                }
                .foregroundColor(Color(task.taskCategory.color))
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Timer Selection
    private var timerSelectionView: some View {
        VStack(spacing: 16) {
            Text("How long do you want to focus?")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(timerDurations, id: \.self) { duration in
                    Button {
                        timerModel.startTimer(duration: duration)
                        Haptics.shared.buttonTap()
                    } label: {
                        VStack(spacing: 4) {
                            Text(formatDurationShort(duration))
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("min")
                                .font(.caption)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.accentColor, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Timer Display
    private var timerDisplayView: some View {
        ZStack {
            // Background circle (shrinking)
            Circle()
                .stroke(Color.accentColor.opacity(0.2), lineWidth: 20)
                .frame(width: 280, height: 280)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: timerModel.progress)
                .stroke(
                    timerModel.isPaused ? Color.orange : Color.accentColor,
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: timerModel.progress)
            
            // Time text
            VStack(spacing: 8) {
                Text(timerModel.formattedTime)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                if timerModel.isPaused {
                    Text("PAUSED")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .frame(height: 300)
    }
    
    // MARK: - Control Buttons
    private var controlButtons: some View {
        VStack(spacing: 12) {
            if timerModel.isRunning || timerModel.isPaused {
                // Pause/Resume button
                Button {
                    if timerModel.isPaused {
                        timerModel.resumeTimer()
                        Haptics.shared.buttonTap()
                    } else {
                        timerModel.pauseTimer()
                        Haptics.shared.light()
                    }
                } label: {
                    HStack {
                        Image(systemName: timerModel.isPaused ? "play.fill" : "pause.fill")
                        Text(timerModel.isPaused ? "Resume" : "Pause")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(timerModel.isPaused ? Color.green : Color.orange)
                    .cornerRadius(16)
                }
                
                // Complete Early button
                Button {
                    timerModel.stopTimer()
                    showingImagePicker = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Complete Early")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("doneColor"))
                    .cornerRadius(16)
                }
                
                // Cancel button
                Button {
                    timerModel.stopTimer()
                } label: {
                    Text("Cancel Timer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatDurationShort(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)"
    }
    
    private func completeTask() {
        if let image = afterImage {
            task.afterImagePath = ImageStorage.shared.saveImage(image)
        }
        
        task.completedAt = Date()
        taskViewModel.updateTaskStatus(task, to: .done)
        
        dismiss()
        onComplete(task)
    }
}

// MARK: - Focus Timer Model
class FocusTimerModel: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var isRunning = false
    @Published var isPaused = false
    
    private var timer: Timer?
    
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return timeRemaining / totalTime
    }
    
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startTimer(duration: TimeInterval) {
        totalTime = duration
        timeRemaining = duration
        isRunning = true
        isPaused = false
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.timerFinished()
            }
        }
    }
    
    func pauseTimer() {
        isPaused = true
    }
    
    func resumeTimer() {
        isPaused = false
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        timeRemaining = 0
        totalTime = 0
    }
    
    func timerFinished() {
        stopTimer()
        // Could trigger a notification or sound here
    }
}

#Preview {
    FocusTimerView(
        task: TaskEntity(),
        taskViewModel: TaskViewModel(context: PersistenceController.preview.container.viewContext),
        onComplete: { _ in }
    )
}
