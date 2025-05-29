import SwiftUI

struct CreateTeamView: View {
    @StateObject private var teamManager = TeamManager.shared
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var teamName = ""
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Team Name", text: $teamName)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Team Information")
                } footer: {
                    Text("Choose a name that represents your team or organization")
                }
                
                Section {
                    teamFeaturesList
                } header: {
                    Text("Team Features")
                }
                
                Section {
                    VStack(spacing: 16) {
                        if isCreating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Creating team...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Button("Create Team") {
                                createTeam()
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                            .disabled(teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        
                        Text("You'll be the team administrator and can invite up to 25 members")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .navigationTitle("Create Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var teamFeaturesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureRow(
                icon: "person.3.fill",
                title: "Up to 25 Members",
                description: "Invite colleagues, friends, or family"
            )
            
            FeatureRow(
                icon: "chart.bar.fill",
                title: "Team Analytics",
                description: "Track collective progress and engagement"
            )
            
            FeatureRow(
                icon: "trophy.fill",
                title: "Team Challenges",
                description: "Compete together and stay motivated"
            )
            
            FeatureRow(
                icon: "gear.badge",
                title: "Admin Controls",
                description: "Manage members and view detailed insights"
            )
            
            FeatureRow(
                icon: "lock.shield.fill",
                title: "Privacy Focused",
                description: "Individual data remains private"
            )
        }
    }
    
    private func createTeam() {
        let trimmedName = teamName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        guard let userId = authManager.currentUser?.id else {
            errorMessage = "User not authenticated"
            showingError = true
            return
        }
        
        guard subscriptionManager.subscriptionStatus.allowsTeamFeatures else {
            errorMessage = "Team subscription required"
            showingError = true
            return
        }
        
        isCreating = true
        
        Task {
            do {
                // In a real implementation, this would use the actual subscription ID
                let mockSubscriptionId = "team_sub_\(UUID().uuidString)"
                
                let team = try await teamManager.createTeam(
                    name: trimmedName,
                    adminId: userId,
                    subscriptionId: mockSubscriptionId
                )
                
                await MainActor.run {
                    isCreating = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Invite Members View

struct InviteMembersView: View {
    @Binding var inviteEmails: String
    let onInvite: ([String]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var emailAddresses: [String] = []
    @State private var currentEmail = ""
    @State private var isValidatingEmails = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Enter email address", text: $currentEmail)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onSubmit {
                                addEmail()
                            }
                        
                        Button("Add Email") {
                            addEmail()
                        }
                        .disabled(currentEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("Email Addresses")
                } footer: {
                    Text("Enter email addresses one at a time. Each person will receive an invitation to join your team.")
                }
                
                if !emailAddresses.isEmpty {
                    Section {
                        ForEach(emailAddresses, id: \.self) { email in
                            HStack {
                                Text(email)
                                Spacer()
                                Button("Remove") {
                                    removeEmail(email)
                                }
                                .foregroundColor(.red)
                            }
                        }
                    } header: {
                        Text("Invitations to Send (\(emailAddresses.count))")
                    }
                }
                
                Section {
                    Button("Send Invitations") {
                        sendInvitations()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(emailAddresses.isEmpty)
                }
            }
            .navigationTitle("Invite Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addEmail() {
        let email = currentEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !email.isEmpty,
              isValidEmail(email),
              !emailAddresses.contains(email) else {
            return
        }
        
        emailAddresses.append(email)
        currentEmail = ""
    }
    
    private func removeEmail(_ email: String) {
        emailAddresses.removeAll { $0 == email }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func sendInvitations() {
        onInvite(emailAddresses)
        dismiss()
    }
}

// MARK: - Member Details View

struct MemberDetailsView: View {
    let member: TeamMember
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Member Header
                    memberHeaderSection
                    
                    // Statistics
                    if let stats = member.stats {
                        memberStatsSection(stats: stats)
                    }
                    
                    // Activity Information
                    memberActivitySection
                }
                .padding()
            }
            .navigationTitle("Member Details")
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
    
    private var memberHeaderSection: some View {
        VStack(alignment: .center, spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(member.name.prefix(2)).uppercased())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )
            
            VStack(spacing: 4) {
                Text(member.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(member.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(member.role.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(member.role == .admin ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text(member.isActive ? "Active" : "Inactive")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(member.isActive ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func memberStatsSection(stats: MemberStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(title: "Total Workouts", value: "\(stats.totalWorkouts)")
                StatCard(title: "This Week", value: "\(stats.weeklyWorkouts)")
                StatCard(title: "Current Streak", value: "\(stats.currentStreak) days")
                StatCard(title: "Total Minutes", value: "\(stats.totalMinutes)")
            }
            
            if !stats.favoriteWorkoutType.isEmpty {
                HStack {
                    Text("Favorite Workout Type:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(stats.favoriteWorkoutType)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    private var memberActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Joined Team:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(member.joinedAt, style: .date)
                        .font(.subheadline)
                }
                
                if let lastActive = member.lastActiveAt {
                    HStack {
                        Text("Last Active:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(lastActive, style: .relative)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    CreateTeamView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(SubscriptionManager.shared)
}