//
//  VisitingChefsView.swift
//  TigerDine
//
//  Created by Campbell on 9/8/25.
//

import SwiftUI

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct VisitingChefsView: View {
    @Environment(DiningModel.self) var model
    
    @State private var locationsWithChefs: [DiningLocation] = []
    @State private var safariUrl: IdentifiableURL?
    @State private var chefDays: [String] = []
    @State private var focusedIndex: Int = 0
    
    // Builds a list of days that each contain a list of dining locations that have visiting chefs
    // to make displaying them as easy as possible.
    private var locationsWithChefsByDay: [[DiningLocation]] {
        var locationsWithChefsByDay = [[DiningLocation]]()
        for day in model.locationsByDay {
            var locationsWithChefs = [DiningLocation]()
            for location in day {
                if let visitingChefs = location.visitingChefs, !visitingChefs.isEmpty {
                    locationsWithChefs.append(location)
                }
            }
            locationsWithChefsByDay.append(locationsWithChefs)
        }
        return locationsWithChefsByDay
    }
    
    var body: some View {
        TabView(selection: $focusedIndex) {
            ForEach(0..<7, id: \.self) { index in
                List {
                    if locationsWithChefsByDay[index].isEmpty {
                        Section {
                            VStack {
                                Spacer()
                                
                                Image(systemName: "clock.badge.exclamationmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 75, height: 75)
                                    .foregroundStyle(.accent)
                                
                                Text("No visiting chefs today.")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 16)
                            .frame(maxWidth: .infinity)
                            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                            .listRowBackground(Color.clear)
                        }
                    } else {
                        ForEach(
                            locationsWithChefsByDay[index], id: \.self) { location in
                            if let visitingChefs = location.visitingChefs, !visitingChefs.isEmpty {
                                Section(
                                    header:
                                        HStack(alignment: .center) {
                                            Text(location.name)
                                            
                                            Spacer()
                                            
                                            Button {
                                                safariUrl = IdentifiableURL(
                                                    url: URL(string: location.mapsUrl)!
                                                )
                                            } label: {
                                                Image(systemName: "map")
                                                    .foregroundStyle(.accent)
                                            }
                                        }
                                ) {
                                    ForEach(visitingChefs, id: \.self) { chef in
                                        VStack(alignment: .leading) {
                                            Text(chef.name)
                                                .fontWeight(.semibold)
                                            
                                            Text(chef.description)
                                                .foregroundStyle(.secondary)
                                            
                                            if index == 0 {
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
                                            } else {
                                                Text(
                                                    "Arriving on \(weekdayFromDate.string(from: model.daysRepresented[index]))"
                                                )
                                                .foregroundStyle(.red)
                                            }
                                            
                                            Text(
                                                "\(dateDisplay.string(from: chef.openTime)) - \(dateDisplay.string(from: chef.closeTime))"
                                            )
                                            .foregroundStyle(.secondary)

                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .top, spacing: 0) {
            header
                .padding(.vertical, 8)
                .background(.background)
        }
        .refreshable {
            do {
                try await model.getHoursByDay()
            } catch {
                print(error)
            }
        }
        .navigationTitle("Visiting Chefs")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $safariUrl) { url in
            SafariView(url: url.url)
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        focusedIndex -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title)
                }
                .disabled(focusedIndex == 0)
                
                Spacer()
                
                Text(visitingChefDateDisplay.string(from: model.daysRepresented[focusedIndex]))
                    .font(.title)
                    .multilineTextAlignment(.center)
                    // Makes this text NOT animate when you tap a day's button.
                    .transaction { $0.animation = nil }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        focusedIndex += 1
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title)
                }
                .disabled(focusedIndex == 6)
            }
            .padding(.horizontal)
            
            Picker("Day", selection: Binding(
                get: { focusedIndex },
                set: { newValue in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        focusedIndex = newValue
                    }
                }
            )) {
                ForEach(0..<7, id: \.self) { index in
                    Text(
                        weekdayShortFromDate.string(
                            from: model.daysRepresented[index]
                        )
                    ).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
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
    
    var mockLocationsByDay: [[DiningLocation]] = []

    for i in 0..<7 {
        mockLocationsByDay.append([mockLocation])
    }
    
    previewModel.locationsByDay = mockLocationsByDay
    
    previewModel.daysRepresented = (0..<7).map { i in
        Date(timeIntervalSince1970: 1776960000.0 + Double(i * 86400))
    }
    
    return NavigationStack {
        VisitingChefsView()
    }
    .environment(previewModel)
}
