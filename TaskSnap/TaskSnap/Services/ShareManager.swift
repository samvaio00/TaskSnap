import Foundation
import CoreData
import CloudKit
import Combine

// MARK: - Enums
enum SpaceRole: String, CaseIterable {
    case owner = "owner"
    case admin = "admin"
    case member = "member"
    
    var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .admin: return "Admin"
        case .member: return "Member"
        }
    }
    
    var canInvite: Bool {
        self == .owner || self == .admin
    }
    
    var canManageMembers: Bool {
        self == .owner || self == .admin
    }
    
    var canDeleteSpace: Bool {
        self == .owner
    }
}

enum InvitationStatus: String {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
}

// MARK: - Models
struct SharedSpace: Identifiable {
    let id: UUID
    let name: String
    let emoji: String
    let color: String
    let createdAt: Date
    let createdByUserId: String
    let createdByUserName: String
    let isActive: Bool
    let shareCode: String?
    let members: [SpaceMember]
    let tasks: [TaskEntity]
    
    init(from entity: SharedSpaceEntity, context: NSManagedObjectContext) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? "Unnamed Space"
        self.emoji = entity.emoji ?? "🏠"
        self.color = entity.color ?? "blue"
        self.createdAt = entity.createdAt ?? Date()
        self.createdByUserId = entity.createdByUserId ?? ""
        self.createdByUserName = entity.createdByUserName ?? "Unknown"
        self.isActive = entity.isActive
        self.shareCode = entity.shareCode
        
        // Fetch members
        let memberRequest: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "spaceId == %@ AND isActive == YES", self.id as CVarArg)
        self.members = (try? context.fetch(memberRequest))?.map { SpaceMember(from: $0) } ?? []
        
        // Fetch tasks
        let taskRequest: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
        taskRequest.predicate = NSPredicate(format: "sharedSpaceId == %@ AND isShared == YES", self.id as CVarArg)
        self.tasks = (try? context.fetch(taskRequest)) ?? []
    }
    
    var memberCount: Int { members.count }
    
    var taskCount: Int { tasks.count }
    
    var displayColor: Color {
        Color(color)
    }
}

struct SpaceMember: Identifiable {
    let id: UUID
    let spaceId: UUID
    let userId: String
    let userName: String
    let role: SpaceRole
    let joinedAt: Date
    let isActive: Bool
    
    init(from entity: SpaceMemberEntity) {
        self.id = entity.id ?? UUID()
        self.spaceId = entity.spaceId ?? UUID()
        self.userId = entity.userId ?? ""
        self.userName = entity.userName ?? "Unknown"
        self.role = SpaceRole(rawValue: entity.role ?? "member") ?? .member
        self.joinedAt = entity.joinedAt ?? Date()
        self.isActive = entity.isActive
    }
}

struct ShareInvitation: Identifiable {
    let id: UUID
    let spaceId: UUID
    let spaceName: String
    let invitedByUserId: String
    let invitedByUserName: String
    let invitedUserId: String?
    let invitedUserEmail: String?
    let status: InvitationStatus
    let createdAt: Date
    let expiresAt: Date?
    
    init(from entity: ShareInvitationEntity) {
        self.id = entity.id ?? UUID()
        self.spaceId = entity.spaceId ?? UUID()
        self.spaceName = entity.spaceName ?? "Unnamed Space"
        self.invitedByUserId = entity.invitedByUserId ?? ""
        self.invitedByUserName = entity.invitedByUserName ?? "Unknown"
        self.invitedUserId = entity.invitedUserId
        self.invitedUserEmail = entity.invitedUserEmail
        self.status = InvitationStatus(rawValue: entity.status ?? "pending") ?? .pending
        self.createdAt = entity.createdAt ?? Date()
        self.expiresAt = entity.expiresAt
    }
    
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

// MARK: - Share Manager
class ShareManager: ObservableObject {
    static let shared = ShareManager()
    
    @Published var spaces: [SharedSpace] = []
    @Published var invitations: [ShareInvitation] = []
    @Published var pendingInvitations: [ShareInvitation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    private var currentUserName: String?
    
    private init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        loadCurrentUserInfo()
        fetchSpaces()
        fetchInvitations()
    }
    
    // MARK: - User Info
    
    private func loadCurrentUserInfo() {
        // Get iCloud user ID if available
        CKContainer.default().fetchUserRecordID { [weak self] recordID, error in
            DispatchQueue.main.async {
                if let recordID = recordID {
                    self?.currentUserId = recordID.recordName
                }
                // For now, use device identifier as fallback
                if self?.currentUserId == nil {
                    self?.currentUserId = UIDevice.current.identifierForVendor?.uuidString
                }
                self?.currentUserName = UserDefaults.standard.string(forKey: "userDisplayName") ?? "Me"
            }
        }
    }
    
    // MARK: - Space Management
    
    func createSpace(name: String, emoji: String = "🏠", color: String = "blue") -> SharedSpace? {
        guard let userId = currentUserId else {
            errorMessage = "Not signed in"
            return nil
        }
        
        let space = SharedSpaceEntity(context: context)
        space.id = UUID()
        space.name = name
        space.emoji = emoji
        space.color = color
        space.createdAt = Date()
        space.createdByUserId = userId
        space.createdByUserName = currentUserName
        space.isActive = true
        space.shareCode = generateShareCode()
        
        // Add creator as owner
        let member = SpaceMemberEntity(context: context)
        member.id = UUID()
        member.spaceId = space.id
        member.userId = userId
        member.userName = currentUserName
        member.role = SpaceRole.owner.rawValue
        member.joinedAt = Date()
        member.isActive = true
        
        do {
            try context.save()
            fetchSpaces()
            return spaces.first { $0.id == space.id }
        } catch {
            errorMessage = "Failed to create space: \(error.localizedDescription)"
            return nil
        }
    }
    
    func updateSpace(id: UUID, name: String? = nil, emoji: String? = nil, color: String? = nil) {
        let request: NSFetchRequest<SharedSpaceEntity> = SharedSpaceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        guard let space = try? context.fetch(request).first else { return }
        
        // Check permissions
        guard canManageSpace(id: id) else {
            errorMessage = "You don't have permission to edit this space"
            return
        }
        
        if let name = name { space.name = name }
        if let emoji = emoji { space.emoji = emoji }
        if let color = color { space.color = color }
        
        do {
            try context.save()
            fetchSpaces()
        } catch {
            errorMessage = "Failed to update space: \(error.localizedDescription)"
        }
    }
    
    func deleteSpace(id: UUID) {
        let request: NSFetchRequest<SharedSpaceEntity> = SharedSpaceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        guard let space = try? context.fetch(request).first else { return }
        
        // Only owner can delete
        guard space.createdByUserId == currentUserId else {
            errorMessage = "Only the owner can delete this space"
            return
        }
        
        space.isActive = false
        
        do {
            try context.save()
            fetchSpaces()
        } catch {
            errorMessage = "Failed to delete space: \(error.localizedDescription)"
        }
    }
    
    func leaveSpace(id: UUID) {
        let request: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        request.predicate = NSPredicate(format: "spaceId == %@ AND userId == %@", 
                                       id as CVarArg, currentUserId ?? "" as CVarArg)
        
        guard let membership = try? context.fetch(request).first else { return }
        
        // Owner cannot leave, must transfer ownership first
        if membership.role == SpaceRole.owner.rawValue {
            errorMessage = "Transfer ownership before leaving"
            return
        }
        
        membership.isActive = false
        
        do {
            try context.save()
            fetchSpaces()
        } catch {
            errorMessage = "Failed to leave space: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Task Sharing
    
    func shareTask(_ task: TaskEntity, to spaceId: UUID) {
        guard canAddTasksToSpace(id: spaceId) else {
            errorMessage = "You don't have permission to add tasks to this space"
            return
        }
        
        task.sharedSpaceId = spaceId
        task.isShared = true
        task.createdByUserId = currentUserId
        
        do {
            try context.save()
            fetchSpaces()
        } catch {
            errorMessage = "Failed to share task: \(error.localizedDescription)"
        }
    }
    
    func unshareTask(_ task: TaskEntity) {
        guard task.createdByUserId == currentUserId || canManageSpace(id: task.sharedSpaceId) else {
            errorMessage = "You don't have permission to unshare this task"
            return
        }
        
        task.isShared = false
        task.sharedSpaceId = nil
        
        do {
            try context.save()
            fetchSpaces()
        } catch {
            errorMessage = "Failed to unshare task: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Invitations
    
    func inviteUser(to spaceId: UUID, email: String) {
        guard let userId = currentUserId else { return }
        
        guard canInviteToSpace(id: spaceId) else {
            errorMessage = "You don't have permission to invite users"
            return
        }
        
        // Get space name
        let spaceRequest: NSFetchRequest<SharedSpaceEntity> = SharedSpaceEntity.fetchRequest()
        spaceRequest.predicate = NSPredicate(format: "id == %@", spaceId as CVarArg)
        let spaceName = (try? context.fetch(spaceRequest).first)?.name ?? "Unnamed Space"
        
        let invitation = ShareInvitationEntity(context: context)
        invitation.id = UUID()
        invitation.spaceId = spaceId
        invitation.spaceName = spaceName
        invitation.invitedByUserId = userId
        invitation.invitedByUserName = currentUserName
        invitation.invitedUserEmail = email
        invitation.status = InvitationStatus.pending.rawValue
        invitation.createdAt = Date()
        invitation.expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        
        do {
            try context.save()
            
            // In a real app, this would send an email/notification
            // For now, we just store it locally
            fetchInvitations()
        } catch {
            errorMessage = "Failed to send invitation: \(error.localizedDescription)"
        }
    }
    
    func acceptInvitation(_ invitationId: UUID) {
        let request: NSFetchRequest<ShareInvitationEntity> = ShareInvitationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", invitationId as CVarArg)
        
        guard let invitation = try? context.fetch(request).first else { return }
        
        guard !invitation.isExpired else {
            invitation.status = InvitationStatus.expired.rawValue
            try? context.save()
            errorMessage = "Invitation has expired"
            return
        }
        
        invitation.status = InvitationStatus.accepted.rawValue
        
        // Add user as member
        let member = SpaceMemberEntity(context: context)
        member.id = UUID()
        member.spaceId = invitation.spaceId
        member.userId = currentUserId
        member.userName = currentUserName
        member.role = SpaceRole.member.rawValue
        member.joinedAt = Date()
        member.isActive = true
        
        do {
            try context.save()
            fetchSpaces()
            fetchInvitations()
        } catch {
            errorMessage = "Failed to accept invitation: \(error.localizedDescription)"
        }
    }
    
    func declineInvitation(_ invitationId: UUID) {
        let request: NSFetchRequest<ShareInvitationEntity> = ShareInvitationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", invitationId as CVarArg)
        
        guard let invitation = try? context.fetch(request).first else { return }
        
        invitation.status = InvitationStatus.declined.rawValue
        
        do {
            try context.save()
            fetchInvitations()
        } catch {
            errorMessage = "Failed to decline invitation: \(error.localizedDescription)"
        }
    }
    
    func joinSpace(with shareCode: String) -> Bool {
        let request: NSFetchRequest<SharedSpaceEntity> = SharedSpaceEntity.fetchRequest()
        request.predicate = NSPredicate(format: "shareCode == %@ AND isActive == YES", shareCode)
        
        guard let space = try? context.fetch(request).first else {
            errorMessage = "Invalid share code"
            return false
        }
        
        // Check if already a member
        let memberRequest: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "spaceId == %@ AND userId == %@ AND isActive == YES",
                                             space.id! as CVarArg, currentUserId ?? "" as CVarArg)
        
        if (try? context.fetch(memberRequest).first) != nil {
            errorMessage = "You're already a member of this space"
            return false
        }
        
        // Add as member
        let member = SpaceMemberEntity(context: context)
        member.id = UUID()
        member.spaceId = space.id
        member.userId = currentUserId
        member.userName = currentUserName
        member.role = SpaceRole.member.rawValue
        member.joinedAt = Date()
        member.isActive = true
        
        do {
            try context.save()
            fetchSpaces()
            return true
        } catch {
            errorMessage = "Failed to join space: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Member Management
    
    func updateMemberRole(spaceId: UUID, memberId: UUID, newRole: SpaceRole) {
        guard canManageMembers(spaceId: spaceId) else {
            errorMessage = "You don't have permission to manage members"
            return
        }
        
        let request: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND spaceId == %@", 
                                       memberId as CVarArg, spaceId as CVarArg)
        
        guard let member = try? context.fetch(request).first else { return }
        
        member.role = newRole.rawValue
        
        do {
            try context.save()
            fetchSpaces()
        } catch {
            errorMessage = "Failed to update role: \(error.localizedDescription)"
        }
    }
    
    func removeMember(spaceId: UUID, memberId: UUID) {
        guard canManageMembers(spaceId: spaceId) else {
            errorMessage = "You don't have permission to remove members"
            return
        }
        
        let request: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND spaceId == %@", 
                                       memberId as CVarArg, spaceId as CVarArg)
        
        guard let member = try? context.fetch(request).first else { return }
        
        // Cannot remove owner
        guard member.role != SpaceRole.owner.rawValue else {
            errorMessage = "Cannot remove the owner"
            return
        }
        
        member.isActive = false
        
        do {
            try context.save()
            fetchSpaces()
        } catch {
            errorMessage = "Failed to remove member: \(error.localizedDescription)"
        }
    }
    
    func transferOwnership(spaceId: UUID, to memberId: UUID) {
        guard isOwner(spaceId: spaceId) else {
            errorMessage = "Only the owner can transfer ownership"
            return
        }
        
        let request: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        request.predicate = NSPredicate(format: "spaceId == %@", spaceId as CVarArg)
        
        guard let members = try? context.fetch(request) else { return }
        
        // Find current owner and new owner
        guard let currentOwner = members.first(where: { $0.userId == currentUserId }),
              let newOwner = members.first(where: { $0.id == memberId }) else { return }
        
        currentOwner.role = SpaceRole.admin.rawValue
        newOwner.role = SpaceRole.owner.rawValue
        
        // Update space
        let spaceRequest: NSFetchRequest<SharedSpaceEntity> = SharedSpaceEntity.fetchRequest()
        spaceRequest.predicate = NSPredicate(format: "id == %@", spaceId as CVarArg)
        
        if let space = try? context.fetch(spaceRequest).first {
            space.createdByUserId = newOwner.userId
            space.createdByUserName = newOwner.userName
        }
        
        do {
            try context.save()
            fetchSpaces()
        } catch {
            errorMessage = "Failed to transfer ownership: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Permission Checks
    
    func canManageSpace(id: UUID) -> Bool {
        let request: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        request.predicate = NSPredicate(format: "spaceId == %@ AND userId == %@ AND isActive == YES",
                                       id as CVarArg, currentUserId ?? "" as CVarArg)
        
        guard let member = try? context.fetch(request).first else { return false }
        let role = SpaceRole(rawValue: member.role ?? "") ?? .member
        return role == .owner || role == .admin
    }
    
    func canInviteToSpace(id: UUID) -> Bool {
        let request: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        request.predicate = NSPredicate(format: "spaceId == %@ AND userId == %@ AND isActive == YES",
                                       id as CVarArg, currentUserId ?? "" as CVarArg)
        
        guard let member = try? context.fetch(request).first else { return false }
        let role = SpaceRole(rawValue: member.role ?? "") ?? .member
        return role.canInvite
    }
    
    func canManageMembers(spaceId: UUID) -> Bool {
        return canManageSpace(id: spaceId)
    }
    
    func canAddTasksToSpace(id: UUID) -> Bool {
        let request: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        request.predicate = NSPredicate(format: "spaceId == %@ AND userId == %@ AND isActive == YES",
                                       id as CVarArg, currentUserId ?? "" as CVarArg)
        return (try? context.fetch(request).first) != nil
    }
    
    func isOwner(spaceId: UUID) -> Bool {
        let request: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        request.predicate = NSPredicate(format: "spaceId == %@ AND userId == %@ AND isActive == YES",
                                       spaceId as CVarArg, currentUserId ?? "" as CVarArg)
        
        guard let member = try? context.fetch(request).first else { return false }
        return member.role == SpaceRole.owner.rawValue
    }
    
    // MARK: - Fetching
    
    func fetchSpaces() {
        guard let userId = currentUserId else { return }
        
        // Get all space IDs where user is a member
        let memberRequest: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "userId == %@ AND isActive == YES", userId)
        
        guard let memberships = try? context.fetch(memberRequest) else {
            spaces = []
            return
        }
        
        let spaceIds = memberships.compactMap { $0.spaceId }
        
        // Fetch spaces
        let spaceRequest: NSFetchRequest<SharedSpaceEntity> = SharedSpaceEntity.fetchRequest()
        spaceRequest.predicate = NSPredicate(format: "id IN %@ AND isActive == YES", spaceIds)
        spaceRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SharedSpaceEntity.createdAt, ascending: false)]
        
        guard let spaceEntities = try? context.fetch(spaceRequest) else {
            spaces = []
            return
        }
        
        spaces = spaceEntities.map { SharedSpace(from: $0, context: context) }
    }
    
    func fetchInvitations() {
        guard let userId = currentUserId else { return }
        
        // Fetch pending invitations for this user
        // In a real app, this would query by email or user ID from CloudKit
        let request: NSFetchRequest<ShareInvitationEntity> = ShareInvitationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "invitedUserId == %@ OR invitedUserEmail == %@",
                                       userId, UserDefaults.standard.string(forKey: "userEmail") ?? "")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ShareInvitationEntity.createdAt, ascending: false)]
        
        guard let entities = try? context.fetch(request) else {
            invitations = []
            pendingInvitations = []
            return
        }
        
        invitations = entities.map { ShareInvitation(from: $0) }
        pendingInvitations = invitations.filter { $0.status == .pending && !$0.isExpired }
    }
    
    // MARK: - Helpers
    
    private func generateShareCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        var code = ""
        for _ in 0..<6 {
            code.append(letters.randomElement()!)
        }
        return code
    }
    
    func getSpace(by id: UUID) -> SharedSpace? {
        spaces.first { $0.id == id }
    }
    
    func getMyRole(in spaceId: UUID) -> SpaceRole {
        let request: NSFetchRequest<SpaceMemberEntity> = SpaceMemberEntity.fetchRequest()
        request.predicate = NSPredicate(format: "spaceId == %@ AND userId == %@ AND isActive == YES",
                                       spaceId as CVarArg, currentUserId ?? "" as CVarArg)
        
        guard let member = try? context.fetch(request).first,
              let roleString = member.role else {
            return .member
        }
        
        return SpaceRole(rawValue: roleString) ?? .member
    }
}

// MARK: - CKContainer Extension
extension CKContainer {
    func fetchUserRecordID(completion: @escaping (CKRecord.ID?, Error?) -> Void) {
        fetchUserRecordID(completionHandler: completion)
    }
}
