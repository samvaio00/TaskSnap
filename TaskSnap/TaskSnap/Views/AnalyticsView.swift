import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var selectedTab = 0
    @State private var showingPatternInsights = false
    
    let tabs = ["Overview", "Time", "Categories"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Analytics", selection: $selectedTab) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        Text(tabs[index])
                            .tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    OverviewTab(viewModel: viewModel)
                        .tag(0)
                    
                    TimeAnalyticsTab(viewModel: viewModel)
                        .tag(1)
                    
                    CategoryAnalyticsTab(viewModel: viewModel)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Analytics")
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingPatternInsights = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                            Text("Insights")
                                .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingPatternInsights) {
                PatternInsightsView()
            }
        }
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stats Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard2(
                        title: "Total Tasks",
                        value: "\(viewModel.totalStats.totalTasks)",
                        icon: "checkmark.circle.fill",
                        color: .blue
                    )
                    
                    StatCard2(
                        title: "Completed",
                        value: "\(viewModel.totalStats.completedTasks)",
                        icon: "checkmark.seal.fill",
                        color: Color("doneColor")
                    )
                    
                    StatCard2(
                        title: "Success Rate",
                        value: "\(viewModel.totalStats.completionPercentage)%",
                        icon: "chart.pie.fill",
                        color: .orange
                    )
                    
                    StatCard2(
                        title: "Best Streak",
                        value: "\(viewModel.totalStats.longestStreak)",
                        icon: "flame.fill",
                        color: .red
                    )
                }
                .padding(.horizontal)
                
                // Weekly Trend Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Trend")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if #available(iOS 16.0, *) {
                        Chart(viewModel.weeklyTrend) { data in
                            BarMark(
                                x: .value("Week", data.week),
                                y: .value("Tasks", data.count)
                            )
                            .foregroundStyle(Color.accentColor.gradient)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                        .padding()
                    } else {
                        // Fallback for iOS 15
                        WeeklyTrendBarChart(data: viewModel.weeklyTrend)
                            .frame(height: 200)
                            .padding()
                    }
                }
                .padding(.vertical)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Time Analytics Tab
struct TimeAnalyticsTab: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Day of Week Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Productive Days")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if #available(iOS 16.0, *) {
                        Chart(viewModel.completionByDayOfWeek) { data in
                            BarMark(
                                x: .value("Day", data.day),
                                y: .value("Tasks", data.count)
                            )
                            .foregroundStyle(by: .value("Day", data.day))
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                        .padding()
                    } else {
                        DayOfWeekBarChart(data: viewModel.completionByDayOfWeek)
                            .frame(height: 200)
                            .padding()
                    }
                }
                .padding(.vertical)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Time of Day Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Productive Times")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if #available(iOS 16.0, *) {
                        Chart(viewModel.completionByHour) { data in
                            SectorMark(
                                angle: .value("Tasks", data.count),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Time", data.period))
                        }
                        .frame(height: 250)
                        .padding()
                    } else {
                        TimeOfDayBarChart(data: viewModel.completionByHour)
                            .frame(height: 250)
                            .padding()
                    }
                }
                .padding(.vertical)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Insights
                if let mostProductiveDay = viewModel.completionByDayOfWeek.max(by: { $0.count < $1.count })?.day,
                   let mostProductiveTime = viewModel.completionByHour.max(by: { $0.count < $1.count })?.period {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Insights")
                            .font(.headline)
                        
                        Text("You're most productive on **\(mostProductiveDay)s** during the **\(mostProductiveTime)**.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Category Analytics Tab
struct CategoryAnalyticsTab: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Category Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tasks by Category")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if #available(iOS 16.0, *) {
                        Chart(viewModel.completionByCategory) { data in
                            BarMark(
                                x: .value("Count", data.count),
                                y: .value("Category", data.category)
                            )
                            .foregroundStyle(Color(data.color))
                            .cornerRadius(4)
                        }
                        .frame(height: min(CGFloat(viewModel.completionByCategory.count * 50), 300))
                        .padding()
                    } else {
                        CategoryBarChart(data: viewModel.completionByCategory)
                            .frame(height: min(CGFloat(viewModel.completionByCategory.count * 50), 300))
                            .padding()
                    }
                }
                .padding(.vertical)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Category List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category Breakdown")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.completionByCategory) { data in
                        HStack {
                            Circle()
                                .fill(Color(data.color))
                                .frame(width: 12, height: 12)
                            
                            Text(data.category)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(data.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.vertical)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Stat Card
struct StatCard2: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - iOS 15 Fallback Charts
struct WeeklyTrendBarChart: View {
    let data: [WeeklyData]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            ForEach(data) { item in
                VStack {
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(height: max(CGFloat(item.count) / CGFloat(maxCount) * geometry.size.height, 4))
                    }
                    
                    Text(item.week)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(-45))
                }
            }
        }
    }
    
    private var maxCount: Int {
        max(data.map { $0.count }.max() ?? 1, 1)
    }
}

struct DayOfWeekBarChart: View {
    let data: [DayOfWeekData]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data) { item in
                VStack {
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(height: max(CGFloat(item.count) / CGFloat(maxCount) * geometry.size.height, 4))
                    }
                    
                    Text(item.day)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var maxCount: Int {
        max(data.map { $0.count }.max() ?? 1, 1)
    }
}

struct TimeOfDayBarChart: View {
    let data: [HourData]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            ForEach(data) { item in
                VStack {
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange)
                            .frame(height: max(CGFloat(item.count) / CGFloat(maxCount) * geometry.size.height, 4))
                    }
                    
                    Text(item.period)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    private var maxCount: Int {
        max(data.map { $0.count }.max() ?? 1, 1)
    }
}

struct CategoryBarChart: View {
    let data: [CategoryData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(data) { item in
                HStack {
                    Text(item.category)
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)
                    
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(item.color))
                            .frame(width: max(CGFloat(item.count) / CGFloat(maxCount) * geometry.size.width, 4))
                    }
                    
                    Text("\(item.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 30, alignment: .trailing)
                }
                .frame(height: 30)
            }
        }
    }
    
    private var maxCount: Int {
        max(data.map { $0.count }.max() ?? 1, 1)
    }
}

// MARK: - Preview
#Preview {
    AnalyticsView()
}
