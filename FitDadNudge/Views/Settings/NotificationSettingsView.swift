import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationIntelligence = NotificationIntelligence()
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var showingInsights = false
    @State private var insights: NotificationInsights?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    notificationLevelPicker
                } header: {
                    Text("Notification Frequency")
                } footer: {
                    frequencyFooterText
                }
                
                Section {
                    quietHoursSection
                } header: {
                    Text("Quiet Hours")
                } footer: {
                    Text("No notifications will be sent during these hours")
                }
                
                Section {
                    insightsSection
                } header: {
                    Text("Your Notification Activity")
                }
                
                if notificationManager.authorizationStatus != .authorized {
                    Section {
                        notificationPermissionSection
                    } header: {
                        Text("Permission Required")
                    } footer: {
                        Text("Enable notifications in Settings to receive workout reminders")
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadInsights()
            }
            .sheet(isPresented: $showingInsights) {
                NotificationInsightsView(insights: insights)
            }
        }
    }
    
    // MARK: - Notification Level Picker
    
    private var notificationLevelPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How often would you like workout reminders?")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("Notification Frequency", selection: $notificationIntelligence.notificationLevel) {
                ForEach(NotificationIntelligence.NotificationLevel.allCases, id: \.self) { level in
                    VStack(alignment: .leading) {
                        Text(levelTitle(for: level))
                            .font(.headline)
                        Text(levelDescription(for: level))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(level)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Quiet Hours Section
    
    private var quietHoursSection: some View {
        VStack(spacing: 16) {
            Toggle("Enable Quiet Hours", isOn: $notificationIntelligence.quietHoursEnabled)
            
            if notificationIntelligence.quietHoursEnabled {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Start")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker(
                            "Start Time",
                            selection: $notificationIntelligence.quietHoursStart,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading) {
                        Text("End")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker(
                            "End Time",
                            selection: $notificationIntelligence.quietHoursEnd,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                    }
                }
            }
        }
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(spacing: 12) {
            if let insights = insights {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Last 30 Days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(insights.totalSent) notifications sent")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Response Rate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(insights.responseRate * 100))%")
                            .font(.headline)
                            .foregroundColor(responseRateColor(insights.responseRate))
                    }
                }
                
                if insights.recommendedLevel != notificationIntelligence.notificationLevel {
                    recommendationCard(for: insights.recommendedLevel)
                }
                
                Button("View Detailed Insights") {
                    showingInsights = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            } else {
                Text("Loading insights...")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Permission Section
    
    private var notificationPermissionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.slash")
                    .foregroundColor(.orange)
                VStack(alignment: .leading) {
                    Text("Notifications Disabled")
                        .font(.headline)
                    Text("You'll miss workout reminders")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Button("Enable in Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Helper Views
    
    private func recommendationCard(for level: NotificationIntelligence.NotificationLevel) -> some View {
        HStack {
            Image(systemName: "lightbulb")
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading) {
                Text("Recommendation")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Try '\(levelTitle(for: level))' for better engagement")
                    .font(.subheadline)
            }
            
            Spacer()
            
            Button("Apply") {
                notificationIntelligence.notificationLevel = level
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private var frequencyFooterText: Text {
        switch notificationIntelligence.notificationLevel {
        case .minimal:
            return Text("Perfect for focused workers who prefer minimal interruptions")
        case .balanced:
            return Text("Good balance between reminders and focus time")
        case .aggressive:
            return Text("Maximum motivation for building strong workout habits")
        case .off:
            return Text("You'll only receive notifications for critical updates")
        }
    }
    
    private func levelTitle(for level: NotificationIntelligence.NotificationLevel) -> String {
        switch level {
        case .minimal: return "Minimal"
        case .balanced: return "Balanced" 
        case .aggressive: return "Aggressive"
        case .off: return "Off"
        }
    }
    
    private func levelDescription(for level: NotificationIntelligence.NotificationLevel) -> String {
        switch level {
        case .minimal: return "1 notification per day maximum"
        case .balanced: return "2 notifications per day maximum"
        case .aggressive: return "3 notifications per day maximum"
        case .off: return "No workout notifications"
        }
    }
    
    private func responseRateColor(_ rate: Double) -> Color {
        if rate > 0.6 { return .green }
        if rate > 0.3 { return .orange }
        return .red
    }
    
    private func loadInsights() {
        insights = notificationIntelligence.getNotificationFrequencyInsights()
    }
}

// MARK: - Insights Detail View

struct NotificationInsightsView: View {
    let insights: NotificationInsights?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let insights = insights {
                    Form {
                        Section("Activity Summary") {
                            insightRow("Total Notifications", value: "\(insights.totalSent)")
                            insightRow("Response Rate", value: "\(Int(insights.responseRate * 100))%")
                            insightRow("Ignore Rate", value: "\(Int(insights.ignoreRate * 100))%")
                            insightRow("Daily Average", value: String(format: "%.1f", insights.averagePerDay))
                        }
                        
                        Section("Optimization") {
                            HStack {
                                Text("Recommended Level")
                                Spacer()
                                Text(insights.recommendedLevel.rawValue)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Section("Tips") {
                            optimizationTips
                        }
                    }
                } else {
                    Text("No insights available")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Notification Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func insightRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
    
    private var optimizationTips: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let insights = insights {
                if insights.ignoreRate > 0.5 {
                    tipRow("Consider reducing notification frequency", icon: "minus.circle")
                }
                if insights.responseRate > 0.7 {
                    tipRow("Your engagement is excellent!", icon: "checkmark.circle")
                }
                if insights.averagePerDay < 1 && insights.responseRate > 0.5 {
                    tipRow("You might benefit from more frequent reminders", icon: "plus.circle")
                }
            }
        }
    }
    
    private func tipRow(_ text: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    NotificationSettingsView()
}