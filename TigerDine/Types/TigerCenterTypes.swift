//
//  TigerCenterTypes.swift
//  TigerDine
//
//  Created by Campbell on 9/2/25.
//
//  Types required to parse response data from the TigerCenter API endpoints.
//

import Foundation

/// Struct to parse the response data from the TigerCenter API when getting the information for a dining location.
struct DiningLocationTCParser: Decodable {
    /// An individual "event", which is just an open period for the location.
    struct Event: Decodable {
        /// Hour exceptions for the given event.
        struct HoursException: Decodable {
            let id: Int
            let name: String
            let startTime: String
            let endTime: String
            let daysOfWeek: [String]
            let startDate: String
            let endDate: String
            let open: Bool
        }
        let startTime: String
        let endTime: String
        let daysOfWeek: [String]
        let exceptions: [HoursException]?
    }
    /// An individual "menu", which can be either a daily special item or a visitng chef. Description needs to be optional because visiting chefs have descriptions but specials do not.
    struct Menu: Decodable {
        let name: String
        let description: String?
        let category: String
    }
    /// Other basic information to read from a location's JSON that we'll need later.
    let id: Int
    let mdoId: Int
    let name: String
    let summary: String
    let description: String
    let mapsUrl: String
    let events: [Event]
    let menus: [Menu]
}

/// Struct that probably doesn't need to exist but this made parsing the list of location responses easy.
struct DiningLocationsParser: Decodable {
    let locations: [DiningLocationTCParser]
}

/// Parser to read the occupancy data for a location.
struct DiningOccupancyParser: Decodable {
    /// Represents a per-hour occupancy rating.
    struct HourlyOccupancy: Decodable {
        let hour: Int
        let today: Int
        let today_max: Int
        let one_week_ago: Int
        let one_week_ago_max: Int
        let average: Int
    }
    let count: Int
    let location: String
    let building: String
    let mdo_id: Int
    let max_occ: Int
    let open_status: String
    let intra_loc_hours: [HourlyOccupancy]
}
