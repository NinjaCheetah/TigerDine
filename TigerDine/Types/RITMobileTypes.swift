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
    struct OpenHoursRM: Hashable, Codable {
        let startTime: String
        let endTime: String
        let isOpen: Bool
    }
    
    struct VisitingChefRM: Hashable, Codable {
        let name: String
        let startTime: String
        let endTime: String
        let description: String
    }
    
    struct DailySpecialRM: Hashable, Codable {
        
    }
    
    let id: Int
    let clicId: Int
    let name: String
    let summary: String
    let description: String
    let mdoId: Int
    let onDemandId: Int?
    let hasMenu: Bool
    let hasMenu2: Bool
    let openTimeString: String
    let dotwString: String
    let isOpen: Bool
    let closesTime: String
    let opensTime: String
    let open24h: Bool
    let openHours: [String: [OpenHoursRM]]
    let visitingChefs: [String: [VisitingChefRM]]
    let dailySpecials: [DailySpecialRM]
    let dietaryTags: [String]
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case id, clicId, name, summary, description
        case mdoId, onDemandId, hasMenu, hasMenu2
        case openTimeString, dotwString, isOpen
        case closesTime, opensTime, open24h
        case openHours, visitingChefs
        case dailySpecials, dietaryTags, url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        clicId = try container.decode(Int.self, forKey: .clicId)
        name = try container.decode(String.self, forKey: .name)
        summary = try container.decode(String.self, forKey: .summary)
        description = try container.decode(String.self, forKey: .description)
        mdoId = try container.decode(Int.self, forKey: .mdoId)
        onDemandId = try container.decodeIfPresent(Int.self, forKey: .onDemandId)
        hasMenu = try container.decode(Bool.self, forKey: .hasMenu)
        hasMenu2 = try container.decode(Bool.self, forKey: .hasMenu2)
        openTimeString = try container.decode(String.self, forKey: .openTimeString)
        dotwString = try container.decode(String.self, forKey: .dotwString)
        isOpen = try container.decode(Bool.self, forKey: .isOpen)
        closesTime = try container.decode(String.self, forKey: .closesTime)
        opensTime = try container.decode(String.self, forKey: .opensTime)
        open24h = try container.decode(Bool.self, forKey: .open24h)
        openHours = try container.decode([String: [OpenHoursRM]].self, forKey: .openHours)

        visitingChefs = (try? container.decode(
            [String: [VisitingChefRM]].self,
            forKey: .visitingChefs
        )) ?? [:]

        dailySpecials = (try? container.decode(
            [DailySpecialRM].self,
            forKey: .dailySpecials
        )) ?? []

        dietaryTags = (try? container.decode(
            [String].self,
            forKey: .dietaryTags
        )) ?? []
        
        url = (try? container.decode(String.self, forKey: .url)) ?? ""
    }
}
