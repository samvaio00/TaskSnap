import SwiftUI

// MARK: - Environment Key for Reduce Motion
private struct ReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = UIAccessibility.isReduceMotionEnabled
}

extension EnvironmentValues {
    var reduceMotion: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
}

// MARK: - Circular Progress View
/// Animated circular progress ring with gradient stroke and percentage display
struct CircularProgressView: View {
    let progress: Double // 0.0 to 1.0
    var lineWidth: CGFloat = 8
    var colors: [Color] = [.accentColor, .accentColor.opacity(0.7)]
    var showPercentage: Bool = true
    var size: CGFloat = 80
    
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var animatedProgress: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color(.systemFill), lineWidth: lineWidth)
            
            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: colors,
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .rotationEffect(.degrees(reduceMotion ? 0 : rotation))
            
            // Percentage text
            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(Int(progress * 100)) percent")
        .accessibilityValue(progress >= 1.0 ? "Complete" : "In progress")
        .onAppear {
            animateProgress()
        }
        .onChange(of: progress) { _ in
            animateProgress()
        }
    }
    
    private func animateProgress() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animatedProgress = min(max(progress, 0), 1)
        }
        
        if !reduceMotion {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - TaskSnap Loading Indicator
/// Custom branded loader with camera icon and pulsing animation
struct TaskSnapLoadingIndicator: View {
    var text: String = "Loading"
    var showText: Bool = true
    var size: CGFloat = 60
    
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var isPulsing = false
    @State private var shutterRotation: Double = 0
    @State private var dotCount = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Camera icon with shutter effect
            ZStack {
                // Outer ring (shutter)
                Circle()
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 3)
                    .frame(width: size, height: size)
                
                // Rotating shutter segments
                if !reduceMotion {
                    ForEach(0..<6) { index in
                        ShutterSegment(index: index, total: 6, rotation: shutterRotation)
                    }
                }
                
                // Camera icon
                Image(systemName: "camera.fill")
                    .font(.system(size: size * 0.35, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                    .opacity(isPulsing ? 0.8 : 1.0)
            }
            .frame(width: size * 1.2, height: size * 1.2)
            
            // Loading text with animated ellipsis
            if showText {
                HStack(spacing: 0) {
                    Text(text)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Animated dots
                    if !reduceMotion {
                        Text(String(repeating: ".", count: dotCount))
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(width: 30, alignment: .leading)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(text)...")
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        guard !reduceMotion else { return }
        
        // Pulsing animation
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            isPulsing = true
        }
        
        // Shutter rotation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            shutterRotation = 360
        }
        
        // Ellipsis animation
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

// MARK: - Shutter Segment
private struct ShutterSegment: View {
    let index: Int
    let total: Int
    let rotation: Double
    
    var body: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(width: 4, height: 12)
            .offset(y: -28)
            .rotationEffect(.degrees(Double(index) * (360.0 / Double(total)) + rotation))
    }
}

// MARK: - Skeleton Loading View
/// Shimmer effect for content placeholders
struct SkeletonLoadingView: View {
    var lineCount: Int = 3
    var lineHeight: CGFloat = 12
    var spacing: CGFloat = 8
    var showImagePlaceholder: Bool = true
    
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            if showImagePlaceholder {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemFill))
                    .frame(height: 120)
                    .overlay(shimmerOverlay)
            }
            
            ForEach(0..<lineCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemFill))
                    .frame(height: lineHeight)
                    .frame(maxWidth: index == lineCount - 1 ? 0.6 : 1.0, alignment: .leading)
                    .overlay(shimmerOverlay)
            }
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
    }
    
    private var shimmerOverlay: some View {
        GeometryReader { geometry in
            if !reduceMotion {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.5),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width * 0.5)
                .offset(x: -geometry.size.width * 0.5 + phase * geometry.size.width * 1.5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Skeleton Card
/// Skeleton placeholder for task cards
struct SkeletonCard: View {
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemFill))
                .frame(height: 100)
                .overlay(shimmerOverlay)
            
            // Title placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemFill))
                .frame(height: 16)
                .frame(width: 100)
                .overlay(shimmerOverlay)
            
            // Date placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemFill))
                .frame(height: 12)
                .frame(width: 60)
                .overlay(shimmerOverlay)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
    }
    
    private var shimmerOverlay: some View {
        GeometryReader { geometry in
            if !reduceMotion {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.4),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width * 0.5)
                .offset(x: -geometry.size.width * 0.5 + phase * geometry.size.width * 1.5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Linear Progress Bar
/// Animated linear progress with spring animation and segment support
struct LinearProgressBar: View {
    let progress: Double // 0.0 to 1.0
    var height: CGFloat = 8
    var colors: [Color] = [.accentColor]
    var showSegments: Bool = false
    var segmentCount: Int = 4
    var backgroundColor: Color = Color(.systemFill)
    
    @Environment(\.reduceMotion) private var reduceMotion
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                
                // Segments
                if showSegments {
                    HStack(spacing: 2) {
                        ForEach(0..<segmentCount, id: \.self) { index in
                            let segmentProgress = Double(index) / Double(segmentCount)
                            let isFilled = animatedProgress >= segmentProgress + (1.0 / Double(segmentCount))
                            
                            RoundedRectangle(cornerRadius: (height - 4) / 2)
                                .fill(isFilled ? gradient : Color.clear)
                                .frame(maxWidth: .infinity)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isFilled)
                        }
                    }
                    .padding(2)
                } else {
                    // Continuous fill
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(gradient)
                        .frame(width: geometry.size.width * animatedProgress, height: height)
                        .animation(reduceMotion ? .easeInOut(duration: 0.3) : .spring(response: 0.6, dampingFraction: 0.8), value: animatedProgress)
                }
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress bar")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
        .onAppear {
            animateProgress()
        }
        .onChange(of: progress) { _ in
            animateProgress()
        }
    }
    
    private var gradient: LinearGradient {
        if colors.count == 1 {
            return LinearGradient(
                colors: [colors[0]],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func animateProgress() {
        animatedProgress = min(max(progress, 0), 1)
    }
}

// MARK: - Multi-Step Progress Bar
/// Shows progress through multiple steps with labels
struct MultiStepProgressBar: View {
    let steps: [String]
    let currentStep: Int
    
    @Environment(\.reduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress line with dots
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack(spacing: 0) {
                        // Dot
                        ZStack {
                            Circle()
                                .fill(stepColor(for: index))
                                .frame(width: 16, height: 16)
                            
                            if index < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            } else if index == currentStep {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .scaleEffect(index == currentStep && !reduceMotion ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentStep)
                        
                        // Line (except for last item)
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? Color.accentColor : Color(.systemFill))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            
            // Labels
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    Text(steps[index])
                        .font(.caption)
                        .foregroundColor(stepTextColor(for: index))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(currentStep + 1) of \(steps.count): \(steps[currentStep])")
    }
    
    private func stepColor(for index: Int) -> Color {
        if index < currentStep {
            return .accentColor
        } else if index == currentStep {
            return .accentColor
        } else {
            return Color(.systemFill)
        }
    }
    
    private func stepTextColor(for index: Int) -> Color {
        if index <= currentStep {
            return .primary
        } else {
            return .secondary
        }
    }
}

// MARK: - Upload Progress View
/// Specialized progress view for uploads/downloads
struct UploadProgressView: View {
    let progress: Double
    let fileName: String?
    let fileSize: String?
    var onCancel: (() -> Void)?
    
    @Environment(\.reduceMotion) private var reduceMotion
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Uploading...")
                        .font(.headline)
                    
                    if let fileName = fileName {
                        Text(fileName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let fileSize = fileSize {
                        Text(fileSize)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            
            LinearProgressBar(
                progress: progress,
                height: 6,
                colors: [.accentColor, .accentColor.opacity(0.7)]
            )
            
            if let onCancel = onCancel {
                Button("Cancel", role: .cancel, action: onCancel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Uploading \(fileName ?? "file"): \(Int(progress * 100)) percent complete")
    }
}

// MARK: - Pressable Button Style
/// Button style with press animation for retry buttons
struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    var opacity: Double = 0.9
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? opacity : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview("Loading Indicators") {
    ScrollView {
        VStack(spacing: 40) {
            // Circular Progress
            VStack {
                Text("Circular Progress")
                    .font(.headline)
                CircularProgressView(progress: 0.65, size: 100)
            }
            
            // TaskSnap Loader
            VStack {
                Text("TaskSnap Loader")
                    .font(.headline)
                TaskSnapLoadingIndicator()
            }
            
            // Skeleton Loading
            VStack {
                Text("Skeleton Loading")
                    .font(.headline)
                SkeletonLoadingView()
                    .frame(height: 150)
            }
            
            // Linear Progress
            VStack {
                Text("Linear Progress")
                    .font(.headline)
                LinearProgressBar(progress: 0.6)
            }
            
            // Multi-Step Progress
            VStack {
                Text("Multi-Step Progress")
                    .font(.headline)
                MultiStepProgressBar(
                    steps: ["Capture", "Review", "Save"],
                    currentStep: 1
                )
            }
            
            // Upload Progress
            VStack {
                Text("Upload Progress")
                    .font(.headline)
                UploadProgressView(
                    progress: 0.45,
                    fileName: "photo_task_001.jpg",
                    fileSize: "2.4 MB",
                    onCancel: {}
                )
            }
            
            // Skeleton Card
            VStack {
                Text("Skeleton Card")
                    .font(.headline)
                SkeletonCard()
                    .frame(width: 160)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Dark Mode") {
    CircularProgressView(progress: 0.75)
        .preferredColorScheme(.dark)
}
