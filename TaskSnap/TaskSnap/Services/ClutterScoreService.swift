import Foundation
import UIKit
import CoreImage
import Vision

// MARK: - Clutter Score Result
struct ClutterScoreResult {
    let score: Int // 0-100, higher = more cluttered/messy
    let category: ClutterCategory
    let confidence: Double
    let details: ClutterDetails
    let suggestions: [String]
    
    enum ClutterCategory: String, CaseIterable {
        case minimal = "minimal"
        case light = "light"
        case moderate = "moderate"
        case heavy = "heavy"
        case extreme = "extreme"
        
        var displayName: String {
            switch self {
            case .minimal: return "Minimal Clutter"
            case .light: return "Light Clutter"
            case .moderate: return "Moderate Clutter"
            case .heavy: return "Heavy Clutter"
            case .extreme: return "Extreme Clutter"
            }
        }
        
        var emoji: String {
            switch self {
            case .minimal: return "✨"
            case .light: return "🙂"
            case .moderate: return "😅"
            case .heavy: return "😰"
            case .extreme: return "😱"
            }
        }
        
        var color: String {
            switch self {
            case .minimal: return "green"
            case .light: return "blue"
            case .moderate: return "orange"
            case .heavy: return "red"
            case .extreme: return "purple"
            }
        }
        
        var description: String {
            switch self {
            case .minimal:
                return "This space is nearly organized! Just a few touches needed."
            case .light:
                return "Some items out of place, but manageable. You got this!"
            case .moderate:
                return "Noticeable clutter. Breaking into smaller tasks will help."
            case .heavy:
                return "Significant clutter detected. Focus on one area at a time."
            case .extreme:
                return "Major clutter! Consider this a multi-session project."
            }
        }
    }
}

// MARK: - Clutter Details
struct ClutterDetails {
    let edgeDensity: Double // 0-1
    let colorVariance: Double // 0-1
    let textureComplexity: Double // 0-1
    let objectCountEstimate: Int
    let dominantColors: [String]
}

// MARK: - Clutter Score Service
class ClutterScoreService {
    static let shared = ClutterScoreService()
    
    private init() {}
    
    // MARK: - Analyze Image
    func analyzeImage(_ image: UIImage, completion: @escaping (ClutterScoreResult?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = image.cgImage else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Perform image analysis
            let edgeDensity = self.calculateEdgeDensity(cgImage)
            let colorVariance = self.calculateColorVariance(cgImage)
            let textureComplexity = self.calculateTextureComplexity(cgImage)
            let dominantColors = self.extractDominantColors(cgImage)
            
            // Estimate object count based on edge density and texture
            let objectEstimate = self.estimateObjectCount(
                edgeDensity: edgeDensity,
                textureComplexity: textureComplexity,
                imageSize: image.size
            )
            
            // Calculate overall clutter score (0-100)
            let rawScore = self.calculateClutterScore(
                edgeDensity: edgeDensity,
                colorVariance: colorVariance,
                textureComplexity: textureComplexity
            )
            
            // Normalize to 0-100
            let normalizedScore = min(100, max(0, Int(rawScore * 100)))
            
            // Determine category
            let category = self.categoryForScore(normalizedScore)
            
            // Calculate confidence based on image quality
            let confidence = self.calculateConfidence(image: image)
            
            // Generate suggestions
            let suggestions = self.generateSuggestions(
                score: normalizedScore,
                category: category,
                objectCount: objectEstimate
            )
            
            let details = ClutterDetails(
                edgeDensity: edgeDensity,
                colorVariance: colorVariance,
                textureComplexity: textureComplexity,
                objectCountEstimate: objectEstimate,
                dominantColors: dominantColors
            )
            
            let result = ClutterScoreResult(
                score: normalizedScore,
                category: category,
                confidence: confidence,
                details: details,
                suggestions: suggestions
            )
            
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    // MARK: - Image Analysis Methods
    
    private func calculateEdgeDensity(_ cgImage: CGImage) -> Double {
        let ciImage = CIImage(cgImage: cgImage)
        
        // Apply edge detection filter
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return 0.5 }
        edgeFilter.setValue(ciImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.0, forKey: "inputIntensity")
        
        guard let outputImage = edgeFilter.outputImage else { return 0.5 }
        
        // Calculate edge pixel ratio
        let extent = outputImage.extent
        let context = CIContext()
        
        guard let cgOutput = context.createCGImage(outputImage, from: extent) else { return 0.5 }
        
        let width = cgOutput.width
        let height = cgOutput.height
        let totalPixels = width * height
        
        guard let data = cgOutput.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0.5 }
        
        var edgePixels = 0
        let bytesPerPixel = 4
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let brightness = (Int(ptr[offset]) + Int(ptr[offset + 1]) + Int(ptr[offset + 2])) / 3
                if brightness > 30 { // Threshold for edge detection
                    edgePixels += 1
                }
            }
        }
        
        return Double(edgePixels) / Double(totalPixels)
    }
    
    private func calculateColorVariance(_ cgImage: CGImage) -> Double {
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent
        let context = CIContext()
        
        // Downsample for faster processing
        let scale = min(100.0 / extent.width, 100.0 / extent.height)
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgScaled = context.createCGImage(scaledImage, from: scaledImage.extent) else { return 0.5 }
        
        let width = cgScaled.width
        let height = cgScaled.height
        
        guard let data = cgScaled.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0.5 }
        
        var totalVariance: Double = 0
        let bytesPerPixel = 4
        var sampleCount = 0
        
        // Sample every 4th pixel for performance
        for y in stride(from: 0, to: height, by: 4) {
            for x in stride(from: 0, to: width, by: 4) {
                let offset = (y * width + x) * bytesPerPixel
                
                // Compare with neighboring pixels
                if x + 4 < width && y + 4 < height {
                    let rightOffset = (y * width + (x + 4)) * bytesPerPixel
                    let downOffset = ((y + 4) * width + x) * bytesPerPixel
                    
                    let rDiff = Double(ptr[offset]) - Double(ptr[rightOffset])
                    let gDiff = Double(ptr[offset + 1]) - Double(ptr[rightOffset + 1])
                    let bDiff = Double(ptr[offset + 2]) - Double(ptr[rightOffset + 2])
                    
                    let variance = (rDiff * rDiff + gDiff * gDiff + bDiff * bDiff) / 3.0
                    totalVariance += variance
                    sampleCount += 1
                }
            }
        }
        
        let averageVariance = sampleCount > 0 ? totalVariance / Double(sampleCount) : 0
        // Normalize to 0-1 range (65535 is max variance for RGB)
        return min(1.0, averageVariance / 5000.0)
    }
    
    private func calculateTextureComplexity(_ cgImage: CGImage) -> Double {
        // Simplified texture analysis using local contrast
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent
        let context = CIContext()
        
        // Apply contrast enhancement to highlight texture
        guard let contrastFilter = CIFilter(name: "CIColorControls") else { return 0.5 }
        contrastFilter.setValue(ciImage, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.5, forKey: kCIInputContrastKey)
        
        guard let outputImage = contrastFilter.outputImage,
              let cgOutput = context.createCGImage(outputImage, from: extent) else { return 0.5 }
        
        let width = cgOutput.width
        let height = cgOutput.height
        
        guard let data = cgOutput.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0.5 }
        
        var complexity: Double = 0
        let bytesPerPixel = 4
        let sampleStep = 8
        var sampleCount = 0
        
        for y in stride(from: sampleStep, to: height - sampleStep, by: sampleStep) {
            for x in stride(from: sampleStep, to: width - sampleStep, by: sampleStep) {
                let offset = (y * width + x) * bytesPerPixel
                
                // Calculate local gradient
                let leftOffset = (y * width + (x - sampleStep)) * bytesPerPixel
                let rightOffset = (y * width + (x + sampleStep)) * bytesPerPixel
                let upOffset = ((y - sampleStep) * width + x) * bytesPerPixel
                let downOffset = ((y + sampleStep) * width + x) * bytesPerPixel
                
                let hGradient = abs(Double(ptr[offset]) - Double(ptr[rightOffset])) +
                               abs(Double(ptr[offset]) - Double(ptr[leftOffset]))
                let vGradient = abs(Double(ptr[offset]) - Double(ptr[downOffset])) +
                               abs(Double(ptr[offset]) - Double(ptr[upOffset]))
                
                complexity += (hGradient + vGradient) / 2.0
                sampleCount += 1
            }
        }
        
        let averageComplexity = sampleCount > 0 ? complexity / Double(sampleCount) : 0
        return min(1.0, averageComplexity / 100.0)
    }
    
    private func extractDominantColors(_ cgImage: CGImage) -> [String] {
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        
        // Downsample
        let extent = ciImage.extent
        let scale = min(50.0 / extent.width, 50.0 / extent.height)
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgScaled = context.createCGImage(scaledImage, from: scaledImage.extent),
              let data = cgScaled.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return ["Unknown"] }
        
        let width = cgScaled.width
        let height = cgScaled.height
        let bytesPerPixel = 4
        
        var colorCounts: [String: Int] = [:]
        
        // Sample colors and bucket them
        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                let offset = (y * width + x) * bytesPerPixel
                let r = ptr[offset]
                let g = ptr[offset + 1]
                let b = ptr[offset + 2]
                
                let colorName = categorizeColor(r: r, g: g, b: b)
                colorCounts[colorName, default: 0] += 1
            }
        }
        
        // Return top 3 colors
        return colorCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }
    
    private func categorizeColor(r: UInt8, g: UInt8, b: UInt8) -> String {
        let rf = Double(r) / 255.0
        let gf = Double(g) / 255.0
        let bf = Double(b) / 255.0
        
        let maxVal = max(rf, gf, bf)
        let minVal = min(rf, gf, bf)
        let delta = maxVal - minVal
        
        // Grayscale
        if delta < 0.1 {
            if maxVal < 0.2 { return "Black" }
            if maxVal > 0.8 { return "White" }
            return "Gray"
        }
        
        // Determine hue
        var hue: Double = 0
        if delta != 0 {
            if maxVal == rf {
                hue = (gf - bf) / delta
                if hue < 0 { hue += 6 }
            } else if maxVal == gf {
                hue = (bf - rf) / delta + 2
            } else {
                hue = (rf - gf) / delta + 4
            }
            hue *= 60
        }
        
        switch hue {
        case 0..<30, 330...360: return "Red"
        case 30..<60: return "Orange"
        case 60..<90: return "Yellow"
        case 90..<150: return "Green"
        case 150..<210: return "Cyan"
        case 210..<270: return "Blue"
        case 270..<330: return "Purple"
        default: return "Unknown"
        }
    }
    
    private func estimateObjectCount(edgeDensity: Double, textureComplexity: Double, imageSize: CGSize) -> Int {
        // Heuristic estimation based on visual complexity
        let areaFactor = sqrt(imageSize.width * imageSize.height) / 100.0
        let complexityFactor = (edgeDensity + textureComplexity) / 2.0
        let estimate = Int(complexityFactor * areaFactor * 10)
        return max(1, min(estimate, 100)) // Clamp between 1-100
    }
    
    private func calculateClutterScore(edgeDensity: Double, colorVariance: Double, textureComplexity: Double) -> Double {
        // Weighted combination of factors
        // Edge density: lots of edges = lots of objects/edges = cluttered
        // Color variance: high variance = many different items = cluttered
        // Texture complexity: complex textures = detailed/disorganized = cluttered
        
        let edgeWeight = 0.4
        let colorWeight = 0.35
        let textureWeight = 0.25
        
        // Apply non-linear scaling to emphasize higher clutter
        let weightedScore = (pow(edgeDensity, 0.7) * edgeWeight) +
                           (pow(colorVariance, 0.8) * colorWeight) +
                           (pow(textureComplexity, 0.6) * textureWeight)
        
        return min(1.0, weightedScore * 1.5) // Scale up slightly
    }
    
    private func categoryForScore(_ score: Int) -> ClutterScoreResult.ClutterCategory {
        switch score {
        case 0..<20: return .minimal
        case 20..<40: return .light
        case 40..<60: return .moderate
        case 60..<80: return .heavy
        default: return .extreme
        }
    }
    
    private func calculateConfidence(image: UIImage) -> Double {
        var confidence = 0.8 // Base confidence
        
        // Reduce confidence for very small images
        let pixelCount = image.size.width * image.size.height * image.scale * image.scale
        if pixelCount < 100000 { // Less than ~300x300
            confidence -= 0.2
        }
        
        // Reduce confidence for blurry images (simplified check)
        // In real implementation, would use proper blur detection
        
        return max(0.4, min(0.95, confidence))
    }
    
    private func generateSuggestions(score: Int, category: ClutterScoreResult.ClutterCategory, objectCount: Int) -> [String] {
        var suggestions: [String] = []
        
        // Base suggestions by category
        switch category {
        case .minimal:
            suggestions.append("Great job maintaining this space!")
            suggestions.append("Just 5-10 minutes of tidying should do it.")
            
        case .light:
            suggestions.append("Start by putting away obvious items that have homes.")
            suggestions.append("Focus on flat surfaces like tables and counters.")
            
        case .moderate:
            suggestions.append("Break this into 15-minute focused sessions.")
            suggestions.append("Start with one category: clothes, papers, or dishes.")
            suggestions.append("Use the 'one-touch' rule: pick it up, put it away.")
            
        case .heavy:
            suggestions.append("This needs a plan! Schedule 30-60 minute sessions.")
            suggestions.append("Start with the area that bothers you most.")
            suggestions.append("Sort items into: Keep, Donate, Trash bins.")
            suggestions.append("Consider body doubling - invite someone to keep you company.")
            
        case .extreme:
            suggestions.append("This is a big project - be kind to yourself!")
            suggestions.append("Break into zones and tackle one zone per day.")
            suggestions.append("Set a timer for 20 minutes - you can stop after that.")
            suggestions.append("Use the Body Doubling room for accountability.")
            suggestions.append("Consider if some items can be donated or discarded.")
        }
        
        // Object count specific
        if objectCount > 50 {
            suggestions.append("With ~\(objectCount) visible items, sorting by category will help.")
        }
        
        return suggestions
    }
}

// MARK: - Clutter Score View Model
class ClutterScoreViewModel: ObservableObject {
    @Published var result: ClutterScoreResult?
    @Published var isAnalyzing = false
    @Published var errorMessage: String?
    
    func analyze(image: UIImage) {
        isAnalyzing = true
        result = nil
        errorMessage = nil
        
        ClutterScoreService.shared.analyzeImage(image) { [weak self] result in
            DispatchQueue.main.async {
                self?.isAnalyzing = false
                if let result = result {
                    self?.result = result
                } else {
                    self?.errorMessage = "Failed to analyze image"
                }
            }
        }
    }
}
