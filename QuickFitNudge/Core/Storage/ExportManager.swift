import Foundation
import UIKit
import PDFKit

// MARK: - Export Data Models

struct WorkoutExport {
    let user: UserInfo
    let dateRange: DateInterval
    let workouts: [CompletedWorkout]
    let statistics: WorkoutStatistics
    
    func toCSV() -> String {
        var csv = "Date,Time,Workout Name,Type,Duration (minutes),Exercises,Equipment,Family Friendly,Calories Burned,With Family,Notes\n"
        
        for workout in workouts {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            
            let date = dateFormatter.string(from: workout.date)
            let time = timeFormatter.string(from: workout.date)
            let durationMinutes = String(format: "%.1f", workout.duration / 60)
            let exercises = workout.exercises.joined(separator: "; ")
            let equipment = workout.equipment.joined(separator: "; ")
            let familyFriendly = workout.isFamilyFriendly ? "Yes" : "No"
            let calories = workout.caloriesBurned?.description ?? ""
            let withFamily = workout.withFamily ? "Yes" : "No"
            let notes = workout.notes?.replacingOccurrences(of: "\n", with: " ") ?? ""
            
            csv += "\"\(date)\",\"\(time)\",\"\(workout.name)\",\"\(workout.type)\",\"\(durationMinutes)\",\"\(exercises)\",\"\(equipment)\",\"\(familyFriendly)\",\"\(calories)\",\"\(withFamily)\",\"\(notes)\"\n"
        }
        
        return csv
    }
    
    func toPDF() -> Data {
        let pageWidth: CGFloat = 612 // 8.5 inches
        let pageHeight: CGFloat = 792 // 11 inches
        let margin: CGFloat = 50
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        
        return renderer.pdfData { context in
            var yPosition: CGFloat = margin
            
            // Start first page
            context.beginPage()
            
            // Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let title = "QuickFit Nudge - Workout History"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.black
            ]
            let titleSize = title.size(withAttributes: titleAttributes)
            title.draw(at: CGPoint(x: (pageWidth - titleSize.width) / 2, y: yPosition), withAttributes: titleAttributes)
            yPosition += titleSize.height + 20
            
            // User info and date range
            let headerFont = UIFont.systemFont(ofSize: 14)
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: headerFont,
                .foregroundColor: UIColor.black
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let userInfo = "User: \(user.name)"
            let dateRangeInfo = "Period: \(dateFormatter.string(from: dateRange.start)) - \(dateFormatter.string(from: dateRange.end))"
            
            userInfo.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
            yPosition += 20
            dateRangeInfo.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
            yPosition += 30
            
            // Statistics
            yPosition = drawStatistics(context: context, yPosition: yPosition, pageWidth: pageWidth, margin: margin)
            yPosition += 30
            
            // Workout details
            yPosition = drawWorkoutDetails(context: context, yPosition: yPosition, pageWidth: pageWidth, pageHeight: pageHeight, margin: margin)
        }
    }
    
    func toJSON() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return (try? encoder.encode(self)) ?? Data()
    }
    
    // MARK: - Private PDF Drawing Methods
    
    private func drawStatistics(context: UIGraphicsPDFRendererContext, yPosition: CGFloat, pageWidth: CGFloat, margin: CGFloat) -> CGFloat {
        var currentY = yPosition
        
        let sectionFont = UIFont.boldSystemFont(ofSize: 16)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: UIColor.black
        ]
        
        let contentFont = UIFont.systemFont(ofSize: 12)
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: contentFont,
            .foregroundColor: UIColor.black
        ]
        
        // Statistics section title
        "Summary Statistics".draw(at: CGPoint(x: margin, y: currentY), withAttributes: sectionAttributes)
        currentY += 25
        
        // Statistics grid
        let stats = [
            ("Total Workouts:", "\(statistics.totalWorkouts)"),
            ("Total Duration:", "\(String(format: "%.1f", statistics.totalDuration / 60)) minutes"),
            ("Average Duration:", "\(String(format: "%.1f", statistics.averageDuration / 60)) minutes"),
            ("Most Popular Type:", statistics.mostPopularType),
            ("Current Streak:", "\(statistics.currentStreak) days"),
            ("Total Calories:", "\(statistics.totalCalories)")
        ]
        
        let columnWidth = (pageWidth - 2 * margin) / 2
        
        for (index, (label, value)) in stats.enumerated() {
            let x = margin + (CGFloat(index % 2) * columnWidth)
            let y = currentY + (CGFloat(index / 2) * 20)
            
            label.draw(at: CGPoint(x: x, y: y), withAttributes: contentAttributes)
            value.draw(at: CGPoint(x: x + 120, y: y), withAttributes: contentAttributes)
        }
        
        currentY += CGFloat((stats.count + 1) / 2) * 20
        
        return currentY
    }
    
    private func drawWorkoutDetails(context: UIGraphicsPDFRendererContext, yPosition: CGFloat, pageWidth: CGFloat, pageHeight: CGFloat, margin: CGFloat) -> CGFloat {
        var currentY = yPosition
        
        let sectionFont = UIFont.boldSystemFont(ofSize: 16)
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionFont,
            .foregroundColor: UIColor.black
        ]
        
        let contentFont = UIFont.systemFont(ofSize: 10)
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: contentFont,
            .foregroundColor: UIColor.black
        ]
        
        // Workout details section title
        "Workout Details".draw(at: CGPoint(x: margin, y: currentY), withAttributes: sectionAttributes)
        currentY += 25
        
        // Table headers
        let headers = ["Date", "Workout", "Type", "Duration", "Family"]
        let columnWidths: [CGFloat] = [80, 150, 80, 80, 60]
        let tableWidth = columnWidths.reduce(0, +)
        let tableStartX = (pageWidth - tableWidth) / 2
        
        var headerX = tableStartX
        for (index, header) in headers.enumerated() {
            header.draw(at: CGPoint(x: headerX, y: currentY), withAttributes: sectionAttributes)
            headerX += columnWidths[index]
        }
        currentY += 20
        
        // Draw line under headers
        let headerLineRect = CGRect(x: tableStartX, y: currentY - 2, width: tableWidth, height: 1)
        context.cgContext.setFillColor(UIColor.black.cgColor)
        context.cgContext.fill(headerLineRect)
        currentY += 10
        
        // Workout rows
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy"
        
        for workout in workouts {
            // Check if we need a new page
            if currentY > pageHeight - margin - 30 {
                context.beginPage()
                currentY = margin
            }
            
            let rowData = [
                dateFormatter.string(from: workout.date),
                String(workout.name.prefix(20)),
                workout.type,
                "\(String(format: "%.0f", workout.duration / 60))m",
                workout.withFamily ? "Yes" : "No"
            ]
            
            var rowX = tableStartX
            for (index, data) in rowData.enumerated() {
                data.draw(at: CGPoint(x: rowX, y: currentY), withAttributes: contentAttributes)
                rowX += columnWidths[index]
            }
            currentY += 15
        }
        
        return currentY
    }
}

struct CompletedWorkout: Codable {
    let date: Date
    let name: String
    let type: String
    let duration: TimeInterval
    let exercises: [String]
    let equipment: [String]
    let isFamilyFriendly: Bool
    let withFamily: Bool
    let caloriesBurned: Int?
    let notes: String?
}

struct UserInfo: Codable {
    let name: String
    let email: String
    let joinDate: Date
}

struct WorkoutStatistics: Codable {
    let totalWorkouts: Int
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let mostPopularType: String
    let currentStreak: Int
    let totalCalories: Int
    let workoutsByType: [String: Int]
    let workoutsByMonth: [String: Int]
}

// MARK: - Export Format Enum

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case pdf = "PDF"
    case json = "JSON"
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .pdf: return "pdf"
        case .json: "json"
        }
    }
    
    var mimeType: String {
        switch self {
        case .csv: return "text/csv"
        case .pdf: return "application/pdf"
        case .json: return "application/json"
        }
    }
}

enum DateRange: String, CaseIterable {
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"
    case lastThreeMonths = "Last 3 Months"
    case lastYear = "Last Year"
    case allTime = "All Time"
    
    var interval: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .lastWeek:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return DateInterval(start: weekAgo, end: now)
        case .lastMonth:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return DateInterval(start: monthAgo, end: now)
        case .lastThreeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return DateInterval(start: threeMonthsAgo, end: now)
        case .lastYear:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return DateInterval(start: yearAgo, end: now)
        case .allTime:
            // Use a very old date as the start
            let distantPast = calendar.date(byAdding: .year, value: -10, to: now) ?? now
            return DateInterval(start: distantPast, end: now)
        }
    }
}

// MARK: - Export Manager

@MainActor
final class ExportManager: ObservableObject {
    
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var lastError: Error?
    
    func exportWorkouts(
        format: ExportFormat,
        dateRange: DateRange,
        userId: String
    ) async throws -> URL {
        isExporting = true
        exportProgress = 0.0
        defer { 
            isExporting = false
            exportProgress = 0.0
        }
        
        do {
            // Step 1: Fetch workout data (20% progress)
            exportProgress = 0.2
            let workoutData = try await fetchWorkoutData(for: userId, in: dateRange)
            
            // Step 2: Generate export content (60% progress)
            exportProgress = 0.6
            let exportData: Data
            let fileName: String
            
            switch format {
            case .csv:
                exportData = workoutData.toCSV().data(using: .utf8) ?? Data()
                fileName = "workout_export_\(formatDate(Date())).\(format.fileExtension)"
            case .pdf:
                exportData = workoutData.toPDF()
                fileName = "workout_export_\(formatDate(Date())).\(format.fileExtension)"
            case .json:
                exportData = workoutData.toJSON()
                fileName = "workout_export_\(formatDate(Date())).\(format.fileExtension)"
            }
            
            // Step 3: Save to temporary file (80% progress)
            exportProgress = 0.8
            let tempURL = try saveToTemporaryFile(data: exportData, fileName: fileName)
            
            // Step 4: Complete (100% progress)
            exportProgress = 1.0
            
            logInfo("Successfully exported \(workoutData.workouts.count) workouts as \(format.rawValue)", category: .general)
            
            return tempURL
            
        } catch {
            lastError = error
            logError("Export failed: \(error)", category: .general)
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchWorkoutData(for userId: String, in dateRange: DateRange) async throws -> WorkoutExport {
        // In a real implementation, this would fetch from CloudKit or local storage
        // For now, we'll create mock data
        
        let user = UserInfo(
            name: "QuickFit User",
            email: "user@example.com",
            joinDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        )
        
        let mockWorkouts = generateMockWorkouts(in: dateRange.interval)
        let statistics = calculateStatistics(from: mockWorkouts)
        
        return WorkoutExport(
            user: user,
            dateRange: dateRange.interval,
            workouts: mockWorkouts,
            statistics: statistics
        )
    }
    
    private func generateMockWorkouts(in interval: DateInterval) -> [CompletedWorkout] {
        let workoutTypes = WorkoutType.allCases
        let sampleWorkouts = [
            ("Push-ups", ["Push-ups: 10 reps", "Rest: 30 seconds"], ["None"]),
            ("Squats", ["Squats: 15 reps", "Hold: 5 seconds"], ["None"]),
            ("Plank", ["Plank hold: 30 seconds"], ["Exercise Mat"]),
            ("Jumping Jacks", ["Jumping Jacks: 20 reps"], ["None"]),
            ("Wall Sit", ["Wall sit: 45 seconds"], ["Wall"]),
            ("Lunges", ["Lunges: 10 each leg"], ["None"])
        ]
        
        var workouts: [CompletedWorkout] = []
        let calendar = Calendar.current
        var currentDate = interval.start
        
        while currentDate < interval.end {
            // Generate 1-3 workouts per week randomly
            if Int.random(in: 0...6) < 3 {
                let randomWorkout = sampleWorkouts.randomElement()!
                let randomType = workoutTypes.randomElement()!
                
                let workout = CompletedWorkout(
                    date: currentDate,
                    name: randomWorkout.0,
                    type: randomType.rawValue,
                    duration: TimeInterval(Int.random(in: 60...300)), // 1-5 minutes
                    exercises: randomWorkout.1,
                    equipment: randomWorkout.2,
                    isFamilyFriendly: randomType == .familyFriendly,
                    withFamily: randomType == .familyFriendly && Bool.random(),
                    caloriesBurned: Int.random(in: 15...50),
                    notes: Bool.random() ? "Great workout!" : nil
                )
                workouts.append(workout)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return workouts.sorted { $0.date < $1.date }
    }
    
    private func calculateStatistics(from workouts: [CompletedWorkout]) -> WorkoutStatistics {
        let totalWorkouts = workouts.count
        let totalDuration = workouts.reduce(0) { $0 + $1.duration }
        let averageDuration = totalWorkouts > 0 ? totalDuration / Double(totalWorkouts) : 0
        
        let typeGroups = Dictionary(grouping: workouts) { $0.type }
        let mostPopularType = typeGroups.max { $0.value.count < $1.value.count }?.key ?? "None"
        
        let totalCalories = workouts.compactMap { $0.caloriesBurned }.reduce(0, +)
        
        // Calculate current streak (mock calculation)
        let currentStreak = calculateCurrentStreak(from: workouts)
        
        let workoutsByType = typeGroups.mapValues { $0.count }
        let workoutsByMonth = calculateWorkoutsByMonth(from: workouts)
        
        return WorkoutStatistics(
            totalWorkouts: totalWorkouts,
            totalDuration: totalDuration,
            averageDuration: averageDuration,
            mostPopularType: mostPopularType,
            currentStreak: currentStreak,
            totalCalories: totalCalories,
            workoutsByType: workoutsByType,
            workoutsByMonth: workoutsByMonth
        )
    }
    
    private func calculateCurrentStreak(from workouts: [CompletedWorkout]) -> Int {
        guard !workouts.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedWorkouts = workouts.sorted { $0.date > $1.date }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for workout in sortedWorkouts {
            let workoutDate = calendar.startOfDay(for: workout.date)
            
            if calendar.isDate(workoutDate, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if workoutDate < currentDate {
                break
            }
        }
        
        return streak
    }
    
    private func calculateWorkoutsByMonth(from workouts: [CompletedWorkout]) -> [String: Int] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        let monthGroups = Dictionary(grouping: workouts) { workout in
            formatter.string(from: workout.date)
        }
        
        return monthGroups.mapValues { $0.count }
    }
    
    private func saveToTemporaryFile(data: Data, fileName: String) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func logInfo(_ message: String, category: LogCategory) {
        Logger.shared.info(message, category: category)
    }
    
    private func logError(_ message: String, category: LogCategory) {
        Logger.shared.error(message, category: category)
    }
}