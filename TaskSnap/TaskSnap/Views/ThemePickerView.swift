import SwiftUI

struct ThemePickerView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingPreview = false
    @State private var previewTheme: CelebrationTheme?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Theme Card
                    currentThemeCard
                    
                    // Available Themes
                    themesGrid
                    
                    // Pro Banner
                    if !themeManager.isProUser {
                        proBanner
                    }
                }
                .padding()
            }
            .navigationTitle("Celebration Themes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $previewTheme) { theme in
                ThemePreviewSheet(theme: theme) {
                    showingPreview = false
                    previewTheme = nil
                }
            }
        }
    }
    
    // MARK: - Current Theme Card
    private var currentThemeCard: some View {
        VStack(spacing: 16) {
            Text("Currently Active")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: Array(themeManager.selectedTheme.confettiColors.prefix(3)),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: themeManager.selectedTheme.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(themeManager.selectedTheme.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(themeManager.selectedTheme.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button {
                previewTheme = themeManager.selectedTheme
            } label: {
                Label("Preview", systemImage: "play.circle.fill")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Themes Grid
    private var themesGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Themes")
                .font(.headline)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(CelebrationTheme.allCases) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: themeManager.selectedTheme == theme,
                        isUnlocked: themeManager.isThemeUnlocked(theme),
                        progress: themeManager.themeProgress[theme] ?? 0
                    ) {
                        if themeManager.isThemeUnlocked(theme) {
                            themeManager.selectTheme(theme)
                        }
                    } onPreview: {
                        previewTheme = theme
                    }
                }
            }
        }
    }
    
    // MARK: - Pro Banner
    private var proBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock All Themes")
                        .font(.headline)
                    
                    Text("Get Pro to unlock Diamond, Neon, and all future themes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button {
                // TODO: Show Pro upgrade flow
            } label: {
                Text("Upgrade to Pro")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.1), .orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Theme Card
struct ThemeCard: View {
    let theme: CelebrationTheme
    let isSelected: Bool
    let isUnlocked: Bool
    let progress: Double
    let onSelect: () -> Void
    let onPreview: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isUnlocked ? Array(theme.confettiColors.prefix(3)) : [.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: theme.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isUnlocked ? .white : .gray)
                }
                .overlay(
                    ZStack {
                        if isSelected {
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 3)
                        }
                        
                        if !isUnlocked {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                            
                            Image(systemName: "lock.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.accentColor)
                                .background(Color.white)
                                .clipShape(Circle())
                                .offset(x: 20, y: -20)
                        }
                    }
                )
                
                // Info
                VStack(spacing: 4) {
                    Text(theme.displayName)
                        .font(.subheadline)
                        .fontWeight(isSelected ? .semibold : .medium)
                        .foregroundColor(isUnlocked ? .primary : .secondary)
                    
                    if !isUnlocked {
                        Text(theme.unlockRequirement.displayText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.accentColor)
                                    .frame(width: geometry.size.width * progress, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
            .padding()
            .frame(height: 160)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1.0 : 0.7)
        .contextMenu {
            Button(action: onPreview) {
                Label("Preview", systemImage: "play.circle")
            }
        }
    }
}

// MARK: - Theme Preview Sheet
struct ThemePreviewSheet: View {
    let theme: CelebrationTheme
    let onDismiss: () -> Void
    
    @State private var showConfetti = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                (theme.confettiColors.first ?? Color.gray).opacity(0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Theme Info
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: Array(theme.confettiColors.prefix(3)),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: theme.icon)
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        }
                        
                        Text(theme.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(theme.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Preview Button
                    Button {
                        withAnimation {
                            showConfetti = true
                        }
                        Haptics.shared.taskCompleted()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showConfetti = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Preview Celebration")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: Array(theme.confettiColors.prefix(2)),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    
                    // Close Button
                    Button("Done", action: onDismiss)
                        .padding()
                }
                .padding()
                
                // Confetti Overlay
                if showConfetti {
                    ThemedConfettiView(theme: theme)
                        .ignoresSafeArea()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Themed Confetti View
struct ThemedConfettiView: View {
    let theme: CelebrationTheme
    
    var body: some View {
        // Reuse existing ConfettiView with theme colors
        ConfettiView(reaction: nil)
            .ignoresSafeArea()
    }
}

// MARK: - Preview
#Preview {
    ThemePickerView()
}
