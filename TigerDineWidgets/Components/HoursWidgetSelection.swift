//
//  HoursWidgetSelection.swift
//  TigerDine
//
//  Created by Campbell on 1/9/26.
//

import AppIntents

struct DiningLocationEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Location"
    )

    let id: Int
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = DiningLocationQuery()
}

struct DiningLocationQuery: EntityQuery {
    func entities(for identifiers: [Int]) async throws -> [DiningLocationEntity] {
        allEntities.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [DiningLocationEntity] {
        allEntities
    }

    private var allEntities: [DiningLocationEntity] {
        guard
            let data = UserDefaults(
                suiteName: "group.dev.ninjacheetah.RIT-Dining"
            )?.data(forKey: "cachedLocationsByDay"),
            let decoded = try? JSONDecoder().decode([[DiningLocation]].self, from: data)
        else { return [] }

        let todaysLocations = decoded.first ?? []

        let locations = todaysLocations.map {
            DiningLocationEntity(id: $0.id, name: $0.name)
        }
        
        // These are being sorted the same way the locations are in the app, alphabetical dropping a leading "the" so that they
        // appear in an order that makes sense.
        return locations.sorted {
            sortableLocationName($0.name)
                .localizedCaseInsensitiveCompare(
                    sortableLocationName($1.name)
                ) == .orderedAscending
        }
    }
}

struct LocationHoursIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Location"

    @Parameter(title: "Location")
    var location: DiningLocationEntity?
}

// I should probably move this to somewhere shared in the future since this same logic *is* used in LocationList.
private func sortableLocationName(_ name: String) -> String {
    let lowercased = name.lowercased()
    if lowercased.hasPrefix("the ") {
        return String(name.dropFirst(4))
    }
    return name
}
