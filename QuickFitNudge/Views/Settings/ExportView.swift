import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @StateObject private var exportManager = ExportManager()
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var exportFormat = ExportFormat.csv
    @State private var dateRange = DateRange.lastMonth
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    formatSection
                } header: {
                    Text("Export Format")
                } footer: {
                    formatFooterText
                }
                
                Section {
                    dateRangeSection
                } header: {
                    Text("Date Range")
                } footer: {
                    Text("Select the time period for your workout export")
                }
                
                Section {
                    previewSection
                } header: {
                    Text("Export Preview")
                }
                
                Section {
                    exportSection
                }
            }
            .navigationTitle("Export Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismissView()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(exportManager.lastError?.localizedDescription ?? "An unknown error occurred")
            }
        }
    }
    
    // MARK: - Format Section
    
    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose your preferred export format")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("Export Format", selection: $exportFormat) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    HStack {
                        Image(systemName: formatIcon(for: format))
                            .foregroundColor(formatColor(for: format))
                            .frame(width: 20)
                        VStack(alignment: .leading) {
                            Text(format.rawValue)
                                .font(.headline)
                            Text(formatDescription(for: format))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tag(format)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Date Range Section
    
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Date Range", selection: $dateRange) {
                ForEach(DateRange.allCases, id: \.self) { range in
                    VStack(alignment: .leading) {
                        Text(range.rawValue)
                            .font(.headline)
                        Text(dateRangeDescription(for: range))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(range)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Export Details")
                        .font(.headline)
                    Text(previewText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                previewRow("Format:", exportFormat.rawValue)
                previewRow("Period:", dateRange.rawValue)
                previewRow("File Type:", ".\(exportFormat.fileExtension)")
                previewRow("Estimated Size:", estimatedFileSize)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Export Section
    
    private var exportSection: some View {
        VStack(spacing: 16) {
            if exportManager.isExporting {
                VStack(spacing: 12) {
                    HStack {
                        Text("Exporting...")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(exportManager.exportProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: exportManager.exportProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                }
            } else {
                Button(action: performExport) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Workouts")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(exportManager.isExporting)
            }
            
            if !exportManager.isExporting {
                Text("Your data will be exported and can be shared or saved to Files")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func previewRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Methods
    
    private var formatFooterText: Text {
        switch exportFormat {
        case .csv:
            return Text("CSV files open in Excel, Google Sheets, and other spreadsheet apps")
        case .pdf:
            return Text("PDF includes formatted summaries and charts for easy viewing")
        case .json:
            return Text("JSON format for developers and advanced data analysis")
        }
    }
    
    private var previewText: String {
        let interval = dateRange.interval
        let days = Calendar.current.dateComponents([.day], from: interval.start, to: interval.end).day ?? 0
        return "Export covering \(days) days of workout data"
    }
    
    private var estimatedFileSize: String {
        let baseSize: Int
        switch exportFormat {
        case .csv: baseSize = 50 // KB per week
        case .pdf: baseSize = 200 // KB per week
        case .json: baseSize = 75 // KB per week
        }
        
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: dateRange.interval.start, to: dateRange.interval.end).weekOfYear ?? 1)
        let totalSize = baseSize * weeks
        
        if totalSize < 1024 {
            return "\(totalSize) KB"
        } else {
            return String(format: "%.1f MB", Double(totalSize) / 1024.0)
        }
    }
    
    private func formatIcon(for format: ExportFormat) -> String {
        switch format {
        case .csv: return "tablecells"
        case .pdf: return "doc.richtext"
        case .json: return "chevron.left.forwardslash.chevron.right"
        }
    }
    
    private func formatColor(for format: ExportFormat) -> Color {
        switch format {
        case .csv: return .green
        case .pdf: return .red
        case .json: return .orange
        }
    }
    
    private func formatDescription(for format: ExportFormat) -> String {
        switch format {
        case .csv: return "Spreadsheet format for Excel, Google Sheets"
        case .pdf: return "Formatted document with charts and summaries"
        case .json: return "Structured data format for developers"
        }
    }
    
    private func dateRangeDescription(for range: DateRange) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let interval = range.interval
        
        switch range {
        case .allTime:
            return "All recorded workouts"
        default:
            return "\(formatter.string(from: interval.start)) - \(formatter.string(from: interval.end))"
        }
    }
    
    private func performExport() {
        guard let userId = authManager.currentUser?.id else {
            showingError = true
            return
        }
        
        Task {
            do {
                let fileURL = try await exportManager.exportWorkouts(
                    format: exportFormat,
                    dateRange: dateRange,
                    userId: userId
                )
                
                await MainActor.run {
                    exportedFileURL = fileURL
                    showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    showingError = true
                }
            }
        }
    }
    
    private func dismissView() {
        // In a NavigationView context, this would dismiss the view
        // Implementation depends on how this view is presented
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Exclude some activities that don't make sense for file sharing
        controller.excludedActivityTypes = [
            .postToFacebook,
            .postToTwitter,
            .postToWeibo,
            .postToVimeo,
            .postToTencentWeibo,
            .postToFlickr,
            .assignToContact,
            .addToReadingList
        ]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Export History View

struct ExportHistoryView: View {
    @State private var exportHistory: [ExportRecord] = []
    
    var body: some View {
        NavigationView {
            List {
                if exportHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.badge.clock")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Exports Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        Text("Your export history will appear here after you create your first export.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(exportHistory) { record in
                        ExportHistoryRow(record: record)
                    }
                }
            }
            .navigationTitle("Export History")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadExportHistory()
            }
        }
    }
    
    private func loadExportHistory() {
        // In a real implementation, this would load from UserDefaults or CloudKit
        exportHistory = []
    }
}

struct ExportHistoryRow: View {
    let record: ExportRecord
    
    var body: some View {
        HStack {
            Image(systemName: iconForFormat(record.format))
                .font(.title2)
                .foregroundColor(colorForFormat(record.format))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(record.format.rawValue) Export")
                    .font(.headline)
                
                Text(record.dateRange)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Created \(record.createdAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(record.workoutCount) workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(record.fileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func iconForFormat(_ format: ExportFormat) -> String {
        switch format {
        case .csv: return "tablecells"
        case .pdf: return "doc.richtext"
        case .json: return "chevron.left.forwardslash.chevron.right"
        }
    }
    
    private func colorForFormat(_ format: ExportFormat) -> Color {
        switch format {
        case .csv: return .green
        case .pdf: return .red
        case .json: return .orange
        }
    }
}

struct ExportRecord: Identifiable {
    let id = UUID()
    let format: ExportFormat
    let dateRange: String
    let workoutCount: Int
    let fileSize: String
    let createdAt: Date
}

#Preview {
    ExportView()
        .environmentObject(AuthenticationManager.shared)
}