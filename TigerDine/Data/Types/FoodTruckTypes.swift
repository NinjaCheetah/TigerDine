//
//  FoodTruckTypes.swift
//  TigerDine
//
//  Created by Campbell on 11/3/25.
//

import Foundation

/// A weekend food trucks even representing when it's happening and what food trucks will be there.
struct FoodTruckEvent: Hashable {
    let date: Date
    let openTime: Date
    let closeTime: Date
    let location: String
    let trucks: [String]
}

struct FoodTruck: Decodable, Hashable {
    let id: String
    let title: String
    let description: String
    let imageUrl: String
    let imageAltTag: String
    let url: String
    let datesAvailable: [String]
}
