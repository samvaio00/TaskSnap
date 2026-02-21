import SwiftUI

struct BackupRestoreView: View {
    @StateObject private var backupService = BackupService.shared
    @State private var showingCreateBackup = false
    @State private var showingRestoreConfirmation = false
    @State private var selectedBackup: BackupMetadata?
    @State private var showingDeleteConfirmation = false
    @State private var showingInfoSheet = false
    
    var body: some View {
        List {
            // iCloud Status Section
            iCloudStatusSection
            
            // Create Backup Section
            createBackupSection
            
            // Automatic Backup Settings
            automaticBackupSection
            
            // Existing Backups
            backupsListSection
            
            // Info Section
            infoSection
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingInfoSheet) {
            BackupInfoView()
        }
        .alert("Restore Backup?", isPresented: $showingRestoreConfirmation, presenting: selectedBackup) { backup in
            Button("Cancel", role: .cancel) {}
            Button("Restore", role: .destructive) {
                restoreBackup(backup)
            }
        } message: { backup in
            Text("This will replace all current data with data from \(backup.formattedDate). This cannot be undone.")
        }
        .alert("Delete Backup?", isPresented: $showingDeleteConfirmation, presenting: selectedBackup) { backup in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                backupService.deleteBackup(backup.id)
            }
        } message: { backup in
            Text("This backup from \(backup.formattedDate) will be permanently deleted.")
        }
        .alert("Error", isPresented: .constant(backupService.lastError != nil)) {
            Button("OK") {
                backupService.lastError = nil
            }
        } message: {
            if let error = backupService.lastError {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            backupService.loadBackupList()
        }
    }
    
    // MARK: - iCloud Status Section
    private var iCloudStatusSection: some View {
        Section {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iCloudStatusColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "icloud")
                        .font(.title2)
                        .foregroundColor(iCloudStatusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("iCloud Drive")
                        .font(.headline)
                    
                    Text(iCloudStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: iCloudStatusIcon)
                    .foregroundColor(iCloudStatusColor)
            }
            .padding(.vertical, 4)
        }
    }
    
    private var iCloudStatusColor: Color {
        backupService.isICloudAvailable() ? .green : .orange
    }
    
    private var iCloudStatusText: String {
        backupService.isICloudAvailable() ? "Connected and ready" : "Not available - check Settings"
    }
    
    private var iCloudStatusIcon: String {
        backupService.isICloudAvailable() ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }
    
    private func isICloudAvailable() -> Bool {
        FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
    }
    
    // MARK: - Create Backup Section
    private var createBackupSection: some View {
        Section {
            VStack(spacing: 16) {
                // Last backup info
                if let lastDate = backupService.lastBackupDate {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Last backup: \(lastDate.formattedString(style: .medium))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                // Create button
                Button {
                    showingCreateBackup = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise.icloud")
                        Text("Backup Now")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
                .disabled(backupService.isBackingUp || !backupService.isICloudAvailable())
                .sheet(isPresented: $showingCreateBackup) {
                    CreateBackupView()
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("Manual Backup")
        } footer: {
            Text("Create a backup of all your tasks, settings, and data to iCloud Drive.")
        }
    }
    
    // MARK: - Automatic Backup Section
    private var automaticBackupSection: some View {
        Section {
            Toggle("Automatic Weekly Backup", isOn: .constant(true))
            
            HStack {
                Text("Next scheduled backup")
                Spacer()
                Text(calculateNextBackupDate())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Automatic Backup")
        } footer: {
            Text("TaskSnap automatically creates a backup once per week when you open the app.")
        }
    }
    
    private func calculateNextBackupDate() -> String {
        guard let lastDate = backupService.lastBackupDate else {
            return "Next app launch"
        }
        
        let calendar = Calendar.current
        if let nextDate = calendar.date(byAdding: .day, value: 7, to: lastDate) {
            let formatter = RelativeDateTimeFormatter()
            return formatter.localizedString(for: nextDate, relativeTo: Date())
        }
        
        return "Unknown"
    }
    
    // MARK: - Backups List Section
    private var backupsListSection: some View {
        Section {
            if backupService.backups.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "icloud.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No Backups Yet")
                        .font(.headline)
                    
                    Text("Create your first backup to protect your data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(backupService.backups) { backup in
                    BackupRow(backup: backup)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBackup = backup
                            showingRestoreConfirmation = true
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                selectedBackup = backup
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        } header: {
            Text("Available Backups")
        } footer: {
            Text("Tap a backup to restore your data to that point in time. Swipe left to delete.")
        }
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        Section {
            Button {
                showingInfoSheet = true
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                    Text("About Backups")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func restoreBackup(_ backup: BackupMetadata) {
        backupService.restoreBackup(backup.id) { result in
            switch result {
            case .success:
                // Post notification to refresh UI
                NotificationCenter.default.post(name: .cloudKitSyncCompleted, object: nil)
            case .failure:
                // Error is already set in lastError
                break
            }
        }
    }
}

// MARK: - Backup Row
struct BackupRow: View {
    let backup: BackupMetadata
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "doc.zipper")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Label("\(backup.totalTasks) tasks", systemImage: "checklist")
                    Text("•")
                    Text(backup.formattedSize)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "iphone")
                        .font(.caption2)
                    Text(backup.deviceName)
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if backup.isAutomatic {
                Text("Auto")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Backup View
struct CreateBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var backupService = BackupService.shared
    @State private var backupComplete = false
    @State private var backupURL: URL?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                if backupService.isBackingUp {
                    // Progress view
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .stroke(Color.accentColor.opacity(0.2), lineWidth: 12)
                                .frame(width: 150, height: 150)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(backupService.backupProgress))
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear, value: backupService.backupProgress)
                            
                            VStack {
                                Text("\(Int(backupService.backupProgress * 100))%")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                Text("Complete")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text("Creating Backup...")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Please keep the app open")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if backupComplete {
                    // Success view
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 150, height: 150)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Backup Complete!")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Your data has been safely backed up to iCloud")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    }
                } else {
                    // Error view
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 150, height: 150)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.red)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Backup Failed")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let error = backupService.lastError {
                                Text(error.localizedDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button {
                                dismiss()
                            } label: {
                                Text("Cancel")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(12)
                            }
                            
                            Button {
                                startBackup()
                            } label: {
                                Text("Try Again")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.accentColor)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Create Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !backupService.isBackingUp {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                if !backupService.isBackingUp && !backupComplete {
                    startBackup()
                }
            }
        }
    }
    
    private func startBackup() {
        backupComplete = false
        backupService.createBackup(automatic: false) { result in
            switch result {
            case .success(let url):
                backupURL = url
                backupComplete = true
            case .failure:
                backupComplete = false
            }
        }
    }
}

// MARK: - Backup Info View
struct BackupInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: "icloud.and.arrow.up")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        
                        Text("About Backups")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    
                    // Info sections
                    InfoSection(
                        icon: "checkmark.shield",
                        title: "What's Backed Up",
                        content: "All your tasks, focus sessions, shared spaces, achievements, and settings are included in the backup. Photos you attach to tasks are also backed up."
                    )
                    
                    InfoSection(
                        icon: "icloud",
                        title: "Where Backups Are Stored",
                        content: "Backups are stored in your iCloud Drive. They don't count against your iCloud storage limit for the app itself, but they do use your general iCloud storage space."
                    )
                    
                    InfoSection(
                        icon: "arrow.clockwise",
                        title: "Automatic Backups",
                        content: "TaskSnap automatically creates a backup once per week when you open the app. You can also create manual backups anytime."
                    )
                    
                    InfoSection(
                        icon: "arrow.uturn.backward",
                        title: "Restoring Data",
                        content: "When you restore from a backup, all current data is replaced with the backup data. This cannot be undone. Make sure you want to replace your current data before restoring."
                    )
                    
                    InfoSection(
                        icon: "number.circle",
                        title: "Backup Limits",
                        content: "TaskSnap keeps your 10 most recent backups. Older backups are automatically deleted to save space."
                    )
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("")
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

// MARK: - Info Section
struct InfoSection: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }
            
            Text(content)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        BackupRestoreView()
    }
}
