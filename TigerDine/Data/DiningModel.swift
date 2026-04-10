//
//  DiningModel.swift
//  TigerDine
//
//  Created by Campbell on 10/1/25.
//

import SwiftUI
import WidgetKit

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
    // Loading state to access in the UI.
    var isLoaded = false
    // Locks
    var pushSchedulerLock = false
    
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
        print("loading from network")
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
        
        // Then refresh widget timelines with the new data.
        WidgetCenter.shared.reloadAllTimelines()
        
        // Then schedule a background refresh 6 hours from now.
        scheduleNextRefresh()
        
        // And finally set the loaded state to true.
        isLoaded = true
    }
    
    /// Wrapper function for the real getHoursByDay() that checks the last refreshed stamp and uses cached data if it's fresh or triggers a refresh if it's stale.
    func getHoursByDayCached() async throws {
        let now = Date()
        // If we can't access the lastRefreshed key, then there is likely no cache.
        if let lastRefreshed = lastRefreshed {
            if Calendar.current.startOfDay(for: now) == Calendar.current.startOfDay(for: lastRefreshed) {
                // Last refresh happened today, so the cache is fresh and we should load that.
                print("cache hit, trying load from cache")
                await getDaysRepresented()
                let decoder = JSONDecoder()
                
                // These checks ensure that the key can actually be loaded from UserDefaults and that the cached JSON data can
                // actually be loaded from the cache before trying to use it, to prevent potential crashes from force unwrapping
                // it. Currently unclear on what could make these fail if the lastRefreshed date loaded as today, but this should
                // mitigate it by falling back on a network load if they do.
                if let cacheUserDefaults = UserDefaults(suiteName: "group.dev.ninjacheetah.RIT-Dining") {
                    if let cacheData = cacheUserDefaults.data(forKey: "cachedLocationsByDay") {
                        let cachedLocationsByDay = try decoder.decode([[DiningLocation]].self, from: cacheData)
                        
                        // Load cache, update open status, do a notification cleanup, and return. We only need to clean up because
                        // loading cache means that there can't be any new notifications to schedule since the last real data refresh.
                        locationsByDay = cachedLocationsByDay
                        updateOpenStatuses()
                        await cleanupPushes()
                        
                        isLoaded = true
                        return
                    } else {
                        print("cache exists, but failed to load JSON data")
                    }
                } else {
                    print("cache appears to exist, but failed to load from UserDefaults")
                }
            }
            print("cache miss")
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
        guard !pushSchedulerLock else { return }
        pushSchedulerLock = true
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
        pushSchedulerLock = false
    }
    
    /// Cleans up old push notifications that have already been delivered so that we're not still tracking them forever.
    func cleanupPushes() async {
        let now = Date()
        for push in visitingChefPushes.pushes {
            if now > push.endTime {
                // Guard this with an if let to avoid force unwrapping the index. That's something that theoretically
                // should always be safe given that this is iterating over elements so obviously that element should exist,
                // however there was an issue where this would sometimes unwrap a nil. My theory is that there was a small
                // chance of this task getting run twice concurrently under certain conditions, and so one would remove the
                // notification right before the other tried, and then it would be gone and the index would be nil.
                if let pushIndex = visitingChefPushes.pushes.firstIndex(of: push) {
                    visitingChefPushes.pushes.remove(at: pushIndex)
                }
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
