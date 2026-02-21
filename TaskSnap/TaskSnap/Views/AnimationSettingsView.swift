import SwiftUI

struct AnimationSettingsView: View {
    @AppStorage("animationIntensity") private var animationIntensity = "full"
    @AppStorage("hapticIntensity") private var hapticIntensity = "strong"
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Animation Intensity")
                        .font(.headline)
                    
                    Text("Choose how animations appear when you complete tasks and earn achievements")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                ForEach(AnimationIntensity.allCases) { intensity in
                    Button {
                        animationIntensity = intensity.rawValue
                        Haptics.shared.selectionChanged()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(intensity.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text(intensity.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if animationIntensity == intensity.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Haptic Feedback")
                        .font(.headline)
                    
                    Text("Adjust the strength of vibration feedback")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                ForEach(HapticIntensity.allCases) { intensity in
                    Button {
                        hapticIntensity = intensity.rawValue
                        Haptics.shared.selectionChanged()
                        // Test the haptic
                        testHaptic(intensity)
                    } label: {
                        HStack {
                            Text(intensity.displayName)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if hapticIntensity == intensity.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Section {
                Button("Test Animation") {
                    AnimationManager.shared.play(.badgeUnlock)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.accentColor)
            } footer: {
                Text("Test the current animation settings")
            }
        }
        .navigationTitle("Animation Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func testHaptic(_ intensity: HapticIntensity) {
        switch intensity {
        case .strong:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .gentle:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .off:
            break
        }
    }
}

// MARK: - Animation Intensity Enum
enum AnimationIntensity: String, CaseIterable, Identifiable {
    case full = "full"
    case reduced = "reduced"
    case minimal = "minimal"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .full: return "Full Animations"
        case .reduced: return "Reduced Speed"
        case .minimal: return "Minimal (Haptics Only)"
        }
    }
    
    var description: String {
        switch self {
        case .full: return "All animations play at full length with audio"
        case .reduced: return "Animations play at 2x speed"
        case .minimal: return "Only haptic feedback, no video animations"
        }
    }
}

// MARK: - Haptic Intensity Enum
enum HapticIntensity: String, CaseIterable, Identifiable {
    case strong = "strong"
    case gentle = "gentle"
    case off = "off"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .strong: return "Strong"
        case .gentle: return "Gentle"
        case .off: return "Off"
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        AnimationSettingsView()
    }
}
