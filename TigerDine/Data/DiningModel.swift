//
//  DiningModel.swift
//  TigerDine
//
//  Created by Campbell on 10/1/25.
//

import SwiftUI

@Observable
class DiningModel {
    var locationsByDay = [[DiningLocation]]()
    var daysRepresented = [Date]()
    var lastRefreshed: Date? {
        get {
            let sharedDefaults = UserDefaults(suiteName: "group.dev.ninjacheetah.RIT-Dining")
            // If this fails, we should default to an interval of 0. 1970 is obviously going to register as stale cache and will
            // trigger a reload.
            return Date(timeIntervalSince1970: sharedDefaults?.double(forKey: "lastRefreshed") ?? 0.0)
        }
        set {
            let sharedDefaults = UserDefaults(suiteName: "group.dev.ninjacheetah.RIT-Dining")
            sharedDefaults?.set(newValue?.timeIntervalSince1970, forKey: "lastRefreshed")
        }
    }
    
    // External models that should be nested under this one.
    var favorites = Favorites()
    var notifyingChefs = NotifyingChefs()
    var visitingChefPushes = VisitingChefPushesModel()
    
    func getDaysRepresented() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let week: [Date] = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
        daysRepresented = week
    }
    
    /// This is the actual method responsible for making requests to the API for the current day and next 6 days to collect all of the information that the app needs for the various view. Making it part of the model allows it to be updated from any view at any time, and prevents excess API requests (if you never refresh, the app will never need to make more than 7 calls per launch).
    func getHoursByDay() async throws {
        await getDaysRepresented()
        var newLocationsByDay = [[DiningLocation]]()
        for day in daysRepresented {
            let dateString = day.formatted(.iso8601
                .year().month().day()
                .dateSeparator(.dash))
            switch await getAllDiningInfo(date: dateString) {
            case .success(let locations):
                var newDiningLocations = [DiningLocation]()
                for i in 0..<locations.locations.count {
                    let diningInfo = parseLocationInfo(location: locations.locations[i], forDate: day)
                    newDiningLocations.append(diningInfo)
                }
                newLocationsByDay.append(newDiningLocations)
            case .failure(let error):
                throw(error)
            }
        }
        
        // Encode all the locations as JSON.
        let encoder = JSONEncoder()
        let encodedLocationsByDay = try encoder.encode(newLocationsByDay)
        
        // Write the data out so it's cached for later.
        let sharedDefaults = UserDefaults(suiteName: "group.dev.ninjacheetah.RIT-Dining")
        sharedDefaults?.set(encodedLocationsByDay, forKey: "cachedLocationsByDay")
        
        // Once we're done caching, update the UI.
        locationsByDay = newLocationsByDay
        lastRefreshed = Date()
        
        // And then schedule push notifications.
        await scheduleAllPushes()
        
        // And finally schedule a background refresh 6 hours from now.
        scheduleNextRefresh()
    }
    
    /// Wrapper function for the real getHoursByDay() that checks the last refreshed stamp and uses cached data if it's fresh or triggers a refresh if it's stale.
    func getHoursByDayCached() async throws {
        let now = Date()
        // If we can't access the lastRefreshed key, then there is likely no cache.
        if let lastRefreshed = lastRefreshed {
            if Calendar.current.startOfDay(for: now) == Calendar.current.startOfDay(for: lastRefreshed) {
                // Last refresh happened today, so the cache is fresh and we should load that.
                await getDaysRepresented()
                let decoder = JSONDecoder()
                let cachedLocationsByDay = try decoder.decode([[DiningLocation]].self, from: (UserDefaults(suiteName: "group.dev.ninjacheetah.RIT-Dining")!.data(forKey: "cachedLocationsByDay")!))
                print(cachedLocationsByDay)
                
                // Load cache, update open status, do a notification cleanup, and return. We only need to clean up because loading
                // cache means that there can't be any new notifications to schedule since the last real data refresh.
                locationsByDay = cachedLocationsByDay
                updateOpenStatuses()
                await cleanupPushes()
                return
            }
            // Otherwise, the cache is stale and we can fall out to the call to update it.
        }
        try await getHoursByDay()
    }
    
    /// Iterates through all of the locations and updates their open status indicator based on the current time. Does a replace to make sure that it updates any views observing this model.
    func updateOpenStatuses() {
        locationsByDay = locationsByDay.map { day in
            day.map { location in
                var location = location
                location.updateOpenStatus()
                return location
            }
        }
    }
    
    /// Schedules and saves push notifications for all enabled visiting chefs.
    func scheduleAllPushes() async {
        for day in locationsByDay {
            for location in day {
                if let visitingChefs = location.visitingChefs {
                    for chef in visitingChefs {
                        if notifyingChefs.contains(chef.name) {
                            await visitingChefPushes.scheduleNewPush(
                                name: chef.name,
                                location: location.name,
                                startTime: chef.openTime,
                                endTime: chef.closeTime
                            )
                        }
                    }
                }
            }
        }
        // Run a cleanup task once we're done scheduling.
        await cleanupPushes()
    }
    
    /// Cleans up old push notifications that have already been delivered so that we're not still tracking them forever.
    func cleanupPushes() async {
        let now = Date()
        for push in visitingChefPushes.pushes {
            if now > push.endTime {
                visitingChefPushes.pushes.remove(at: visitingChefPushes.pushes.firstIndex(of: push)!)
            }
        }
    }
    
    /// Cancels all pending push notifications. Used when disabling push notifications as a whole.
    func cancelAllPushes() async {
        let uuids = visitingChefPushes.pushes.map(\.uuid)
        await cancelVisitingChefNotifs(uuids: uuids)
        visitingChefPushes.pushes.removeAll()
    }
    
    /// Schedules and saves push notifications for a specific visiting chef.
    func schedulePushesForChef(_ chefName: String) async {
        for day in locationsByDay {
            for location in day {
                if let visitingChefs = location.visitingChefs {
                    for chef in visitingChefs {
                        if chef.name == chefName && notifyingChefs.contains(chef.name) {
                            await visitingChefPushes.scheduleNewPush(
                                name: chef.name,
                                location: location.name,
                                startTime: chef.openTime,
                                endTime: chef.closeTime
                            )
                        }
                    }
                }
            }
        }
    }
}
