import SwiftUI

struct LibraryView: View {
    @State private var searchText = ""
    @State private var selectedType: WorkoutType?
    @State private var selectedDifficulty: Workout.Difficulty?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search workouts...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(WorkoutType.allCases, id: \.self) { type in
                                FilterChip(
                                    title: type.rawValue,
                                    isSelected: selectedType == type,
                                    action: {
                                        selectedType = selectedType == type ? nil : type
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Workout categories
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Popular Workouts")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Placeholder workout cards
                        ForEach(0..<5) { _ in
                            WorkoutLibraryCard()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Workout Library")
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct WorkoutLibraryCard: View {
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "figure.run")
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Quick HIIT Blast")
                    .font(.headline)
                
                Text("3 minutes • High Intensity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Label("4.8", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("1.2k workouts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Preview
#Preview {
    LibraryView()
} 