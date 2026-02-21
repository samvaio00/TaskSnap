import SwiftUI
import CloudKit
import CoreData

struct SettingsView: View {
    @StateObject private var syncManager = SyncManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    @StateObject private var soundManager = SoundEffectManager.shared
    @State private var showingICloudAlert = false
    @State private var showingMigrationAlert = false
    @State private var showingDisableConfirmation = false
    
    // Notification settings
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("dailyRemindersEnabled") private var dailyRemindersEnabled = true
    @AppStorage("achievementAlertsEnabled") private var achievementAlertsEnabled = true
    
    // Animation settings
    @AppStorage("reduceMotionEnabled") private var reduceMotionEnabled = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - iCloud Sync Section
                Section {
                    // iCloud Sync Toggle with AnimatedToggle
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: syncManager.syncStatus.icon)
                                .font(.title2)
                                .foregroundColor(Color(syncManager.syncStatus.color))
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("iCloud Sync")
                                    .font(.headline)
                                
                                Text(syncStatusDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Use AnimatedToggle for iCloud Sync
                            AnimatedToggle(
                                isOn: $syncManager.isSyncEnabled,
                                size: .regular,
                                showIcons: true,
                                onColor: .blue,
                                hapticEnabled: hapticsEnabled
                            )
                            .onChange(of: syncManager.isSyncEnabled) { oldValue, newValue in
                                if newValue {
                                    handleEnableSync()
                                } else {
                                    showingDisableConfirmation = true
                                }
                            }
                            .accessibilityLabel("iCloud Sync")
                            .accessibilityHint("Toggle to sync tasks across all your devices")
                            .accessibilityValue(syncManager.isSyncEnabled ? "Enabled" : "Disabled")
                        }
                        
                        if syncManager.isSyncEnabled,
                           let lastSync = syncManager.lastSyncDate {
                            Text("Last synced: \(lastSync.formattedString(style: .medium))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("Last synced \(lastSync.formattedString(style: .medium))")
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .contain)
                    
                    // Manual Sync Button with PressableButtonStyle
                    if syncManager.isSyncEnabled {
                        Button {
                            syncManager.triggerManualSync()
                            if hapticsEnabled {
                                Haptics.shared.buttonTap()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .accessibilityHidden(true)
                                Text("Sync Now")
                            }
                        }
                        .disabled(syncManager.syncStatus == .syncing)
                        .pressableButton(type: .secondary, hapticEnabled: hapticsEnabled)
                        .accessibilityLabel("Sync Now")
                        .accessibilityHint("Manually trigger synchronization with iCloud")
                        .accessibilityValue(syncManager.syncStatus == .syncing ? "Syncing in progress" : "Ready to sync")
                    }
                } header: {
                    Text("Cloud & Sync")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("Enable iCloud Sync to access your tasks across all your devices. Your data is securely stored in your iCloud account.")
                }
                
                // MARK: - iCloud Account Status
                if !syncManager.canEnableSync {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("iCloud Not Available")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(syncManager.iCloudStatusDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("iCloud Not Available: \(syncManager.iCloudStatusDescription)")
                    }
                }
                
                // MARK: - Notifications Section
                Section {
                    SettingsToggleRow(
                        icon: "bell.badge.fill",
                        iconColor: .orange,
                        title: "Enable Notifications",
                        description: "Receive task reminders and alerts",
                        isOn: $notificationsEnabled,
                        onColor: .orange,
                        hapticEnabled: hapticsEnabled,
                        onToggle: { isOn in
                            if isOn {
                                NotificationManager.shared.requestAuthorization()
                            }
                        }
                    )
                    
                    if notificationsEnabled {
                        SettingsToggleRow(
                            icon: "calendar.badge.clock",
                            iconColor: .blue,
                            title: "Daily Reminders",
                            description: "Get reminded to complete tasks",
                            isOn: $dailyRemindersEnabled,
                            size: .small,
                            onColor: .blue,
                            hapticEnabled: hapticsEnabled
                        )
                        
                        SettingsToggleRow(
                            icon: "trophy.fill",
                            iconColor: .yellow,
                            title: "Achievement Alerts",
                            description: "Celebrate when you earn badges",
                            isOn: $achievementAlertsEnabled,
                            size: .small,
                            onColor: .yellow,
                            hapticEnabled: hapticsEnabled
                        )
                    }
                } header: {
                    Text("Notifications")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("Manage notification preferences for TaskSnap.")
                }
                
                // MARK: - Animation & Haptics Section
                Section {
                    SettingsToggleRow(
                        icon: "hand.tap.fill",
                        iconColor: .purple,
                        title: "Haptic Feedback",
                        description: "Feel taps and gestures",
                        isOn: $hapticsEnabled,
                        onColor: .purple,
                        hapticEnabled: false // Don't haptic when toggling haptics
                    )
                    
                    // Sound Effects Toggle
                    SoundEffectsSettingsRow(hapticsEnabled: hapticsEnabled)
                    
                    SettingsToggleRow(
                        icon: "figure.walk.motion",
                        iconColor: .green,
                        title: "Reduce Motion",
                        description: "Minimize animations",
                        isOn: $reduceMotionEnabled,
                        onColor: .green,
                        hapticEnabled: hapticsEnabled,
                        onToggle: { isOn in
                            // Apply the setting immediately
                            UserDefaults.standard.set(isOn, forKey: "reduceMotion")
                        }
                    )
                } header: {
                    Text("Accessibility")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("Adjust animation and feedback settings to match your preferences.")
                }
                
                // MARK: - Backup & Restore Section
                Section {
                    NavigationLink(destination: BackupRestoreView()) {
                        HStack {
                            Image(systemName: "arrow.clockwise.icloud")
                                .font(.title2)
                                .frame(width: 40)
                                .foregroundColor(.accentColor)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Backup & Restore")
                                    .font(.headline)
                                
                                if let lastBackup = BackupService.shared.lastBackupDate {
                                    Text("Last backup: \(lastBackup.formattedString(style: .short))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Never backed up")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .accessibilityLabel("Backup & Restore")
                    .accessibilityHint("Navigate to backup and restore options")
                    .accessibilityValue(BackupService.shared.lastBackupDate != nil ? "Last backup: \(BackupService.shared.lastBackupDate!.formattedString(style: .short))" : "Never backed up")
                } header: {
                    Text("Data")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("Create backups to protect your data and restore from previous backups if needed.")
                }
                
                // MARK: - Themes Section
                Section {
                    NavigationLink(destination: ThemePickerView()) {
                        HStack {
                            Image(systemName: themeManager.selectedTheme.icon)
                                .font(.title2)
                                .frame(width: 40)
                                .foregroundColor(themeManager.selectedTheme.confettiColors.first)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Celebration Theme")
                                    .font(.headline)
                                    .accessibleText(lineLimit: 1)
                                
                                Text(themeManager.selectedTheme.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .accessibleText(lineLimit: 1)
                            }
                        }
                    }
                    .accessibilityLabel("Celebration Theme")
                    .accessibilityHint("Navigate to choose celebration animation theme")
                    .accessibilityValue("Current theme: \(themeManager.selectedTheme.displayName)")
                    
                    // Animation Intensity Picker
                    NavigationLink(destination: AnimationSettingsView()) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .frame(width: 40)
                                .foregroundColor(.accentColor)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Animation Intensity")
                                    .font(.headline)
                                    .accessibleText(lineLimit: 1)
                                
                                Text(animationIntensityLabel)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .accessibleText(lineLimit: 1)
                            }
                        }
                    }
                    .accessibilityLabel("Animation Intensity")
                    .accessibilityHint("Navigate to adjust celebration animation settings")
                    .accessibilityValue(animationIntensityLabel)
                } header: {
                    Text("Personalization")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("Unlock more themes by completing tasks and building streaks")
                }
                
                // MARK: - Accessibility Section
                Section {
                    // Reduce Motion Toggle
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(isOn: $accessibilitySettings.reduceMotion) {
                            HStack {
                                Image(systemName: accessibilitySettings.reduceMotion ? "figure.walk" : "figure.run")
                                    .font(.title2)
                                    .frame(width: 40)
                                    .foregroundColor(.accentColor)
                                    .accessibilityHidden(true)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Reduce Motion")
                                        .font(.headline)
                                        .accessibleText(lineLimit: 1)
                                    
                                    if accessibilitySettings.reduceMotionOverridden {
                                        Text("Custom override (system: \(UIAccessibility.isReduceMotionEnabled ? "on" : "off"))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .accessibleText(lineLimit: 1)
                                    } else {
                                        Text("Using system setting")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .accessibleText(lineLimit: 1)
                                    }
                                }
                            }
                        }
                        .tint(.accentColor)
                        .onChange(of: accessibilitySettings.reduceMotion) { _, _ in
                            accessibilitySettings.reduceMotionOverridden = true
                        }
                        
                        if accessibilitySettings.reduceMotionOverridden {
                            Button {
                                accessibilitySettings.resetReduceMotionToSystemDefault()
                            } label: {
                                Text("Reset to System Default")
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                            }
                            .accessibilityLabel("Reset reduce motion to system default")
                        }
                    }
                    .accessibilityElement(children: .contain)
                    
                    // High Contrast Toggle
                    Toggle(isOn: $accessibilitySettings.highContrast) {
                        HStack {
                            Image(systemName: "circle.righthalf.filled")
                                .font(.title2)
                                .frame(width: 40)
                                .foregroundColor(.accentColor)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("High Contrast")
                                    .font(.headline)
                                    .accessibleText(lineLimit: 1)
                                
                                Text("Enhanced visibility with stronger colors")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .accessibleText(lineLimit: 2)
                            }
                        }
                    }
                    .tint(.accentColor)
                    .accessibilityLabel("High Contrast")
                    .accessibilityHint("Toggle high contrast mode for enhanced visibility")
                    .accessibilityValue(accessibilitySettings.highContrast ? "Enabled" : "Disabled")
                    
                    // Button Shapes Toggle
                    Toggle(isOn: $accessibilitySettings.buttonShapes) {
                        HStack {
                            Image(systemName: "square.dashed")
                                .font(.title2)
                                .frame(width: 40)
                                .foregroundColor(.accentColor)
                                .accessibilityHidden(true)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Button Shapes")
                                    .font(.headline)
                                    .accessibleText(lineLimit: 1)
                                
                                Text("Show borders around interactive elements")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .accessibleText(lineLimit: 2)
                            }
                        }
                    }
                    .tint(.accentColor)
                    .accessibilityLabel("Button Shapes")
                    .accessibilityHint("Toggle visible borders around buttons for clarity")
                    .accessibilityValue(accessibilitySettings.buttonShapes ? "Enabled" : "Disabled")
                } header: {
                    Text("Accessibility")
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("These settings help make TaskSnap more accessible. Reduce Motion respects your system setting by default but can be customized.")
                }
                
                // MARK: - About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("App version 1.0")
                    
                    Link(destination: URL(string: "https://tasksnap.app/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityLabel("Privacy Policy")
                    .accessibilityHint("Opens privacy policy in browser")
                    .accessibilityAddTraits(.isLink)
                    
                    Link(destination: URL(string: "https://tasksnap.app/support")!) {
                        HStack {
                            Text("Support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityLabel("Support")
                    .accessibilityHint("Opens support page in browser")
                    .accessibilityAddTraits(.isLink)
                } header: {
                    Text("About")
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .navigationTitle("Settings")
            .alert("iCloud Required", isPresented: $showingICloudAlert) {
                Button("OK", role: .cancel) {
                    syncManager.isSyncEnabled = false
                }
            } message: {
                Text("Please sign in to iCloud in your device settings to enable sync.")
            }
            .alert("Sync Your Existing Data?", isPresented: $showingMigrationAlert) {
                Button("Not Now", role: .cancel) {
                    // Just enable sync for future data
                }
                Button("Sync Now") {
                    triggerMigration()
                }
            } message: {
                Text("Would you like to sync your existing tasks to iCloud?")
            }
            .alert("Disable iCloud Sync?", isPresented: $showingDisableConfirmation) {
                Button("Cancel", role: .cancel) {
                    syncManager.isSyncEnabled = true
                }
                .pressableButton(type: .secondary, hapticEnabled: hapticsEnabled)
                
                Button("Disable", role: .destructive) {
                    syncManager.disableSync()
                }
                .pressableButton(type: .destructive, hapticEnabled: hapticsEnabled)
            } message: {
                Text("Your data will remain on this device but won't sync with iCloud anymore.")
            }
        }
    }
    
    // MARK: - Helpers
    
    private var syncStatusDescription: String {
        if syncManager.isSyncEnabled {
            return syncManager.syncStatus.rawValue
        } else {
            return syncManager.canEnableSync ? "Tap to enable" : syncManager.iCloudStatusDescription
        }
    }
    
    private var animationIntensityLabel: String {
        let intensity = UserDefaults.standard.string(forKey: "animationIntensity") ?? "full"
        switch intensity {
        case "minimal": return "Minimal (haptics only)"
        case "reduced": return "Reduced (2x speed)"
        default: return "Full animations"
        }
    }
    
    private func handleEnableSync() {
        guard syncManager.canEnableSync else {
            showingICloudAlert = true
            return
        }
        
        // Show migration dialog if there are existing tasks
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            if count > 0 {
                showingMigrationAlert = true
            }
        } catch {
            print("Error counting tasks: \(error)")
        }
        
        syncManager.enableSync()
    }
    
    private func triggerMigration() {
        // Migration would happen automatically when CloudKit is enabled
        // The store will sync existing data
        syncManager.triggerManualSync()
    }
}

// MARK: - Sound Effects Settings Row
struct SoundEffectsSettingsRow: View {
    @StateObject private var soundManager = SoundEffectManager.shared
    let hapticsEnabled: Bool
    @State private var showingSoundTest = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2)
                    .frame(width: 40)
                    .foregroundColor(.cyan)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sound Effects")
                        .font(.headline)
                        .accessibleText(lineLimit: 1)
                    
                    Text("Audio feedback for actions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibleText(lineLimit: 1)
                }
                
                Spacer()
                
                AnimatedToggle(
                    isOn: $soundManager.isSoundEnabled,
                    size: .regular,
                    showIcons: true,
                    onColor: .cyan,
                    hapticEnabled: hapticsEnabled
                )
            }
            
            if soundManager.isSoundEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: $soundManager.volume,
                            in: 0...1,
                            step: 0.1
                        )
                        .tint(.cyan)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Volume: \(Int(soundManager.volume * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    showingSoundTest = true
                } label: {
                    HStack {
                        Image(systemName: "play.circle")
                        Text("Test Sounds")
                    }
                    .font(.subheadline)
                    .foregroundColor(.cyan)
                }
                .pressableButton(type: .ghost, hapticEnabled: hapticsEnabled)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .sheet(isPresented: $showingSoundTest) {
            SoundTestView()
        }
    }
}

// MARK: - Sound Test View
struct SoundTestView: View {
    @StateObject private var soundManager = SoundEffectManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("UI Sounds")) {
                    ForEach([
                        SoundEffectManager.SoundEffect.buttonTap,
                        .taskComplete,
                        .success,
                        .error,
                        .cameraShutter
                    ]) { effect in
                        SoundTestRow(effect: effect)
                    }
                }
                
                Section(header: Text("Celebration Sounds")) {
                    ForEach([
                        SoundEffectManager.SoundEffect.achievement,
                        .streakMilestone
                    ]) { effect in
                        SoundTestRow(effect: effect)
                    }
                }
                
                Section(header: Text("Gesture Sounds")) {
                    ForEach([
                        SoundEffectManager.SoundEffect.swipe,
                        .pop
                    ]) { effect in
                        SoundTestRow(effect: effect)
                    }
                }
                
                Section(footer: Text("Using system sounds as placeholders. Custom sounds can be added to the app bundle.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Test Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SoundTestRow: View {
    let effect: SoundEffectManager.SoundEffect
    @StateObject private var soundManager = SoundEffectManager.shared
    
    var body: some View {
        Button {
            soundManager.testSound(effect)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(effect.displayName)
                        .font(.headline)
                    Text(effect.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)
            }
        }
        .pressableButton(type: .ghost)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
