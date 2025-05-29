import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct WorkoutGapEntry: TimelineEntry {
    let date: Date
    let gap: CalendarGap?
    let configuration: ConfigurationIntent?
}

// MARK: - Timeline Provider
struct WorkoutGapProvider: IntentTimelineProvider {
    let calendarManager = CalendarManager.shared
    
    func placeholder(in context: Context) -> WorkoutGapEntry {
        WorkoutGapEntry(
            date: Date(),
            gap: CalendarGap.placeholder,
            configuration: nil
        )
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (WorkoutGapEntry) -> Void) {
        let entry = WorkoutGapEntry(
            date: Date(),
            gap: CalendarGap.placeholder,
            configuration: configuration
        )
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<WorkoutGapEntry>) -> Void) {
        Task {
            await calendarManager.scanForGaps(hours: 24)
            
            let currentDate = Date()
            let nextGap = calendarManager.upcomingGaps.first { $0.startDate > currentDate }
            
            let entry = WorkoutGapEntry(
                date: currentDate,
                gap: nextGap,
                configuration: configuration
            )
            
            // Update every 30 minutes
            let nextUpdate = currentDate.addingTimeInterval(30 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}

// MARK: - Widget View
struct WorkoutGapWidgetView: View {
    var entry: WorkoutGapProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(gap: entry.gap)
        case .systemMedium:
            MediumWidgetView(gap: entry.gap)
        case .systemLarge:
            LargeWidgetView(gap: entry.gap)
        case .accessoryCircular:
            CircularWidgetView(gap: entry.gap)
        case .accessoryRectangular:
            RectangularWidgetView(gap: entry.gap)
        default:
            SmallWidgetView(gap: entry.gap)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let gap: CalendarGap?
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: gap?.suggestedWorkoutType.iconName ?? "figure.run")
                .font(.largeTitle)
                .foregroundStyle(.blue.gradient)
            
            if let gap = gap {
                Text("\(gap.durationInMinutes) min")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(gap.startDate, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("No gaps")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let gap: CalendarGap?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Next Workout Gap")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let gap = gap {
                    HStack {
                        Image(systemName: gap.suggestedWorkoutType.iconName)
                            .font(.title2)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(gap.suggestedWorkoutType.rawValue)
                                .font(.headline)
                            Text("\(gap.durationInMinutes) minutes")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Label(gap.startDate, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No upcoming gaps")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Quality indicator
            if let gap = gap {
                VStack {
                    Circle()
                        .fill(Color(gap.quality.color).gradient)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("\(gap.durationInMinutes)")
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                    
                    Text(gap.quality.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let gap: CalendarGap?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Opportunities")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if let gap = gap {
                // Main gap card
                HStack {
                    Image(systemName: gap.suggestedWorkoutType.iconName)
                        .font(.largeTitle)
                        .foregroundStyle(.blue.gradient)
                        .frame(width: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gap.suggestedWorkoutType.rawValue)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("\(gap.durationInMinutes) minute window")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Label(gap.startDate, systemImage: "clock")
                            Text("-")
                            Text(gap.endDate, style: .time)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Quality badge
                    Text(gap.quality.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(gap.quality.color).opacity(0.2))
                        .foregroundColor(Color(gap.quality.color))
                        .cornerRadius(4)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Motivation
                Text("💪 \(gap.motivationalQuote)")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    
                    Text("No workout gaps found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Check your calendar permissions")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Spacer()
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Circular Widget (Apple Watch)
struct CircularWidgetView: View {
    let gap: CalendarGap?
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            if let gap = gap {
                VStack(spacing: 2) {
                    Image(systemName: gap.suggestedWorkoutType.iconName)
                        .font(.title2)
                    
                    Text("\(gap.durationInMinutes)m")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            } else {
                Image(systemName: "figure.run")
                    .font(.title2)
            }
        }
    }
}

// MARK: - Rectangular Widget (Apple Watch)
struct RectangularWidgetView: View {
    let gap: CalendarGap?
    
    var body: some View {
        HStack {
            Image(systemName: gap?.suggestedWorkoutType.iconName ?? "figure.run")
                .font(.title3)
            
            VStack(alignment: .leading) {
                if let gap = gap {
                    Text("\(gap.durationInMinutes) min gap")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(gap.startDate, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No gaps")
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Widget Configuration
struct QuickFitNudgeWidget: Widget {
    let kind: String = "QuickFitNudgeWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: WorkoutGapProvider()
        ) { entry in
            WorkoutGapWidgetView(entry: entry)
        }
        .configurationDisplayName("Workout Gaps")
        .description("See your next micro-workout opportunity")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Widget Bundle
@main
struct QuickFitNudgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuickFitNudgeWidget()
    }
}

// MARK: - Extensions
extension CalendarGap {
    static var placeholder: CalendarGap {
        CalendarGap(
            startDate: Date(),
            endDate: Date().addingTimeInterval(180),
            duration: 180,
            quality: .good,
            suggestedWorkoutType: .hiit
        )
    }
    
    var motivationalQuote: String {
        let quotes = [
            "Every minute counts!",
            "Small steps, big results!",
            "You've got this!",
            "Make it happen!",
            "Consistency is key!",
            "Your family is watching!",
            "Be their inspiration!",
            "Squeeze it in!"
        ]
        return quotes.randomElement() ?? "Let's go!"
    }
}

// MARK: - Configuration Intent
struct ConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Configure your workout widget")
} 