import SwiftUI

struct StreaksView: View {
    @StateObject private var viewModel = StreaksViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Streaks").tag(0)
                    Text("Achievements").tag(1)
                    Text("Leaderboard").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    StreakListView(streaks: viewModel.streaks)
                        .tag(0)
                    
                    AchievementsGridView(achievements: viewModel.achievements)
                        .tag(1)
                    
                    LeaderboardView(entries: viewModel.leaderboardEntries)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                        Text("\(viewModel.totalPoints)")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Streak List View
struct StreakListView: View {
    let streaks: [Streak]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(streaks) { streak in
                    StreakCard(streak: streak)
                }
            }
            .padding()
        }
    }
}

// MARK: - Streak Card
struct StreakCard: View {
    let streak: Streak
    
    var body: some View {
        HStack {
            // Icon
            ZStack {
                Circle()
                    .fill(streak.isActive ? Color.orange : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: streak.type.iconName)
                    .font(.title2)
                    .foregroundColor(streak.isActive ? .white : .gray)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(streak.type.rawValue)
                    .font(.headline)
                
                Text(streak.type.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Label("\(streak.currentCount) days", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(streak.isActive ? .orange : .gray)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("Best: \(streak.longestCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Streak count
            if streak.currentCount > 0 {
                VStack {
                    Text("\(streak.currentCount)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(streak.isActive ? .orange : .gray)
                    
                    Image(systemName: "flame.fill")
                        .foregroundColor(streak.isActive ? .orange : .gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Achievements Grid View
struct AchievementsGridView: View {
    let achievements: [Achievement]
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
            .padding()
        }
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            // Badge icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? 
                          Color(achievement.type.tier.color).opacity(0.2) : 
                          Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                if achievement.isUnlocked {
                    Image(systemName: achievement.iconName)
                        .font(.largeTitle)
                        .foregroundColor(Color(achievement.type.tier.color))
                } else {
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        
                        Circle()
                            .trim(from: 0, to: achievement.progressPercentage)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(achievement.progressPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(width: 60, height: 60)
                }
            }
            
            // Name
            Text(achievement.name)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Progress or unlock date
            if achievement.isUnlocked, let unlockedAt = achievement.unlockedAt {
                Text(unlockedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(Int(achievement.progress))/\(achievement.target)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leaderboard View
struct LeaderboardView: View {
    let entries: [LeaderboardEntry]
    @State private var selectedTimeframe: LeaderboardEntry.Timeframe = .weekly
    
    var filteredEntries: [LeaderboardEntry] {
        entries.filter { $0.timeframe == selectedTimeframe }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Timeframe picker
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(LeaderboardEntry.Timeframe.allCases, id: \.self) { timeframe in
                    Label(timeframe.rawValue, systemImage: timeframe.iconName)
                        .tag(timeframe)
                }
            }
            .pickerStyle(.menu)
            .padding()
            
            // Leaderboard list
            List {
                ForEach(filteredEntries) { entry in
                    LeaderboardRow(entry: entry)
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Leaderboard Row
struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    
    var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .primary
        }
    }
    
    var body: some View {
        HStack {
            // Rank
            Text("#\(entry.rank)")
                .font(.headline)
                .foregroundColor(rankColor)
                .frame(width: 40)
            
            // Avatar placeholder
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(entry.userName.prefix(2).uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                )
            
            // Name
            VStack(alignment: .leading) {
                Text(entry.userName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(entry.score) points")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Medal for top 3
            if entry.rank <= 3 {
                Image(systemName: "medal.fill")
                    .foregroundColor(rankColor)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - View Model
@MainActor
class StreaksViewModel: ObservableObject {
    @Published var streaks: [Streak] = []
    @Published var achievements: [Achievement] = []
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var totalPoints = 0
    
    func loadData() async {
        // Load streaks
        streaks = [
            Streak(
                userId: "current",
                type: .daily,
                currentCount: 7,
                longestCount: 14
            ),
            Streak(
                userId: "current",
                type: .dadKid,
                currentCount: 3,
                longestCount: 5
            ),
            Streak(
                userId: "current",
                type: .earlyBird,
                currentCount: 0,
                longestCount: 10
            )
        ]
        
        // Load achievements
        achievements = [
            Achievement(
                type: .firstWorkout,
                name: "First Steps",
                description: "Complete your first workout",
                iconName: "figure.walk",
                unlockedAt: Date(),
                progress: 1,
                target: 1
            ),
            Achievement(
                type: .weekWarrior,
                name: "Week Warrior",
                description: "Complete 7 workouts in a week",
                iconName: "calendar.badge.checkmark",
                progress: 5,
                target: 7
            ),
            Achievement(
                type: .dadOfTheYear,
                name: "Dad of the Year",
                description: "Complete 50 dad-kid workouts",
                iconName: "figure.2.and.child.holdinghands",
                progress: 12,
                target: 50
            )
        ]
        
        // Load leaderboard
        leaderboardEntries = [
            LeaderboardEntry(
                userId: "user1",
                userName: "Mike Johnson",
                score: 1250,
                rank: 1,
                timeframe: .weekly
            ),
            LeaderboardEntry(
                userId: "user2",
                userName: "David Smith",
                score: 980,
                rank: 2,
                timeframe: .weekly
            ),
            LeaderboardEntry(
                userId: "current",
                userName: "You",
                score: 850,
                rank: 3,
                timeframe: .weekly
            )
        ]
        
        totalPoints = 850
    }
}

// MARK: - Preview
#Preview {
    StreaksView()
} 