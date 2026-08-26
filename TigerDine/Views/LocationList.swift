//
//  LocationList.swift
//  TigerDine
//
//  Created by Campbell on 10/1/25.
//

import SwiftUI

// This view handles the actual location list, because having it inside ContentView was too complex
// (both visually and for the type checker).
struct LocationList: View {
    @Binding var openLocationsFirst: Bool
    @Binding var openLocationsOnly: Bool
    @Binding var searchText: String
    var hiddenLocations: Bool
    
    @Environment(DiningModel.self) var model
    
    // The dining locations need to be sorted before being displayed. Favorites should always be
    // shown first, followed by non-favorites. Afterwards, filters the sorted list based on any
    // current search text and the "open locations only" filtering option.
    private var filteredLocations: [DiningLocation] {
        let targetLocations = if hiddenLocations {
            model.locationsByDay[0].filter { location in
                model.hiddenLocations.contains(location)
            }
        } else {
            model.locationsByDay[0].filter { location in
                !model.hiddenLocations.contains(location)
            }
        }
        
        // Because "The Commons" should be C for "Commons" and not T for "The".
        func removeThe(_ name: String) -> String {
            let lowercased = name.lowercased()
            if lowercased.hasPrefix("the ") {
                return String(name.dropFirst(4))
            }
            return name
        }
        
        return targetLocations.sorted { firstLoc, secondLoc in
            let firstLocIsFavorite = model.favorites.contains(firstLoc)
            let secondLocIsFavorite = model.favorites.contains(secondLoc)
            
            // Favorites get priority!
            if firstLocIsFavorite != secondLocIsFavorite {
                return firstLocIsFavorite && !secondLocIsFavorite
            }
            
            // Additional sorting rule that sorts open locations ahead of closed locations,
            // if enabled.
            if openLocationsFirst {
                let firstIsOpen = (firstLoc.open == .open || firstLoc.open == .closingSoon)
                let secondIsOpen = (secondLoc.open == .open || secondLoc.open == .closingSoon)
                if firstIsOpen != secondIsOpen {
                    return firstIsOpen && !secondIsOpen
                }
            }
            return removeThe(firstLoc.name)
                .localizedCaseInsensitiveCompare(removeThe(secondLoc.name)) == .orderedAscending
        }.filter { location in
            // Search/open only filtering step.
            let searchedLocations = searchText.isEmpty || location.name.localizedCaseInsensitiveContains(searchText)
            let openLocations = !openLocationsOnly || location.open == .open || location.open == .closingSoon
            return searchedLocations && openLocations
        }
    }
    
    var body: some View {
        ForEach(filteredLocations, id: \.self) { location in
            NavigationLink(value: location) {
                VStack(alignment: .leading) {
                    HStack {
                        Text(location.name)
                        if model.favorites.contains(location) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                    switch location.open {
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
                    if let times = location.diningTimes, !times.isEmpty {
                        ForEach(times, id: \.self) { time in
                            Text("\(dateDisplay.string(from: time.openTime)) - \(dateDisplay.string(from: time.closeTime))")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Not Open Today")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .swipeActions {
                Button(action: {
                    withAnimation {
                        if model.favorites.contains(location) {
                            model.favorites.remove(location)
                        } else {
                            model.favorites.add(location)
                        }
                    }
                    
                }) {
                    if model.favorites.contains(location) {
                        Label("Unfavorite", systemImage: "star")
                    } else {
                        Label("Favorite", systemImage: "star")
                    }
                }
                .tint(model.favorites.contains(location) ? .yellow : nil)
                
                Button(action: {
                    withAnimation {
                        if model.hiddenLocations.contains(location) {
                            model.hiddenLocations.remove(location)
                        } else {
                            model.hiddenLocations.add(location)
                        }
                    }
                }) {
                    if model.hiddenLocations.contains(location) {
                        Label("Unhide", systemImage: "eye")
                    } else {
                        Label("Hide", systemImage: "eye.slash")
                    }
                }
                .tint(model.hiddenLocations.contains(location) ? .blue : nil)
            }
        }
    }
}
