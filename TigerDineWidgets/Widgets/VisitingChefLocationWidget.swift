//
//  VisitingChefLocationWidget.swift
//  TigerDine
//
//  Created by Campbell on 4/14/26.
//

import WidgetKit
import SwiftUI

struct VisitingChefLocationWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> VisitingChefLocationWidgetEntry {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday)!

        return VisitingChefLocationWidgetEntry(
            date: Date(),
            name: "Select a Location",
            diningTimes: [
                DiningTimes(openTime: startOfToday, closeTime: startOfTomorrow)
            ],
            url: URL(string: "tigerdine://")!
        )
    }
    
    func snapshot(
            for configuration: LocationHoursIntent,
            in context: Context
    ) async -> VisitingChefLocationWidgetEntry {
        loadEntry(for: configuration) ?? placeholder(in: context)
    }

    func timeline(
        for configuration: LocationHoursIntent,
        in context: Context
    ) async -> Timeline<VisitingChefLocationWidgetEntry> {

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
            VisitingChefLocationWidgetEntry(
                date: $0,
                name: baseEntry.name,
                diningTimes: baseEntry.diningTimes,
                url: baseEntry.url
            )
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
    
    func loadEntry(for configuration: LocationHoursIntent) -> VisitingChefLocationWidgetEntry? {
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

        return VisitingChefLocationWidgetEntry(
            date: Date(),
            name: location.name,
            diningTimes: location.diningTimes,
            url: URL(string: "tigerdine:///location?id=\(location.id)")!
        )
    }
    
    func buildUpdateSchedule(
        now: Date,
        open: Date?,
        close: Date?
    ) -> [Date] {

        var dates: Set<Date> = [now]

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

struct VisitingChefLocationWidgetEntry: TimelineEntry {
    let date: Date
    let name: String
    let diningTimes: [DiningTimes]?
    let url: URL
}

struct VisitingChefLocationWidgetEntryView : View {
    var entry: VisitingChefLocationWidgetProvider.Entry
    
    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.name)
                .font(.title3)
                .fontWeight(.bold)
            
            if Calendar.current.isDateInToday(entry.date) {
                if let diningTimes = entry.diningTimes {
                    let openStatus = parseMultiOpenStatus(diningTimes: diningTimes, referenceTime: entry.date)
                    switch openStatus {
                    case .open:
                        Text("Open")
                            .foregroundStyle(.green)
                    case .closed:
                        Text("Closed")
                            .foregroundStyle(.red)
                    case .openingSoon:
                        Text("Opening Soon")
                            .foregroundStyle(.orange)
                    case .closingSoon:
                        Text("Closing Soon")
                            .foregroundStyle(.orange)
                    }
                    ForEach(diningTimes, id: \.self) { diningTime in
                        Text("\(dateDisplay.string(from: diningTime.openTime)) - \(dateDisplay.string(from: diningTime.closeTime))")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Closed")
                        .foregroundStyle(.red)
                    
                    Text("Not Open Today")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            } else {
                // If the date isn't today, show a placeholder telling the user to open TigerDine to
                // refresh the data and update the widget.
                Text("Open TigerDine to Refresh")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()

            OpeningHoursGauge(
                diningTimes: entry.diningTimes,
                referenceTime: entry.date
            )
        }
    }
}

struct VisitingChefLocationWidget: Widget {
    let kind: String = "VisitingChefLocationWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: LocationHoursIntent.self,
            provider: VisitingChefLocationWidgetProvider()
        ) { entry in
            VisitingChefLocationWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(entry.url)
        }
        .configurationDisplayName("Visiting Chefs by Location")
        .description("See what visiting chefs are at a given location.")
        .supportedFamilies([.systemSmall])
    }
}
