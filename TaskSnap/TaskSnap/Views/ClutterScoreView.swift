import SwiftUI

struct ClutterScoreView: View {
    let image: UIImage
    @StateObject private var viewModel = ClutterScoreViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Image Preview
                    imagePreviewSection
                    
                    if viewModel.isAnalyzing {
                        analyzingSection
                    } else if let result = viewModel.result {
                        resultSection(result: result)
                    } else if let error = viewModel.errorMessage {
                        errorSection(error: error)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Clutter Analysis")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.analyze(image: image)
            }
        }
    }
    
    // MARK: - Image Preview Section
    private var imagePreviewSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 250)
                .cornerRadius(16)
            
            // Analysis badge
            if let result = viewModel.result {
                Text(result.category.emoji)
                    .font(.system(size: 40))
                    .background(Circle().fill(Color.white).frame(width: 60, height: 60))
                    .offset(x: -10, y: -10)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Analyzing Section
    private var analyzingSection: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing your space...")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                AnalysisStepRow(
                    icon: "eye",
                    text: "Detecting edges and shapes",
                    isComplete: false
                )
                AnalysisStepRow(
                    icon: "paintpalette",
                    text: "Analyzing color patterns",
                    isComplete: false
                )
                AnalysisStepRow(
                    icon: "square.grid.2x2",
                    text: "Estimating clutter density",
                    isComplete: false
                )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Result Section
    private func resultSection(result: ClutterScoreResult) -> some View {
        VStack(spacing: 20) {
            // Score Card
            scoreCard(result: result)
            
            // Category Description
            categoryDescription(result: result)
            
            // Details
            detailsSection(result: result)
            
            // Suggestions
            suggestionsSection(result: result)
            
            // Action Button
            Button {
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Got It!")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(result.category.color))
                .cornerRadius(16)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Score Card
    private func scoreCard(result: ClutterScoreResult) -> some View {
        VStack(spacing: 16) {
            // Score Circle
            ZStack {
                Circle()
                    .stroke(Color(result.category.color).opacity(0.2), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: CGFloat(result.score) / 100.0)
                    .stroke(
                        Color(result.category.color),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: result.score)
                
                VStack(spacing: 4) {
                    Text("\(result.score)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color(result.category.color))
                    
                    Text("/ 100")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Category Label
            HStack(spacing: 8) {
                Text(result.category.emoji)
                    .font(.title2)
                Text(result.category.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .foregroundColor(Color(result.category.color))
            
            // Confidence
            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield")
                    .font(.caption)
                Text("\(Int(result.confidence * 100))% confidence")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    // MARK: - Category Description
    private func categoryDescription(result: ClutterScoreResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What This Means")
                .font(.headline)
            
            Text(result.category.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Details Section
    private func detailsSection(result: ClutterScoreResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis Details")
                .font(.headline)
            
            VStack(spacing: 12) {
                DetailRow(
                    icon: "square.stack.3d.up",
                    label: "Estimated Items",
                    value: "~\(result.details.objectCountEstimate)",
                    color: .blue
                )
                
                DetailRow(
                    icon: "line.3.horizontal",
                    label: "Edge Density",
                    value: "\(Int(result.details.edgeDensity * 100))%",
                    color: .orange
                )
                
                DetailRow(
                    icon: "paintpalette",
                    label: "Color Variance",
                    value: "\(Int(result.details.colorVariance * 100))%",
                    color: .purple
                )
                
                DetailRow(
                    icon: "square.grid.2x2",
                    label: "Texture Complexity",
                    value: "\(Int(result.details.textureComplexity * 100))%",
                    color: .green
                )
                
                // Dominant Colors
                HStack {
                    Image(systemName: "paintbrush")
                        .foregroundColor(.pink)
                        .frame(width: 24)
                    
                    Text("Dominant Colors")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(result.details.dominantColors, id: \.self) { color in
                            Text(color)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(colorBadgeColor(color))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Suggestions Section
    private func suggestionsSection(result: ClutterScoreResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recommendations")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(result.suggestions, id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color(result.category.color))
                            .padding(.top, 2)
                        
                        Text(suggestion)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Error Section
    private func errorSection(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Analysis Failed")
                .font(.headline)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                viewModel.analyze(image: image)
            } label: {
                Text("Try Again")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Helpers
    private func colorBadgeColor(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red.opacity(0.2)
        case "orange": return .orange.opacity(0.2)
        case "yellow": return .yellow.opacity(0.2)
        case "green": return .green.opacity(0.2)
        case "cyan", "blue": return .blue.opacity(0.2)
        case "purple": return .purple.opacity(0.2)
        case "white", "gray": return .gray.opacity(0.2)
        case "black": return .black.opacity(0.2)
        default: return .secondary.opacity(0.2)
        }
    }
}

// MARK: - Analysis Step Row
struct AnalysisStepRow: View {
    let icon: String
    let text: String
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                ProgressView()
                    .scaleEffect(0.6)
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Clutter Score Button (for integration)
struct ClutterScoreButton: View {
    let image: UIImage
    @State private var showingAnalysis = false
    
    var body: some View {
        Button {
            showingAnalysis = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "eye")
                Text("Analyze Clutter")
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.purple)
            .cornerRadius(20)
        }
        .sheet(isPresented: $showingAnalysis) {
            ClutterScoreView(image: image)
        }
    }
}

#Preview {
    ClutterScoreView(image: UIImage(systemName: "photo")!)
}
