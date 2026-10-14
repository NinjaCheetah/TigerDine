//
//  RITMobileParsers.swift
//  TigerDine
//
//  Created by Campbell Bagley on 10/12/26.
//
//  Parsing functions to convert the intermediary RIT Mobile parsing types into the final common
//  types used in the app.
//

import Foundation

func parseLocationInfoRM(location: DiningLocationRMParser, forDate: Date?) -> DiningLocation {
    print("beginning parse for \(location.name) (id: \(location.id)) from RM API")
    
    // Pull the matching summary from the hardcoded map.
    let summary: String = if constLocationInfo.keys.contains(location.id) {
        constLocationInfo[location.id]!["summary"]!
    } else {
        location.summary
    }
    
    // Pull the matching description from the hardcoded map.
    let desc: String = if constLocationInfo.keys.contains(location.id) {
        constLocationInfo[location.id]!["description"]!
    } else {
        location.description
    }
    
    // Check if this location's ID is in the TigerCenter -> FD MealPlanner ID map and save those
    // IDs if it is.
    let fdmpIds: FDMPIds? = if tCtoFDMPMap.keys.contains(location.id) {
        FDMPIds(
            locationId: tCtoFDMPMap[location.id]!.0,
            accountId: tCtoFDMPMap[location.id]!.1
        )
    } else {
        nil
    }
    
    // Generate a maps URL from the mdoId key. This is required because the mapsUrl served by
    // TigerCenter is not compatible with the new RIT map that was deployed in December 2025.
    let mapsUrl = "https://maps.rit.edu/?mdo_id=\(location.mdoId)"
    
    // Get the string for the date we're processing.
    let dateStr: String = if let date = forDate {
        getTCAPIFriendlyDateString(date: date)
    } else {
        getTCAPIFriendlyDateString(date: Date())
    }
    
    // Early return if there are no events, good for things like the food trucks which can very
    // easily have no openings in a week.
    if !location.openHours.keys.contains(dateStr) {
        return DiningLocation(
            id: location.id,
            mdoId: location.mdoId,
            fdmpIds: fdmpIds,
            name: location.name,
            summary: summary,
            desc: desc,
            mapsUrl: mapsUrl,
            websiteUrl: location.url,
            date: forDate ?? Date(),
            diningTimes: nil,
            open: .closed,
            visitingChefs: nil,
            dailySpecials: nil
        )
    }
    
    var openStrings: [String] = []
    var closeStrings: [String] = []
    
    // Unlike TigerCenter, the RIT Mobile API always lists the hours for each day individually, so
    // we don't have to worry about all the nonsense that we had to worry about for TigerCenter.
    if let openings = location.openHours[dateStr] {
        for opening in openings {
            if opening.isOpen {
                openStrings.append(opening.startTime)
                closeStrings.append(opening.endTime)
            }
        }
    }
    
    // Early return if there are no valid opening times, most likely because the day's exceptions
    // dictate that the location is closed.  Mostly comes into play on holidays.
    if openStrings.isEmpty || closeStrings.isEmpty {
        return DiningLocation(
            id: location.id,
            mdoId: location.mdoId,
            fdmpIds: fdmpIds,
            name: location.name,
            summary: summary,
            desc: desc,
            mapsUrl: mapsUrl,
            websiteUrl: location.url,
            date: forDate ?? Date(),
            diningTimes: nil,
            open: .closed,
            visitingChefs: nil,
            dailySpecials: nil)
    }
    
    // I hate all of this date component nonsense.
    // But hey at least this is the only hellish part of this parsing process, unlike TigerCenter.
    var openDates: [Date] = []
    var closeDates: [Date] = []
    
    let calendar = Calendar.current
    let now = Date()
    
    for i in 0..<openStrings.count {
        openDates.append(getDateFromTimeStr(timeStr: openStrings[i], forDate: forDate))
        closeDates.append(getDateFromTimeStr(timeStr: closeStrings[i], forDate: forDate))
    }
    var diningTimes: [DiningTimes] = []
    for i in 0..<openDates.count {
        diningTimes.append(DiningTimes(openTime: openDates[i], closeTime: closeDates[i]))
    }
    
    // If the closing time is less than or equal to the opening time, it's probably midnight and
    // means either open until midnight or open 24/7, in the case of Bytes.
    for i in diningTimes.indices {
        if diningTimes[i].closeTime <= diningTimes[i].openTime {
            diningTimes[i].closeTime = calendar.date(byAdding: .day, value: 1, to: diningTimes[i].closeTime)!
        }
    }
    
    // Sometimes the openings are not in order, for some reason. I know this happened with
    // TigerCenter and I'd like to think it won't happen with the RIT Mobile APIs, but I'd rather
    // be safe than sorry.
    diningTimes.sort { $0.openTime < $1.openTime }
    
    // Get the current open status for a location. Details about how this works can be seen in the
    // docs for getOpenStatus().
    var openStatus: OpenStatus = .closed
    for i in diningTimes.indices {
        openStatus = getOpenStatus(openTime: diningTimes[i].openTime, closeTime: diningTimes[i].closeTime, referenceTime: now)
        // If the first event pass came back closed, loop again in case a later event has a
        // different status. This is mostly to accurately catch Gracie's multiple open periods
        // each day.
        if openStatus != .closed {
            break
        }
    }
    
    // Handle visiting chefs, which can be done so much more easily than with the TigerCenter APIs.
    let visitingChefs: [VisitingChef]?
    if let visitingChefsForDate = location.visitingChefs[dateStr] {
        var chefs: [VisitingChef] = []
        for chef in visitingChefsForDate {
            print("found visiting chef: \(chef.name)")
            let openTime = getDateFromTimeStr(timeStr: chef.startTime, forDate: forDate)
            let closeTime = getDateFromTimeStr(timeStr: chef.endTime, forDate: forDate)
            
            // Parse the chef's status, mapping the OpenStatus to a VisitingChefStatus.
            let visitngChefStatus: VisitingChefStatus = switch getOpenStatus(openTime: openTime, closeTime: closeTime, referenceTime: now) {
            case .open:
                    .hereNow
            case .closed:
                if now < openTime {
                    .arrivingLater
                } else {
                    .gone
                }
            case .openingSoon:
                    .arrivingSoon
            case .closingSoon:
                    .leavingSoon
            }
            
            chefs.append(VisitingChef(
                name: chef.name,
                description: chef.description,
                openTime: openTime,
                closeTime: closeTime,
                status: visitngChefStatus)
            )
        }
        visitingChefs = chefs
    } else {
        visitingChefs = nil
    }
    
    // Same with the daily specials.
    let dailySpecials: [DailySpecial]?
    if !location.dailySpecials.isEmpty {
        // I need RIT to actually put in some daily specials so that I can understand how to parse
        // this data!!!!! Until then we're just going to always default to nil.
        dailySpecials = nil
    } else {
        dailySpecials = nil
    }
    
    return DiningLocation(
        id: location.id,
        mdoId: location.mdoId,
        fdmpIds: fdmpIds,
        name: location.name,
        summary: summary,
        desc: desc,
        mapsUrl: mapsUrl,
        websiteUrl: location.url,
        date: forDate ?? Date(),
        diningTimes: diningTimes,
        open: openStatus,
        visitingChefs: visitingChefs,
        dailySpecials: dailySpecials
    )
}

func parseFoodTruckInfoRM(truck: FoodTruckRMParser) -> FoodTruck {
    var availability: [FoodTruckAvailability] = []
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    
    for dateAvailable in truck.datesAvailable {
        // Get today's date to use for the availability and to combine with the timestamps.
        let date = dateFormatter.date(from: dateAvailable.date)!
        
        let openTime = getDateFromTimeStr(timeStr: dateAvailable.startTime, forDate: date)
        let closeTime = getDateFromTimeStr(timeStr: dateAvailable.endTime, forDate: date)
        
        availability.append(
            FoodTruckAvailability(
                date: date,
                openTime: openTime,
                closeTime: closeTime,
                mapsUrl: dateAvailable.url,
                locationName: dateAvailable.urlTitle,
                location: dateAvailable.location
            )
        )
    }
    
    return FoodTruck(
        id: Int(truck.id)!, // This **SHOULD** always be okay??
        name: truck.title,
        description: truck.description,
        imageUrl: truck.imageUrl,
        imageAltTag: truck.imageAltTag,
        url: truck.url,
        availability: availability
    )
}
