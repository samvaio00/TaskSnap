import Foundation
import CoreData
import CloudKit
import Combine
import UIKit

// MARK: - Backup Metadata
struct BackupMetadata: Codable, Identifiable {
    let id: String
    let createdAt: Date
    let deviceName: String
    let appVersion: String
    let iosVersion: String
    let totalTasks: Int
    let fileSize: Int64
    let isAutomatic: Bool
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

// MARK: - Backup Result
enum BackupResult {
    case success(URL)
    case failure(Error)
}

enum RestoreResult {
    case success
    case failure(Error)
}

// MARK: - Backup Error
enum BackupError: LocalizedError {
    case iCloudNotAvailable
    case failedToCreateBackup
    case failedToSaveToiCloud
    case failedToReadBackup
    case failedToRestore
    case invalidBackupFile
    case newerDataExists
    case insufficientSpace
    
    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available. Please enable iCloud Drive in Settings."
        case .failedToCreateBackup:
            return "Failed to create backup. Please try again."
        case .failedToSaveToiCloud:
            return "Failed to save backup to iCloud. Check your connection."
        case .failedToReadBackup:
            return "Failed to read backup file. It may be corrupted."
        case .failedToRestore:
            return "Failed to restore from backup. No data was changed."
        case .invalidBackupFile:
            return "The backup file is invalid or corrupted."
        case .newerDataExists:
            return "You have newer data. Backup was not restored."
        case .insufficientSpace:
            return "Insufficient iCloud storage space."
        }
    }
}

// MARK: - Backup Service
class BackupService: ObservableObject {
    static let shared = BackupService()
    
    @Published var backups: [BackupMetadata] = []
    @Published var isBackingUp = false
    @Published var isRestoring = false
    @Published var lastBackupDate: Date?
    @Published var lastError: BackupError?
    @Published var backupProgress: Double = 0
    
    private let context: NSManagedObjectContext
    private let fileManager = FileManager.default
    private var cancellables = Set<AnyCancellable>()
    
    // iCloud container URL
    private var iCloudContainerURL: URL? {
        fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents/Backups")
    }
    
    // Local backup directory
    private var localBackupDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("Backups", isDirectory: true)
    }
    
    private init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        setupDirectories()
        loadBackupList()
        checkLastBackupDate()
    }
    
    // MARK: - Setup
    
    private func setupDirectories() {
        try? fileManager.createDirectory(at: localBackupDirectory, withIntermediateDirectories: true)
        
        // Create iCloud backup directory if iCloud is available
        if let iCloudURL = iCloudContainerURL {
            try? fileManager.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Create Backup
    
    func createBackup(automatic: Bool = false, completion: @escaping (BackupResult) -> Void) {
        guard isICloudAvailable() else {
            lastError = .iCloudNotAvailable
            completion(.failure(BackupError.iCloudNotAvailable))
            return
        }
        
        isBackingUp = true
        backupProgress = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Step 1: Export data
                self.backupProgress = 0.1
                let backupData = try self.exportAllData()
                
                // Step 2: Create JSON file
                self.backupProgress = 0.3
                let timestamp = ISO8601DateFormatter().string(from: Date())
                let backupFileName = "TaskSnap_\(timestamp).json"
                let localBackupURL = self.localBackupDirectory.appendingPathComponent(backupFileName)
                
                let jsonData = try JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted)
                try jsonData.write(to: localBackupURL)
                
                // Step 3: Copy to iCloud
                self.backupProgress = 0.7
                guard let iCloudURL = self.iCloudContainerURL else {
                    throw BackupError.iCloudNotAvailable
                }
                
                let iCloudBackupURL = iCloudURL.appendingPathComponent(backupFileName)
                
                if self.fileManager.fileExists(atPath: iCloudBackupURL.path) {
                    try self.fileManager.removeItem(at: iCloudBackupURL)
                }
                try self.fileManager.copyItem(at: localBackupURL, to: iCloudBackupURL)
                
                // Step 4: Create metadata
                self.backupProgress = 0.9
                let metadata = self.createMetadata(for: localBackupURL, automatic: automatic)
                try self.saveMetadata(metadata, for: backupFileName)
                
                // Step 5: Cleanup old backups (keep last 10)
                self.backupProgress = 0.95
                try self.cleanupOldBackups()
                
                self.backupProgress = 1.0
                
                DispatchQueue.main.async {
                    self.isBackingUp = false
                    self.lastBackupDate = Date()
                    self.loadBackupList()
                    completion(.success(iCloudBackupURL))
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isBackingUp = false
                    self.lastError = .failedToCreateBackup
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Restore Backup
    
    func restoreBackup(_ backupId: String, completion: @escaping (RestoreResult) -> Void) {
        isRestoring = true
        backupProgress = 0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                // Step 1: Find backup file
                self.backupProgress = 0.1
                let backupFileName = "\(backupId).json"
                
                guard let iCloudURL = self.iCloudContainerURL else {
                    throw BackupError.iCloudNotAvailable
                }
                
                let iCloudBackupURL = iCloudURL.appendingPathComponent(backupFileName)
                let localRestoreURL = self.localBackupDirectory.appendingPathComponent("restore_\(backupId).json")
                
                // Step 2: Download from iCloud
                self.backupProgress = 0.3
                if self.fileManager.fileExists(atPath: iCloudBackupURL.path) {
                    if self.fileManager.fileExists(atPath: localRestoreURL.path) {
                        try self.fileManager.removeItem(at: localRestoreURL)
                    }
                    try self.fileManager.copyItem(at: iCloudBackupURL, to: localRestoreURL)
                } else {
                    throw BackupError.failedToReadBackup
                }
                
                // Step 3: Read and validate
                self.backupProgress = 0.5
                let jsonData = try Data(contentsOf: localRestoreURL)
                guard let restoreData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                    throw BackupError.invalidBackupFile
                }
                
                // Step 4: Verify backup integrity
                self.backupProgress = 0.6
                guard self.validateBackup(restoreData) else {
                    throw BackupError.invalidBackupFile
                }
                
                // Step 5: Perform restore
                self.backupProgress = 0.8
                try self.importData(restoreData)
                
                // Step 6: Cleanup
                self.backupProgress = 0.9
                try? self.fileManager.removeItem(at: localRestoreURL)
                
                self.backupProgress = 1.0
                
                DispatchQueue.main.async {
                    self.isRestoring = false
                    completion(.success)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isRestoring = false
                    self.lastError = .failedToRestore
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Export Data
    
    private func exportAllData() throws -> [String: Any] {
        var exportData: [String: Any] = [:]
        
        // Export tasks
        let taskRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        let tasks = try context.fetch(taskRequest)
        exportData["tasks"] = tasks.map { taskToDictionary($0) }
        
        // Export focus sessions
        let sessionRequest: NSFetchRequest<FocusSessionEntity> = FocusSessionEntity.fetchRequest()
        let sessions = try context.fetch(sessionRequest)
        exportData["focusSessions"] = sessions.map { sessionToDictionary($0) }
        
        // Export shared spaces
        let spaceRequest: NSFetchRequest<SharedSpaceEntity> = SharedSpaceEntity.fetchRequest()
        let spaces = try context.fetch(spaceRequest)
        exportData["sharedSpaces"] = spaces.map { spaceToDictionary($0) }
        
        // Export space members
        let memberRequest: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        let members = try context.fetch(memberRequest)
        exportData["spaceMembers"] = members.map { memberToDictionary($0) }
        
        // Export invitations
        let invitationRequest: NSFetchRequest<ShareInvitationEntity> = ShareInvitationEntity.fetchRequest()
        let invitations = try context.fetch(invitationRequest)
        exportData["invitations"] = invitations.map { invitationToDictionary($0) }
        
        // Export metadata
        exportData["exportMetadata"] = [
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
            "exportedAt": ISO8601DateFormatter().string(from: Date()),
            "deviceName": UIDevice.current.name,
            "iosVersion": UIDevice.current.systemVersion
        ]
        
        return exportData
    }
    
    private func taskToDictionary(_ task: TaskEntity) -> [String: Any] {
        var dict: [String: Any] = [
            "id": task.id?.uuidString ?? UUID().uuidString,
            "title": task.title ?? "",
            "taskDescription": task.taskDescription ?? "",
            "status": task.status ?? "todo",
            "category": task.category ?? "other",
            "isUrgent": task.isUrgent,
            "order": task.order,
            "isShared": task.isShared
        ]
        
        if let createdAt = task.createdAt {
            dict["createdAt"] = ISO8601DateFormatter().string(from: createdAt)
        }
        if let startedAt = task.startedAt {
            dict["startedAt"] = ISO8601DateFormatter().string(from: startedAt)
        }
        if let dueDate = task.dueDate {
            dict["dueDate"] = ISO8601DateFormatter().string(from: dueDate)
        }
        if let completedAt = task.completedAt {
            dict["completedAt"] = ISO8601DateFormatter().string(from: completedAt)
        }
        if let sharedSpaceId = task.sharedSpaceId {
            dict["sharedSpaceId"] = sharedSpaceId.uuidString
        }
        if let createdByUserId = task.createdByUserId {
            dict["createdByUserId"] = createdByUserId
        }
        
        // Images stored separately - just save paths
        if let beforeImagePath = task.beforeImagePath {
            dict["beforeImagePath"] = beforeImagePath
        }
        if let afterImagePath = task.afterImagePath {
            dict["afterImagePath"] = afterImagePath
        }
        
        return dict
    }
    
    private func sessionToDictionary(_ session: FocusSessionEntity) -> [String: Any] {
        var dict: [String: Any] = [
            "id": session.id?.uuidString ?? UUID().uuidString,
            "taskTitle": session.taskTitle ?? "",
            "duration": session.duration,
            "plannedDuration": session.plannedDuration,
            "completedEarly": session.completedEarly,
            "soundType": session.soundType ?? "none"
        ]
        
        if let taskId = session.taskId {
            dict["taskId"] = taskId.uuidString
        }
        
        let formatter = ISO8601DateFormatter()
        if let startedAt = session.startedAt {
            dict["startedAt"] = formatter.string(from: startedAt)
        }
        
        return dict
    }
    
    private func spaceToDictionary(_ space: SharedSpaceEntity) -> [String: Any] {
        var dict: [String: Any] = [
            "id": space.id?.uuidString ?? UUID().uuidString,
            "name": space.name ?? "",
            "emoji": space.emoji ?? "🏠",
            "color": space.color ?? "blue",
            "isActive": space.isActive,
            "shareCode": space.shareCode ?? ""
        ]
        
        if let createdAt = space.createdAt {
            dict["createdAt"] = ISO8601DateFormatter().string(from: createdAt)
        }
        if let createdByUserId = space.createdByUserId {
            dict["createdByUserId"] = createdByUserId
        }
        if let createdByUserName = space.createdByUserName {
            dict["createdByUserName"] = createdByUserName
        }
        
        return dict
    }
    
    private func memberToDictionary(_ member: SpaceMemberEntity) -> [String: Any] {
        var dict: [String: Any] = [
            "id": member.id?.uuidString ?? UUID().uuidString,
            "spaceId": member.spaceId?.uuidString ?? "",
            "userId": member.userId ?? "",
            "userName": member.userName ?? "",
            "role": member.role ?? "member",
            "isActive": member.isActive
        ]
        
        if let joinedAt = member.joinedAt {
            dict["joinedAt"] = ISO8601DateFormatter().string(from: joinedAt)
        }
        
        return dict
    }
    
    private func invitationToDictionary(_ invitation: ShareInvitationEntity) -> [String: Any] {
        var dict: [String: Any] = [
            "id": invitation.id?.uuidString ?? UUID().uuidString,
            "spaceId": invitation.spaceId?.uuidString ?? "",
            "spaceName": invitation.spaceName ?? "",
            "invitedByUserId": invitation.invitedByUserId ?? "",
            "invitedByUserName": invitation.invitedByUserName ?? "",
            "status": invitation.status ?? "pending"
        ]
        
        if let invitedUserId = invitation.invitedUserId {
            dict["invitedUserId"] = invitedUserId
        }
        if let invitedUserEmail = invitation.invitedUserEmail {
            dict["invitedUserEmail"] = invitedUserEmail
        }
        if let createdAt = invitation.createdAt {
            dict["createdAt"] = ISO8601DateFormatter().string(from: createdAt)
        }
        if let expiresAt = invitation.expiresAt {
            dict["expiresAt"] = ISO8601DateFormatter().string(from: expiresAt)
        }
        
        return dict
    }
    
    // MARK: - Import Data
    
    private func importData(_ data: [String: Any]) throws {
        // Clear existing data first
        try clearAllData()
        
        // Import tasks
        if let tasksData = data["tasks"] as? [[String: Any]] {
            for taskDict in tasksData {
                let task = TaskEntity(context: context)
                populateTask(task, from: taskDict)
            }
        }
        
        // Import focus sessions
        if let sessionsData = data["focusSessions"] as? [[String: Any]] {
            for sessionDict in sessionsData {
                let session = FocusSessionEntity(context: context)
                populateSession(session, from: sessionDict)
            }
        }
        
        // Import shared spaces
        if let spacesData = data["sharedSpaces"] as? [[String: Any]] {
            for spaceDict in spacesData {
                let space = SharedSpaceEntity(context: context)
                populateSpace(space, from: spaceDict)
            }
        }
        
        // Import space members
        if let membersData = data["spaceMembers"] as? [[String: Any]] {
            for memberDict in membersData {
                let member = SpaceMemberEntity(context: context)
                populateMember(member, from: memberDict)
            }
        }
        
        // Import invitations
        if let invitationsData = data["invitations"] as? [[String: Any]] {
            for invitationDict in invitationsData {
                let invitation = ShareInvitationEntity(context: context)
                populateInvitation(invitation, from: invitationDict)
            }
        }
        
        // Save context
        try context.save()
        
        // Post notification that data changed
        NotificationCenter.default.post(name: .cloudKitSyncCompleted, object: nil)
    }
    
    private func populateTask(_ task: TaskEntity, from dict: [String: Any]) {
        task.id = UUID(uuidString: dict["id"] as? String ?? "")
        task.title = dict["title"] as? String
        task.taskDescription = dict["taskDescription"] as? String
        task.status = dict["status"] as? String
        task.category = dict["category"] as? String
        task.isUrgent = dict["isUrgent"] as? Bool ?? false
        task.order = dict["order"] as? Int32 ?? 0
        task.isShared = dict["isShared"] as? Bool ?? false
        task.beforeImagePath = dict["beforeImagePath"] as? String
        task.afterImagePath = dict["afterImagePath"] as? String
        task.createdByUserId = dict["createdByUserId"] as? String
        
        let formatter = ISO8601DateFormatter()
        if let createdAt = dict["createdAt"] as? String {
            task.createdAt = formatter.date(from: createdAt)
        }
        if let startedAt = dict["startedAt"] as? String {
            task.startedAt = formatter.date(from: startedAt)
        }
        if let dueDate = dict["dueDate"] as? String {
            task.dueDate = formatter.date(from: dueDate)
        }
        if let completedAt = dict["completedAt"] as? String {
            task.completedAt = formatter.date(from: completedAt)
        }
        if let sharedSpaceId = dict["sharedSpaceId"] as? String {
            task.sharedSpaceId = UUID(uuidString: sharedSpaceId)
        }
    }
    
    private func populateSession(_ session: FocusSessionEntity, from dict: [String: Any]) {
        session.id = UUID(uuidString: dict["id"] as? String ?? "")
        session.taskTitle = dict["taskTitle"] as? String
        session.duration = dict["duration"] as? Double ?? 0
        session.plannedDuration = dict["plannedDuration"] as? Double ?? 0
        session.completedEarly = dict["completedEarly"] as? Bool ?? false
        session.soundType = dict["soundType"] as? String
        
        if let taskId = dict["taskId"] as? String {
            session.taskId = UUID(uuidString: taskId)
        }
        
        let formatter = ISO8601DateFormatter()
        if let startedAt = dict["startedAt"] as? String {
            session.startedAt = formatter.date(from: startedAt)
        }
    }
    
    private func populateSpace(_ space: SharedSpaceEntity, from dict: [String: Any]) {
        space.id = UUID(uuidString: dict["id"] as? String ?? "")
        space.name = dict["name"] as? String
        space.emoji = dict["emoji"] as? String
        space.color = dict["color"] as? String
        space.isActive = dict["isActive"] as? Bool ?? true
        space.shareCode = dict["shareCode"] as? String
        space.createdByUserId = dict["createdByUserId"] as? String
        space.createdByUserName = dict["createdByUserName"] as? String
        
        let formatter = ISO8601DateFormatter()
        if let createdAt = dict["createdAt"] as? String {
            space.createdAt = formatter.date(from: createdAt)
        }
    }
    
    private func populateMember(_ member: SpaceMemberEntity, from dict: [String: Any]) {
        member.id = UUID(uuidString: dict["id"] as? String ?? "")
        if let spaceId = dict["spaceId"] as? String {
            member.spaceId = UUID(uuidString: spaceId)
        }
        member.userId = dict["userId"] as? String
        member.userName = dict["userName"] as? String
        member.role = dict["role"] as? String
        member.isActive = dict["isActive"] as? Bool ?? true
        
        let formatter = ISO8601DateFormatter()
        if let joinedAt = dict["joinedAt"] as? String {
            member.joinedAt = formatter.date(from: joinedAt)
        }
    }
    
    private func populateInvitation(_ invitation: ShareInvitationEntity, from dict: [String: Any]) {
        invitation.id = UUID(uuidString: dict["id"] as? String ?? "")
        if let spaceId = dict["spaceId"] as? String {
            invitation.spaceId = UUID(uuidString: spaceId)
        }
        invitation.spaceName = dict["spaceName"] as? String
        invitation.invitedByUserId = dict["invitedByUserId"] as? String
        invitation.invitedByUserName = dict["invitedByUserName"] as? String
        invitation.invitedUserId = dict["invitedUserId"] as? String
        invitation.invitedUserEmail = dict["invitedUserEmail"] as? String
        invitation.status = dict["status"] as? String
        
        let formatter = ISO8601DateFormatter()
        if let createdAt = dict["createdAt"] as? String {
            invitation.createdAt = formatter.date(from: createdAt)
        }
        if let expiresAt = dict["expiresAt"] as? String {
            invitation.expiresAt = formatter.date(from: expiresAt)
        }
    }
    
    private func clearAllData() throws {
        let entities = ["TaskEntity", "FocusSessionEntity", "SharedSpaceEntity", "SpaceMemberEntity", "ShareInvitationEntity"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(batchDelete)
        }
        
        try context.save()
    }
    
    // MARK: - Metadata Management
    
    private func createMetadata(for backupURL: URL, automatic: Bool) -> BackupMetadata {
        let attributes = try? fileManager.attributesOfItem(atPath: backupURL.path)
        let fileSize = attributes?[.size] as? Int64 ?? 0
        
        let taskRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        let taskCount = (try? context.count(for: taskRequest)) ?? 0
        
        return BackupMetadata(
            id: backupURL.deletingPathExtension().lastPathComponent,
            createdAt: Date(),
            deviceName: UIDevice.current.name,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            iosVersion: UIDevice.current.systemVersion,
            totalTasks: taskCount,
            fileSize: fileSize,
            isAutomatic: automatic
        )
    }
    
    private func saveMetadata(_ metadata: BackupMetadata, for fileName: String) throws {
        let metadataURL = localBackupDirectory.appendingPathComponent("\(fileName).metadata")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)
        try data.write(to: metadataURL)
        
        // Also save to iCloud
        if let iCloudURL = iCloudContainerURL {
            let iCloudMetadataURL = iCloudURL.appendingPathComponent("\(fileName).metadata")
            try? fileManager.removeItem(at: iCloudMetadataURL)
            try fileManager.copyItem(at: metadataURL, to: iCloudMetadataURL)
        }
    }
    
    private func loadMetadata(for fileName: String) -> BackupMetadata? {
        // Try iCloud first, then local
        var metadataURL: URL?
        
        if let iCloudURL = iCloudContainerURL {
            let iCloudMetadataURL = iCloudURL.appendingPathComponent("\(fileName).metadata")
            if fileManager.fileExists(atPath: iCloudMetadataURL.path) {
                metadataURL = iCloudMetadataURL
            }
        }
        
        if metadataURL == nil {
            metadataURL = localBackupDirectory.appendingPathComponent("\(fileName).metadata")
        }
        
        guard let url = metadataURL,
              fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(BackupMetadata.self, from: data)
    }
    
    // MARK: - Backup List Management
    
    func loadBackupList() {
        guard let iCloudURL = iCloudContainerURL else {
            // Fallback to local backups
            loadLocalBackups()
            return
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: iCloudURL, includingPropertiesForKeys: nil)
            let jsonFiles = contents.filter { $0.pathExtension == "json" }
            
            var metadataList: [BackupMetadata] = []
            
            for file in jsonFiles {
                let fileName = file.lastPathComponent
                if let metadata = loadMetadata(for: fileName) {
                    metadataList.append(metadata)
                }
            }
            
            backups = metadataList.sorted { $0.createdAt > $1.createdAt }
            
        } catch {
            print("Failed to load backup list: \(error)")
            loadLocalBackups()
        }
    }
    
    private func loadLocalBackups() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: localBackupDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = contents.filter { $0.pathExtension == "json" }
            
            var metadataList: [BackupMetadata] = []
            
            for file in jsonFiles {
                let fileName = file.lastPathComponent
                if let metadata = loadMetadata(for: fileName) {
                    metadataList.append(metadata)
                }
            }
            
            backups = metadataList.sorted { $0.createdAt > $1.createdAt }
            
        } catch {
            print("Failed to load local backups: \(error)")
            backups = []
        }
    }
    
    func deleteBackup(_ backupId: String) {
        do {
            // Delete from iCloud
            if let iCloudURL = iCloudContainerURL {
                let iCloudFile = iCloudURL.appendingPathComponent("\(backupId).json")
                let iCloudMetadata = iCloudURL.appendingPathComponent("\(backupId).json.metadata")
                try? fileManager.removeItem(at: iCloudFile)
                try? fileManager.removeItem(at: iCloudMetadata)
            }
            
            // Delete local files
            let localFile = localBackupDirectory.appendingPathComponent("\(backupId).json")
            let metadataFile = localBackupDirectory.appendingPathComponent("\(backupId).json.metadata")
            try? fileManager.removeItem(at: localFile)
            try? fileManager.removeItem(at: metadataFile)
            
            loadBackupList()
            
        } catch {
            print("Failed to delete backup: \(error)")
        }
    }
    
    private func cleanupOldBackups() throws {
        while backups.count > 10 {
            if let oldest = backups.last {
                deleteBackup(oldest.id)
            }
        }
    }
    
    // MARK: - Validation
    
    private func validateBackup(_ data: [String: Any]) -> Bool {
        guard data["exportMetadata"] is [String: Any] else { return false }
        return true
    }
    
    // MARK: - Helpers
    
    private func isICloudAvailable() -> Bool {
        return iCloudContainerURL != nil
    }
    
    private func checkLastBackupDate() {
        if let mostRecent = backups.first {
            lastBackupDate = mostRecent.createdAt
        }
    }
    
    func scheduleAutomaticBackup() {
        let calendar = Calendar.current
        
        if let lastDate = lastBackupDate {
            let daysSinceLastBackup = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            
            if daysSinceLastBackup >= 7 {
                createBackup(automatic: true) { result in
                    switch result {
                    case .success:
                        print("Automatic backup completed")
                    case .failure(let error):
                        print("Automatic backup failed: \(error)")
                    }
                }
            }
        } else {
            createBackup(automatic: true) { _ in }
        }
    }
}
