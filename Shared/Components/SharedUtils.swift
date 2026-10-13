//
//  SharedUtils.swift
//  TigerDine
//
//  Created by Campbell on 9/8/25.
//

import Foundation
import SafariServices
import SwiftUI

// Gross disgusting UIKit code :(
// There isn't a direct way to use integrated Safari from SwiftUI, except maybe in iOS 26? I'm not targeting that though so I must fall
// back on UIKit stuff.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

func getTCAPIFriendlyDateString(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

func getFDMPAPIFriendlyDateString(date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy/MM/dd"
    return formatter.string(from: date)
}

func getDateFromTimeStr(timeStr: String, forDate: Date?) -> Date {
    let timeParts = timeStr.split(separator: ":").map { Int($0) ?? 0 }
    // Clamp this because the RM API will use 24:00 to mean midnight, so we need to wrap that
    // around to 00:00.
    let hour: Int = timeParts[0] > 23 ? 0 : timeParts[0]
    let timeComponents = DateComponents(hour: hour, minute: timeParts[1], second: 00)
    
    let calendar = Calendar.current
    
    return calendar.date(
        bySettingHour: timeComponents.hour!,
        minute: timeComponents.minute!,
        second: timeComponents.second!,
        of: forDate ?? Date()
    )!
}

// The common date formatter that I'm using everywhere that open periods are shown within the app.
let dateDisplay: DateFormatter = {
    let display = DateFormatter()
    display.timeZone = TimeZone(identifier: "America/New_York")
    display.dateStyle = .none
    display.timeStyle = .short
    return display
}()

let upNextDisplay: DateFormatter = {
    let display = DateFormatter()
    display.timeZone = TimeZone(identifier: "America/New_York")
    display.dateFormat = "h:mm a EEE"
    return display
}()

let visitingChefDateDisplay: DateFormatter = {
    let display = DateFormatter()
    display.dateFormat = "EEEE, MMM d"
    display.locale = Locale(identifier: "en_US_POSIX")
    return display
}()

let fullTextDateDisplay: DateFormatter = {
    let display = DateFormatter()
    display.dateFormat = "EEEE, MMMM d"
    display.locale = Locale(identifier: "en_US_POSIX")
    return display
}()

let weekdayFromDate: DateFormatter = {
    let weekdayFormatter = DateFormatter()
    weekdayFormatter.dateFormat = "EEEE"
    return weekdayFormatter
}()

let weekdayShortFromDate: DateFormatter = {
    let weekdayFormatter = DateFormatter()
    weekdayFormatter.dateFormat = "EEE"
    return weekdayFormatter
}()

// Custom view extension that just applies modifiers in a block to the object it's applied to.
// Mostly useful for splitting up conditional modifiers that should only be applied for certain
// OS versions. (A returning feature from RNGTool!)
extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}
