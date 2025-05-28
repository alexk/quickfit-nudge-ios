import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var teamManager = TeamManager.shared
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @State private var showingCreateTeam = false
    @State private var showingInviteSheet = false
    @State private var showingMemberDetails: TeamMember?
    @State private var inviteEmails = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let team = teamManager.currentTeam {
                        // Team Overview
                        teamOverviewSection(team: team)
                        
                        // Analytics Cards
                        if let analytics = teamManager.teamAnalytics {
                            analyticsSection(analytics: analytics)
                        }
                        
                        // Team Members
                        membersSection(team: team)
                        
                        // Invite Section
                        inviteSection(team: team)
                        
                    } else if subscriptionManager.subscriptionStatus.allowsTeamFeatures {
                        // Create Team Section
                        createTeamSection
                        
                    } else {
                        // Upgrade Required
                        upgradeRequiredSection
                    }
                }
                .padding()
            }
            .navigationTitle("Team Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if teamManager.currentTeam != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Refresh") {
                            Task {
                                await teamManager.refreshTeamData()
                            }
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    if let team = teamManager.currentTeam {
                        await teamManager.refreshTeamData()
                    }
                }
            }
            .sheet(isPresented: $showingCreateTeam) {
                CreateTeamView()
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteMembersView(
                    inviteEmails: $inviteEmails,
                    onInvite: { emails in
                        Task {
                            await inviteMembers(emails: emails)
                        }
                    }
                )
            }
            .sheet(item: $showingMemberDetails) { member in
                MemberDetailsView(member: member)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Team Overview Section
    
    private func teamOverviewSection(team: Team) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(team.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Team Code: \(team.inviteCode)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = team.inviteCode
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("\(teamManager.teamMembers.count)/\(team.maxMembers)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("\(team.availableSlots)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(team.availableSlots > 0 ? .green : .red)
                    Text("Available Slots")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Analytics Section
    
    private func analyticsSection(analytics: TeamAnalytics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team Performance")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Active Members",
                    value: "\(analytics.activeMembers)/\(analytics.totalMembers)",
                    icon: "person.3.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Team Streak Avg",
                    value: "\(String(format: "%.1f", analytics.teamStreakAverage)) days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                MetricCard(
                    title: "Weekly Workouts",
                    value: "\(String(format: "%.1f", analytics.averageWorkoutsPerWeek))",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                MetricCard(
                    title: "Engagement Score",
                    value: "\(Int(analytics.engagementScore * 100))%",
                    icon: "heart.fill",
                    color: engagementColor(analytics.engagementScore)
                )
            }
        }
    }
    
    // MARK: - Members Section
    
    private func membersSection(team: Team) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Team Members")
                    .font(.headline)
                
                Spacer()
                
                if !team.isAtCapacity {
                    Button("Invite") {
                        showingInviteSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(teamManager.teamMembers) { member in
                    MemberRow(
                        member: member,
                        isAdmin: member.id == team.adminUserId,
                        onTap: {
                            showingMemberDetails = member
                        },
                        onRemove: member.id != team.adminUserId ? {
                            Task {
                                await removeMember(userId: member.id, teamId: team.id)
                            }
                        } : nil
                    )
                }
            }
        }
    }
    
    // MARK: - Invite Section
    
    private func inviteSection(team: Team) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pending Invitations")
                .font(.headline)
            
            if teamManager.pendingInvitations.isEmpty {
                Text("No pending invitations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(teamManager.pendingInvitations) { invitation in
                    InvitationRow(invitation: invitation)
                }
            }
        }
    }
    
    // MARK: - Create Team Section
    
    private var createTeamSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Create Your Team")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Manage up to 25 team members and track collective fitness progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Team") {
                showingCreateTeam = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Upgrade Required Section
    
    private var upgradeRequiredSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Team Plan Required")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Upgrade to QuickFit Team to manage up to 25 members with admin dashboard and analytics")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Upgrade to Team Plan") {
                // Navigate to team subscription purchase
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func engagementColor(_ score: Double) -> Color {
        if score > 0.8 { return .green }
        if score > 0.6 { return .yellow }
        if score > 0.4 { return .orange }
        return .red
    }
    
    private func inviteMembers(emails: [String]) async {
        guard let team = teamManager.currentTeam,
              let userId = authManager.currentUser?.id else { return }
        
        do {
            try await teamManager.inviteMembers(
                emails: emails,
                teamId: team.id,
                invitedBy: userId
            )
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func removeMember(userId: String, teamId: UUID) async {
        do {
            try await teamManager.removeMember(userId: userId, teamId: teamId)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MemberRow: View {
    let member: TeamMember
    let isAdmin: Bool
    let onTap: () -> Void
    let onRemove: (() -> Void)?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.name)
                        .font(.headline)
                    
                    if isAdmin {
                        Text("ADMIN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Text(member.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let stats = member.stats {
                    Text("\(stats.weeklyWorkouts) workouts this week • \(stats.currentStreak) day streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                if let onRemove = onRemove {
                    Button("Remove") {
                        onRemove()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
                
                Text(member.isActive ? "Active" : "Inactive")
                    .font(.caption)
                    .foregroundColor(member.isActive ? .green : .secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
    }
}

struct InvitationRow: View {
    let invitation: TeamInvitation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(invitation.email)
                    .font(.headline)
                
                Text("Invited \(invitation.invitedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(invitation.status.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(invitation.status).opacity(0.2))
                .foregroundColor(statusColor(invitation.status))
                .cornerRadius(4)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func statusColor(_ status: TeamInvitation.InvitationStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .expired: return .gray
        }
    }
}

#Preview {
    AdminDashboardView()
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(SubscriptionManager.shared)
}