import SwiftUI
import AVFoundation

struct FocusTimerView: View {
    let task: TaskEntity
    @ObservedObject var taskViewModel: TaskViewModel
    let onComplete: (TaskEntity) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var timerModel = FocusTimerModel()
    @StateObject private var soundManager = FocusSoundManager.shared
    @StateObject private var breakManager = BreakReminderManager.shared
    
    @State private var showingCompleteConfirmation = false
    @State private var showingImagePicker = false
    @State private var showingSoundPicker = false
    @State private var showingSessionHistory = false
    @State private var showingBreakSheet = false
    @State private var afterImage: UIImage?
    @State private var showingBreakAlert = false
    
    let timerDurations: [TimeInterval] = [5 * 60, 10 * 60, 15 * 60, 25 * 60, 45 * 60, 60 * 60]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Task Info Card
                    taskInfoCard
                    
                    // Break Reminder Banner (when active)
                    if timerModel.isRunning && breakManager.timeUntilBreak > 0 && breakManager.timeUntilBreak < 300 {
                        breakReminderBanner
                    }
                    
                    // Timer Selection (when not running)
                    if !timerModel.isRunning && !timerModel.isPaused {
                        timerSelectionView
                        
                        // Sound Selection
                        soundSelectionView
                    }
                    
                    // Timer Display
                    if timerModel.isRunning || timerModel.isPaused {
                        timerDisplayView
                        
                        // Break reminder progress
                        if timerModel.totalTime > 900 { // Only for sessions > 15 min
                            breakProgressView
                        }
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
                        cleanupAndDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSessionHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            CameraImagePicker(image: $afterImage, isPresented: $showingImagePicker)
        }
        .sheet(isPresented: $showingSoundPicker) {
            SoundPickerView()
        }
        .sheet(isPresented: $showingSessionHistory) {
            FocusSessionHistoryView()
        }
        .sheet(isPresented: $showingBreakSheet) {
            BreakSheetView(
                onTakeBreak: {
                    breakManager.takeBreak()
                    showingBreakSheet = false
                },
                onSkipBreak: {
                    breakManager.skipBreak()
                    showingBreakSheet = false
                }
            )
        }
        .alert("Complete Task?", isPresented: $showingCompleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Complete", role: .none) {
                completeTask()
            }
        } message: {
            Text("Take an after photo to celebrate your accomplishment!")
        }
        .alert("Time for a Break!", isPresented: $showingBreakAlert) {
            Button("Take 5 Min Break") {
                showingBreakSheet = true
            }
            Button("Skip This Time", role: .cancel) {
                breakManager.skipBreak()
            }
        } message: {
            Text("You've been focusing for a while. Taking breaks improves productivity and prevents burnout.")
        }
        .onChange(of: afterImage) { _, newImage in
            if newImage != nil {
                showingCompleteConfirmation = true
            }
        }
        .onReceive(timerModel.$timeRemaining) { time in
            if time == 0 && timerModel.isRunning {
                timerModel.timerFinished()
                Haptics.shared.success()
                saveFocusSession()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .breakReminderTriggered)) { _ in
            showingBreakAlert = true
        }
        .onAppear {
            // Load sound preference
            if soundManager.currentSound != .none {
                // Don't auto-play, wait for timer to start
            }
        }
        .onDisappear {
            cleanupAndDismiss()
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
    
    // MARK: - Break Reminder Banner
    private var breakReminderBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Break in \(breakManager.formattedTimeUntilBreak)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Taking breaks improves focus")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
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
                        startFocusSession(duration: duration)
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
    
    // MARK: - Sound Selection
    private var soundSelectionView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Background Sound")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    showingSoundPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: soundManager.currentSound.icon)
                        Text(soundManager.currentSound.displayName)
                            .font(.subheadline)
                    }
                    .foregroundColor(.accentColor)
                }
            }
            
            // Volume slider (if sound is selected)
            if soundManager.currentSound != .none {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Slider(value: Binding(
                        get: { soundManager.volume },
                        set: { soundManager.setVolume($0) }
                    ), in: 0...1)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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
                
                // Sound indicator
                if soundManager.isPlaying {
                    HStack(spacing: 4) {
                        Image(systemName: soundManager.currentSound.icon)
                            .font(.caption)
                        Text(soundManager.currentSound.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .frame(height: 300)
    }
    
    // MARK: - Break Progress
    private var breakProgressView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("Next break: \(breakManager.formattedTimeUntilBreak)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Break progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * (1 - (breakManager.timeUntilBreak / 1500)), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Control Buttons
    private var controlButtons: some View {
        VStack(spacing: 12) {
            if timerModel.isRunning || timerModel.isPaused {
                // Pause/Resume button
                Button {
                    if timerModel.isPaused {
                        resumeFocus()
                    } else {
                        pauseFocus()
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
                    saveFocusSession(completedEarly: true)
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
                    cleanupAndDismiss()
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
    private func startFocusSession(duration: TimeInterval) {
        // Play focus start animation
        AnimationManager.shared.play(.focusStart)
        
        // Start timer
        timerModel.startTimer(duration: duration)
        
        // Start sound if selected
        if soundManager.currentSound != .none {
            soundManager.play(sound: soundManager.currentSound)
        }
        
        // Start break reminders for longer sessions
        if duration > 900 {
            breakManager.startMonitoring(sessionDuration: duration)
        }
        
        Haptics.shared.buttonTap()
    }
    
    private func pauseFocus() {
        timerModel.pauseTimer()
        soundManager.pause()
        Haptics.shared.light()
    }
    
    private func resumeFocus() {
        timerModel.resumeTimer()
        soundManager.resume()
        Haptics.shared.buttonTap()
    }
    
    private func cleanupAndDismiss() {
        timerModel.stopTimer()
        soundManager.stop()
        breakManager.stopMonitoring()
        dismiss()
    }
    
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
        
        cleanupAndDismiss()
        onComplete(task)
    }
    
    private func saveFocusSession(completedEarly: Bool = false) {
        let session = FocusSessionEntity(context: PersistenceController.shared.container.viewContext)
        session.id = UUID()
        session.taskId = task.id
        session.taskTitle = task.title
        session.startedAt = Date().addingTimeInterval(-(timerModel.totalTime - timerModel.timeRemaining))
        session.duration = timerModel.totalTime - timerModel.timeRemaining
        session.plannedDuration = timerModel.totalTime
        session.completedEarly = completedEarly
        session.soundType = soundManager.currentSound.rawValue
        
        do {
            try PersistenceController.shared.container.viewContext.save()
        } catch {
            print("Failed to save focus session: \(error)")
        }
    }
}

// MARK: - Sound Picker View
struct SoundPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var soundManager = FocusSoundManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(FocusSound.allCases) { sound in
                        Button {
                            soundManager.play(sound: sound)
                            Haptics.shared.selectionChanged()
                        } label: {
                            HStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(sound == .none ? Color(.tertiarySystemBackground) : Color(sound.color).opacity(0.2))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: sound.icon)
                                        .font(.title3)
                                        .foregroundColor(sound == .none ? .secondary : Color(sound.color))
                                }
                                
                                // Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sound.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(sound.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                // Selection indicator
                                if soundManager.currentSound == sound {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.title3)
                                }
                                
                                // Playing indicator
                                if soundManager.isPlaying && soundManager.currentSound == sound && sound != .none {
                                    SoundWaveIndicator()
                                        .frame(width: 20, height: 20)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } header: {
                    Text("Select a background sound to help you focus")
                }
                
                // Volume section
                if soundManager.currentSound != .none {
                    Section("Volume") {
                        HStack(spacing: 16) {
                            Image(systemName: "speaker.fill")
                                .foregroundColor(.secondary)
                            
                            Slider(value: Binding(
                                get: { soundManager.volume },
                                set: { soundManager.setVolume($0) }
                            ), in: 0...1)
                            
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Focus Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Stop preview if playing
                        if soundManager.isPlaying {
                            soundManager.stop()
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Sound Wave Indicator
struct SoundWaveIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.accentColor)
                    .frame(width: 3, height: animating ? 16 : 4)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Break Sheet View
struct BreakSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let onTakeBreak: () -> Void
    let onSkipBreak: () -> Void
    
    @State private var breakTimeRemaining: TimeInterval = 300 // 5 minutes
    @State private var isOnBreak = false
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                }
                
                // Title
                if isOnBreak {
                    Text("Break Time")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    
                    Text(formattedTime(breakTimeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                        .monospacedDigit()
                    
                    Text("Step away from your screen. Stretch, hydrate, or take a short walk.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("Time for a Break!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    
                    Text("You've been focusing for a while. Taking short breaks helps maintain productivity and prevents mental fatigue.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    if isOnBreak {
                        Button {
                            endBreak()
                        } label: {
                            Text("End Break & Resume")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(16)
                        }
                    } else {
                        Button {
                            startBreak()
                        } label: {
                            Text("Take 5-Minute Break")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(16)
                        }
                        
                        Button {
                            onSkipBreak()
                            dismiss()
                        } label: {
                            Text("Skip This Time")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle(isOnBreak ? "On Break" : "Break Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startBreak() {
        isOnBreak = true
        onTakeBreak()
        breakTimeRemaining = 300
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if breakTimeRemaining > 0 {
                breakTimeRemaining -= 1
            } else {
                // Break is over
                timer?.invalidate()
                Haptics.shared.success()
            }
        }
    }
    
    private func endBreak() {
        timer?.invalidate()
        dismiss()
    }
    
    private func formattedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Focus Session History View
struct FocusSessionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sessions: [FocusSession] = []
    
    var body: some View {
        NavigationView {
            List {
                if sessions.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("No Focus Sessions Yet")
                                .font(.headline)
                            
                            Text("Complete a focus session to see your history here.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                } else {
                    // Stats summary
                    Section("This Week") {
                        HStack(spacing: 20) {
                            StatBox(
                                value: "\(sessions.count)",
                                label: "Sessions",
                                icon: "number",
                                color: .blue
                            )
                            
                            StatBox(
                                value: formatDuration(sessions.reduce(0) { $0 + $1.duration }),
                                label: "Total Focus Time",
                                icon: "clock",
                                color: .green
                            )
                            
                            StatBox(
                                value: "\(sessions.filter(\.completedEarly).count)",
                                label: "Early Completions",
                                icon: "bolt.fill",
                                color: .orange
                            )
                        }
                    }
                    
                    // Session list
                    Section("Recent Sessions") {
                        ForEach(sessions) { session in
                            SessionRow(session: session)
                        }
                    }
                }
            }
            .navigationTitle("Focus History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSessions()
            }
        }
    }
    
    private func loadSessions() {
        // Load from Core Data
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<FocusSessionEntity> = FocusSessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FocusSessionEntity.startedAt, ascending: false)]
        request.fetchLimit = 50
        
        do {
            let entities = try context.fetch(request)
            sessions = entities.map { FocusSession(from: $0) }
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Session Row
struct SessionRow: View {
    let session: FocusSession
    
    var body: some View {
        HStack(spacing: 12) {
            // Sound icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: session.soundIcon)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.taskTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(session.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if session.completedEarly {
                        Text("Early")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            Text(session.formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Focus Session Model
struct FocusSession: Identifiable {
    let id: UUID
    let taskId: UUID?
    let taskTitle: String
    let startedAt: Date
    let duration: TimeInterval
    let plannedDuration: TimeInterval
    let completedEarly: Bool
    let soundType: String
    
    init(from entity: FocusSessionEntity) {
        self.id = entity.id ?? UUID()
        self.taskId = entity.taskId
        self.taskTitle = entity.taskTitle ?? "Unknown Task"
        self.startedAt = entity.startedAt ?? Date()
        self.duration = entity.duration
        self.plannedDuration = entity.plannedDuration
        self.completedEarly = entity.completedEarly
        self.soundType = entity.soundType ?? "none"
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: startedAt, relativeTo: Date())
    }
    
    var soundIcon: String {
        FocusSound(rawValue: soundType)?.icon ?? "speaker.slash.fill"
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
    }
}

#Preview {
    FocusTimerView(
        task: TaskEntity(),
        taskViewModel: TaskViewModel(context: PersistenceController.preview.container.viewContext),
        onComplete: { _ in }
    )
}
