import SwiftUI

struct AchievementView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedAchievement: Achievement?
    @State private var showingDetail = false
    
    private var unlockedAchievements: [Achievement] {
        achievementManager.achievements.filter(\.isUnlocked)
    }
    
    private var lockedAchievements: [Achievement] {
        achievementManager.achievements.filter { !$0.isUnlocked }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress Header
                    progressHeader
                    
                    // Unlocked Achievements
                    if !unlockedAchievements.isEmpty {
                        achievementsSection(
                            title: "Unlocked",
                            achievements: unlockedAchievements,
                            showProgress: false
                        )
                    }
                    
                    // Locked Achievements
                    achievementsSection(
                        title: "In Progress",
                        achievements: lockedAchievements,
                        showProgress: true
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("Achievements")
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailView(achievement: achievement)
            }
        }
    }
    
    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 20) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemBackground), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(
                        AngularGradient(
                            colors: [.achievementBronze, .achievementSilver, .achievementGold, .achievementBronze],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: progressPercentage)
                
                VStack {
                    Text("\(achievementManager.unlockedCount)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("of \(achievementManager.totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("\(Int(progressPercentage * 100))% Complete")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    private var progressPercentage: Double {
        Double(achievementManager.unlockedCount) / Double(achievementManager.totalCount)
    }
    
    // MARK: - Achievements Section
    private func achievementsSection(title: String, achievements: [Achievement], showProgress: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(achievements.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement, showProgress: showProgress)
                        .onTapGesture {
                            selectedAchievement = achievement
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    let showProgress: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color(achievement.color).opacity(0.2) : Color(.tertiarySystemBackground))
                    .frame(width: 70, height: 70)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 32))
                    .foregroundColor(achievement.isUnlocked ? Color(achievement.color) : .secondary)
                    .symbolEffect(.bounce, options: achievement.isUnlocked ? .repeating : .nonRepeating)
                
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.doneColor)
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 20, y: 20)
                }
            }
            
            // Title
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                .lineLimit(2)
            
            // Progress Bar (for locked achievements)
            if showProgress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.tertiarySystemBackground))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(achievement.color))
                            .frame(width: geometry.size.width * achievement.progress, height: 4)
                    }
                }
                .frame(height: 4)
                
                Text("\(Int(achievement.progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(height: showProgress ? 160 : 140)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(achievement.isUnlocked ? Color(achievement.color).opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Achievement Detail View
struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(achievement.color).opacity(0.2))
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 80))
                        .foregroundColor(Color(achievement.color))
                        .symbolEffect(.bounce, options: .repeating)
                    
                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.doneColor)
                            .background(Color.white)
                            .clipShape(Circle())
                            .offset(x: 50, y: 50)
                    }
                }
                
                // Title & Description
                VStack(spacing: 12) {
                    Text(achievement.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Status
                if achievement.isUnlocked {
                    VStack(spacing: 8) {
                        Text("Unlocked!")
                            .font(.headline)
                            .foregroundColor(.doneColor)
                        
                        if let date = achievement.unlockedAt {
                            Text("on \(date.formattedString())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.doneColor.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    VStack(spacing: 8) {
                        Text("Progress: \(Int(achievement.progress * 100))%")
                            .font(.headline)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.tertiarySystemBackground))
                                    .frame(height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(achievement.color))
                                    .frame(width: geometry.size.width * achievement.progress, height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AchievementView()
}
