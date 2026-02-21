import SwiftUI

struct PatternInsightsView: View {
    @StateObject private var patternService = PatternRecognitionService.shared
    @State private var showingDetail: PatternInsight?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Insights List
                if patternService.isAnalyzing {
                    analyzingView
                } else if patternService.insights.isEmpty {
                    emptyStateView
                } else {
                    insightsList
                }
                
                // Refresh Button
                refreshSection
            }
            .padding(.vertical)
        }
        .navigationTitle("AI Insights")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            patternService.analyzePatterns()
        }
        .sheet(item: $showingDetail) { insight in
            InsightDetailView(insight: insight)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundStyle(.purple)
            }
            
            VStack(spacing: 8) {
                Text("Your Patterns")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("AI-powered insights from your task completion data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let lastDate = patternService.lastAnalysisDate {
                Text("Last updated: \(lastDate.formattedString(style: .short))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    // MARK: - Analyzing View
    private var analyzingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing your patterns...")
                .font(.headline)
            
            Text("Looking at your task completion times, categories, and habits to generate personalized insights.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("Not Enough Data Yet")
                .font(.headline)
            
            Text("Complete a few more tasks and I'll analyze your productivity patterns!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("📊 Need at least 5 completed tasks")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Insights List
    private var insightsList: some View {
        VStack(spacing: 12) {
            // Top Insights Section
            if let topInsight = patternService.insights.first {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Insight")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    TopInsightCard(insight: topInsight) {
                        showingDetail = topInsight
                    }
                    .padding(.horizontal)
                }
            }
            
            // All Insights Grid
            VStack(alignment: .leading, spacing: 12) {
                Text("All Insights")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 12) {
                    ForEach(patternService.insights) { insight in
                        InsightRow(insight: insight) {
                            showingDetail = insight
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Refresh Section
    private var refreshSection: some View {
        Button {
            patternService.analyzePatterns(force: true)
        } label: {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Refresh Analysis")
            }
            .font(.subheadline)
            .foregroundColor(.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(20)
        }
        .disabled(patternService.isAnalyzing)
        .padding(.top, 8)
    }
}

// MARK: - Top Insight Card
struct TopInsightCard: View {
    let insight: PatternInsight
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(insight.type.color).opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: insight.type.icon)
                            .font(.title2)
                            .foregroundColor(Color(insight.type.color))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.type.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(insight.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Confidence badge
                    ConfidenceBadge(confidence: insight.confidence)
                }
                
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let metric = insight.metric {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption)
                            .foregroundColor(Color(insight.type.color))
                        
                        Text(metric)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(insight.type.color))
                        
                        Spacer()
                        
                        if let trend = insight.trend {
                            HStack(spacing: 4) {
                                Image(systemName: trend.icon)
                                Text("\(trend == .up ? "+" : "")")
                            }
                            .font(.caption)
                            .foregroundColor(trend.color)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(insight.type.color).opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Insight Row
struct InsightRow: View {
    let insight: PatternInsight
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(insight.type.color).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: insight.type.icon)
                        .font(.title3)
                        .foregroundColor(Color(insight.type.color))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(insight.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Trend or Metric
                if let trend = insight.trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
                } else if let metric = insight.metric {
                    Text(metric)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Confidence Badge
struct ConfidenceBadge: View {
    let confidence: Double
    
    var level: String {
        if confidence >= 0.8 { return "High" }
        if confidence >= 0.6 { return "Good" }
        return "Fair"
    }
    
    var color: Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .yellow
    }
    
    var body: some View {
        Text(level)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(8)
    }
}

// MARK: - Insight Detail View
struct InsightDetailView: View {
    let insight: PatternInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color(insight.type.color).opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: insight.type.icon)
                                .font(.system(size: 50))
                                .foregroundColor(Color(insight.type.color))
                        }
                        
                        VStack(spacing: 8) {
                            Text(insight.type.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(insight.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            ConfidenceBadge(confidence: insight.confidence)
                        }
                    }
                    .padding(.top)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What We Found")
                            .font(.headline)
                        
                        Text(insight.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Detail
                    VStack(alignment: .leading, spacing: 12) {
                        Text("The Details")
                            .font(.headline)
                        
                        Text(insight.detail)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if let metric = insight.metric {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(Color(insight.type.color))
                                Text("Metric: \(metric)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .padding(.top, 4)
                        }
                        
                        if let trend = insight.trend {
                            HStack {
                                Image(systemName: trend.icon)
                                    .foregroundColor(trend.color)
                                Text("Trend: \(trend == .up ? "Improving" : trend == .down ? "Declining" : "Stable")")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(trend.color)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Recommendation
                    if let recommendation = insight.recommendation {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("Recommendation")
                                    .font(.headline)
                            }
                            
                            Text(recommendation)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Generated date
                    Text("Generated: \(insight.generatedAt.formattedString(style: .full))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding(.bottom)
            }
            .navigationTitle("Insight Details")
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
    NavigationView {
        PatternInsightsView()
    }
}
