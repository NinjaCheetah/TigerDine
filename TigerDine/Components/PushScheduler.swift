//
//  PushScheduler.swift
//  TigerDine
//
//  Created by Campbell on 10/3/25.
//

import Foundation
import UserNotifications

/// Function to schedule a notification for a visting chef showing up on campus using the name, location, and timeframe. Returns the UUID string assigned to the notification.
func scheduleVisitingChefNotif(name: String, location: String, startTime: Date, endTime: Date) async -> String {
    // Validate that the user has authorized TigerDine to send you notifications before trying to schedule one.
    let center = UNUserNotificationCenter.current()
    let settings = await center.notificationSettings()
    guard (settings.authorizationStatus == .authorized) else { return "" }
    
    // Build the notification content from the name, location, and timeframe.
    let content = UNMutableNotificationContent()
    if name == "P.H. Express" {
        content.title = "Good Food is Waiting"
    } else {
        content.title = "\(name) Is On Campus Today"
    }
    content.body = "\(name) will be at \(location) from \(dateDisplay.string(from: startTime))-\(dateDisplay.string(from: endTime))"
    content.sound = .default
    
    // Get the time that we're going to schedule the notification for, which is a specified number of hours before the chef
    // shows up. This is configurable from the notification settings.
    let offset: Int = UserDefaults.standard.integer(forKey: "notificationOffset")
    // The ternary happening on this line is stupid, but the UserDefaults key isn't always initialized because it's being used
    // through @AppStorage. This will eventually be refactored into something better, but this system should work for now to
    // ensure that we never use an offset of 0.
    let notifTime = Calendar.current.date(byAdding: .hour, value: -(offset != 0 ? offset : 2), to: startTime)!
    let notifTimeComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notifTime)
    let trigger = UNCalendarNotificationTrigger(dateMatching: notifTimeComponents, repeats: false)
    
    // Create the request with the content and time.
    let uuid_string = UUID().uuidString
    let request = UNNotificationRequest(identifier: uuid_string, content: content, trigger: trigger)
    
    // Hook into the notification center and attempt to schedule the notification.
    let notificationCenter = UNUserNotificationCenter.current()
    do {
        try await notificationCenter.add(request)
        print("successfully scheduled notification for chef \(name) to be delivered at \(notifTime)")
        return uuid_string
    } catch {
        // Presumably this shouldn't ever happen? That's what I'm hoping for!
        print(error)
        return ""
    }
}

/// Cancel a list of pending visiting chef notifications using their UUIDs.
func cancelVisitingChefNotifs(uuids: [String]) async {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: uuids)
    print("successfully cancelled pending notifications with UUIDs: \(uuids)")
}
