import SwiftUI

struct SharedSpacesListView: View {
    @StateObject private var shareManager = ShareManager.shared
    @State private var showingCreateSpace = false
    @State private var showingJoinSpace = false
    @State private var showingInvitations = false
    @State private var selectedSpace: SharedSpace?
    
    var body: some View {
        NavigationView {
            List {
                // Invitations Section
                if !shareManager.pendingInvitations.isEmpty {
                    invitationsSection
                }
                
                // My Spaces Section
                mySpacesSection
                
                // Empty State
                if shareManager.spaces.isEmpty && shareManager.pendingInvitations.isEmpty {
                    emptyStateSection
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Shared Spaces")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingCreateSpace = true
                        } label: {
                            Label("Create Space", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showingJoinSpace = true
                        } label: {
                            Label("Join Space", systemImage: "person.badge.key")
                        }
                        
                        if !shareManager.invitations.isEmpty {
                            Button {
                                showingInvitations = true
                            } label: {
                                Label("Invitations", systemImage: "envelope")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSpace) {
                CreateSpaceView()
            }
            .sheet(isPresented: $showingJoinSpace) {
                JoinSpaceView()
            }
            .sheet(isPresented: $showingInvitations) {
                InvitationsView()
            }
            .onAppear {
                shareManager.fetchSpaces()
                shareManager.fetchInvitations()
            }
        }
    }
    
    // MARK: - Invitations Section
    private var invitationsSection: some View {
        Section {
            Button {
                showingInvitations = true
            } label: {
                HStack {
                    Image(systemName: "envelope.badge.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(shareManager.pendingInvitations.count) Pending Invitation\(shareManager.pendingInvitations.count == 1 ? "" : "s")")
                            .font(.headline)
                        
                        Text("Tap to view and respond")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Invitations")
        }
    }
    
    // MARK: - My Spaces Section
    private var mySpacesSection: some View {
        Section {
            ForEach(shareManager.spaces) { space in
                NavigationLink(destination: SpaceDetailView(space: space)) {
                    SpaceRow(space: space)
                }
            }
        } header: {
            Text("My Spaces")
        }
    }
    
    // MARK: - Empty State
    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 20) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary.opacity(0.5))
                
                Text("No Shared Spaces")
                    .font(.headline)
                
                Text("Create a space to share tasks with family, roommates, or coworkers")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack(spacing: 12) {
                    Button {
                        showingCreateSpace = true
                    } label: {
                        Label("Create", systemImage: "plus")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        showingJoinSpace = true
                    } label: {
                        Label("Join", systemImage: "key")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Space Row
struct SpaceRow: View {
    let space: SharedSpace
    
    var body: some View {
        HStack(spacing: 16) {
            // Emoji Icon
            Text(space.emoji)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(Color(space.color).opacity(0.2))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(space.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(space.memberCount)", systemImage: "person.2")
                    Label("\(space.taskCount)", systemImage: "checkmark.circle")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Text("Created by \(space.createdByUserName)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Role badge
            let role = ShareManager.shared.getMyRole(in: space.id)
            Text(role.displayName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(role == .owner ? .orange : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (role == .owner ? Color.orange : Color.secondary)
                        .opacity(0.15)
                )
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Space View
struct CreateSpaceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shareManager = ShareManager.shared
    
    @State private var spaceName = ""
    @State private var selectedEmoji = "🏠"
    @State private var selectedColor = "blue"
    
    let emojis = ["🏠", "👨‍👩‍👧‍👦", "💼", "🎓", "🏢", "❤️", "🤝", "🎯", "🌟", "🔥"]
    let colors = [
        ("blue", Color.blue),
        ("green", Color.green),
        ("orange", Color.orange),
        ("purple", Color.purple),
        ("pink", Color.pink),
        ("red", Color.red),
        ("yellow", Color.yellow),
        ("indigo", Color.indigo)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Space Name") {
                    TextField("e.g., Family Tasks", text: $spaceName)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                                Haptics.shared.selectionChanged()
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .frame(width: 50, height: 50)
                                    .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedEmoji == emoji ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Color") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 12) {
                        ForEach(colors, id: \.0) { colorName, color in
                            Button {
                                selectedColor = colorName
                                Haptics.shared.selectionChanged()
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == colorName ? Color.white : Color.clear, lineWidth: 3)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == colorName ? color : Color.clear, lineWidth: selectedColor == colorName ? 5 : 0)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button {
                        createSpace()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Create Space")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(spaceName.isEmpty)
                }
            }
            .navigationTitle("Create Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
    
    private func createSpace() {
        guard !spaceName.isEmpty else { return }
        
        if let space = shareManager.createSpace(name: spaceName, emoji: selectedEmoji, color: selectedColor) {
            dismiss()
        }
    }
}

// MARK: - Join Space View
struct JoinSpaceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shareManager = ShareManager.shared
    
    @State private var shareCode = ""
    @State private var isJoining = false
    @State private var joinSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "key.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                }
                
                VStack(spacing: 8) {
                    Text("Join a Space")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter the 6-character share code to join a shared space")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Code input
                VStack(spacing: 16) {
                    TextField("ABC123", text: $shareCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .textCase(.uppercase)
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(height: 60)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 40)
                        .onChange(of: shareCode) { _, newValue in
                            // Auto-uppercase and limit to 6 characters
                            shareCode = String(newValue.uppercased().prefix(6))
                        }
                    
                    Button {
                        joinSpace()
                    } label: {
                        HStack {
                            if isJoining {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Join Space")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(shareCode.count == 6 ? Color.accentColor : Color.gray)
                        .cornerRadius(16)
                    }
                    .disabled(shareCode.count != 6 || isJoining)
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Alternative
                VStack(spacing: 8) {
                    Text("Have an invitation?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button {
                        dismiss()
                        // Would show invitations
                    } label: {
                        Text("Check Invitations")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Join Space")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $joinSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("You've successfully joined the space.")
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
    
    private func joinSpace() {
        isJoining = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let success = shareManager.joinSpace(with: shareCode)
            isJoining = false
            
            if success {
                joinSuccess = true
            }
        }
    }
}

// MARK: - Invitations View
struct InvitationsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shareManager = ShareManager.shared
    
    var body: some View {
        NavigationView {
            List {
                if shareManager.pendingInvitations.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "envelope.open")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Text("No Pending Invitations")
                                .font(.headline)
                            
                            Text("Invitations from others will appear here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                } else {
                    Section("Pending") {
                        ForEach(shareManager.pendingInvitations) { invitation in
                            InvitationRow(invitation: invitation)
                        }
                    }
                }
                
                // Show declined/expired for reference
                let otherInvitations = shareManager.invitations.filter { $0.status != .pending }
                if !otherInvitations.isEmpty {
                    Section("History") {
                        ForEach(otherInvitations) { invitation in
                            InvitationRow(invitation: invitation, isHistory: true)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Invitations")
            .navigationBarTitleDisplayMode(.large)
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

// MARK: - Invitation Row
struct InvitationRow: View {
    let invitation: ShareInvitation
    var isHistory: Bool = false
    @StateObject private var shareManager = ShareManager.shared
    @State private var isProcessing = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(invitation.spaceName)
                    .font(.headline)
                
                Text("From: \(invitation.invitedByUserName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if invitation.isExpired {
                    Text("Expired")
                        .font(.caption)
                        .foregroundColor(.red)
                } else if isHistory {
                    Text(invitation.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Expires: \(invitation.expiresAt?.formattedString(style: .short) ?? "Soon")")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if !isHistory && !invitation.isExpired && invitation.status == .pending {
                HStack(spacing: 8) {
                    Button {
                        decline()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        accept()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isProcessing)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var iconName: String {
        if invitation.isExpired { return "envelope.badge.xmark" }
        if isHistory {
            return invitation.status == .accepted ? "envelope.badge.checkmark" : "envelope.badge.minus"
        }
        return "envelope.badge.fill"
    }
    
    private func accept() {
        isProcessing = true
        shareManager.acceptInvitation(invitation.id)
        isProcessing = false
    }
    
    private func decline() {
        shareManager.declineInvitation(invitation.id)
    }
}

#Preview {
    SharedSpacesListView()
}
