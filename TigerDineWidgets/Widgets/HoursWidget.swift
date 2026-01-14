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
            diningTimes: [
                DiningTimes(openTime: startOfToday, closeTime: startOfTomorrow)
            ]
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
            open: baseEntry.diningTimes?.first!.openTime,
            close: baseEntry.diningTimes?.first!.closeTime
        )

        let entries = updateDates.map {
            OpenEntry(
                date: $0,
                name: baseEntry.name,
                diningTimes: baseEntry.diningTimes
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
            diningTimes: location.diningTimes
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
    let diningTimes: [DiningTimes]?
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
            if let diningTimes = entry.diningTimes {
                let openStatus = parseMultiOpenStatus(diningTimes: diningTimes)
                switch openStatus {
                case .open:
                    Text("Open")
                        .font(.title3)
                        .foregroundStyle(.green)
                case .closed:
                    Text("Closed")
                        .font(.title3)
                        .foregroundStyle(.red)
                case .openingSoon:
                    Text("Opening Soon")
                        .font(.title3)
                        .foregroundStyle(.orange)
                case .closingSoon:
                    Text("Closing Soon")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
                
                Text("\(dateDisplay.string(from: diningTimes[0].openTime)) - \(dateDisplay.string(from: diningTimes[0].closeTime))")
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
                diningTimes: entry.diningTimes,
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
    OpenEntry(
        date: .now,
        name: "Beanz",
        diningTimes: [
            DiningTimes(
                openTime: Date(timeIntervalSince1970: 1767963600),
                closeTime: Date(timeIntervalSince1970: 1767988800)
            )
        ]
    )
    OpenEntry(
        date: Date(timeIntervalSince1970: 1767978000),
        name: "Beanz",
        diningTimes: [
            DiningTimes(
                openTime: Date(timeIntervalSince1970: 1767963600),
                closeTime: Date(timeIntervalSince1970: 1767988800)
            )
        ]
    )
}
