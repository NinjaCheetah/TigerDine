//
//  PushTypes.swift
//  TigerDine
//
//  Created by Campbell on 11/20/25.
//

import Foundation

/// Struct to represent a visiting chef notification that has already been scheduled, allowing it to be loaded again later to recall what notifications have been scheduled.
struct ScheduledVistingChefPush: Codable, Equatable {
    let uuid: String
    let name: String
    let location: String
    let startTime: Date
    let endTime: Date
}
