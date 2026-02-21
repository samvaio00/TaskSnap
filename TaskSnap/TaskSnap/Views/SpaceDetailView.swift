import SwiftUI

struct SpaceDetailView: View {
    let space: SharedSpace
    @StateObject private var shareManager = ShareManager.shared
    @State private var showingInviteSheet = false
    @State private var showingShareSheet = false
    @State private var showingLeaveConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showingMemberManagement = false
    @State private var selectedMember: SpaceMember?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                headerCard
                
                // Share Code Section (for owners/admins)
                if shareManager.canInviteToSpace(id: space.id) {
                    shareCodeSection
                }
                
                // Members Section
                membersSection
                
                // Shared Tasks Section
                sharedTasksSection
                
                // Danger Zone
                dangerZoneSection
            }
            .padding(.vertical)
        }
        .navigationTitle(space.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if shareManager.canManageSpace(id: space.id) {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingMemberManagement = true
                    } label: {
                        Image(systemName: "person.badge.gearshape")
                    }
                }
            }
        }
        .sheet(isPresented: $showingInviteSheet) {
            InviteMemberView(spaceId: space.id)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(space: space)
        }
        .sheet(isPresented: $showingMemberManagement) {
            MemberManagementView(space: space)
        }
        .alert("Leave Space?", isPresented: $showingLeaveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                shareManager.leaveSpace(id: space.id)
            }
        } message: {
            Text("You will lose access to all shared tasks in this space.")
        }
        .alert("Delete Space?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                shareManager.deleteSpace(id: space.id)
            }
        } message: {
            Text("This will permanently delete the space and all shared tasks. This cannot be undone.")
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            Text(space.emoji)
                .font(.system(size: 80))
            
            VStack(spacing: 8) {
                Text(space.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text("\(space.memberCount) member\(space.memberCount == 1 ? "" : "s")")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                
                Text("Created by \(space.createdByUserName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Role badge
            let role = shareManager.getMyRole(in: space.id)
            Text(role.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(space.color).opacity(0.2))
                .foregroundColor(Color(space.color))
                .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
    
    // MARK: - Share Code Section
    private var shareCodeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share Code")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                // Code display
                Text(space.shareCode ?? "------")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(12)
                
                // Copy button
                Button {
                    UIPasteboard.general.string = space.shareCode
                    Haptics.shared.success()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(12)
                }
                
                // Share button
                Button {
                    showingShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .frame(width: 50, height: 50)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            Text("Share this code with others to let them join this space")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Members Section
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Members")
                    .font(.headline)
                
                Spacer()
                
                if shareManager.canInviteToSpace(id: space.id) {
                    Button {
                        showingInviteSheet = true
                    } label: {
                        Label("Invite", systemImage: "person.badge.plus")
                            .font(.subheadline)
                    }
                }
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(space.members) { member in
                    MemberRow(member: member, isCurrentUser: member.userId == ShareManager.shared.currentUserId)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Shared Tasks Section
    private var sharedTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Shared Tasks")
                    .font(.headline)
                
                Spacer()
                
                Text("\(space.taskCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if space.tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No shared tasks yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Tasks shared to this space will appear here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(space.tasks.prefix(5), id: \.id) { task in
                        SharedTaskRow(task: task)
                    }
                }
                .padding(.horizontal)
                
                if space.tasks.count > 5 {
                    Text("+ \(space.tasks.count - 5) more tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Danger Zone
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(.headline)
                .foregroundColor(.red)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                if shareManager.isOwner(spaceId: space.id) {
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Space")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.red)
                        .padding()
                    }
                } else {
                    Button {
                        showingLeaveConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "person.fill.xmark")
                            Text("Leave Space")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.orange)
                        .padding()
                    }
                }
            }
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .padding(.top, 20)
    }
}

// MARK: - Member Row
struct MemberRow: View {
    let member: SpaceMember
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(String(member.userName.prefix(1).uppercased()))
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(member.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(member.role.displayName)
                    .font(.caption)
                    .foregroundColor(roleColor)
            }
            
            Spacer()
            
            // Online indicator (placeholder)
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    private var roleColor: Color {
        switch member.role {
        case .owner: return .orange
        case .admin: return .blue
        case .member: return .secondary
        }
    }
}

// MARK: - Shared Task Row
struct SharedTaskRow: View {
    let task: TaskEntity
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled Task")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Image(systemName: task.taskCategory.icon)
                        .font(.caption)
                    Text(task.taskCategory.displayName)
                        .font(.caption)
                }
                .foregroundColor(Color(task.taskCategory.color))
            }
            
            Spacer()
            
            if task.isUrgent {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch task.taskStatus {
        case .todo: return .gray
        case .doing: return .blue
        case .done: return Color("doneColor")
        }
    }
}

// MARK: - Invite Member View
struct InviteMemberView: View {
    let spaceId: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shareManager = ShareManager.shared
    
    @State private var email = ""
    @State private var isInviting = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                }
                
                VStack(spacing: 8) {
                    Text("Invite Member")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter their email address to invite them to this space")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Email input
                VStack(spacing: 16) {
                    TextField("email@example.com", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                    
                    Button {
                        sendInvite()
                    } label: {
                        HStack {
                            if isInviting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Send Invitation")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidEmail ? Color.accentColor : Color.gray)
                        .cornerRadius(16)
                    }
                    .disabled(!isValidEmail || isInviting)
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Privacy note
                Text("They will receive an invitation to join this shared space. Their tasks will be visible to all members.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
            .navigationTitle("Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invitation Sent!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("An invitation has been sent to \(email)")
            }
            .alert("Error", isPresented: .constant(shareManager.errorMessage != nil)) {
                Button("OK") {
                    shareManager.errorMessage = nil
                }
            } message: {
                Text(shareManager.errorMessage ?? "")
            }
        }
    }
    
    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
    
    private func sendInvite() {
        isInviting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shareManager.inviteUser(to: spaceId, email: email)
            isInviting = false
            
            if shareManager.errorMessage == nil {
                showSuccess = true
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: View {
    let space: SharedSpace
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Space info
                VStack(spacing: 16) {
                    Text(space.emoji)
                        .font(.system(size: 80))
                    
                    Text("Join \"\(space.name)\"")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Use this code to join the shared space:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Big code display
                Text(space.shareCode ?? "------")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .tracking(4)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 40)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(16)
                
                // Share buttons
                VStack(spacing: 12) {
                    ShareLink(
                        item: "Join my shared space on TaskSnap! Code: \(space.shareCode ?? "")",
                        subject: Text("Join my TaskSnap Space"),
                        message: Text("Use code \(space.shareCode ?? "") to join \"\(space.name)\"")
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Invitation")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(16)
                    }
                    
                    Button {
                        UIPasteboard.general.string = "Join my TaskSnap space \"\(space.name)\" with code: \(space.shareCode ?? "")"
                        Haptics.shared.success()
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Invitation Text")
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("Share Space")
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

// MARK: - Member Management View
struct MemberManagementView: View {
    let space: SharedSpace
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shareManager = ShareManager.shared
    @State private var selectedMember: SpaceMember?
    @State private var showingRoleSheet = false
    @State private var showingRemoveConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Members") {
                    ForEach(space.members) { member in
                        MemberManagementRow(
                            member: member,
                            isCurrentUser: member.userId == shareManager.currentUserId,
                            canManage: shareManager.canManageMembers(spaceId: space.id) && member.userId != shareManager.currentUserId
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if shareManager.canManageMembers(spaceId: space.id),
                               member.userId != shareManager.currentUserId {
                                selectedMember = member
                                showingRoleSheet = true
                            }
                        }
                    }
                }
                
                // Role explanations
                Section("Roles") {
                    Label("Owner - Full control, can delete space", systemImage: "crown.fill")
                        .font(.caption)
                    Label("Admin - Can invite and manage members", systemImage: "person.badge.shield.checkmark")
                        .font(.caption)
                    Label("Member - Can view and add tasks", systemImage: "person")
                        .font(.caption)
                }
            }
            .navigationTitle("Manage Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Manage Member", isPresented: $showingRoleSheet, presenting: selectedMember) { member in
                if shareManager.isOwner(spaceId: space.id) {
                    Button("Make Owner") {
                        shareManager.transferOwnership(spaceId: space.id, to: member.id)
                    }
                }
                
                if shareManager.canManageMembers(spaceId: space.id) {
                    if member.role != .admin {
                        Button("Make Admin") {
                            shareManager.updateMemberRole(spaceId: space.id, memberId: member.id, newRole: .admin)
                        }
                    }
                    
                    if member.role != .member {
                        Button("Make Member") {
                            shareManager.updateMemberRole(spaceId: space.id, memberId: member.id, newRole: .member)
                        }
                    }
                }
                
                if shareManager.canManageMembers(spaceId: space.id) && member.role != .owner {
                    Button("Remove from Space", role: .destructive) {
                        showingRemoveConfirmation = true
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            }
            .alert("Remove Member?", isPresented: $showingRemoveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    if let member = selectedMember {
                        shareManager.removeMember(spaceId: space.id, memberId: member.id)
                    }
                }
            } message: {
                Text("\(selectedMember?.userName ?? "This member") will lose access to all shared tasks.")
            }
        }
    }
}

// MARK: - Member Management Row
struct MemberManagementRow: View {
    let member: SpaceMember
    let isCurrentUser: Bool
    let canManage: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(String(member.userName.prefix(1).uppercased()))
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(member.userName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(member.role.displayName)
                    .font(.caption)
                    .foregroundColor(roleColor)
            }
            
            Spacer()
            
            if canManage {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var roleColor: Color {
        switch member.role {
        case .owner: return .orange
        case .admin: return .blue
        case .member: return .secondary
        }
    }
}

#Preview {
    SpaceDetailView(space: SharedSpace(
        from: SharedSpaceEntity(),
        context: PersistenceController.preview.container.viewContext
    ))
}
