//
//  DetailView.swift
//  TigerDine
//
//  Created by Campbell on 9/1/25.
//

import SwiftUI
import SafariServices

struct DetailView: View {
    @State var locationId: Int
    
    @Environment(DiningModel.self) var model
    @Environment(\.openURL) private var openURL
    
    @State private var showingSafari: Bool = false
    @State private var occupancyLoading: Bool = true
    @State private var occupancyPercentage: Double = 0.0

    // This gets the location that we're meant to be displaying details about using the provided ID.
    private var location: DiningLocation {
        return model.locationsByDay[0].first { $0.id == locationId }!
    }
    
    // This creates a list of the time strings for the current day and following 6 days to display
    // in the "Upcoming Hours" section. I realized that it makes a lot more sense to do today + 6
    // rather than just the current calendar week's hours, because who cares what Tuesday's hours
    // were on Saturday, you want to know what Sunday's hours will be.
    private var weeklyHours: [WeeklyHours] {
        var newWeeklyHours: [WeeklyHours] = []
        for day in model.locationsByDay {
            for location in day {
                if location.id == locationId {
                    let weekdayFormatter = DateFormatter()
                    weekdayFormatter.dateFormat = "EEEE"
                    if let times = location.diningTimes, !times.isEmpty {
                        var timeStrings: [String] = []
                        for time in times {
                            timeStrings.append("\(dateDisplay.string(from: time.openTime)) - \(dateDisplay.string(from: time.closeTime))")
                        }
                        newWeeklyHours.append(
                            WeeklyHours(
                                day: weekdayFormatter.string(from: location.date),
                                date: location.date,
                                timeStrings: timeStrings
                            ))
                    } else {
                        newWeeklyHours.append(
                            WeeklyHours(
                                day: weekdayFormatter.string(from: location.date),
                                date: location.date,
                                timeStrings: ["Closed"]
                            ))
                    }
                }
            }
        }
        return newWeeklyHours
    }
    
    private var upNextString: String {
        let calendar = Calendar.current
        var newUpNextString = ""
        if location.open == .open || location.open == .closingSoon {
            if let diningTimes = location.diningTimes {
                for time in diningTimes {
                    // This case is here pretty much exclusively for Bytes, so that the string
                    // doesn't perpetually say that Bytes will close at 12:00 AM.
                    if time.closeTime == calendar.date(byAdding: .day, value: 1, to: time.openTime)! {
                        newUpNextString = "Open 24 Hours"
                        break
                    }
                    
                    if time.closeTime > Date() {
                        newUpNextString = "Closes \(dateDisplay.string(from: time.closeTime))"
                        break
                    }
                }
            }
        } else {
            for day in model.locationsByDay {
                if newUpNextString != "" {
                    break
                }

                for location in day {
                    if location.id == locationId {
                        if let diningTimes = location.diningTimes {
                            for time in diningTimes {
                                if time.openTime > Date() {
                                    if calendar.isDateInToday(time.openTime) {
                                        newUpNextString = "Opens \(dateDisplay.string(from: time.openTime)) Today"
                                        break
                                    } else {
                                        newUpNextString = "Opens \(upNextDisplay.string(from: time.openTime))"
                                        break
                                    }
                                }
                            }
                        }
                        // If this code is running, we already found our location match, and since
                        // there won't ever be another match we should stop looping for no reason.
                        break
                    }
                }
            }
        }
        // This condition should only ever be true if a location is closed all 7 days that we have
        // data for, so the fallback is to say "Closed this week".
        if newUpNextString == "" {
            newUpNextString = "Closed this week"
        }
        return newUpNextString
    }
    
    // Still a little broken, does not work for refresh. Need to fix.
    private func getOccupancy() async {
        // Only fetch occupancy data if the location is actually open right now. Otherwise, just
        // exit early and hide the spinner.
        if location.open == .open || location.open == .closingSoon {
            occupancyLoading = true
            switch await getOccupancyPercentage(mdoId: location.mdoId) {
            case .success(let occupancy):
                occupancyPercentage = occupancy
                occupancyLoading = false
            case .failure(let error):
                print(error)
                occupancyLoading = false
            }
        } else {
            occupancyLoading = false
        }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    Text(location.name)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(location.summary)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading) {
                        switch location.open {
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
                        Text(upNextString)
                            .foregroundStyle(.secondary)
                    }
//                    #if DEBUG
//                    HStack(spacing: 0) {
//                        ForEach(Range(1...5), id: \.self) { index in
//                            if occupancyPercentage > (20 * Double(index)) {
//                                Image(systemName: "person.fill")
//                            } else {
//                                Image(systemName: "person")
//                            }
//                        }
//                        ProgressView()
//                            .progressViewStyle(.circular)
//                            .frame(width: 18, height: 18)
//                            .opacity(occupancyLoading ? 1 : 0)
//                            .task {
//                                await getOccupancy()
//                            }
//                    }
//                    .foregroundStyle(Color.accent.opacity(occupancyLoading ? 0.5 : 1.0))
//                    .font(.title3)
//                    #endif
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 8, trailing: 8))
                .listRowBackground(Color.clear)
            }
            
            if let visitingChefs = location.visitingChefs, !visitingChefs.isEmpty {
                Section(
                    header: Text("Today's Visiting Chefs")
                ) {
                    ForEach(visitingChefs, id: \.self) { chef in
                        HStack(alignment: .top) {
                            Text(chef.name)
                            Spacer()
                            VStack(alignment: .trailing) {
                                switch chef.status {
                                case .hereNow:
                                    Text("Here Now")
                                        .foregroundStyle(.green)
                                case .gone:
                                    Text("Left For Today")
                                        .foregroundStyle(.red)
                                case .arrivingLater:
                                    Text("Arriving Later")
                                        .foregroundStyle(.red)
                                case .arrivingSoon:
                                    Text("Arriving Soon")
                                        .foregroundStyle(.orange)
                                case .leavingSoon:
                                    Text("Leaving Soon")
                                        .foregroundStyle(.orange)
                                }
                                Text("\(dateDisplay.string(from: chef.openTime)) - \(dateDisplay.string(from: chef.closeTime))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            
            if let dailySpecials = location.dailySpecials, !dailySpecials.isEmpty {
                Section(
                    header: Text("Today's Daily Specials")
                ) {
                    ForEach(dailySpecials, id: \.self) { special in
                        HStack(alignment: .top) {
                            Text(special.name)
                            Spacer()
                            Text(special.type)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section(
                header: Text("Upcoming Hours")
            ) {
                ForEach(weeklyHours, id: \.self) { day in
                    HStack(alignment: .top) {
                        Text(day.day)
                        Spacer()
                        VStack {
                            ForEach(day.timeStrings, id: \.self) { timeString in
                                Text(timeString)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            
            Section {
                Text(location.desc)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
            .listRowBackground(Color.clear)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Favorites toggle button.
                Button(action: {
                    if model.favorites.contains(location) {
                        model.favorites.remove(location)
                    } else {
                        model.favorites.add(location)
                    }
                }) {
                    if model.favorites.contains(location) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            //.font(.title3)
                    } else {
                        Image(systemName: "star")
                            .foregroundStyle(.yellow)
                            //.font(.title3)
                    }
                }
                // Open this location on the RIT map in embedded Safari.
                Button(action: {
                    showingSafari = true
                }) {
                    Image(systemName: "map")
                        //.font(.title3)
                }
                if let fdmpIds = location.fdmpIds {
                    NavigationLink(destination: MenuView(accountId: fdmpIds.accountId, locationId: fdmpIds.locationId)) {
                        Image(systemName: "menucard")
                    }
                }
            }
        }
        .contentMargins(.top, 0)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingSafari) {
            SafariView(url: URL(string: location.mapsUrl)!)
        }
        .refreshable {
            do {
                try await model.getHoursByDay()
            } catch {
                print(error)
            }
            await getOccupancy()
        }
    }
}

#Preview {
    let previewModel = DiningModel()
    
    // This sample data is taken from the actual data for Crossroads on April 23, 2026.
    // Why this day? I kept using Imagine's date as a sample, but then I realized that
    // a weekend date is maybe not the best to test with. So I just stepped it back
    // a single day to get a better picture of what a typical day looks like.
    // If it's ever important, the preview time is meant to be 12:00.
    let mockLocation = DiningLocation(
        id: 23,
        mdoId: 123,
        fdmpIds: FDMPIds(
            locationId: 7,
            accountId: 7
        ),
        name: "The Cafe & Market at Crossroads",
        summary: "Restaurant and Convenience Store",
        desc: "Located in the Crossroads building in Global Village, the Cafe and Market at Crossroads features a food court and convenience store. Inside of Crossroads are eight different food stations: grill, salad bar, pasta toss, pizza, Asian cuisine, deli, chef specials, and visiting chefs.\nThis location is cashless everyday after 7 p.m. Customers using cash may use a Tiger Spend Reload Station to add funds to an existing RIT ID card or a Reload Card.",
        mapsUrl: "https://maps.rit.edu/?mdo_id=123",
        date: Date(timeIntervalSince1970: 1776960000.0),
        diningTimes: [
            DiningTimes(
                openTime: Date(timeIntervalSince1970: 1776954600.0),
                closeTime: Date(timeIntervalSince1970: 1776992400.0)
            )
        ],
        open: .open,
        visitingChefs: [
            VisitingChef(
                name: "Esan's Kitchen",
                description: "Traditional Nigerian cuisine",
                openTime: Date(timeIntervalSince1970: 1776956400.0),
                closeTime: Date(timeIntervalSince1970: 1776967200.0),
                status: .hereNow
            ),
            VisitingChef(
                name: "P.H. Express",
                description: "Traditional Pakistani cuisine",
                openTime: Date(timeIntervalSince1970: 1776974400.0),
                closeTime: Date(timeIntervalSince1970: 1776985200.0),
                status: .arrivingLater
            )
        ],
        dailySpecials: [
            DailySpecial(
                name: "General Tso Chicken",
                type: "asian"
            ),
            DailySpecial(
                name: "Poutine",
                type: "Grill"
            )
        ]
    )
    
    previewModel.locationsByDay = [[mockLocation]]

    return NavigationStack {
        DetailView(locationId: 23)
    }
    .environment(previewModel)
}
