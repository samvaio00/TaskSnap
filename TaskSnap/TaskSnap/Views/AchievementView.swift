import SwiftUI

struct AchievementView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedAchievement: Achievement?
    @State private var selectedCategory: AchievementCategory?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Header
                    progressHeader
                    
                    // Category Filter
                    categoryFilter
                    
                    // Achievement Sections by Category
                    if let selected = selectedCategory {
                        // Show only selected category
                        categorySection(category: selected)
                    } else {
                        // Show all categories
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            categorySection(category: category)
                        }
                    }
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
        VStack(spacing: 16) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemBackground), lineWidth: 16)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progressPercentage)
                    .stroke(
                        AngularGradient(
                            colors: [Color("achievementBronze"), Color("achievementSilver"), Color("achievementGold"), Color("achievementBronze")],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: progressPercentage)
                
                VStack(spacing: 2) {
                    Text("\(achievementManager.unlockedCount)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("/ \(achievementManager.totalCount)")
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
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All button
                CategoryFilterButton(
                    title: "All",
                    icon: "square.grid.2x2",
                    count: achievementManager.unlockedCount,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation {
                        selectedCategory = nil
                    }
                }
                
                // Category buttons
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    let count = achievementManager.unlockedByCategory[category] ?? 0
                    let total = achievementManager.achievements(for: category).count
                    
                    CategoryFilterButton(
                        title: category.rawValue,
                        icon: category.icon,
                        count: count,
                        total: total,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Category Section
    private func categorySection(category: AchievementCategory) -> some View {
        let achievements = achievementManager.achievements(for: category)
        let unlockedCount = achievements.filter(\.isUnlocked).count
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(.accentColor)
                
                Text(category.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text("\(unlockedCount)/\(achievements.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                        .onTapGesture {
                            selectedAchievement = achievement
                        }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let count: Int
    var total: Int? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                
                if let total = total {
                    Text("\(count)/\(total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color(achievement.color).opacity(0.2) : Color(.tertiarySystemBackground))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 28))
                    .foregroundColor(achievement.isUnlocked ? Color(achievement.color) : .secondary)
                
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(Color("doneColor"))
                        .background(Color.white)
                        .clipShape(Circle())
                        .offset(x: 18, y: 18)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .offset(x: 18, y: 18)
                }
            }
            
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                .lineLimit(2)
                .frame(height: 36)
            
            if !achievement.isUnlocked && achievement.progress > 0 {
                ProgressView(value: achievement.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(achievement.color)))
                    .frame(height: 4)
                    
                Text("\(Int(achievement.progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .frame(height: 140)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
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
                    
                    if achievement.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(Color("doneColor"))
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
                
                // Category Badge
                HStack {
                    Image(systemName: achievement.category.icon)
                    Text(achievement.category.rawValue)
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(20)
                
                // Status
                if achievement.isUnlocked {
                    VStack(spacing: 8) {
                        Text("Unlocked! 🎉")
                            .font(.headline)
                            .foregroundColor(Color("doneColor"))
                        
                        if let date = achievement.unlockedAt {
                            Text("on \(date.formattedString())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color("doneColor").opacity(0.1))
                    .cornerRadius(12)
                } else {
                    VStack(spacing: 8) {
                        Text("Progress: \(Int(achievement.progress * 100))%")
                            .font(.headline)
                        
                        ProgressView(value: achievement.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(achievement.color)))
                            .frame(height: 8)
                            .padding(.horizontal)
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

// MARK: - Preview
#Preview {
    AchievementView()
}
