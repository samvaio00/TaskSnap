import SwiftUI

struct BodyDoublingRoomView: View {
    @StateObject private var manager = BodyDoublingManager.shared
    @State private var taskName = ""
    @State private var showingEndConfirmation = false
    @State private var selectedDuration = 25 // minutes
    @State private var timeRemaining: TimeInterval = 25 * 60
    @State private var timer: Timer?
    
    let durations = [15, 25, 45, 60]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                
                if manager.isInSession {
                    activeSessionView
                } else {
                    preSessionView
                }
            }
            .navigationTitle("Body Doubling")
            .navigationBarTitleDisplayMode(.large)
            .alert("End Session?", isPresented: $showingEndConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("End", role: .destructive) {
                    endSession()
                }
            } message: {
                Text("Your focus session will end and you'll leave the virtual room.")
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.accentColor.opacity(0.05),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Pre-Session View
    private var preSessionView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Duration selector
                durationSelector
                
                // Task input
                taskInputSection
                
                // Start button
                startButton
                
                // Info
                infoSection
            }
            .padding()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 8) {
                Text("Virtual Body Doubling")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Work alongside others in silent focus")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }
    
    private var durationSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Duration")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(durations, id: \.self) { duration in
                    DurationButton(
                        duration: duration,
                        isSelected: selectedDuration == duration
                    ) {
                        withAnimation(.spring()) {
                            selectedDuration = duration
                            timeRemaining = TimeInterval(duration * 60)
                        }
                    }
                }
            }
        }
    }
    
    private var taskInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What are you working on?")
                .font(.headline)
            
            TextField("Optional: Enter task name", text: $taskName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
        }
    }
    
    private var startButton: some View {
        Button {
            startSession()
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                Text("Start Focus Session")
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
        .disabled(!manager.isRoomAvailable)
        .opacity(manager.isRoomAvailable ? 1.0 : 0.6)
    }
    
    private var infoSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.secondary)
                Text("\(manager.participantCount) people in room")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !manager.isRoomAvailable {
                Label("Room is full. Try again soon.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Silent accountability - no chat", systemImage: "checkmark.circle.fill")
                Label("Visible presence keeps you focused", systemImage: "checkmark.circle.fill")
                Label("Sessions saved to your streak", systemImage: "checkmark.circle.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Active Session View
    private var activeSessionView: some View {
        VStack(spacing: 24) {
            // Timer
            timerSection
            
            // Participants
            participantsSection
            
            Spacer()
            
            // End button
            endSessionButton
        }
        .padding()
    }
    
    private var timerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Progress circle
                Circle()
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: 1 - (timeRemaining / (TimeInterval(selectedDuration) * 60)))
                    .stroke(
                        Color.accentColor.gradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: timeRemaining)
                
                VStack(spacing: 4) {
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    
                    if let task = manager.currentSession?.taskName, !task.isEmpty {
                        Text(task)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .padding(.horizontal)
                    }
                }
            }
            
            Text("Focusing together")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Focus Partners")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("\(manager.participantCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Self
                    participantCard(
                        name: "You",
                        avatar: manager.currentSession?.avatar ?? "person.circle",
                        task: manager.currentSession?.taskName,
                        isSelf: true
                    )
                    
                    // Other participants
                    ForEach(manager.participants) { participant in
                        participantCard(
                            name: participant.name,
                            avatar: participant.avatar,
                            task: participant.currentTask,
                            isSelf: false
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func participantCard(name: String, avatar: String, task: String?, isSelf: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: avatar)
                    .font(.system(size: 40))
                    .foregroundColor(isSelf ? .accentColor : .secondary)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(isSelf ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemBackground))
                    )
                
                if !isSelf {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                }
            }
            
            Text(name)
                .font(.caption)
                .fontWeight(isSelf ? .semibold : .regular)
            
            if let task = task, !task.isEmpty {
                Text(task)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 80)
            }
        }
        .frame(width: 90)
    }
    
    private var endSessionButton: some View {
        Button {
            showingEndConfirmation = true
        } label: {
            HStack {
                Image(systemName: "stop.circle.fill")
                    .font(.title2)
                Text("End Session")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.8))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Actions
    
    private func startSession() {
        manager.startSession(taskName: taskName.isEmpty ? nil : taskName)
        startTimer()
    }
    
    private func endSession() {
        timer?.invalidate()
        timer = nil
        manager.endSession()
        
        // Record completion for streak
        StreakManager.shared.recordTaskCompletion()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                // Timer finished
                timer?.invalidate()
                manager.endSession()
                StreakManager.shared.recordTaskCompletion()
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Duration Button
struct DurationButton: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(duration)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("min")
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview
#Preview {
    BodyDoublingRoomView()
}
