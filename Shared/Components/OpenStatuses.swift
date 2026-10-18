//
//  OpenStatuses.swift
//  TigerDine
//
//  Created by Campbell Bagley on 10/12/26.
//

import Foundation

/// Gets the current open status of a location based on the open time and close time.
func getOpenStatus(openTime: Date, closeTime: Date, referenceTime: Date) -> OpenStatus {
    // If the location is open but the close time is within the next 30 minutes, label it as
    // closing soon, and do the opposite if it's closed but the open time is within the next 30
    // minutes.
    let calendar = Calendar.current
    if referenceTime >= openTime && referenceTime <= closeTime {
        // This is basically just for Bytes, it checks the case where the open and close times are
        // exactly 24 hours apart, which is only true for 24-hour locations.
        if closeTime == calendar.date(byAdding: .day, value: 1, to: openTime)! {
            return .open
        } else if closeTime < calendar.date(byAdding: .minute, value: 30, to: referenceTime)! {
            return .closingSoon
        }
        return .open
    } else if referenceTime < openTime && openTime <= calendar.date(byAdding: .minute, value: 30, to: referenceTime)! {
        return .openingSoon
    } else {
        return .closed
    }
}

/// Gets the current open status of a location with multiple opening periods based on all of its open and close times.
func getMultiOpenStatus(diningTimes: [DiningTimes]?, referenceTime: Date) -> OpenStatus {
    var openStatus: OpenStatus = .closed
    
    guard let diningTimes, !diningTimes.isEmpty else {
        return .closed
    }
    
    for i in diningTimes.indices {
        openStatus = getOpenStatus(
            openTime: diningTimes[i].openTime,
            closeTime: diningTimes[i].closeTime,
            referenceTime: referenceTime
        )
        
        // If we're closing soon for the current opening period, but then we're opening again at
        // the same time we close in the next period, we should just stick with "Open" because
        // showing "Closing Soon" for 30 minutes and then going straight back to "Open" is kinda
        // confusing. This issue has been observed with Petals specifically.
        if openStatus == .closingSoon && i != diningTimes.indices.last {
            if diningTimes[i].closeTime == diningTimes[i + 1].openTime {
                openStatus = .open
            }
        }
        
        // If the first event pass came back closed, loop again in case a later event has a
        // different status. This is mostly to accurately catch Gracie's/Brick City Cafe's
        // multiple open periods each day.
        if openStatus != .closed {
            return openStatus
        }
    }
    
    return .closed
}
