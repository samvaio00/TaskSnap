import Foundation
import CoreImage
import Vision
import UIKit

// MARK: - Smart Category Suggestion
struct SmartCategorySuggestion {
    let category: TaskCategory
    let confidence: Double
    let reason: String
}

// MARK: - Smart Category Service
class SmartCategoryService {
    static let shared = SmartCategoryService()
    
    private init() {}
    
    // MARK: - Analyze Image for Category
    func suggestCategory(for image: UIImage, title: String? = nil) -> [SmartCategorySuggestion] {
        var suggestions: [SmartCategorySuggestion] = []
        
        // 1. Vision-based object detection (if available)
        let visionSuggestions = analyzeWithVision(image: image)
        suggestions.append(contentsOf: visionSuggestions)
        
        // 2. Color-based analysis
        let colorSuggestions = analyzeColors(image: image)
        suggestions.append(contentsOf: colorSuggestions)
        
        // 3. Title-based analysis (if title provided)
        if let title = title, !title.isEmpty {
            let titleSuggestions = analyzeTitle(title)
            suggestions.append(contentsOf: titleSuggestions)
        }
        
        // 4. Context-based (time of day, user's history)
        let contextSuggestions = analyzeContext()
        suggestions.append(contentsOf: contextSuggestions)
        
        // Merge and rank suggestions
        return mergeAndRankSuggestions(suggestions)
    }
    
    // MARK: - Vision Analysis
    private func analyzeWithVision(image: UIImage) -> [SmartCategorySuggestion] {
        var suggestions: [SmartCategorySuggestion] = []
        
        guard let cgImage = image.cgImage else { return suggestions }
        
        // Use Core Image for feature detection
        let ciImage = CIImage(cgImage: cgImage)
        
        // Detect edges and shapes
        if let edgeDetector = CIFilter(name: "CIEdges") {
            edgeDetector.setValue(ciImage, forKey: kCIInputImageKey)
            edgeDetector.setValue(2.0, forKey: "inputIntensity")
            
            if let outputImage = edgeDetector.outputImage {
                // Analyze edge patterns for object detection
                let context = CIContext()
                if let cgOutput = context.createCGImage(outputImage, from: outputImage.extent) {
                    let edgeDensity = calculateEdgeDensity(cgOutput)
                    
                    // High edge density might indicate "fix" or "organize" tasks
                    if edgeDensity > 0.15 {
                        suggestions.append(SmartCategorySuggestion(
                            category: .fix,
                            confidence: edgeDensity * 0.7,
                            reason: "Detected complex shapes that may need repair"
                        ))
                    }
                }
            }
        }
        
        // Detect text (receipts, documents)
        if #available(iOS 13.0, *) {
            let textRequest = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation],
                      !observations.isEmpty else { return }
                
                // If text detected, likely "buy" or "organize"
                suggestions.append(SmartCategorySuggestion(
                    category: .buy,
                    confidence: 0.6,
                    reason: "Detected text (shopping list or receipt)"
                ))
            }
            textRequest.recognitionLevel = .fast
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([textRequest])
        }
        
        return suggestions
    }
    
    // MARK: - Color Analysis
    private func analyzeColors(image: UIImage) -> [SmartCategorySuggestion] {
        guard let cgImage = image.cgImage else { return [] }
        
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        // Downsample for analysis
        let scale = min(100.0 / ciImage.extent.width, 100.0 / ciImage.extent.height)
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgScaled = context.createCGImage(scaledImage, from: scaledImage.extent),
              let data = cgScaled.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return [] }
        
        let width = cgScaled.width
        let height = cgScaled.height
        let bytesPerPixel = 4
        
        var colorDistribution: [String: Int] = [:]
        var brightnessSum: Double = 0
        var sampleCount = 0
        
        for y in stride(from: 0, to: height, by: 4) {
            for x in stride(from: 0, to: width, by: 4) {
                let offset = (y * width + x) * bytesPerPixel
                let r = ptr[offset]
                let g = ptr[offset + 1]
                let b = ptr[offset + 2]
                
                let colorCategory = categorizeColor(r: r, g: g, b: b)
                colorDistribution[colorCategory, default: 0] += 1
                
                let brightness = (Double(r) + Double(g) + Double(b)) / 3.0
                brightnessSum += brightness
                sampleCount += 1
            }
        }
        
        var suggestions: [SmartCategorySuggestion] = []
        let totalPixels = sampleCount
        
        // Analyze color patterns
        if let dominantColor = colorDistribution.max(by: { $0.value < $1.value }) {
            switch dominantColor.key {
            case "green":
                let confidence = Double(dominantColor.value) / Double(totalPixels)
                suggestions.append(SmartCategorySuggestion(
                    category: .health,
                    confidence: confidence * 0.6,
                    reason: "Green tones detected (plants, health items)"
                ))
                
            case "blue", "cyan":
                let confidence = Double(dominantColor.value) / Double(totalPixels)
                suggestions.append(SmartCategorySuggestion(
                    category: .clean,
                    confidence: confidence * 0.5,
                    reason: "Blue tones detected (cleaning supplies, water)"
                ))
                
            case "orange", "brown":
                let confidence = Double(dominantColor.value) / Double(totalPixels)
                suggestions.append(SmartCategorySuggestion(
                    category: .organize,
                    confidence: confidence * 0.5,
                    reason: "Earthy tones detected (wood, storage)"
                ))
                
            case "white", "gray":
                let confidence = Double(dominantColor.value) / Double(totalPixels)
                suggestions.append(SmartCategorySuggestion(
                    category: .clean,
                    confidence: confidence * 0.7,
                    reason: "Light colors suggest cleaning or laundry"
                ))
                
            default:
                break
            }
        }
        
        // Average brightness analysis
        let avgBrightness = brightnessSum / Double(sampleCount)
        if avgBrightness < 80 { // Dark image
            suggestions.append(SmartCategorySuggestion(
                category: .fix,
                confidence: 0.4,
                reason: "Dark areas may indicate repair needs"
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Title Analysis
    private func analyzeTitle(_ title: String) -> [SmartCategorySuggestion] {
        let lowerTitle = title.lowercased()
        var suggestions: [SmartCategorySuggestion] = []
        
        // Keywords for each category
        let keywords: [TaskCategory: [String]] = [
            .clean: ["clean", "wash", "laundry", "vacuum", "dust", "wipe", "mop", "scrub", "tidy", "sanitize"],
            .fix: ["fix", "repair", "broken", "leak", "replace", "install", "mount", "assemble", "tool"],
            .buy: ["buy", "purchase", "shop", "groceries", "order", "get", "pick up", "delivery", "amazon"],
            .organize: ["organize", "sort", "file", "declutter", "arrange", "put away", "storage", "closet", "drawer"],
            .health: ["health", "doctor", "dentist", "appointment", "medicine", "gym", "workout", "exercise", "diet"],
            .work: ["work", "email", "call", "meeting", "project", "deadline", "report", "presentation"]
        ]
        
        for (category, words) in keywords {
            for word in words {
                if lowerTitle.contains(word) {
                    suggestions.append(SmartCategorySuggestion(
                        category: category,
                        confidence: 0.9,
                        reason: "Keyword '\(word)' detected in title"
                    ))
                    break // Only count once per category
                }
            }
        }
        
        return suggestions
    }
    
    // MARK: - Context Analysis
    private func analyzeContext() -> [SmartCategorySuggestion] {
        var suggestions: [SmartCategorySuggestion] = []
        
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Time-based suggestions
        if hour < 9 {
            suggestions.append(SmartCategorySuggestion(
                category: .health,
                confidence: 0.3,
                reason: "Morning tasks often involve health routines"
            ))
        } else if hour >= 9 && hour < 17 {
            suggestions.append(SmartCategorySuggestion(
                category: .work,
                confidence: 0.4,
                reason: "Work hours - likely work-related task"
            ))
        } else if hour >= 17 && hour < 20 {
            suggestions.append(SmartCategorySuggestion(
                category: .buy,
                confidence: 0.3,
                reason: "Evening errands often involve shopping"
            ))
        } else {
            suggestions.append(SmartCategorySuggestion(
                category: .clean,
                confidence: 0.3,
                reason: "Evening/night tasks often involve home maintenance"
            ))
        }
        
        // Day of week
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 { // Weekend
            suggestions.append(SmartCategorySuggestion(
                category: .organize,
                confidence: 0.3,
                reason: "Weekends are popular for organizing projects"
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Merge and Rank
    private func mergeAndRankSuggestions(_ suggestions: [SmartCategorySuggestion]) -> [SmartCategorySuggestion] {
        // Group by category and sum confidences
        var merged: [TaskCategory: (confidence: Double, reasons: [String])] = [:]
        
        for suggestion in suggestions {
            if let existing = merged[suggestion.category] {
                merged[suggestion.category] = (
                    confidence: existing.confidence + suggestion.confidence,
                    reasons: existing.reasons + [suggestion.reason]
                )
            } else {
                merged[suggestion.category] = (
                    confidence: suggestion.confidence,
                    reasons: [suggestion.reason]
                )
            }
        }
        
        // Normalize and create final suggestions
        let maxConfidence = merged.values.map { $0.confidence }.max() ?? 1.0
        
        var finalSuggestions: [SmartCategorySuggestion] = []
        for (category, data) in merged {
            let normalizedConfidence = min(1.0, data.confidence / maxConfidence)
            let primaryReason = data.reasons.first ?? "Based on image analysis"
            
            finalSuggestions.append(SmartCategorySuggestion(
                category: category,
                confidence: normalizedConfidence,
                reason: primaryReason
            ))
        }
        
        // Sort by confidence
        return finalSuggestions.sorted { $0.confidence > $1.confidence }
    }
    
    // MARK: - Helpers
    private func calculateEdgeDensity(_ cgImage: CGImage) -> Double {
        let width = cgImage.width
        let height = cgImage.height
        
        guard let data = cgImage.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0 }
        
        var edgePixels = 0
        let bytesPerPixel = 4
        let threshold: UInt8 = 30
        
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let offset = (y * width + x) * bytesPerPixel
                
                // Simple edge detection using gradient
                let leftOffset = (y * width + (x - 1)) * bytesPerPixel
                let rightOffset = (y * width + (x + 1)) * bytesPerPixel
                let upOffset = ((y - 1) * width + x) * bytesPerPixel
                let downOffset = ((y + 1) * width + x) * bytesPerPixel
                
                let hDiff = abs(Int(ptr[offset]) - Int(ptr[rightOffset]))
                let vDiff = abs(Int(ptr[offset]) - Int(ptr[downOffset]))
                
                if hDiff > Int(threshold) || vDiff > Int(threshold) {
                    edgePixels += 1
                }
            }
        }
        
        return Double(edgePixels) / Double(width * height)
    }
    
    private func categorizeColor(r: UInt8, g: UInt8, b: UInt8) -> String {
        let rf = Double(r) / 255.0
        let gf = Double(g) / 255.0
        let bf = Double(b) / 255.0
        
        let maxVal = max(rf, gf, bf)
        let minVal = min(rf, gf, bf)
        let delta = maxVal - minVal
        
        if delta < 0.1 {
            if maxVal < 0.2 { return "black" }
            if maxVal > 0.8 { return "white" }
            return "gray"
        }
        
        if maxVal == rf {
            return "red"
        } else if maxVal == gf {
            return "green"
        } else {
            return "blue"
        }
    }
}

// MARK: - Smart Category View
struct SmartCategorySuggestionView: View {
    let image: UIImage
    let onSelect: (TaskCategory) -> Void
    @State private var suggestions: [SmartCategorySuggestion] = []
    @State private var isAnalyzing = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.accentColor)
                Text("AI Suggestions")
                    .font(.headline)
                
                Spacer()
                
                if isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if isAnalyzing {
                Text("Analyzing image for category suggestions...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if suggestions.isEmpty {
                Text("No strong category detected. Choose manually.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(suggestions.prefix(3), id: \.category) { suggestion in
                        Button {
                            onSelect(suggestion.category)
                        } label: {
                            HStack {
                                Image(systemName: suggestion.category.icon)
                                    .foregroundColor(Color(suggestion.category.color))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.category.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(suggestion.reason)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                // Confidence bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 40, height: 4)
                                        
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.accentColor)
                                            .frame(width: 40 * CGFloat(suggestion.confidence), height: 4)
                                    }
                                }
                                .frame(width: 40, height: 4)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .onAppear {
            analyzeImage()
        }
    }
    
    private func analyzeImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let results = SmartCategoryService.shared.suggestCategory(for: image)
            
            DispatchQueue.main.async {
                suggestions = results
                isAnalyzing = false
            }
        }
    }
}
