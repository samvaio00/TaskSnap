import SwiftUI

struct VictoryView: View {
    let task: TaskEntity
    let onDismiss: () -> Void
    
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var selectedReaction: String?
    
    let reactions = ["🎉", "💪", "✨", "🔥", "🙌", "😊"]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.doneColor.opacity(0.3),
                    Color.doneColor.opacity(0.1),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Confetti
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Success Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.doneColor.opacity(0.2))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.doneColor)
                                .symbolEffect(.bounce, options: .repeating)
                        }
                        
                        Text("Task Complete!")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.doneColor)
                        
                        Text("You captured your success!")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .scaleEffect(scale)
                    .opacity(opacity)
                    
                    // Before & After Comparison
                    if task.afterImage != nil {
                        beforeAfterSection
                            .scaleEffect(scale)
                            .opacity(opacity)
                    }
                    
                    // Reaction Section
                    VStack(spacing: 16) {
                        Text("How does this feel?")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            ForEach(reactions, id: \.self) { reaction in
                                Button {
                                    withAnimation(.bouncy()) {
                                        selectedReaction = reaction
                                    }
                                    Haptics.shared.light()
                                } label: {
                                    Text(reaction)
                                        .font(.system(size: 32))
                                        .scaleEffect(selectedReaction == reaction ? 1.3 : 1.0)
                                        .opacity(selectedReaction == nil || selectedReaction == reaction ? 1 : 0.4)
                                    }
                                }
                        }
                    }
                    .opacity(opacity)
                    
                    // Stats
                    HStack(spacing: 24) {
                        StatCard(
                            value: "\(StreakManager.shared.currentStreak)",
                            label: "Day Streak",
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            value: "\(AchievementManager.shared.unlockedCount)",
                            label: "Achievements",
                            icon: "trophy.fill",
                            color: .yellow
                        )
                    }
                    .opacity(opacity)
                    
                    Spacer()
                    
                    // Done Button
                    Button {
                        withAnimation {
                            onDismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Continue")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.doneColor)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .opacity(opacity)
                }
                .padding()
            }
        }
        .onAppear {
            // Trigger animations
            withAnimation(.easeOut(duration: 0.5)) {
                scale = 1.0
                opacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
                Haptics.shared.taskCompleted()
            }
            
            // Check for new achievements
            AchievementManager.shared.checkAchievements(
                streak: StreakManager.shared.currentStreak,
                tasksCompleted: 1, // This will be updated by the task view model
                tasks: []
            )
        }
    }
    
    // MARK: - Before & After Section
    private var beforeAfterSection: some View {
        VStack(spacing: 16) {
            Text("Your Transformation")
                .font(.headline)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 12) {
                    // Before/After Slider
                    BeforeAfterSlider(
                        beforeImage: task.beforeImage,
                        afterImage: task.afterImage
                    )
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
            }
        }
    }
}

// MARK: - Before After Slider
struct BeforeAfterSlider: View {
    let beforeImage: UIImage?
    let afterImage: UIImage?
    @State private var sliderPosition: CGFloat = 0.5
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // After Image (Background)
                if let image = afterImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                
                // Before Image (Clipped)
                if let image = beforeImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipShape(
                            Rectangle()
                                .path(in: CGRect(
                                    x: 0,
                                    y: 0,
                                    width: geometry.size.width * sliderPosition,
                                    height: geometry.size.height
                                ))
                        )
                }
                
                // Slider Line
                VStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 4, height: geometry.size.height)
                        .shadow(radius: 2)
                }
                .position(
                    x: geometry.size.width * sliderPosition,
                    y: geometry.size.height / 2
                )
                
                // Slider Handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .shadow(radius: 4)
                    .overlay(
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
                    .position(
                        x: geometry.size.width * sliderPosition,
                        y: geometry.size.height / 2
                    )
                
                // Labels
                HStack {
                    Text("BEFORE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding(12)
                    
                    Spacer()
                    
                    Text("AFTER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        .padding(8)
                        .background(Color.doneColor.opacity(0.8))
                        .cornerRadius(8)
                        .padding(12)
                }
                .position(x: geometry.size.width / 2, y: 30)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        sliderPosition = max(0, min(1, value.location.x / geometry.size.width))
                    }
            )
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let task = TaskEntity(context: context)
    task.id = UUID()
    task.title = "Clean Kitchen"
    task.taskStatus = .done
    task.createdAt = Date()
    task.completedAt = Date()
    
    return VictoryView(task: task) {}
}
