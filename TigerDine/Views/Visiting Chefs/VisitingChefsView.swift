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
                            locationsWithChefsByDay[index],
                            id: \.self
                        ) { location in
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
                                            
                                            HStack(spacing: 3) {
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
                                                
                                                Text("•")
                                                    .foregroundStyle(.secondary)
                                                
                                                Text(
                                                    "\(dateDisplay.string(from: chef.openTime)) - \(dateDisplay.string(from: chef.closeTime))"
                                                )
                                                .foregroundStyle(.secondary)
                                            }
                                            
                                            Text(chef.description)
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
        .safeAreaInset(edge: .top, spacing: 0) {
            header
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
                    focusedIndex -= 1
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title)
                }
                .disabled(focusedIndex == 0)
                
                Spacer()
                
                Text(visitingChefDateDisplay.string(from: model.daysRepresented[focusedIndex]))
                    .font(.title)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button(action: {
                    focusedIndex += 1
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title)
                }
                .disabled(focusedIndex == 6)
            }
            .padding(.horizontal)
            
            Picker("Day", selection: $focusedIndex) {
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
    VisitingChefsView()
}
