//
//  PushesModel.swift
//  TigerDine
//
//  Created by Campbell on 11/20/25.
//

import SwiftUI

@Observable
class VisitingChefPushesModel {
    private var pushes: [ScheduledVistingChefPush] = [] {
        didSet {
            save()
        }
    }
    private let key = "ScheduledVisitingChefPushes"
    
    init() {
        load()
    }
    
    /// Schedule a new push notification with the notification center and save its information to UserDefaults if it succeeded.
    func scheduleNewPush(name: String, location: String, startTime: Date, endTime: Date) async {
        guard !pushAlreadyRegisered(name: name, location: location, startTime: startTime, endTime: endTime) else { return }
        let uuid_string = await scheduleVisitingChefNotif(
            name: name,
            location: location,
            startTime: startTime,
            endTime: endTime
        )
        // An empty UUID means that the notification wasn't scheduled for one reason or another. This is ignored for now.
        if uuid_string != "" {
            pushes.append(
                ScheduledVistingChefPush(
                    uuid: uuid_string,
                    name: name,
                    location: location,
                    startTime: startTime,
                    endTime: endTime
                )
            )
            save()
        }
    }
    
    /// Cancels all reigstered push notifications for a specified visiting chef.
    func cancelPushesForChef(name: String) {
        var uuids: [String] = []
        for push in pushes {
            if push.name == name {
                uuids.append(push.uuid)
            }
        }
        Task {
            await cancelVisitingChefNotifs(uuids: uuids)
        }
        // Once they're canceled, we can drop them from the list.
        pushes.removeAll { $0.name == name }
        save()
    }
    
    /// Cancels all pending push notifications. Used when disabling push notifications as a whole.
    func cancelAllPushes() async {
        let uuids = pushes.map(\.uuid)
        await cancelVisitingChefNotifs(uuids: uuids)
        pushes.removeAll()
    }
    
    /// Checks if a push notification meeting the specified criteria is already scheduled.
    func pushAlreadyRegisered(name: String, location: String, startTime: Date, endTime: Date) -> Bool {
        for push in pushes {
            if push.name == name
                && push.location == location
                && push.startTime == startTime
                && push.endTime == endTime
            {
                return true
            }
        }
        return false
    }
    
    /// Cleans up old push notifications that have already been delivered so that we're not still
    /// tracking them forever.
    func cleanupPushes() async {
        let now = Date()
        
        for push in pushes {
            if now > push.endTime {
                // Guard this with an if let to avoid force unwrapping the index. That's something
                // that theoretically should always be safe given that this is iterating over
                // elements so obviously that element should exist,  however there was an issue
                // where this would sometimes unwrap a nil. My theory is that there was a small
                // chance of this task getting run twice concurrently under certain conditions, and
                // so one would remove the notification right before the other tried, and then it
                // would be gone and the index would be nil.
                if let pushIndex = pushes.firstIndex(of: push) {
                    pushes.remove(at: pushIndex)
                }
            }
        }
    }

    /// Write out the registered push notifications.
    private func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(pushes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// Load registered push notifications.
    private func load() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? decoder.decode([ScheduledVistingChefPush].self, from: data) {
            pushes = decoded
        }
    }
}
