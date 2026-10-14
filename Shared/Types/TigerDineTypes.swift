//
//  TigerDineTypes.swift
//  TigerDine
//
//  Created by Campbell Bagley on 10/12/26.
//
//  Final decoded types used to maintain the state of the app, created from TigerCenter/RIT Mobile
//  types through parser functions.

import Foundation

/// Enum to represent the four possible states a given location can be in.
enum OpenStatus: Codable {
    case open
    case closed
    case openingSoon
    case closingSoon
}

/// An individual open period for a location.
struct DiningTimes: Equatable, Hashable, Codable {
    var openTime: Date
    var closeTime: Date
}

/// Enum to represent the five possible states a visiting chef can be in.
enum VisitingChefStatus: Codable {
    case hereNow
    case gone
    case arrivingLater
    case arrivingSoon
    case leavingSoon
}

/// A visiting chef present at a location.
struct VisitingChef: Equatable, Hashable, Codable {
    let name: String
    let description: String
    var openTime: Date
    var closeTime: Date
    var status: VisitingChefStatus
}

/// A daily special at a location.
struct DailySpecial: Equatable, Hashable, Codable {
    let name: String
    let type: String
}

/// The IDs required to get the menu for a location from FD MealPlanner. Only present if the location appears in the map.
struct FDMPIds: Hashable, Codable {
    let locationId: Int
    let accountId: Int
}

/// The basic information about a dining location needed to display it in the app after parsing is finished.
struct DiningLocation: Identifiable, Hashable, Codable {
    let id: Int
    let mdoId: Int
    let fdmpIds: FDMPIds?
    let name: String
    let summary: String
    let desc: String
    let mapsUrl: String
    let websiteUrl: String?
    let date: Date
    let diningTimes: [DiningTimes]?
    var open: OpenStatus
    var visitingChefs: [VisitingChef]?
    let dailySpecials: [DailySpecial]?
}

/// Struct used to represent a day and its hours as strings. Type used for the hours of today and the next 6 days used in DetailView.
struct WeeklyHours: Hashable {
    let day: String
    let date: Date
    let timeStrings: [String]
}

struct FoodTruckAvailability: Hashable {
    let date: Date
    let openTime: Date
    let closeTime: Date
    let mapsUrl: String
    let locationName: String
    let location: String
}

struct FoodTruck: Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String
    let imageUrl: String
    let imageAltTag: String
    let url: String
    let availability: [FoodTruckAvailability]
}
