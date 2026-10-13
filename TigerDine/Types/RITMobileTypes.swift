//
//  RITMobileTypes.swift
//  TigerDine
//
//  Created by Campbell Bagley on 10/12/26.
//
//  Types required to parse responses from the more modern RIT Mobile API endpoints.
//

import Foundation

struct DiningLocationRMParser: Identifiable, Hashable, Codable {
    struct OpenHours: Hashable, Codable {
        let startTime: String
        let endTime: String
        let isOpen: Bool
    }
    
    struct VisitingChef: Hashable, Codable {
        let name: String
        let startTime: String
        let endTime: String
        let description: String
    }
    
    struct DailySpecial: Hashable, Codable {
        
    }
    
    let id: Int
    let clicId: Int
    let name: String
    let summary: String
    let description: String
    let mdoId: Int
    let onDemandId: Int
    let hasMenu: Bool
    let hasMenu2: Bool
    let openTimeString: String
    let dotwString: String
    let isOpen: Bool
    let closesTime: String
    let opensTime: String
    let open24h: Bool
    let openHours: [String: [OpenHours]]
    let visitingChefs: [String: [VisitingChef]]
    let dailySpecials: [String: [DailySpecial]]
    let dietaryTags: [String]
    let url: String
}
