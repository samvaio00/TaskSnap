import SwiftUI

struct StreakView: View {
    @ObservedObject var gamificationViewModel: GamificationViewModel
    @State private var showingDoneGallery = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Plant/Character Section
                    plantSection
                    
                    // Streak Stats
                    streakStatsSection
                    
                    // Today's Progress
                    todayProgressSection
                    
                    // Weekly Calendar
                    weeklyCalendarSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Your Streak")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Plant Section
    private var plantSection: some View {
        VStack(spacing: 20) {
            // Plant Visualization
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(gamificationViewModel.plantColor).opacity(0.3),
                                Color(gamificationViewModel.plantColor).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                
                // Plant/Character Image
                Image(systemName: gamificationViewModel.plantSystemImage)
                    .font(.system(size: 100))
                    .foregroundColor(Color(gamificationViewModel.plantColor))
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityLabel("Plant at stage \(gamificationViewModel.streakManager.plantGrowthStage)")
                
                // Sparkles for higher streaks
                if gamificationViewModel.streakManager.plantGrowthStage >= 7 {
                    ForEach(0..<3) { i in
                        Image(systemName: "sparkle")
                            .font(.title)
                            .foregroundColor(.yellow)
                            .offset(
                                x: CGFloat([60, -50, 40][i]),
                                y: CGFloat([-40, -60, 30][i])
                            )
                            .rotationEffect(.degrees(Double(i * 30)))
                    }
                }
            }
            
            // Streak Counter
            VStack(spacing: 8) {
                Text("\(gamificationViewModel.streakManager.currentStreak)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(Color(gamificationViewModel.plantColor))
                
                Text("Day Streak")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Plant Description
            Text(gamificationViewModel.streakManager.plantDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    // MARK: - Streak Stats
    private var streakStatsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                value: "\(gamificationViewModel.streakManager.currentStreak)",
                label: "Current",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                value: "\(gamificationViewModel.streakManager.longestStreak)",
                label: "Best",
                icon: "trophy.fill",
                color: .yellow
            )
            
            StatCard(
                value: "\(gamificationViewModel.todayTasks.count)",
                label: "Today",
                icon: "checkmark.circle.fill",
                color: Color("doneColor")
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Today's Progress
    private var todayProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.headline)
                    Text(gamificationViewModel.motivationalMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(gamificationViewModel.todayProgressPercentage)%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(height: 20)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [.accentColor, .accentColor.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * gamificationViewModel.todayProgress, height: 20)
                        .animation(.easeInOut(duration: 0.5), value: gamificationViewModel.todayProgress)
                }
            }
            .frame(height: 20)
            
            // Task count and View Gallery button
            HStack {
                if gamificationViewModel.todayTasks.count == 0 {
                    Text("No tasks completed yet today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if gamificationViewModel.todayTasks.count == 1 {
                    Text("1 task completed today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(gamificationViewModel.todayTasks.count) tasks completed today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // View Gallery Button
                if gamificationViewModel.todayTasks.count > 0 {
                    Button {
                        showingDoneGallery = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "photo.stack")
                            Text("View Gallery")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color("doneColor"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("doneColor").opacity(0.15))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDoneGallery) {
            DoneTodayGalleryView(gamificationViewModel: gamificationViewModel)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Weekly Calendar
    private var weeklyCalendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(0..<7) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: dayOffset - 6, to: Date())!
                    let isToday = Calendar.current.isDateInToday(date)
                    let hasTask = gamificationViewModel.hasTasksFor(date: date)
                    
                    DayCell(
                        day: dayLetter(for: date),
                        date: dayNumber(for: date),
                        isActive: hasTask,
                        isToday: isToday
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }
    
    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let day: String
    let date: String
    let isActive: Bool
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(day)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .fill(isActive ? Color("doneColor") : Color(.tertiarySystemBackground))
                    .frame(width: 40, height: 40)
                
                if isToday && !isActive {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 2)
                        .frame(width: 40, height: 40)
                }
                
                Text(date)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isActive ? .white : .primary)
            }
            
            // Indicator dot
            Circle()
                .fill(isActive ? Color("doneColor") : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StreakView(gamificationViewModel: GamificationViewModel())
}
