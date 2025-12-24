//
//  PushesModel.swift
//  TigerDine
//
//  Created by Campbell on 11/20/25.
//

import SwiftUI

@Observable
class VisitingChefPushesModel {
    var pushes: [ScheduledVistingChefPush] = [] {
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
    
    /// Cancel all reigstered push notifications for a specified visiting chef.
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
    
    func pushAlreadyRegisered(name: String, location: String, startTime: Date, endTime: Date) -> Bool {
        for push in pushes {
            if push.name == name && push.location == location && push.startTime == startTime && push.endTime == endTime {
                return true
            }
        }
        return false
    }

    private func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(pushes) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? decoder.decode([ScheduledVistingChefPush].self, from: data) {
            pushes = decoded
        }
    }
}
