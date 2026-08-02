//
//  FoodTruckParsers.swift
//  TigerDine
//
//  Created by Campbell on 11/3/25.
//

import Foundation
import SwiftSoup

// This code is actually miserable and might break sometimes. Sorry. Parse the HTML of the RIT food
// trucks web page and build a list of food trucks that are going to be there the next time they're
// there. This is not a good way to get this data but it's unfortunately the best way that I think
// I could make it happen. Sorry again for both my later self and anyone else who tries to work on
// this code.
func parseWeekendFoodTrucks(htmlString: String) -> [FoodTruckEvent] {
    do {
        let doc = try SwiftSoup.parse(htmlString)
        var events: [FoodTruckEvent] = []
        let now = Date()
        let calendar = Calendar.current
        
        let paragraphs = try doc.select("p:has(strong)")
        
        for p in paragraphs {
            let text = try p.text()
            let parts = text.components(separatedBy: .whitespaces).joined(separator: " ")
            
            let dateRegex = /(?:([A-Za-z]+),\s+[A-Za-z]+\s+\d+)/
            let date = parts.firstMatch(of: dateRegex).map { String($0.0) } ?? ""
            if date.isEmpty { continue }
            
            let timeRegex = /(\d{1,2}(:\d{2})?\s*p\.m\.\s*[-–]\s*\d{1,2}(:\d{2})?\s*p\.m\.|\d{1,2}(:\d{2})?\s*[-–]\s*\d{1,2}(:\d{2})?\s*p\.m\.)/
            let time = parts.firstMatch(of: timeRegex).map { String($0.0) } ?? ""
            
            let locationRegex = /[A-Za-z-]+\s+Lot/
            let location = parts.firstMatch(of: locationRegex).map { String($0.0) } ?? "M Lot"
            
            let year = Calendar.current.component(.year, from: Date())
            let fullDateString = "\(date) \(year)"
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMMM d yyyy"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let dateParsed = formatter.date(from: fullDateString) ?? now
            
            let timeStrings = time.components(separatedBy: CharacterSet(charactersIn: "-–"))
            print("raw open range: \(timeStrings)")
            var openTime = Date()
            var closeTime = Date()
            
            if let openString = timeStrings.first?.trimmingCharacters(in: .whitespaces) {
                let openHourString = openString.filter("0123456789".contains)
                if !openHourString.isEmpty, let baseHour = Int(openHourString) {
                    let openHour = openString.contains("a.m") ? baseHour : (baseHour == 12 ? 12 : baseHour + 12)
                    openTime = calendar.date(bySettingHour: openHour, minute: 0, second: 0, of: dateParsed) ?? now
                }
            }
            
            if let closeString = timeStrings.last?.trimmingCharacters(in: .whitespaces) {
                let closeClean = closeString.filter(":0123456789".contains)
                let closeStringComponents = closeClean.split(separator: ":", maxSplits: 1)
                if let baseHour = Int(closeStringComponents.first ?? "") {
                    let closeHour = baseHour == 12 ? 12 : baseHour + 12
                    let closeMinute = closeStringComponents.count > 1 ? (Int(closeStringComponents[1]) ?? 0) : 0
                    closeTime = calendar.date(bySettingHour: closeHour, minute: closeMinute, second: 0, of: dateParsed) ?? now
                }
            }
            
            if let ul = try p.nextElementSibling(), ul.tagName() == "ul" {
                let trucks = try ul.select("li").array().map { try $0.text() }
                
                events.append(FoodTruckEvent(
                    date: dateParsed,
                    openTime: openTime,
                    closeTime: closeTime,
                    location: location,
                    trucks: trucks
                ))
                print(events)
            }
        }
        
        return events
    } catch {
        print(error)
        return []
    }
}
