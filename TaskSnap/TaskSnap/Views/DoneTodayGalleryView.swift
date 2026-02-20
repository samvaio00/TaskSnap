import SwiftUI

struct DoneTodayGalleryView: View {
    @ObservedObject var gamificationViewModel: GamificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    headerSection
                    
                    // Gallery Grid
                    gallerySection
                }
                .padding(.vertical)
            }
            .navigationTitle("Done Today")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(Color("doneColor").opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color("doneColor"))
            }
            
            // Count
            VStack(spacing: 4) {
                Text("\(gamificationViewModel.todayTasks.count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Color("doneColor"))
                
                if gamificationViewModel.todayTasks.count == 1 {
                    Text("Task Completed Today")
                        .font(.title3)
                        .foregroundColor(.secondary)
                } else {
                    Text("Tasks Completed Today")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Motivational Message
            if gamificationViewModel.todayTasks.count == 0 {
                Text("Complete your first task today!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else if gamificationViewModel.todayTasks.count >= 3 {
                Text("Amazing productivity today! 🔥")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
            } else {
                Text("Keep the momentum going!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    // MARK: - Gallery Section
    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Victory Gallery")
                    .font(.headline)
                
                Spacer()
                
                Text("\(gamificationViewModel.todayTasks.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if gamificationViewModel.todayTasks.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No completed tasks yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Complete tasks to see your victories here!")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
            } else {
                // Gallery Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(gamificationViewModel.todayTasks) { task in
                        TodayTaskCard(task: task)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Today Task Card
struct TodayTaskCard: View {
    let task: TaskEntity
    @State private var showDetail = false
    
    var body: some View {
        Button {
            showDetail = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Before/After Images
                ZStack {
                    // Background (After image if available, otherwise before)
                    if let afterImage = task.afterImage {
                        Image(uiImage: afterImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else if let beforeImage = task.beforeImage {
                        Image(uiImage: beforeImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(task.taskCategory.color).opacity(0.2))
                            .frame(height: 140)
                        
                        Image(systemName: task.taskCategory.icon)
                            .font(.system(size: 40))
                            .foregroundColor(Color(task.taskCategory.color))
                    }
                    
                    // Done Badge
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
                    .padding(8)
                    
                    // Has After Image indicator
                    if task.afterImage != nil {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Image(systemName: "photo.stack")
                                        .font(.caption)
                                    Text("Before/After")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                            }
                            .padding(8)
                        }
                    }
                }
                
                // Task Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title ?? "Untitled")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: task.taskCategory.icon)
                            .font(.caption)
                            .foregroundColor(Color(task.taskCategory.color))
                        Text(task.taskCategory.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let completedAt = task.completedAt {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundColor(Color("doneColor"))
                            Text("Done at \(completedAt.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            TodayTaskDetailSheet(task: task)
        }
    }
}

// MARK: - Today Task Detail Sheet
struct TodayTaskDetailSheet: View {
    let task: TaskEntity
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Before/After Comparison
                    VStack(spacing: 16) {
                        Text("Your Transformation")
                            .font(.headline)
                        
                        if task.afterImage != nil {
                            BeforeAfterSlider(
                                beforeImage: task.beforeImage,
                                afterImage: task.afterImage
                            )
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else if let beforeImage = task.beforeImage {
                            VStack(spacing: 8) {
                                Image(uiImage: beforeImage)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(16)
                                
                                Text("Before (no after photo)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                    
                    // Task Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text(task.title ?? "Untitled Task")
                            .font(.title)
                            .fontWeight(.bold)
                        
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
                        
                        if let description = task.taskDescription, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color("doneColor"))
                            Text("Completed today at \(task.completedAt?.formatted(date: .omitted, time: .shortened) ?? "Unknown")")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                }
                .padding()
            }
            .navigationTitle("Task Details")
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
    DoneTodayGalleryView(gamificationViewModel: GamificationViewModel())
}
