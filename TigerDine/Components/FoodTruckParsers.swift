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
func parseWeekendFoodTrucks(htmlString: String) -> [Date: [FoodTruckEvent]] {
    do {
        let doc = try SwiftSoup.parse(htmlString)
        var eventsForDates: [Date: [FoodTruckEvent]] = [:]

        let paragraphs = try doc.select("p:has(strong)")
        
        for p in paragraphs {
            let text = try p.text()
            let parts = text.components(separatedBy: .whitespaces).joined(separator: " ")
            
            let dateRegex = /(?:([A-Za-z]+),\s+[A-Za-z]+\s+\d+)/
            guard let dateMatch = parts.firstMatch(of: dateRegex) else { continue }
            let date = String(dateMatch.0)
            
            let timeRegex = /\d{1,2}(?::\d{2})?\s*(?:[ap]\.?m\.?)?\s*[-–]\s*\d{1,2}(?::\d{2})?\s*[ap]\.?m\.?/
            let time = parts.firstMatch(of: timeRegex).map { String($0.0) } ?? ""
            
            let locationRegex = /[A-Za-z-]+\s+Lot/
            let location = parts.firstMatch(of: locationRegex).map { String($0.0) } ?? "M Lot"
            
            let year = Calendar.current.component(.year, from: Date())
            let fullDateString = "\(date) \(year)"
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMMM d yyyy"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            let dateParsed = formatter.date(from: fullDateString) ?? Date()
            
            func parseTimeComponent(_ raw: String, defaultPeriod: String, on date: Date) -> Date? {
                let isAM = raw.contains("a.m")
                let isPM = raw.contains("p.m")
                let isAfternoon = isPM || (!isAM && defaultPeriod == "p.m.")
                
                let clean = raw.filter(":0123456789".contains)
                let components = clean.split(separator: ":", maxSplits: 1)
                
                guard let hourStr = components.first, var hour = Int(hourStr) else { return nil }
                let minute = components.count > 1 ? (Int(components[1]) ?? 0) : 0
                
                if isAfternoon {
                    if hour < 12 { hour += 12 }
                } else {
                    if hour == 12 { hour = 0 }
                }
                
                return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date)
            }
            
            let timeStrings = time.components(separatedBy: CharacterSet(charactersIn: "-–"))
            var openTime = dateParsed
            var closeTime = dateParsed
            
            if let openRaw = timeStrings.first?.trimmingCharacters(in: .whitespaces),
               let closeRaw = timeStrings.last?.trimmingCharacters(in: .whitespaces) {
                
                let closePeriod = closeRaw.contains("a.m") ? "a.m." : "p.m."
                
                openTime = parseTimeComponent(openRaw, defaultPeriod: closePeriod, on: dateParsed) ?? dateParsed
                closeTime = parseTimeComponent(closeRaw, defaultPeriod: "p.m.", on: dateParsed) ?? dateParsed
            }
            
            if let ul = try p.nextElementSibling(), ul.tagName() == "ul" {
                let trucks = try ul.select("li").array().map { try $0.text() }
                
                var existingEvents: [FoodTruckEvent] = eventsForDates[dateParsed] ?? []
                existingEvents.append(FoodTruckEvent(
                    date: dateParsed,
                    openTime: openTime,
                    closeTime: closeTime,
                    location: location,
                    trucks: trucks
                ))
                
                eventsForDates[dateParsed] = existingEvents
            }
        }
        
        return eventsForDates
    } catch {
        print(error)
        return [:]
    }
}
