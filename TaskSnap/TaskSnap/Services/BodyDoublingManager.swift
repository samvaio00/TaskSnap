import Foundation
import CloudKit
import Combine
import UIKit

// MARK: - Body Doubling Manager
class BodyDoublingManager: ObservableObject {
    static let shared = BodyDoublingManager()
    
    @Published var isInSession = false
    @Published var currentSession: FocusSession?
    @Published var participants: [SessionParticipant] = []
    @Published var roomStatus: RoomStatus = .available
    @Published var isProFeature = true // This will be checked against subscription
    
    private var heartbeatTimer: Timer?
    private var refreshTimer: Timer?
    private let container = CKContainer.default()
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    // CloudKit record types
    private let sessionRecordType = "FocusSession"
    private let participantRecordType = "SessionParticipant"
    
    private init() {
        self.database = container.publicCloudDatabase
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Monitor app lifecycle
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.pauseSession()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                if self?.isInSession == true {
                    self?.resumeSession()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Session Management
    
    func startSession(taskName: String? = nil) {
        guard !isInSession else { return }
        
        let userId = getUserId()
        let userName = getUserName()
        
        currentSession = FocusSession(
            id: UUID(),
            userId: userId,
            userName: userName,
            avatar: getRandomAvatar(),
            startTime: Date(),
            taskName: taskName,
            isActive: true
        )
        
        isInSession = true
        
        // Save to CloudKit
        saveSessionToCloudKit()
        
        // Start heartbeat
        startHeartbeat()
        
        // Start refreshing participants
        startRefreshingParticipants()
        
        Haptics.shared.success()
    }
    
    func endSession() {
        guard isInSession else { return }
        
        // Stop timers
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        // Mark session as ended in CloudKit
        markSessionEnded()
        
        isInSession = false
        currentSession = nil
        participants = []
        
        Haptics.shared.light()
    }
    
    func pauseSession() {
        guard isInSession else { return }
        heartbeatTimer?.invalidate()
    }
    
    func resumeSession() {
        guard isInSession else { return }
        startHeartbeat()
    }
    
    // MARK: - Heartbeat
    
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
        // Send immediate heartbeat
        sendHeartbeat()
    }
    
    private func sendHeartbeat() {
        guard let session = currentSession else { return }
        
        let record = CKRecord(recordType: participantRecordType)
        record["userId"] = session.userId
        record["name"] = session.userName
        record["avatar"] = session.avatar
        record["joinedAt"] = session.startTime
        record["currentTask"] = session.taskName
        record["isActive"] = session.isActive
        record["lastHeartbeat"] = Date()
        
        database.save(record) { _, error in
            if let error = error {
                print("Error sending heartbeat: \(error)")
            }
        }
    }
    
    // MARK: - Participants
    
    private func startRefreshingParticipants() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.fetchParticipants()
        }
        // Fetch immediately
        fetchParticipants()
    }
    
    private func fetchParticipants() {
        // Query for active participants (heartbeat within last 2 minutes)
        let twoMinutesAgo = Date().addingTimeInterval(-120)
        let predicate = NSPredicate(format: "lastHeartbeat > %@", twoMinutesAgo as NSDate)
        let query = CKQuery(recordType: participantRecordType, predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            if let error = error {
                print("Error fetching participants: \(error)")
                return
            }
            
            guard let records = records else { return }
            
            let fetchedParticipants = records.compactMap { record -> SessionParticipant? in
                guard let userId = record["userId"] as? String,
                      userId != self?.getUserId() // Don't include self
                else { return nil }
                
                return SessionParticipant(
                    id: userId,
                    name: record["name"] as? String ?? "Anonymous",
                    avatar: record["avatar"] as? String ?? "person.circle",
                    joinedAt: record["joinedAt"] as? Date ?? Date(),
                    currentTask: record["currentTask"] as? String,
                    isActive: record["isActive"] as? Bool ?? true,
                    lastHeartbeat: record["lastHeartbeat"] as? Date ?? Date()
                )
            }
            
            DispatchQueue.main.async {
                self?.participants = fetchedParticipants
            }
        }
    }
    
    // MARK: - CloudKit Operations
    
    private func saveSessionToCloudKit() {
        guard let session = currentSession else { return }
        
        let record = CKRecord(recordType: sessionRecordType)
        record["sessionId"] = session.id.uuidString
        record["userId"] = session.userId
        record["userName"] = session.userName
        record["startTime"] = session.startTime
        record["taskName"] = session.taskName
        record["isActive"] = true
        
        database.save(record) { _, error in
            if let error = error {
                print("Error saving session: \(error)")
            }
        }
    }
    
    private func markSessionEnded() {
        guard let session = currentSession else { return }
        
        // Query for the session record
        let predicate = NSPredicate(format: "sessionId == %@", session.id.uuidString)
        let query = CKQuery(recordType: sessionRecordType, predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let record = records?.first else { return }
            
            record["isActive"] = false
            record["endTime"] = Date()
            
            self?.database.save(record) { _, error in
                if let error = error {
                    print("Error marking session ended: \(error)")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func getUserId() -> String {
        // Use iCloud record ID or generate UUID
        return CKContainer.default().userRecordID()?.recordName ?? UUID().uuidString
    }
    
    private func getUserName() -> String {
        // In real app, this would come from user profile
        return "User \(Int.random(in: 1000...9999))"
    }
    
    private func getRandomAvatar() -> String {
        let avatars = ["person.circle", "person.fill", "person.2.circle", "person.3.sequence.fill"]
        return avatars.randomElement() ?? "person.circle"
    }
    
    // MARK: - Room Status
    
    var participantCount: Int {
        participants.count + (isInSession ? 1 : 0)
    }
    
    var isRoomAvailable: Bool {
        participantCount < 10 // Max 10 participants
    }
}

// MARK: - CloudKit Helpers
extension CKContainer {
    func userRecordID() -> CKRecord.ID? {
        // This would need to be fetched asynchronously in real implementation
        // For now, return nil to use local UUID
        return nil
    }
}
