//
//  HoursWidget.swift
//  TigerDineWidgets
//
//  Created by Campbell on 1/8/26.
//

import WidgetKit
import SwiftUI

// This timeline provider is currently held together by duct tape. But hey, that's what beta testing is for.
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> OpenEntry {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        return OpenEntry(
            date: Date(),
            name: "Select a Location",
            openTime: startOfToday,
            closeTime: startOfTomorrow
        )
    }
    
    func snapshot(
            for configuration: LocationHoursIntent,
            in context: Context
    ) async -> OpenEntry {
        loadEntry(for: configuration) ?? placeholder(in: context)
    }

    func timeline(
        for configuration: LocationHoursIntent,
        in context: Context
    ) async -> Timeline<OpenEntry> {

        guard let baseEntry = loadEntry(for: configuration) else {
            return Timeline(
                entries: [placeholder(in: context)],
                policy: .atEnd
            )
        }

        let updateDates = buildUpdateSchedule(
            now: Date(),
            open: baseEntry.openTime,
            close: baseEntry.closeTime
        )

        let entries = updateDates.map {
            OpenEntry(
                date: $0,
                name: baseEntry.name,
                openTime: baseEntry.openTime,
                closeTime: baseEntry.closeTime
            )
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
    
    func loadEntry(for configuration: LocationHoursIntent) -> OpenEntry? {
        guard let selectedLocation = configuration.location else {
            return nil
        }
        
        guard
            let data = UserDefaults(suiteName: "group.dev.ninjacheetah.RIT-Dining")?.data(forKey: "cachedLocationsByDay"),
            let decoded = try? JSONDecoder().decode([[DiningLocation]].self, from: data),
            let todayLocations = decoded.first,
            let location = todayLocations.first(where: {
                $0.id == selectedLocation.id
            })
        else {
            return nil
        }

        return OpenEntry(
            date: Date(),
            name: location.name,
            openTime: location.diningTimes?.first?.openTime,
            closeTime: location.diningTimes?.first?.closeTime
        )
    }
    
    func buildUpdateSchedule(
        now: Date,
        open: Date?,
        close: Date?
    ) -> [Date] {

        var dates: Set<Date> = []

        dates.insert(now)

        if let open = open, let close = close {
            dates.insert(open)
            dates.insert(close)
        }

        let interval: TimeInterval = 5 * 60
        let end = Calendar.current.date(byAdding: .hour, value: 24, to: now)!

        var t = now
        while t < end {
            dates.insert(t)
            t = t.addingTimeInterval(interval)
        }

        return dates
            .filter { $0 >= now }
            .sorted()
    }
}

struct OpenEntry: TimelineEntry {
    let date: Date
    let name: String
    let openTime: Date?
    let closeTime: Date?
}

struct OpenWidgetEntryView : View {
    var entry: Provider.Entry
    
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.name)
                .font(.title2)
                .fontWeight(.bold)
            
            // Should maybe try to unify this with the almost-identical UI code in DetailView.
            if let openTime = entry.openTime, let closeTime = entry.closeTime {
                if entry.date >= openTime && entry.date <= closeTime {
                    if closeTime == calendar.date(byAdding: .day, value: 1, to: openTime)! {
                        Text("Open")
                            .font(.title3)
                            .foregroundStyle(.green)
                    } else if closeTime < calendar.date(byAdding: .minute, value: 30, to: entry.date)! {
                        Text("Closing Soon")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    } else {
                        Text("Open")
                            .font(.title3)
                            .foregroundStyle(.green)
                    }
                } else if openTime <= calendar.date(byAdding: .minute, value: 30, to: entry.date)! && closeTime > entry.date {
                    Text("Opening Soon")
                        .font(.title3)
                        .foregroundStyle(.orange)
                } else {
                    Text("Closed")
                        .font(.title3)
                        .foregroundStyle(.red)
                }
                
                Text("\(dateDisplay.string(from: openTime)) - \(dateDisplay.string(from: closeTime))")
                    .foregroundStyle(.secondary)
            } else {
                Text("Closed")
                    .font(.title3)
                    .foregroundStyle(.red)
                
                Text("Not Open Today")
                    .foregroundStyle(.secondary)
            }
                        
            Spacer()

            OpeningHoursGauge(
                openTime: entry.openTime,
                closeTime: entry.closeTime,
                now: entry.date
            )
        }
    }
}

struct HoursWidget: Widget {
    let kind: String = "HoursWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: LocationHoursIntent.self,
            provider: Provider()
        ) { entry in
            OpenWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Location Hours")
        .description("See today's hours for a chosen location.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    HoursWidget()
} timeline: {
    OpenEntry(date: .now, name: "Beanz", openTime: Date(timeIntervalSince1970: 1767963600), closeTime: Date(timeIntervalSince1970: 1767988800))
    OpenEntry(date: Date(timeIntervalSince1970: 1767978000), name: "Beanz", openTime: Date(timeIntervalSince1970: 1767963600), closeTime: Date(timeIntervalSince1970: 1767988800))
}
