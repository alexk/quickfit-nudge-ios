import SwiftUI

struct KidsView: View {
    @State private var selectedKidAge = 5
    @State private var showingAddKid = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Kids profile section
                    KidsProfileSection()
                    
                    // Age-appropriate workouts
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Perfect for Ages \(selectedKidAge-1)-\(selectedKidAge+1)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<5) { _ in
                                    KidWorkoutCard()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Challenges section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Dad-Kid Challenges")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("See all") {
                                // Navigate to challenges
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ChallengeCard(
                                title: "7-Day Dance Party",
                                description: "Dance together for 5 minutes every day",
                                progress: 0.43
                            )
                            
                            ChallengeCard(
                                title: "Animal Kingdom",
                                description: "Master 10 different animal movements",
                                progress: 0.7
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Tips section
                    DadTipsSection()
                }
            }
            .navigationTitle("Kids Activities")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddKid = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddKid) {
                AddKidView()
            }
        }
    }
}

struct KidsProfileSection: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<3) { index in
                    VStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("👦")
                                    .font(.largeTitle)
                            )
                        
                        Text("Alex")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text("Age 5")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Add kid button
                VStack {
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.blue)
                        )
                    
                    Text("Add Kid")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct KidWorkoutCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 120)
                .overlay(
                    VStack {
                        Text("🦘")
                            .font(.system(size: 40))
                        Text("Kangaroo Hops")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("3 minutes")
                    .font(.caption)
                    .fontWeight(.medium)
                
                HStack {
                    Image(systemName: "face.smiling")
                    Text("Super Fun!")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }
}

struct ChallengeCard: View {
    let title: String
    let description: String
    let progress: Double
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                ProgressView(value: progress)
                    .tint(.purple)
                
                Text("\(Int(progress * 100))% Complete")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundColor(.yellow)
                .opacity(progress >= 1.0 ? 1 : 0.3)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DadTipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dad Tips")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Make it a game - kids love competition!", systemImage: "gamecontroller")
                Label("Use their favorite music for dance workouts", systemImage: "music.note")
                Label("Let them choose the next exercise", systemImage: "hand.raised")
                Label("Celebrate every achievement, big or small", systemImage: "star")
            }
            .font(.subheadline)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct AddKidView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var kidName = ""
    @State private var kidAge = 5
    @State private var selectedEmoji = "👦"
    
    let emojiOptions = ["👦", "👧", "👶", "🧒"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Kid's Info") {
                    TextField("Name", text: $kidName)
                    
                    Picker("Age", selection: $kidAge) {
                        ForEach(1...18, id: \.self) { age in
                            Text("\(age) years old").tag(age)
                        }
                    }
                    
                    HStack {
                        Text("Avatar")
                        Spacer()
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title)
                                .padding(8)
                                .background(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedEmoji = emoji
                                }
                        }
                    }
                }
                
                Section {
                    Button(action: saveKid) {
                        Text("Add Kid")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(kidName.isEmpty)
                }
            }
            .navigationTitle("Add Kid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func saveKid() {
        // Save kid profile
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    KidsView()
} 