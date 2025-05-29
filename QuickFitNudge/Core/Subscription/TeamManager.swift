import Foundation
import CloudKit

// MARK: - Team Models

struct Team: Identifiable, Codable {
    let id: UUID
    let name: String
    let adminUserId: String
    let memberIds: [String]
    let createdAt: Date
    let subscriptionId: String
    let inviteCode: String
    let maxMembers: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        adminUserId: String,
        memberIds: [String] = [],
        createdAt: Date = Date(),
        subscriptionId: String,
        inviteCode: String = "",
        maxMembers: Int = 25
    ) {
        self.id = id
        self.name = name
        self.adminUserId = adminUserId
        self.memberIds = memberIds
        self.createdAt = createdAt
        self.subscriptionId = subscriptionId
        self.inviteCode = inviteCode.isEmpty ? Self.generateInviteCode() : inviteCode
        self.maxMembers = maxMembers
    }
    
    var isAtCapacity: Bool {
        memberIds.count >= maxMembers
    }
    
    var availableSlots: Int {
        max(0, maxMembers - memberIds.count)
    }
    
    private static func generateInviteCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}

struct TeamMember: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let joinedAt: Date
    let role: TeamRole
    let isActive: Bool
    let lastActiveAt: Date?
    let stats: MemberStats?
    
    enum TeamRole: String, Codable, CaseIterable {
        case admin = "admin"
        case member = "member"
        
        var displayName: String {
            switch self {
            case .admin: return "Admin"
            case .member: return "Member"
            }
        }
    }
}

struct MemberStats: Codable {
    let totalWorkouts: Int
    let weeklyWorkouts: Int
    let currentStreak: Int
    let totalMinutes: Int
    let favoriteWorkoutType: String
    let lastWorkoutDate: Date?
}

struct TeamAnalytics: Codable {
    let totalMembers: Int
    let activeMembers: Int
    let totalWorkouts: Int
    let totalMinutes: Int
    let averageWorkoutsPerWeek: Double
    let teamStreakAverage: Double
    let mostPopularWorkoutType: String
    let engagementScore: Double
    let weeklyActivity: [String: Int] // Date -> workout count
    let memberEngagement: [String: MemberEngagement]
}

struct MemberEngagement: Codable {
    let userId: String
    let name: String
    let workoutsThisWeek: Int
    let currentStreak: Int
    let engagementLevel: EngagementLevel
    
    enum EngagementLevel: String, Codable {
        case high = "high"
        case medium = "medium"
        case low = "low"
        case inactive = "inactive"
        
        var displayName: String {
            switch self {
            case .high: return "High"
            case .medium: return "Medium" 
            case .low: return "Low"
            case .inactive: return "Inactive"
            }
        }
        
        var color: String {
            switch self {
            case .high: return "green"
            case .medium: return "yellow"
            case .low: return "orange"
            case .inactive: return "red"
            }
        }
    }
}

struct TeamInvitation: Identifiable, Codable {
    let id: UUID
    let teamId: UUID
    let email: String
    let invitedBy: String
    let invitedAt: Date
    let expiresAt: Date
    let status: InvitationStatus
    
    enum InvitationStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
        case expired = "expired"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .accepted: return "Accepted"
            case .declined: return "Declined"
            case .expired: return "Expired"
            }
        }
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
}

// MARK: - Team Manager

@MainActor
final class TeamManager: ObservableObject {
    static let shared = TeamManager()
    
    @Published private(set) var currentTeam: Team?
    @Published private(set) var teamMembers: [TeamMember] = []
    @Published private(set) var teamAnalytics: TeamAnalytics?
    @Published private(set) var pendingInvitations: [TeamInvitation] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let cloudKitManager = CloudKitManager.shared
    private let authManager = AuthenticationManager.shared
    
    private init() {}
    
    // MARK: - Team Creation & Management
    
    func createTeam(name: String, adminId: String, subscriptionId: String) async throws -> Team {
        isLoading = true
        defer { isLoading = false }
        
        let team = Team(
            name: name,
            adminUserId: adminId,
            memberIds: [adminId], // Admin is automatically a member
            subscriptionId: subscriptionId
        )
        
        do {
            // Save team to CloudKit
            try await saveTeamToCloudKit(team)
            
            // Add admin as first member
            let adminMember = TeamMember(
                id: adminId,
                email: authManager.currentUser?.email ?? "",
                name: authManager.currentUser?.displayName ?? "Team Admin",
                joinedAt: Date(),
                role: .admin,
                isActive: true,
                lastActiveAt: Date(),
                stats: nil
            )
            
            try await addMemberToCloudKit(adminMember, teamId: team.id)
            
            await MainActor.run {
                self.currentTeam = team
                self.teamMembers = [adminMember]
            }
            
            logInfo("Created team '\(name)' with invite code: \(team.inviteCode)", category: .general)
            return team
            
        } catch {
            logError("Failed to create team: \(error)", category: .general)
            throw TeamError.creationFailed
        }
    }
    
    func inviteMembers(emails: [String], teamId: UUID, invitedBy: String) async throws {
        guard let team = currentTeam, team.id == teamId else {
            throw TeamError.teamNotFound
        }
        
        guard !team.isAtCapacity else {
            throw TeamError.teamAtCapacity
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let availableSlots = team.availableSlots
        let emailsToInvite = Array(emails.prefix(availableSlots))
        
        for email in emailsToInvite {
            let invitation = TeamInvitation(
                id: UUID(),
                teamId: teamId,
                email: email,
                invitedBy: invitedBy,
                invitedAt: Date(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                status: .pending
            )
            
            try await saveInvitationToCloudKit(invitation)
            
            // In a real implementation, this would send an email
            logInfo("Sent invitation to \(email) for team \(team.name)", category: .general)
        }
        
        await loadPendingInvitations(for: teamId)
    }
    
    func removeMember(userId: String, teamId: UUID) async throws {
        guard let team = currentTeam, team.id == teamId else {
            throw TeamError.teamNotFound
        }
        
        guard userId != team.adminUserId else {
            throw TeamError.cannotRemoveAdmin
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await removeMemberFromCloudKit(userId, teamId: teamId)
            
            await MainActor.run {
                self.teamMembers.removeAll { $0.id == userId }
                if let updatedTeam = self.currentTeam {
                    let updatedMemberIds = updatedTeam.memberIds.filter { $0 != userId }
                    self.currentTeam = Team(
                        id: updatedTeam.id,
                        name: updatedTeam.name,
                        adminUserId: updatedTeam.adminUserId,
                        memberIds: updatedMemberIds,
                        createdAt: updatedTeam.createdAt,
                        subscriptionId: updatedTeam.subscriptionId,
                        inviteCode: updatedTeam.inviteCode,
                        maxMembers: updatedTeam.maxMembers
                    )
                }
            }
            
            logInfo("Removed member \(userId) from team", category: .general)
            
        } catch {
            logError("Failed to remove member: \(error)", category: .general)
            throw TeamError.removalFailed
        }
    }
    
    func joinTeam(inviteCode: String, userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let team = try await findTeamByInviteCode(inviteCode)
            
            guard !team.isAtCapacity else {
                throw TeamError.teamAtCapacity
            }
            
            guard !team.memberIds.contains(userId) else {
                throw TeamError.alreadyMember
            }
            
            let newMember = TeamMember(
                id: userId,
                email: authManager.currentUser?.email ?? "",
                name: authManager.currentUser?.displayName ?? "Team Member",
                joinedAt: Date(),
                role: .member,
                isActive: true,
                lastActiveAt: Date(),
                stats: nil
            )
            
            try await addMemberToCloudKit(newMember, teamId: team.id)
            
            await MainActor.run {
                self.currentTeam = team
                self.teamMembers.append(newMember)
            }
            
            logInfo("User \(userId) joined team \(team.name)", category: .general)
            
        } catch {
            logError("Failed to join team: \(error)", category: .general)
            throw error
        }
    }
    
    // MARK: - Analytics
    
    func getTeamAnalytics(teamId: UUID) async throws -> TeamAnalytics {
        isLoading = true
        defer { isLoading = false }
        
        // In a real implementation, this would aggregate data from CloudKit
        // For now, we'll generate mock analytics
        
        let analytics = generateMockAnalytics()
        
        await MainActor.run {
            self.teamAnalytics = analytics
        }
        
        return analytics
    }
    
    func refreshTeamData() async {
        guard let team = currentTeam else { return }
        
        do {
            async let membersTask = loadTeamMembers(for: team.id)
            async let analyticsTask = getTeamAnalytics(teamId: team.id)
            async let invitationsTask = loadPendingInvitations(for: team.id)
            
            let (members, analytics, _) = try await (membersTask, analyticsTask, invitationsTask)
            
            await MainActor.run {
                self.teamMembers = members
                self.teamAnalytics = analytics
            }
            
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    // MARK: - Private CloudKit Methods
    
    private func saveTeamToCloudKit(_ team: Team) async throws {
        // CloudKit implementation would go here
        // For now, just simulate success
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
    }
    
    private func addMemberToCloudKit(_ member: TeamMember, teamId: UUID) async throws {
        // CloudKit implementation would go here
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func removeMemberFromCloudKit(_ userId: String, teamId: UUID) async throws {
        // CloudKit implementation would go here
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func saveInvitationToCloudKit(_ invitation: TeamInvitation) async throws {
        // CloudKit implementation would go here
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
    }
    
    private func findTeamByInviteCode(_ code: String) async throws -> Team {
        // CloudKit query implementation would go here
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 second delay
        
        // Mock team for demonstration
        return Team(
            name: "Sample Team",
            adminUserId: "admin123",
            memberIds: ["admin123"],
            subscriptionId: "sub123",
            inviteCode: code
        )
    }
    
    private func loadTeamMembers(for teamId: UUID) async throws -> [TeamMember] {
        // CloudKit query implementation would go here
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return teamMembers // Return current members for now
    }
    
    private func loadPendingInvitations(for teamId: UUID) async throws {
        // CloudKit query implementation would go here
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        await MainActor.run {
            self.pendingInvitations = [] // Mock empty invitations
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockAnalytics() -> TeamAnalytics {
        let memberCount = teamMembers.count
        let activeCount = max(1, Int(Double(memberCount) * 0.8))
        
        let engagement = teamMembers.reduce(into: [String: MemberEngagement]()) { result, member in
            result[member.id] = MemberEngagement(
                userId: member.id,
                name: member.name,
                workoutsThisWeek: Int.random(in: 0...10),
                currentStreak: Int.random(in: 0...30),
                engagementLevel: MemberEngagement.EngagementLevel.allCases.randomElement() ?? .medium
            )
        }
        
        return TeamAnalytics(
            totalMembers: memberCount,
            activeMembers: activeCount,
            totalWorkouts: Int.random(in: 50...500),
            totalMinutes: Int.random(in: 200...2000),
            averageWorkoutsPerWeek: Double.random(in: 2.0...8.0),
            teamStreakAverage: Double.random(in: 3.0...15.0),
            mostPopularWorkoutType: "HIIT",
            engagementScore: Double.random(in: 0.5...1.0),
            weeklyActivity: [:],
            memberEngagement: engagement
        )
    }
    
    private func logInfo(_ message: String, category: LogCategory) {
        Logger.shared.info(message, category: category)
    }
    
    private func logError(_ message: String, category: LogCategory) {
        Logger.shared.error(message, category: category)
    }
}

// MARK: - Team Errors

enum TeamError: LocalizedError {
    case creationFailed
    case teamNotFound
    case teamAtCapacity
    case cannotRemoveAdmin
    case removalFailed
    case alreadyMember
    case invalidInviteCode
    case subscriptionRequired
    
    var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Failed to create team"
        case .teamNotFound:
            return "Team not found"
        case .teamAtCapacity:
            return "Team is at maximum capacity (25 members)"
        case .cannotRemoveAdmin:
            return "Cannot remove team administrator"
        case .removalFailed:
            return "Failed to remove team member"
        case .alreadyMember:
            return "You're already a member of this team"
        case .invalidInviteCode:
            return "Invalid invite code"
        case .subscriptionRequired:
            return "Team subscription required"
        }
    }
}