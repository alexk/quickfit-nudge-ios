import SwiftUI

struct CalendarSettingsView: View {
    @StateObject private var integrationManager = CalendarIntegrationManager.shared
    @State private var showingConnectionError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    calendarStatusSection
                } header: {
                    Text("Connected Calendars")
                } footer: {
                    Text("Connect your calendars to automatically detect micro-workout opportunities in your schedule.")
                }
                
                Section {
                    connectionActionsSection
                } header: {
                    Text("Calendar Sources")
                }
                
                if integrationManager.hasAnyCalendarAccess {
                    Section {
                        gapDetectionPreferencesSection
                    } header: {
                        Text("Gap Detection")
                    } footer: {
                        Text("Customize how we find workout opportunities in your calendar.")
                    }
                }
                
                Section {
                    helpSection
                } header: {
                    Text("Help & Information")
                }
            }
            .navigationTitle("Calendar Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Connection Error", isPresented: $showingConnectionError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Update connection status when view appears
                Task {
                    await refreshConnectionStatus()
                }
            }
        }
    }
    
    // MARK: - Calendar Status Section
    
    private var calendarStatusSection: some View {
        VStack(spacing: 12) {
            if integrationManager.connectedCalendars.isEmpty {
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .foregroundColor(.orange)
                    Text("No calendars connected")
                        .font(.subheadline)
                    Spacer()
                }
            } else {
                ForEach(integrationManager.connectedCalendars) { calendar in
                    CalendarConnectionRow(
                        calendar: calendar,
                        onDisconnect: {
                            Task {
                                await disconnectCalendar(calendar.type)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Connection Actions Section
    
    private var connectionActionsSection: some View {
        VStack(spacing: 12) {
            // iOS Calendar Connection
            CalendarConnectionButton(
                type: .apple,
                isConnected: integrationManager.hasAppleCalendarAccess,
                isConnecting: integrationManager.isConnecting,
                onConnect: {
                    Task {
                        await connectAppleCalendar()
                    }
                },
                onDisconnect: {
                    Task {
                        await disconnectCalendar(.apple)
                    }
                }
            )
            
            // Google Calendar Connection
            CalendarConnectionButton(
                type: .google,
                isConnected: integrationManager.hasGoogleCalendarAccess,
                isConnecting: integrationManager.isConnecting,
                onConnect: {
                    Task {
                        await connectGoogleCalendar()
                    }
                },
                onDisconnect: {
                    Task {
                        await disconnectCalendar(.google)
                    }
                }
            )
        }
    }
    
    // MARK: - Gap Detection Preferences
    
    private var gapDetectionPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Minimum Gap Duration")
                    .font(.headline)
                
                Text("Only detect gaps of at least this duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // In a real implementation, this would be a setting
                HStack {
                    Text("1 minute")
                    Spacer()
                    Text("Currently: 1 minute")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Maximum Gap Duration")
                    .font(.headline)
                
                Text("Don't suggest workouts for gaps longer than this")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("5 minutes")
                    Spacer()
                    Text("Currently: 5 minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Scan Window")
                    .font(.headline)
                
                Text("How far ahead to look for gaps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("48 hours")
                    Spacer()
                    Text("Currently: 48 hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Help Section
    
    private var helpSection: some View {
        VStack(spacing: 12) {
            HelpRow(
                icon: "questionmark.circle",
                title: "How does calendar integration work?",
                description: "We scan your calendars for gaps between meetings and suggest quick workouts that fit perfectly."
            )
            
            HelpRow(
                icon: "lock.shield",
                title: "Is my calendar data private?",
                description: "Yes! We only read event times to find gaps. Event details and content are never accessed or stored."
            )
            
            HelpRow(
                icon: "arrow.clockwise",
                title: "How often do calendars sync?",
                description: "Calendars sync automatically when you open the app and every hour while the app is active."
            )
            
            NavigationLink(destination: CalendarDebugView()) {
                Label("View Calendar Debug Info", systemImage: "wrench.and.screwdriver")
            }
        }
    }
    
    // MARK: - Actions
    
    private func connectAppleCalendar() async {
        let success = await integrationManager.requestAppleCalendarAccess()
        
        if !success {
            await MainActor.run {
                errorMessage = "Failed to connect to iOS Calendar. Please check your privacy settings."
                showingConnectionError = true
            }
        }
    }
    
    private func connectGoogleCalendar() async {
        let success = await integrationManager.requestGoogleCalendarAccess()
        
        if !success {
            await MainActor.run {
                if let error = integrationManager.lastError {
                    errorMessage = error.localizedDescription
                } else {
                    errorMessage = "Failed to connect to Google Calendar. Please try again."
                }
                showingConnectionError = true
            }
        }
    }
    
    private func disconnectCalendar(_ type: CalendarIntegrationManager.CalendarType) async {
        await integrationManager.disconnectCalendar(type)
    }
    
    private func refreshConnectionStatus() async {
        // In a real implementation, this would refresh the connection status
        // For now, it's just for demo purposes
    }
}

// MARK: - Supporting Views

struct CalendarConnectionRow: View {
    let calendar: ConnectedCalendar
    let onDisconnect: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: calendar.type.iconName)
                .foregroundColor(.green)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(calendar.type.displayName)
                    .font(.headline)
                
                Text("Connected \(calendar.connectedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Disconnect") {
                onDisconnect()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(.red)
        }
        .padding(.vertical, 4)
    }
}

struct CalendarConnectionButton: View {
    let type: CalendarIntegrationManager.CalendarType
    let isConnected: Bool
    let isConnecting: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: type.iconName)
                .foregroundColor(isConnected ? .green : .gray)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.displayName)
                    .font(.headline)
                
                Text(connectionDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isConnecting {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button(isConnected ? "Disconnect" : "Connect") {
                    if isConnected {
                        onDisconnect()
                    } else {
                        onConnect()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .foregroundColor(isConnected ? .red : .blue)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var connectionDescription: String {
        if isConnected {
            return "Connected and syncing"
        } else {
            switch type {
            case .apple:
                return "Access your iOS calendar events"
            case .google:
                return "Access your Google Calendar events"
            case .both:
                return "Both calendar sources"
            }
        }
    }
}

struct HelpRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Calendar Debug View

struct CalendarDebugView: View {
    @StateObject private var integrationManager = CalendarIntegrationManager.shared
    @State private var mergedEvents: [CalendarEvent] = []
    @State private var workoutGaps: [WorkoutGap] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Connection Status") {
                    DebugRow(title: "Apple Calendar", value: integrationManager.hasAppleCalendarAccess ? "Connected" : "Not Connected")
                    DebugRow(title: "Google Calendar", value: integrationManager.hasGoogleCalendarAccess ? "Connected" : "Not Connected")
                    DebugRow(title: "Total Connected", value: "\(integrationManager.connectedCalendars.count)")
                }
                
                Section("Recent Events (\(mergedEvents.count))") {
                    if mergedEvents.isEmpty {
                        Text("No events found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(mergedEvents.prefix(10), id: \.id) { event in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.headline)
                                HStack {
                                    Text(event.startDate, style: .time)
                                    Text("-")
                                    Text(event.endDate, style: .time)
                                    Spacer()
                                    Text(event.source.rawValue.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(event.source == .google ? Color.blue : Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Detected Gaps (\(workoutGaps.count))") {
                    if workoutGaps.isEmpty {
                        Text("No gaps found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(workoutGaps.prefix(5), id: \.id) { gap in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("\(gap.durationInMinutes) min gap")
                                        .font(.headline)
                                    Spacer()
                                    Text(gap.quality.rawValue.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(gap.quality.color))
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                                Text("\(gap.startDate, style: .time) - \(gap.endDate, style: .time)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Suggested: \(gap.suggestedWorkoutType.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Refresh Data") {
                        Task {
                            await refreshDebugData()
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Calendar Debug")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await refreshDebugData()
                }
            }
        }
    }
    
    private func refreshDebugData() async {
        isLoading = true
        defer { isLoading = false }
        
        let now = Date()
        let endDate = now.addingTimeInterval(48 * 3600) // 48 hours
        
        let events = await integrationManager.fetchMergedCalendarEvents(
            startDate: now,
            endDate: endDate
        )
        
        let gaps = await integrationManager.detectGapsInMergedCalendars(
            startDate: now,
            endDate: endDate
        )
        
        await MainActor.run {
            self.mergedEvents = events
            self.workoutGaps = gaps
        }
    }
}

struct DebugRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CalendarSettingsView()
}