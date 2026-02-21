import Foundation
import CoreData
import CloudKit
import Combine

// MARK: - Sync Manager
@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()
    
    @Published var isSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSyncEnabled, forKey: syncEnabledKey)
            if isSyncEnabled != oldValue {
                handleSyncStateChange()
            }
        }
    }
    
    @Published var syncStatus: SyncStatus = .notStarted
    @Published var lastSyncDate: Date?
    @Published var iCloudAccountStatus: CKAccountStatus = .couldNotDetermine
    
    private let syncEnabledKey = "tasksnap.syncEnabled"
    private var cancellables = Set<AnyCancellable>()
    
    enum SyncStatus: String, Sendable {
        case notStarted = "Not Started"
        case syncing = "Syncing..."
        case synced = "Synced"
        case error = "Sync Error"
        case offline = "Offline"
        
        var icon: String {
            switch self {
            case .notStarted: return "icloud"
            case .syncing: return "arrow.clockwise.icloud"
            case .synced: return "checkmark.icloud"
            case .error: return "exclamationmark.icloud"
            case .offline: return "icloud.slash"
            }
        }
        
        var color: String {
            switch self {
            case .notStarted: return "secondary"
            case .syncing: return "accentColor"
            case .synced: return "doneColor"
            case .error: return "urgencyHigh"
            case .offline: return "secondary"
            }
        }
    }
    
    private init() {
        self.isSyncEnabled = UserDefaults.standard.bool(forKey: syncEnabledKey)
        checkICloudAccountStatus()
        setupCloudKitObserver()
        setupRemoteChangeObserver()
        
        // Set initial status based on saved preference
        if isSyncEnabled {
            syncStatus = .synced
        }
    }
    
    // MARK: - iCloud Account Status
    
    private func checkICloudAccountStatus() {
        CKContainer.default().accountStatus { [weak self] status, error in
            Task { @MainActor in
                self?.iCloudAccountStatus = status
                
                if status != .available && self?.isSyncEnabled == true {
                    self?.syncStatus = .error
                }
            }
        }
    }
    
    private func setupCloudKitObserver() {
        // Monitor iCloud account changes
        NotificationCenter.default.publisher(for: NSNotification.Name.CKAccountChanged)
            .sink { [weak self] _ in
                self?.checkICloudAccountStatus()
            }
            .store(in: &cancellables)
    }
    
    private func setupRemoteChangeObserver() {
        // Monitor CloudKit remote changes
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.syncStatus = .synced
                    self?.lastSyncDate = Date()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sync State Management
    
    private func handleSyncStateChange() {
        if isSyncEnabled {
            enableSync()
        } else {
            disableSync()
        }
    }
    
    func enableSync() {
        guard iCloudAccountStatus == .available else {
            syncStatus = .error
            return
        }
        
        syncStatus = .syncing
        
        // Trigger container rebuild with iCloud
        PersistenceController.shared.enableCloudKit { [weak self] success in
            Task { @MainActor in
                if success {
                    self?.syncStatus = .synced
                    self?.lastSyncDate = Date()
                } else {
                    self?.syncStatus = .error
                    self?.isSyncEnabled = false
                }
            }
        }
    }
    
    func disableSync() {
        syncStatus = .notStarted
        PersistenceController.shared.disableCloudKit()
    }
    
    // MARK: - Manual Sync
    
    func triggerManualSync() {
        guard isSyncEnabled, iCloudAccountStatus == .available else { return }
        
        syncStatus = .syncing
        
        // CloudKit sync happens automatically, but we can force a refresh
        let context = PersistenceController.shared.container.viewContext
        context.perform {
            try? context.save()
        }
        
        // Update status after a brief delay
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            self.syncStatus = .synced
            self.lastSyncDate = Date()
        }
    }
    
    // MARK: - Helpers
    
    var canEnableSync: Bool {
        iCloudAccountStatus == .available
    }
    
    var iCloudStatusDescription: String {
        switch iCloudAccountStatus {
        case .available:
            return "iCloud account available"
        case .noAccount:
            return "No iCloud account signed in"
        case .restricted:
            return "iCloud access restricted"
        case .couldNotDetermine:
            return "Checking iCloud status..."
        @unknown default:
            return "Unknown iCloud status"
        }
    }
}
